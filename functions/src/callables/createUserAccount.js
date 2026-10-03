// functions/src/callables/createUserAccount.js
// Callable bifurcada de aprovisionamiento de cuentas de usuario por el Super Usuario
// (TRD §3.4.I, ADR-017, PRD CF-07, CA-AD-19, CA-AD-25, AUD-070, AUD-083, Caso Crítico 21)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { validateRegistrationData, normalizeSearchName } from '../domain/validators.js';
import { recordAuditLog } from '../lib/audit.js';

export const createUserAccount = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Control estricto de autenticación y rol (exclusivo para SUPERADMIN)
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    assertRole(request.auth, ROLES.SUPERADMIN);

    if (request.auth.token?.status && request.auth.token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta del llamante no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const callerUid = request.auth.uid;
    const data = request.data || {};
    const { role, email, fullName, phone, documentType, documentNumber, address } = data;

    // 2. Límites innegociables de rol (CA-AD-19, CF-11)
    if (role === ROLES.SUPERADMIN) {
      throw new HttpsError('invalid-argument', 'Cannot create superadmin', {
        errorCode: 'SUPERADMIN_IMMUTABLE',
      });
    }

    if (role !== ROLES.ADMIN && role !== ROLES.CLIENT) {
      throw new HttpsError('invalid-argument', 'El rol debe ser ADMIN o CLIENT.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    // 3. Validación de correo y datos de identidad
    if (!email || typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      throw new HttpsError('invalid-argument', 'Correo electrónico inválido o ausente.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const regValidation = validateRegistrationData({ fullName, phone, documentType, documentNumber, address });
    if (!regValidation.isValid) {
      throw new HttpsError('invalid-argument', 'Datos de identidad del usuario inválidos.', {
        errorCode: 'INVALID_ARGUMENT',
        details: regValidation.errors,
      });
    }

    const trimmedEmail = email.trim().toLowerCase();
    const trimmedFullName = fullName.trim();
    const trimmedPhone = phone.trim();
    const trimmedDocType = documentType.trim();
    const trimmedDocNumber = documentNumber.trim();
    const trimmedAddress = address.trim();
    const searchName = normalizeSearchName(trimmedFullName);

    // 4. Paso 1: Creación de cuenta en Firebase Auth
    let userRecord;
    try {
      userRecord = await auth.createUser({
        email: trimmedEmail,
        displayName: trimmedFullName,
        disabled: false,
      });
    } catch (authError) {
      if (authError.code === 'auth/email-already-exists') {
        throw new HttpsError('already-exists', 'El correo ya se encuentra registrado.', {
          errorCode: 'EMAIL_ALREADY_EXISTS',
        });
      }
      throw new HttpsError('internal', authError.message || 'Error al crear la cuenta en Auth.', {
        errorCode: 'AUTH_CREATION_FAILED',
      });
    }

    const uid = userRecord.uid;

    // 5. Pasos 2 al 5 con mecanismo de compensación transaccional (TRD §3.4.I)
    try {
      const now = FieldValue.serverTimestamp();

      // Paso 2: Asignar custom claims autoritativos
      await auth.setCustomUserClaims(uid, {
        role: role,
        status: USER_STATUS.ACTIVE,
      });

      // Paso 3: Escribir documento completo en /users/{uid} en estado ACTIVE
      const userRef = db.collection('users').doc(uid);
      await userRef.set({
        uid: uid,
        email: trimmedEmail,
        fullName: trimmedFullName,
        phone: trimmedPhone,
        documentType: trimmedDocType,
        documentNumber: trimmedDocNumber,
        address: trimmedAddress,
        role: role,
        status: USER_STATUS.ACTIVE,
        searchName: searchName,
        audit: {
          createdBy: callerUid,
          createdAt: now,
          updatedBy: callerUid,
          updatedAt: now,
        },
      });

      // Paso 4: Bifurcación según rol (ADR-017)
      if (role === ROLES.ADMIN) {
        // Rama ADMIN: Alta en canal interno STAFF_INTERNAL (MC-09)
        const staffInternalRef = db
          .collection('chats')
          .doc('STAFF_INTERNAL')
          .collection('read_states')
          .doc(uid);

        await staffInternalRef.set(
          {
            uid: uid,
            unreadCount: 0,
            lastReadAt: now,
          },
          { merge: true }
        );
      } else {
        // Rama CLIENT: Inicializar sala individual en /chats/{uid} (CH-01)
        // OMISIÓN EXPRESA: Queda terminantemente prohibido crear read_states en STAFF_INTERNAL
        const chatRef = db.collection('chats').doc(uid);
        await chatRef.set({
          id: uid,
          type: 'CLIENT_STAFF',
          clientId: uid,
          clientName: trimmedFullName,
          staffUnreadCount: 0,
          clientUnreadCount: 0,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        });
      }

      // Registro de trazabilidad en /audit_log (TRD §2.12, N-AD-08)
      await recordAuditLog(db, {
        actorUid: callerUid,
        actorName: request.auth.token?.name || 'Super Usuario',
        actorRole: ROLES.SUPERADMIN,
        action: 'CREATE_USER_ACCOUNT',
        targetType: 'USER',
        targetId: uid,
        metadata: {
          email: trimmedEmail,
          role: role,
        },
      });

      // Paso 5: Generar enlace seguro de restablecimiento de contraseña (CF-07)
      const resetLink = await auth.generatePasswordResetLink(trimmedEmail);

      return {
        success: true,
        uid: uid,
        role: role,
        resetLink: resetLink,
      };
    } catch (error) {
      // COMPENSACIÓN ANTE FALLOS: Si falla cualquier paso posterior a Auth, deshacer cuenta huérfana
      try {
        await auth.deleteUser(uid);
      } catch (cleanupError) {
        console.error(`[createUserAccount] Error compensando usuario huérfano ${uid}:`, cleanupError);
      }

      throw new HttpsError('internal', 'Account provisioning failed', {
        errorCode: 'ACCOUNT_PROVISIONING_FAILED',
        originalMessage: error.message,
      });
    }
  }
);
