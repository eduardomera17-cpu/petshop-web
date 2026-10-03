// functions/src/callables/completeRegistration.js
// Callable de finalización de registro y elevación de claims autoritativos (TRD §3.2.A, A-01, A-09, N-17, N-18, CA-17, CA-24, CA-37, CA-38, N-21, ADR-022)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { validateRegistrationData, normalizeSearchName } from '../domain/validators.js';

export const completeRegistration = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Control de autenticación
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    const uid = request.auth.uid;
    const tokenClaims = request.auth.token || {};

    // 2. Control de estado y reclamos previos
    // Si los claims del token ya indican ACTIVE, abortar de inmediato devolviendo PROFILE_ALREADY_COMPLETE
    if (tokenClaims.status === USER_STATUS.ACTIVE) {
      throw new HttpsError('failed-precondition', 'El perfil ya ha sido completado.', {
        errorCode: 'PROFILE_ALREADY_COMPLETE',
      });
    }

    // Exigir obligatoriamente que el claim sea PENDING_PROFILE
    if (tokenClaims.status !== USER_STATUS.PENDING_PROFILE) {
      throw new HttpsError('permission-denied', 'Se requiere estado PENDING_PROFILE para completar el registro.', {
        errorCode: 'INVALID_STATUS',
      });
    }

    // Leer el documento en la base nombrada 'petshopdev'
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'Documento de usuario no encontrado en el sistema.', {
        errorCode: 'USER_NOT_FOUND',
      });
    }

    const userData = userDoc.data();

    // Si el documento en base de datos ya se encuentra en ACTIVE, abortar de inmediato sin reescribir ningún dato
    if (userData?.status === USER_STATUS.ACTIVE) {
      throw new HttpsError('failed-precondition', 'El perfil ya ha sido completado.', {
        errorCode: 'PROFILE_ALREADY_COMPLETE',
      });
    }

    if (userData?.status !== USER_STATUS.PENDING_PROFILE) {
      throw new HttpsError('permission-denied', 'Estado de cuenta no válido para completar el registro.', {
        errorCode: 'INVALID_STATUS',
      });
    }

    // 3. Validación exhaustiva de los 5 campos del formulario (A-01, N-17, N-18, CA-17, CA-37, CA-38)
    const validation = validateRegistrationData(request.data);
    if (!validation.isValid) {
      const firstErrorMessage = Object.values(validation.errors)[0];
      throw new HttpsError('invalid-argument', firstErrorMessage, {
        errorCode: 'INVALID_ARGUMENT',
        errors: validation.errors,
      });
    }

    const { fullName, phone, documentType, documentNumber, address } = request.data;
    const normalizedName = fullName.trim();
    const searchName = normalizeSearchName(normalizedName);
    const email = userData.email || tokenClaims.email || '';
    const existingCreatedAt = userData.audit?.createdAt || FieldValue.serverTimestamp();
    const existingCreatedBy = userData.audit?.createdBy || uid;

    // 4. SECUENCIA DE PERSISTENCIA ESTRICTA (EL ORDEN IMPORTA)

    // PASO A: Escribir en la base nombrada 'petshopdev' el documento completo /users/{uid}
    // con role: 'CLIENT', status: 'ACTIVE', searchName normalizado y auditoría
    await userRef.set({
      uid: uid,
      email: email,
      fullName: normalizedName,
      phone: phone.trim(),
      documentType: documentType.trim(),
      documentNumber: documentNumber.trim(),
      address: address.trim(),
      photoPath: null,
      role: ROLES.CLIENT,
      status: USER_STATUS.ACTIVE,
      searchName: searchName,
      deactivatedAt: null,
      deactivatedBy: null,
      deactivationReason: null,
      reactivatedAt: null,
      reactivatedBy: null,
      audit: {
        createdBy: existingCreatedBy,
        createdAt: existingCreatedAt,
        updatedBy: uid,
        updatedAt: FieldValue.serverTimestamp(),
      },
    });

    // PASO B: Actualizar Custom Claims mediante setCustomUserClaims
    await auth.setCustomUserClaims(uid, {
      role: ROLES.CLIENT,
      status: USER_STATUS.ACTIVE,
    });

    // PASO C: Crear la sala de chat vacía en /chats/{uid} con su metadata inicial mínima
    const chatRef = db.collection('chats').doc(uid);
    await chatRef.set({
      id: uid,
      type: 'CLIENT_STAFF',
      clientId: uid,
      clientName: normalizedName,
      clientSearchName: searchName,
      isArchived: false,
      staffUnreadCount: 0,
      clientUnreadCount: 0,
      lastMessageText: null,
      lastMessageTimestamp: null,
      lastMessageSenderName: null,
      messageCount: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      status: USER_STATUS.ACTIVE,
    };
  }
);
