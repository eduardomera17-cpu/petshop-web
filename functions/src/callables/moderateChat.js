// functions/src/callables/moderateChat.js
// Callable de moderación de chat exclusivo para SUPERADMIN (TRD §2.11, §3.4.E, MC-08, CA-AD-47)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, storage } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { recordAuditLog } from '../lib/audit.js';

export const moderateChat = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación estricta de rol SUPERADMIN (TRD §3.4.E)
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    assertRole(request.auth, ROLES.SUPERADMIN);

    if (request.auth.token?.status && request.auth.token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const callerUid = request.auth.uid;
    const callerName = request.auth.token?.name || 'Super Administrador';
    const { operation, chatId, messageId } = request.data || {};

    if (!chatId || typeof chatId !== 'string' || chatId.trim() === '') {
      throw new HttpsError('invalid-argument', 'chatId es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedChatId = chatId.trim();
    const chatRef = db.collection('chats').doc(trimmedChatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      throw new HttpsError('not-found', 'Sala de chat no encontrada.', {
        errorCode: 'CHAT_NOT_FOUND',
      });
    }

    // 2. INVARIANTE INVIOLABLE: Prohibición absoluta de edición de texto (MC-08)
    // Queda terminantemente prohibida la edición de contenido de un mensaje ajeno, incluso para el rol SUPERADMIN
    if (operation === 'EDIT_MESSAGE' || operation === 'UPDATE_MESSAGE' || request.data?.text !== undefined) {
      throw new HttpsError(
        'invalid-argument',
        'Prohibida la edición de texto de un mensaje ajeno (MC-08 solo contempla borrado).',
        { errorCode: 'EDIT_MESSAGE_PROHIBITED' }
      );
    }

    // 3. Ejecución según la operación de moderación autorizada
    switch (operation) {
      case 'DELETE_MESSAGE': {
        if (!messageId || typeof messageId !== 'string' || messageId.trim() === '') {
          throw new HttpsError('invalid-argument', 'messageId es obligatorio para DELETE_MESSAGE.', {
            errorCode: 'INVALID_ARGUMENT',
          });
        }
        const trimmedMessageId = messageId.trim();
        const msgRef = chatRef.collection('messages').doc(trimmedMessageId);
        const msgDoc = await msgRef.get();
        if (!msgDoc.exists) {
          throw new HttpsError('not-found', 'Mensaje no encontrado.', {
            errorCode: 'MESSAGE_NOT_FOUND',
          });
        }

        // Borrar el mensaje (el trigger onMessageDeleted reajustará contadores y Storage)
        await msgRef.delete();
        break;
      }

      case 'PURGE_ROOM':
      case 'PURGE_THREAD': {
        // Purgar todos los mensajes de la sala
        await db.recursiveDelete(chatRef.collection('messages'));
        try {
          await storage.deleteFiles({ prefix: `media/chat/${trimmedChatId}/` });
        } catch (err) {
          console.warn(`Error al eliminar imágenes en Storage para media/chat/${trimmedChatId}/:`, err);
        }

        await chatRef.update({
          staffUnreadCount: 0,
          messageCount: 0,
          lastMessageText: null,
          lastMessageTimestamp: null,
          lastMessageSenderName: null,
          lastMessageSenderUid: null,
          updatedAt: FieldValue.serverTimestamp(),
        });
        break;
      }

      case 'BLOCK_ROOM': {
        await chatRef.update({
          isBlocked: true,
          updatedAt: FieldValue.serverTimestamp(),
        });
        break;
      }

      case 'UNBLOCK_ROOM': {
        await chatRef.update({
          isBlocked: false,
          updatedAt: FieldValue.serverTimestamp(),
        });
        break;
      }

      case 'DELETE_ARCHIVED_CHAT': {
        const chatData = chatDoc.data() || {};
        if (!chatData.isArchived) {
          throw new HttpsError('failed-precondition', 'Solo se pueden eliminar salas que hayan sido archivadas previamente.', {
            errorCode: 'CHAT_NOT_ARCHIVED',
          });
        }
        // Purgar mensajes y Storage
        await db.recursiveDelete(chatRef.collection('messages'));
        try {
          await storage.deleteFiles({ prefix: `media/chat/${trimmedChatId}/` });
        } catch (err) {
          console.warn(`Error al eliminar imágenes en Storage para media/chat/${trimmedChatId}/:`, err);
        }
        // Marcar la sala eliminada o eliminarla
        await chatRef.delete();
        break;
      }

      default:
        throw new HttpsError('invalid-argument', `Operación de moderación no reconocida: ${operation}`, {
          errorCode: 'INVALID_OPERATION',
        });
    }

    // 4. Registro obligatorio en /audit_log (TRD §2.12, §3.4.E, MC-08)
    await recordAuditLog(db, {
      actorUid: callerUid,
      actorName: callerName,
      actorRole: ROLES.SUPERADMIN,
      action: `CHAT_MODERATE_${operation}`,
      targetType: 'CHAT',
      targetId: trimmedChatId,
      metadata: {
        operation,
        messageId: messageId ? messageId.trim() : null,
      },
    });

    return { success: true, operation, chatId: trimmedChatId };
  }
);
