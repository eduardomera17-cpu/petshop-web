// functions/src/callables/previewAccountDeactivation.js
// Callable de previsualización de baja de cuenta sin efectos secundarios (TRD §3.4.G, CA-59, CA-64, N-20, CA-44, D-03)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db, auth } from '../config/firebase.js';
import { REGIONS, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { PROFORMA_STATUS } from '../domain/proforma.js';
import { requestPreviewLines } from '../domain/product_request.js';

export const previewAccountDeactivation = onCall(
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

    // Verificación de revocación si viene bearer token
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

    const toCancel = [];
    const toRetain = [];

    // 2. Consulta de citas del usuario
    const appointmentsSnap = await db
      .collection('appointments')
      .where('clientId', '==', uid)
      .get();

    for (const doc of appointmentsSnap.docs) {
      const data = doc.data();
      const status = data.status;

      if (status === 'PENDING' || status === 'CONFIRMED') {
        toCancel.push({
          id: doc.id,
          type: 'APPOINTMENT',
          dateString: data.dateString || null,
          timeSlot: data.timeSlot || null,
          concept: data.serviceName || data.concept || 'Servicio',
        });
      } else if (status === 'COMPLETED') {
        toRetain.push({
          id: doc.id,
          type: 'APPOINTMENT',
          dateString: data.dateString || null,
          concept: data.serviceName || data.concept || 'Servicio',
          reason: 'COMPLETED',
        });
      }
    }

    // 3. Consulta de solicitudes de producto del usuario
    const requestsSnap = await db
      .collection('product_requests')
      .where('clientId', '==', uid)
      .get();

    // Cache de proformas consultadas
    const proformaCache = new Map();

    for (const doc of requestsSnap.docs) {
      const data = doc.data();
      const status = data.status;

      if (status === 'PENDING_DISPATCH' || status === 'READY_FOR_PICKUP') {
        let isBilled = false;

        if (data.proformaId) {
          let proformaData = proformaCache.get(data.proformaId);
          if (!proformaData) {
            const pDoc = await db.collection('proformas').doc(data.proformaId).get();
            if (pDoc.exists) {
              proformaData = pDoc.data();
              proformaCache.set(data.proformaId, proformaData);
            }
          }

          if (proformaData && proformaData.status !== PROFORMA_STATUS.DRAFT) {
            isBilled = true;
          }
        }

        // concept y quantity describen la primera línea (TRD §3.4.G). Con la forma plana retirada salen de
        // items[0], que es de donde se copiaban los campos planos (WP-6.11-B, AUD-405).
        const lines = requestPreviewLines(data);
        if (isBilled) {
          toRetain.push({
            id: doc.id,
            type: 'PRODUCT_REQUEST',
            concept: lines[0].productName || data.concept || 'Producto',
            quantity: lines[0].quantity,
            reason: 'BILLED',
            lines,
          });
        } else {
          toCancel.push({
            id: doc.id,
            type: 'PRODUCT_REQUEST',
            concept: lines[0].productName || data.concept || 'Producto',
            quantity: lines[0].quantity,
            lines,
          });
        }
      } else if (status === 'FINALIZED') {
        const lines = requestPreviewLines(data);
        toRetain.push({
          id: doc.id,
          type: 'PRODUCT_REQUEST',
          concept: lines[0].productName || data.concept || 'Producto',
          quantity: lines[0].quantity,
          reason: 'BILLED',
          lines,
        });
      }
    }

    return {
      toCancel,
      toRetain,
    };
  }
);
