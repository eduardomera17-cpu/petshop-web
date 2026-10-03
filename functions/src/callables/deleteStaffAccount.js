// functions/src/callables/deleteStaffAccount.js
// Callable de eliminación lógica de cuentas de personal (ADMIN) por el Super Usuario
// (TRD §3.4.I, PRD CF-12, CA-AD-19, CA-AD-37, CF-11)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { recordAuditLog } from '../lib/audit.js';

export const deleteStaffAccount = onCall(
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
    const userRef = db.collection('users').doc(trimmedTargetUid);
    const now = FieldValue.serverTimestamp();

    // 2. Transacción atómica en Firestore
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new HttpsError('not-found', 'Usuario no encontrado.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const userData = userDoc.data() || {};

      // INVARIANTE INVIOLABLE CA-AD-19, CF-11: El Super Usuario es inmutable
      if (userData.role === ROLES.SUPERADMIN) {
        throw new HttpsError('permission-denied', 'El Super Usuario es inmutable.', {
          errorCode: 'SUPERADMIN_IMMUTABLE',
        });
      }

      // Restricción de alcance: deleteStaffAccount aplica estrictamente sobre personal (ADMIN)
      if (userData.role !== ROLES.ADMIN) {
        throw new HttpsError('failed-precondition', 'deleteStaffAccount solo aplica sobre cuentas con rol ADMIN.', {
          errorCode: 'INVALID_TARGET_ROLE',
        });
      }

      // INVARIANTE CA-AD-37: Preservación histórica íntegra.
      // Queda prohibido eliminar documentos, citas, registros clínicos o auditorías asociadas al personal.
      // Se realiza borrado lógico marcando status = DELETED.
      transaction.update(userRef, {
        status: USER_STATUS.DELETED,
        deletedAt: now,
        deletedBy: callerUid,
        'audit.updatedBy': callerUid,
        'audit.updatedAt': now,
      });

      // Registro de auditoría (TRD §2.12, N-AD-08)
      recordAuditLog(transaction, {
        actorUid: callerUid,
        actorName: request.auth.token?.name || 'Super Usuario',
        actorRole: ROLES.SUPERADMIN,
        action: 'DELETE_STAFF_ACCOUNT',
        targetType: 'USER',
        targetId: trimmedTargetUid,
        metadata: {
          role: userData.role,
          email: userData.email,
        },
      });
    });

    // 3. Deshabilitación y revocación de credenciales en Firebase Auth
    try {
      await auth.updateUser(trimmedTargetUid, { disabled: true });
      await auth.revokeRefreshTokens(trimmedTargetUid);
      const authUser = await auth.getUser(trimmedTargetUid);
      const existingClaims = authUser.customClaims || {};
      await auth.setCustomUserClaims(trimmedTargetUid, {
        ...existingClaims,
        status: USER_STATUS.DELETED,
      });
    } catch (authErr) {
      console.warn(`[deleteStaffAccount] Error sincronizando Auth para ${trimmedTargetUid}:`, authErr.message);
    }

    return {
      success: true,
      targetUid: trimmedTargetUid,
      status: USER_STATUS.DELETED,
    };
  }
);
