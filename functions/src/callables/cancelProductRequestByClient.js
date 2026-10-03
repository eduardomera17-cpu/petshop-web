// functions/src/callables/cancelProductRequestByClient.js
// Callable de cancelación de solicitudes de producto por el cliente (TRD §3.2.E, PR-07, FA-03, FA-05, CA-28, CA-29, N-11, CA-13, AUD-023, AUD-149, AUD-150)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { removeConceptFromDraftProforma, ITEM_TYPES, PROFORMA_STATUS } from '../domain/proforma.js';
import { requestStockLines } from '../domain/product_request.js';

export const cancelProductRequestByClient = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación y estado del usuario
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

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
    const allowedKeys = ['requestId'];
    const hasExtraKeys = Object.keys(requestData).some((k) => !allowedKeys.includes(k));
    if (hasExtraKeys) {
      throw new HttpsError('invalid-argument', 'Parámetros no permitidos.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const { requestId } = requestData;

    if (!requestId || typeof requestId !== 'string' || requestId.trim() === '') {
      throw new HttpsError('invalid-argument', 'El identificador de solicitud (requestId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedRequestId = requestId.trim();
    const productRequestRef = db.collection('product_requests').doc(trimmedRequestId);

    let resultPayload = null;

    // 2. Transacción atómica de cancelación (TRD §3.2.E)
    await db.runTransaction(async (transaction) => {
      // --- FASE 1: LECTURAS ---
      const requestDoc = await transaction.get(productRequestRef);

      // Verificación de propiedad (TRD §3.2.E):
      // Si la solicitud no existe o pertenece a otro usuario, retornar NOT_FOUND (no PERMISSION_DENIED)
      // para evitar divulgar la existencia de IDs ajenos.
      if (!requestDoc.exists || requestDoc.data()?.clientId !== uid) {
        throw new HttpsError('not-found', 'Solicitud no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const requestItem = requestDoc.data();
      const currentStatus = requestItem.status;

      // PASO 2: Validar estados permitidos para cancelación por cliente
      if (currentStatus === 'CANCELLED') {
        throw new HttpsError('failed-precondition', 'La solicitud ya se encuentra cancelada.', {
          errorCode: 'ALREADY_CANCELLED',
        });
      }

      if (currentStatus === 'FINALIZED') {
        throw new HttpsError('failed-precondition', 'Una solicitud finalizada no puede ser cancelada.', {
          errorCode: 'REQUEST_NOT_CANCELLABLE',
        });
      }

      // Estados permitidos: PENDING_DISPATCH o READY_FOR_PICKUP
      if (currentStatus !== 'PENDING_DISPATCH' && currentStatus !== 'READY_FOR_PICKUP') {
        throw new HttpsError('failed-precondition', 'Estado no cancelable por el cliente.', {
          errorCode: 'REQUEST_NOT_CANCELLABLE',
        });
      }

      // E2.2: Leer sus líneas con requestStockLines. Si lanza, no se captura (aborta transacción).
      const stockLines = requestStockLines(requestItem);

      // E2.3: Un transaction.get() por el producto de cada línea
      for (const line of stockLines) {
        const productRef = db.collection('products').doc(line.productId);
        const productDoc = await transaction.get(productRef);
        if (!productDoc.exists) {
          throw new HttpsError('not-found', 'Producto asociado no encontrado.', {
            errorCode: 'NOT_FOUND',
          });
        }
      }

      // E2.4: Si tiene proformaId, verificar la proforma (TRD §3.2.E)
      let proformaDoc = null;
      if (requestItem.proformaId) {
        const proformaRef = db.collection('proformas').doc(requestItem.proformaId);
        proformaDoc = await transaction.get(proformaRef);

        if (proformaDoc.exists) {
          const proformaData = proformaDoc.data();

          // Si status != DRAFT => CONCEPT_LOCKED_BY_DELIVERED_PROFORMA
          if (proformaData.status !== PROFORMA_STATUS.DRAFT) {
            throw new HttpsError(
              'failed-precondition',
              'El concepto está bloqueado porque pertenece a una proforma ya entregada o procesada.',
              { errorCode: 'CONCEPT_LOCKED_BY_DELIVERED_PROFORMA' }
            );
          }
        }
      }

      // --- FASE 2: ESCRITURAS ---

      // E3.1: Actualizar la solicitud a CANCELLED
      transaction.update(productRequestRef, {
        status: 'CANCELLED',
        cancelledReason: 'CLIENT',
        'audit.cancelledBy': uid,
        'audit.cancelledAt': FieldValue.serverTimestamp(),
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      });

      // E3.2: Reponer stock en cada línea
      for (const line of stockLines) {
        const productRef = db.collection('products').doc(line.productId);
        transaction.update(productRef, {
          stock: FieldValue.increment(line.quantity),
          'audit.updatedBy': uid,
          'audit.updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // E3.3: Si había proforma en DRAFT, retirar línea mediante domain/proforma.js (AUD-023)
      if (requestItem.proformaId && proformaDoc && proformaDoc.exists) {
        await removeConceptFromDraftProforma(transaction, db, {
          proformaId: requestItem.proformaId,
          itemType: ITEM_TYPES.PRODUCT,
          refId: trimmedRequestId,
          proformaDoc,
        });
      }

      // Asimetría de cuota (N-11, CA-13): NO decrementar /user_daily_counters
      // Sin avisos (CA-26): NO escribir en /mail

      resultPayload = {
        success: true,
        requestId: trimmedRequestId,
        status: 'CANCELLED',
        cancelledReason: 'CLIENT',
      };
    });

    return resultPayload;
  }
);
