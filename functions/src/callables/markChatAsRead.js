// functions/src/callables/markChatAsRead.js
// Callable para marcar chat como leído por el personal (TRD §2.11, §3.4.F, MC-09, CA-16, CA-AD-17)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';

export const markChatAsRead = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación y rol de personal (ADMIN o SUPERADMIN)
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    assertRole(request.auth, [ROLES.ADMIN, ROLES.SUPERADMIN]);

    if (request.auth.token?.status && request.auth.token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const callerUid = request.auth.uid;
    const { chatId } = request.data || {};

    if (!chatId || typeof chatId !== 'string' || chatId.trim() === '') {
      throw new HttpsError('invalid-argument', 'chatId es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedChatId = chatId.trim();
    const chatRef = db.collection('chats').doc(trimmedChatId);

    // 2. Rama A: Canal Interno del Personal (STAFF_INTERNAL)
    if (trimmedChatId === 'STAFF_INTERNAL') {
      const readStateRef = chatRef.collection('read_states').doc(callerUid);
      await readStateRef.set(
        {
          uid: callerUid,
          unreadCount: 0,
          lastReadAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return { success: true, chatId: trimmedChatId, unreadCount: 0 };
    }

    // 3. Rama B: Salas de Cliente (CLIENT_STAFF)
    const chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      throw new HttpsError('not-found', 'Sala de chat no encontrada.', {
        errorCode: 'CHAT_NOT_FOUND',
      });
    }

    // Poner a 0 el staffUnreadCount en la cabecera de la sala
    await chatRef.update({
      staffUnreadCount: 0,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Marcar los mensajes pendientes como readByStaff: true
    const unreadMessagesSnap = await chatRef
      .collection('messages')
      .where('readByStaff', '==', false)
      .get();

    if (!unreadMessagesSnap.empty) {
      const batch = db.batch();
      unreadMessagesSnap.forEach((doc) => {
        batch.update(doc.ref, { readByStaff: true });
      });
      await batch.commit();
    }

    // INVARIANTE INVIOLABLE: No borra, no archiva y no modifica el contenido de los mensajes.
    return {
      success: true,
      chatId: trimmedChatId,
      markedMessagesCount: unreadMessagesSnap.size,
    };
  }
);
