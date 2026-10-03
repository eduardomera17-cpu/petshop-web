// functions/src/callables/deactivateUserAccount.js
// Callable de desactivación administrativa de cuentas de usuario por el Super Usuario
// (TRD §3.4.I, §3.4.G, PRD CF-09, CF-12, D-03, CA-43, CA-59, CA-64, CA-AD-19, CF-11)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { executeAccountDeactivation } from '../domain/account.js';

export const deactivateUserAccount = onCall(
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

    // 2. Reutilización del módulo de dominio unificado de la Etapa 3 (TRD §3.4.G / §3.4.I, excepción D-03)
    // executeAccountDeactivation ya garantiza atómicamente:
    // - SUPERADMIN_IMMUTABLE si targetUid es Super Usuario
    // - ACCOUNT_ALREADY_DEACTIVATED si la cuenta ya estaba desactivada
    // - Cancelación de citas activas y liberación de cerrojos
    // - Cancelación de solicitudes no facturadas con reposición de inventario
    // - Excepción D-03: conservación de solicitudes en proformas facturadas
    // - Retiro de líneas de borradores de proforma
    // - Mutación a DEACTIVATED, deshabilitación en Auth, revocación de tokens y traza en /audit_log
    const result = await executeAccountDeactivation({
      targetUid: trimmedTargetUid,
      actorUid: callerUid,
      actorName: request.auth.token?.name || 'Super Usuario',
      actorRole: ROLES.SUPERADMIN,
    });

    return {
      success: true,
      ...result,
    };
  }
);
