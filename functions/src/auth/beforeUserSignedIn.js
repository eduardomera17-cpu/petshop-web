// functions/src/auth/beforeUserSignedIn.js
// Blocking function que bloquea cuentas inactivas y sincroniza claims autoritativos (TRD §3.1.B, P-06, CF-09, CF-12, ADR-022)

import { beforeUserSignedIn as beforeUserSignedInTrigger, HttpsError } from 'firebase-functions/v2/identity';
import { db } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS } from '../config/constants.js';

export const beforeUserSignedIn = beforeUserSignedInTrigger(
  {
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    const user = event.data;
    const uid = user?.uid;

    if (!uid) {
      throw new HttpsError('invalid-argument', 'Identificador de usuario no proporcionado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    // 1. Leer el documento de usuario en la base petshopdev
    const userDoc = await db.collection('users').doc(uid).get();

    // 2. Si el documento no existe (carrera con el paso 4 de beforeUserCreated o anomalía),
    // el status devuelto es PENDING_PROFILE. NUNCA ACTIVE (la ausencia de prueba no concede permisos).
    if (!userDoc.exists) {
      return {
        customClaims: {
          role: ROLES.CLIENT,
          status: USER_STATUS.PENDING_PROFILE,
        },
      };
    }

    const userData = userDoc.data();
    const status = userData?.status;
    const role = userData?.role || ROLES.CLIENT;

    // 3. Bloqueo estricto de cuentas desactivadas o eliminadas
    if (status === USER_STATUS.DEACTIVATED || status === USER_STATUS.DELETED) {
      console.warn(`Inicio de sesión bloqueado: Usuario ${uid} en estado ${status}`);
      throw new HttpsError('permission-denied', 'Esta cuenta ha sido desactivada o eliminada del sistema.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    // 4. PENDING_PROFILE no rechaza el inicio de sesión (permite completar registro con completeRegistration)
    // 5. Devuelve customClaims resincronizando documento con el token
    return {
      customClaims: {
        role: role,
        status: status || USER_STATUS.PENDING_PROFILE,
      },
    };
  }
);
