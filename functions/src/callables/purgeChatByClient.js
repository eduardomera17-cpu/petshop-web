// functions/src/callables/purgeChatByClient.js
// Callable de purga de chat por el cliente (TRD §3.4.D, CH-05, CA-31, N-19)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, storage } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { recordAuditLog } from '../lib/audit.js';

export const purgeChatByClient = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación y estado
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    const callerUid = request.auth.uid;
    const callerRole = request.auth.token?.role;

    if (callerRole !== ROLES.CLIENT) {
      throw new HttpsError('permission-denied', 'Esta operación es exclusiva para clientes.', {
        errorCode: 'CLIENT_ONLY_OPERATION',
      });
    }

    if (request.auth.token?.status && request.auth.token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    // 2. Validación de propiedad de la sala: el cliente sólo puede purgar su propia sala
    const requestedChatId = request.data?.chatId;
    const chatId = (typeof requestedChatId === 'string' && requestedChatId.trim())
      ? requestedChatId.trim()
      : callerUid;

    if (chatId !== callerUid) {
      throw new HttpsError('permission-denied', 'No tiene permisos para purgar esta sala.', {
        errorCode: 'PERMISSION_DENIED',
      });
    }

    const chatRef = db.collection('chats').doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      throw new HttpsError('not-found', 'Sala de chat no encontrada.', {
        errorCode: 'CHAT_NOT_FOUND',
      });
    }

    // 3. Borrado recursivo de mensajes en Firestore
    await db.recursiveDelete(chatRef.collection('messages'));

    // 4. Borrado seguro de imágenes asociadas en Storage
    try {
      await storage.deleteFiles({ prefix: `media/chat/${chatId}/` });
    } catch (err) {
      console.warn(`Error al eliminar imágenes en Storage para media/chat/${chatId}/:`, err);
    }

    // 5. Reinicio de contadores y metadatos de último mensaje.
    // INVARIANTE INVIOLABLE: La sala principal /chats/{chatId} NO se borra.
    await chatRef.update({
      staffUnreadCount: 0,
      messageCount: 0,
      lastMessageText: null,
      lastMessageTimestamp: null,
      lastMessageSenderName: null,
      lastMessageSenderUid: null,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 6. Registro en /audit_log (TRD §2.12, N-AD-08)
    const callerName = request.auth.token?.name || chatDoc.data()?.clientName || 'Cliente';
    await recordAuditLog(db, {
      actorUid: callerUid,
      actorName: callerName,
      actorRole: ROLES.CLIENT,
      action: 'CHAT_PURGE',
      targetType: 'CHAT',
      targetId: chatId,
      metadata: { purgedBy: 'CLIENT' },
    });

    return { success: true, chatId };
  }
);
