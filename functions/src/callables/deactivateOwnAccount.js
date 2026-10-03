// functions/src/callables/deactivateOwnAccount.js
// Callable de baja voluntaria de cuenta por el titular en un solo acto indivisible
// (TRD §3.4.G, P-06, N-19, D-03, CA-43, CA-46, CA-59, CA-64, AUD-023, H-09, AUD-258)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { executeAccountDeactivation } from '../domain/account.js';

export const deactivateOwnAccount = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    const uid = request.auth.uid;
    const token = request.auth.token || {};

    // 2. Exigencia de re-autenticación reciente (últimos 5 minutos / 300 segundos, TRD §3.4.G)
    const authTime = token.auth_time;
    const nowSec = Math.floor(Date.now() / 1000);
    if (!authTime || (nowSec - authTime) > 300) {
      throw new HttpsError('unauthenticated', 'Reautenticación requerida para desactivar la cuenta.', {
        errorCode: 'REAUTH_REQUIRED',
      });
    }

    if (token.status && token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    // 3. Delegación en la implementación única de dominio (TRD §3.4.G, AUD-258)
    return await executeAccountDeactivation({
      targetUid: uid,
      actorUid: uid,
      actorName: token.name || 'Cliente',
      actorRole: token.role || ROLES.CLIENT,
    });
  }
);
