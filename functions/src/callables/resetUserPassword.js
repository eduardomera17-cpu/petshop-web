// functions/src/callables/resetUserPassword.js
// Callable de generación de enlace de restablecimiento de contraseña por el Super Usuario
// (TRD §3.4.I, PRD CF-06, CF-10, CA-AD-19, CF-11)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { recordAuditLog } from '../lib/audit.js';

export const resetUserPassword = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Control de autenticación y rol (exclusivo para SUPERADMIN)
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
    const { targetUid } = request.data || {};

    if (!targetUid || typeof targetUid !== 'string' || targetUid.trim() === '') {
      throw new HttpsError('invalid-argument', 'targetUid es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedTargetUid = targetUid.trim();

    // 2. Verificación de existencia del usuario objetivo en Firestore
    const userRef = db.collection('users').doc(trimmedTargetUid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'Usuario no encontrado.', {
        errorCode: 'NOT_FOUND',
      });
    }

    const userData = userDoc.data() || {};

    // 3. INVARIANTE INVIOLABLE CA-AD-19, CF-11: El Super Usuario es inmutable
    if (userData.role === ROLES.SUPERADMIN) {
      throw new HttpsError('permission-denied', 'El Super Usuario es inmutable.', {
        errorCode: 'SUPERADMIN_IMMUTABLE',
      });
    }

    let targetEmail = userData.email;
    if (!targetEmail) {
      try {
        const authUser = await auth.getUser(trimmedTargetUid);
        targetEmail = authUser.email;
      } catch (authErr) {
        throw new HttpsError('not-found', 'No se pudo obtener el correo del usuario.', {
          errorCode: 'NOT_FOUND',
        });
      }
    }

    // 4. Generación segura del enlace de restablecimiento (CF-06, CF-10)
    // INVARIANTE: El sistema NO envía correos electrónicos; el enlace se entrega por canal seguro
    let resetLink;
    try {
      resetLink = await auth.generatePasswordResetLink(targetEmail);
    } catch (linkError) {
      throw new HttpsError('internal', linkError.message || 'Error al generar enlace de restablecimiento.', {
        errorCode: 'PASSWORD_RESET_LINK_FAILED',
      });
    }

    // 5. Trazabilidad inmutable en /audit_log (TRD §2.12, N-AD-08)
    await recordAuditLog(db, {
      actorUid: callerUid,
      actorName: request.auth.token?.name || 'Super Usuario',
      actorRole: ROLES.SUPERADMIN,
      action: 'RESET_USER_PASSWORD',
      targetType: 'USER',
      targetId: trimmedTargetUid,
      metadata: {
        email: targetEmail,
      },
    });

    return {
      success: true,
      targetUid: trimmedTargetUid,
      resetLink: resetLink,
    };
  }
);
