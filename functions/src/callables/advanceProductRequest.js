// functions/src/callables/advanceProductRequest.js
// Callable de avance de estado de solicitud por personal (TRD §3.2.F, IN-04, CA-AD-03, CA-AD-21, AUD-123, AUD-149, AUD-150)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';

export const advanceProductRequest = onCall(
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

    // Verificación de revocación si viene bearer token (TRD §4.2, §4.6)
    if (request.rawRequest?.headers?.authorization) {
      const authHeader = request.rawRequest.headers.authorization;
      if (typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
        const idToken = authHeader.split('Bearer ')[1];
        try {
          await auth.verifyIdToken(idToken, true);
        } catch {
          throw new HttpsError('unauthenticated', 'Token de autenticación revocado o inválido.', {
            errorCode: 'UNAUTHENTICATED',
          });
        }
      }
    }

    const uid = request.auth.uid;
    const token = request.auth.token || {};

    if (token.status && token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const requestData = request.data || {};
    const { requestId } = requestData;

    if (!requestId || typeof requestId !== 'string' || requestId.trim() === '') {
      throw new HttpsError('invalid-argument', 'El identificador de solicitud (requestId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedRequestId = requestId.trim();
    const productRequestRef = db.collection('product_requests').doc(trimmedRequestId);

    let resultPayload = null;

    // 2. Transacción atómica de avance de estado (TRD §3.2.F)
    await db.runTransaction(async (transaction) => {
      const requestDoc = await transaction.get(productRequestRef);
      if (!requestDoc.exists) {
        throw new HttpsError('not-found', 'Solicitud no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const requestItem = requestDoc.data();
      const currentStatus = requestItem.status;

      // ÚNICA transición permitida: PENDING_DISPATCH -> READY_FOR_PICKUP (TRD §3.2.F, CA-AD-03)
      // Cualquier otra transición lanza INVALID_TRANSITION. FINALIZED es inalcanzable aquí.
      if (currentStatus !== 'PENDING_DISPATCH') {
        throw new HttpsError(
          'failed-precondition',
          `Transición no permitida desde ${currentStatus}. Sólo se permite avanzar desde PENDING_DISPATCH a READY_FOR_PICKUP.`,
          { errorCode: 'INVALID_TRANSITION' }
        );
      }

      // Aplicar transición a READY_FOR_PICKUP
      transaction.update(productRequestRef, {
        status: 'READY_FOR_PICKUP',
        'audit.readyBy': uid,
        'audit.readyAt': FieldValue.serverTimestamp(),
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      });

      resultPayload = {
        success: true,
        requestId: trimmedRequestId,
        status: 'READY_FOR_PICKUP',
      };
    });

    return resultPayload;
  }
);
