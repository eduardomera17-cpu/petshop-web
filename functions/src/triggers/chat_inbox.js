// functions/src/triggers/chat_inbox.js
// Sincronía de la bandeja de chat y anti-suplantación estricta (TRD §2.11, §3.5.B, MC-01, MC-05, MC-07, MC-09, CH-06, CA-40, CA-50, ADR-015, ADR-022)

import { onDocumentCreated, onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { db, storage } from '../config/firebase.js';
import { FIRESTORE_DATABASE_ID, REGIONS } from '../config/constants.js';

/**
 * Trigger ejecutado al crear un nuevo mensaje en chats/{chatId}/messages/{messageId}.
 *
 * 1. Sobrescritura anti-suplantación forzada: Sobrescribe en el mensaje el senderName con el
 *    fullName vigente en /users/{senderUid}. Lo que el cliente envíe no sobrevive (TRD §2.11, §3.5.B).
 * 2. Actualiza la sala /chats/{chatId}: lastMessageText (<= 120), lastMessageTimestamp,
 *    lastMessageSenderName, lastMessageSenderUid, e incrementa messageCount.
 * 3. Si senderRole === 'CLIENT', incrementa staffUnreadCount += 1.
 * 4. Si chatId === 'STAFF_INTERNAL', incrementa el contador de no leídos en todos los read_states/{uid}
 *    salvo el del emisor (MC-09).
 */
export const onMessageCreated = onDocumentCreated(
  {
    document: 'chats/{chatId}/messages/{messageId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    if (!event.data) {
      return null;
    }

    const messageData = event.data.data() || {};
    const { chatId, messageId } = event.params;
    const senderUid = messageData.senderUid;

    if (!senderUid) {
      return null;
    }

    // 1. Sobrescritura anti-suplantación estricta
    let authoritativeName = 'Usuario';
    try {
      const userDoc = await db.collection('users').doc(senderUid).get();
      if (userDoc.exists) {
        const userData = userDoc.data() || {};
        authoritativeName = userData.fullName || userData.name || authoritativeName;
      }
    } catch (err) {
      console.warn(`Error al consultar /users/${senderUid} para senderName:`, err);
    }

    // 2. Componer texto de vista previa (recortado a <= 120 caracteres)
    let previewText = null;
    if (messageData.text && typeof messageData.text === 'string') {
      const trimmed = messageData.text.trim();
      previewText = trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
    } else if (messageData.imagePath) {
      previewText = '[Imagen]';
    }

    // 3. Actualizar la sala /chats/{chatId} y el mensaje con transacción idempotente (AUD-INT-13)
    const chatRef = db.collection('chats').doc(chatId);
    const msgRef = db.collection('chats').doc(chatId).collection('messages').doc(messageId);
    let isAlreadyProcessed = false;

    try {
      await db.runTransaction(async (transaction) => {
        const msgDoc = await transaction.get(msgRef);
        if (msgDoc.exists && msgDoc.data()?.processedByTrigger === true) {
          isAlreadyProcessed = true;
          return;
        }

        if (msgDoc.exists) {
          transaction.update(msgRef, {
            senderName: authoritativeName,
            processedByTrigger: true,
          });
        }

        const chatUpdates = {
          lastMessageText: previewText,
          lastMessageTimestamp: messageData.createdAt || FieldValue.serverTimestamp(),
          lastMessageSenderName: authoritativeName,
          lastMessageSenderUid: senderUid,
          messageCount: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        };

        if (messageData.senderRole === 'CLIENT') {
          chatUpdates.staffUnreadCount = FieldValue.increment(1);
        }

        transaction.set(chatRef, chatUpdates, { merge: true });
      });
    } catch (err) {
      console.warn(`Error en transacción de chat para mensaje ${messageId}:`, err);
    }

    if (isAlreadyProcessed) {
      return null;
    }

    // 4. Si es STAFF_INTERNAL, incrementar unreadCount en read_states/{uid} de los demás
    if (chatId === 'STAFF_INTERNAL') {
      try {
        const readStatesSnap = await chatRef.collection('read_states').get();
        if (!readStatesSnap.empty) {
          const batch = db.batch();
          readStatesSnap.forEach((doc) => {
            if (doc.id !== senderUid) {
              batch.update(doc.ref, {
                unreadCount: FieldValue.increment(1),
              });
            }
          });
          await batch.commit();
        }
      } catch (err) {
        console.warn('Error al actualizar read_states en STAFF_INTERNAL:', err);
      }
    }

    return { chatId, messageId, senderName: authoritativeName };
  }
);

/**
 * Trigger ejecutado al eliminar un mensaje en chats/{chatId}/messages/{messageId}.
 *
 * 1. Decrementa messageCount con suelo en 0.
 * 2. Si el mensaje era de cliente y readByStaff == false, decrementa staffUnreadCount con suelo en 0 (CH-06, MC-05, CA-40).
 * 3. Recalcula el último mensaje remanente consultando el más reciente.
 * 4. Borrado seguro de Storage: Elimina la imagen ÚNICAMENTE si imagePath comienza estrictamente
 *    por media/chat/{chatId}/, revalidando el prefijo antes de borrar con el Admin SDK (TRD §2.11, §3.5.B).
 */
export const onMessageDeleted = onDocumentDeleted(
  {
    document: 'chats/{chatId}/messages/{messageId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    if (!event.data) {
      return null;
    }

    const deletedData = event.data.data() || {};
    const { chatId, messageId } = event.params;
    const chatRef = db.collection('chats').doc(chatId);

    // 1. Recalcular el último mensaje remanente
    let lastMessageText = null;
    let lastMessageTimestamp = null;
    let lastMessageSenderName = null;
    let lastMessageSenderUid = null;

    try {
      const remainingSnap = await chatRef.collection('messages')
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();

      if (!remainingSnap.empty) {
        const lastMsg = remainingSnap.docs[0].data() || {};
        if (lastMsg.text && typeof lastMsg.text === 'string') {
          const trimmed = lastMsg.text.trim();
          lastMessageText = trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
        } else if (lastMsg.imagePath) {
          lastMessageText = '[Imagen]';
        }
        lastMessageTimestamp = lastMsg.createdAt || null;
        lastMessageSenderName = lastMsg.senderName || null;
        lastMessageSenderUid = lastMsg.senderUid || null;
      }
    } catch (err) {
      console.warn(`Error al consultar mensajes remanentes en /chats/${chatId}:`, err);
    }

    // 2. Transacción para decrementar contadores con suelo en 0
    try {
      await db.runTransaction(async (transaction) => {
        const chatDoc = await transaction.get(chatRef);
        if (!chatDoc.exists) {
          return;
        }

        const chatData = chatDoc.data() || {};
        const currentMessageCount = chatData.messageCount || 0;
        const newMessageCount = Math.max(0, currentMessageCount - 1);

        let newStaffUnread = chatData.staffUnreadCount || 0;
        if (deletedData.senderRole === 'CLIENT' && deletedData.readByStaff === false) {
          newStaffUnread = Math.max(0, newStaffUnread - 1);
        }

        transaction.update(chatRef, {
          messageCount: newMessageCount,
          staffUnreadCount: newStaffUnread,
          lastMessageText,
          lastMessageTimestamp,
          lastMessageSenderName,
          lastMessageSenderUid,
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
    } catch (err) {
      console.warn(`Error al actualizar contadores en /chats/${chatId}:`, err);
    }

    // 3. Borrado seguro de imágenes (TRD §2.11, §3.5.B)
    const imagePath = deletedData.imagePath;
    if (imagePath && typeof imagePath === 'string') {
      const expectedPrefix = `media/chat/${chatId}/`;
      if (imagePath.startsWith(expectedPrefix)) {
        try {
          await storage.file(imagePath).delete({ ignoreNotFound: true });
          console.log(`[STORAGE] Imagen borrada de forma segura: ${imagePath}`);
        } catch (err) {
          console.warn(`[STORAGE] Error al borrar imagen ${imagePath}:`, err);
        }
      } else {
        console.warn(`[AUDITORÍA SEGURIDAD] imagePath no cumple con el prefijo autorizado '${expectedPrefix}': '${imagePath}'. Eliminación con Admin SDK abortada.`);
      }
    }

    return { chatId, messageId, deleted: true };
  }
);
