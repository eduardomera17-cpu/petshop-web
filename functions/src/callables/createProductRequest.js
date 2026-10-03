// functions/src/callables/createProductRequest.js
// Callable de creación de solicitud de producto con descuento de stock indivisible (TRD §3.2.D, PR-04, N-11, N-12, CA-18, CA-AD-11, B-02, AUD-149, AUD-150)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import {
  REGIONS, USER_STATUS, DAILY_REQUESTS_LIMIT, ENFORCE_APP_CHECK } from '../config/constants.js';
import { todayBusinessDate } from '../domain/clock.js';
import { validateRequestItems } from '../domain/validators.js';

export const createProductRequest = onCall(
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
    const { items, requestId } = requestData;

    // 2. Soporte de Idempotencia por requestId sobre /idempotency/{requestId} (TRD §3.7)
    if (requestId && typeof requestId === 'string') {
      const idempotencyDoc = await db.collection('idempotency').doc(requestId).get();
      if (idempotencyDoc.exists) {
        return idempotencyDoc.data()?.response;
      }
    }

    // 3. Fase 1: Validaciones sintácticas previas fuera de la transacción (TRD v1.21 §3.2.D)
    const validation = validateRequestItems(items);
    if (!validation.isValid) {
      const httpsErrorCode = validation.errorCode === 'TOO_MANY_REQUEST_LINES'
        ? 'resource-exhausted'
        : 'invalid-argument';
      throw new HttpsError(httpsErrorCode, 'Error en las líneas de la solicitud.', validation.details);
    }
    const validatedLines = validation.lines;

    const actionDate = todayBusinessDate(); // N-12, zona del negocio America/Guayaquil
    const dailyCounterKey = `${uid}_${actionDate}`;
    const dailyCounterRef = db.collection('user_daily_counters').doc(dailyCounterKey);
    const userRef = db.collection('users').doc(uid);
    const billingRef = db.collection('business_config').doc('billing_parameters');

    // Generación del ID del documento de solicitud
    const productRequestRef = db.collection('product_requests').doc();
    const newRequestId = productRequestRef.id;

    let responsePayload = null;

    // 4. Transacción atómica estricta (TRD §3.2.D, orden normativo: todas las lecturas antes de las escrituras)
    await db.runTransaction(async (transaction) => {
      // D2.1: Leer /user_daily_counters/{uid}_{actionDate} (N-11, CA-13)
      const dailyDoc = await transaction.get(dailyCounterRef);
      const currentRequestsCount = (dailyDoc.exists && typeof dailyDoc.data()?.productRequestsCount === 'number')
        ? dailyDoc.data().productRequestsCount
        : 0;

      if (currentRequestsCount >= DAILY_REQUESTS_LIMIT) {
        throw new HttpsError('resource-exhausted', 'Límite diario de solicitudes de producto alcanzado (máximo 10).', {
          errorCode: 'DAILY_LIMIT_REQUESTS',
        });
      }

      // D2.2: Leer /users/{uid} dentro de la transacción
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new HttpsError('permission-denied', 'Cuenta no activa.', {
          errorCode: 'ACCOUNT_NOT_ACTIVE',
        });
      }
      const uData = userDoc.data() || {};
      if (uData.status !== USER_STATUS.ACTIVE) {
        throw new HttpsError('permission-denied', 'Cuenta no activa.', {
          errorCode: 'ACCOUNT_NOT_ACTIVE',
        });
      }
      const clientName = uData.fullName || token.name || 'Cliente';

      // D2.3: Leer /business_config/billing_parameters
      const billingDoc = await transaction.get(billingRef);
      if (!billingDoc.exists) {
        throw new HttpsError('failed-precondition', 'Configuración de facturación no disponible.', {
          errorCode: 'CONFIG_UNAVAILABLE',
        });
      }
      const billingData = billingDoc.data() || {};
      const ivaBp = billingData.ivaBp;
      if (typeof ivaBp !== 'number' || !Number.isInteger(ivaBp) || ivaBp < 0) {
        throw new HttpsError('failed-precondition', 'Configuración de facturación no disponible.', {
          errorCode: 'CONFIG_UNAVAILABLE',
        });
      }

      // D2.4: Leer /products/{productId} para cada línea en su orden
      const productDocs = [];
      for (const line of validatedLines) {
        const pRef = db.collection('products').doc(line.productId);
        const pDoc = await transaction.get(pRef);
        productDocs.push(pDoc);
      }

      // D3: Clasificación de todas las líneas después de leer todos los productos
      const notAvailable = [];
      const outOfStock = [];
      const insufficientStock = [];

      for (let i = 0; i < validatedLines.length; i++) {
        const line = validatedLines[i];
        const pDoc = productDocs[i];

        if (!pDoc.exists || pDoc.data()?.isActive !== true) {
          notAvailable.push({
            productId: line.productId,
            productName: pDoc.exists ? (pDoc.data()?.name ?? null) : null,
          });
        } else {
          const pData = pDoc.data() || {};
          const currentStock = typeof pData.stock === 'number' ? pData.stock : 0;
          if (currentStock <= 0) {
            outOfStock.push({
              productId: line.productId,
              productName: pData.name ?? null,
            });
          } else if (currentStock < line.quantity) {
            insufficientStock.push({
              productId: line.productId,
              productName: pData.name ?? null,
            });
          }
        }
      }

      if (notAvailable.length > 0 || outOfStock.length > 0 || insufficientStock.length > 0) {
        let primaryErrorCode;
        let errorMessage;

        if (notAvailable.length > 0) {
          primaryErrorCode = 'PRODUCT_NOT_AVAILABLE';
          errorMessage = 'Uno o más productos no se encuentran disponibles.';
        } else if (outOfStock.length > 0) {
          primaryErrorCode = 'OUT_OF_STOCK';
          errorMessage = 'Uno o más productos están agotados.';
        } else {
          primaryErrorCode = 'INSUFFICIENT_STOCK';
          errorMessage = 'Uno o más productos no disponen de existencias suficientes.';
        }

        throw new HttpsError('failed-precondition', errorMessage, {
          errorCode: primaryErrorCode,
          products: {
            PRODUCT_NOT_AVAILABLE: notAvailable,
            OUT_OF_STOCK: outOfStock,
            INSUFFICIENT_STOCK: insufficientStock,
          },
        });
      }

      // D4: --- INICIO DE ESCRITURAS TRANSACCIONALES ---

      // D4.1: Descuento indivisible de stock por cada línea
      for (const line of validatedLines) {
        const pRef = db.collection('products').doc(line.productId);
        transaction.update(pRef, {
          stock: FieldValue.increment(-line.quantity),
          'audit.updatedBy': uid,
          'audit.updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Construcción de items[] congelados
      const itemsPayload = [];
      for (let i = 0; i < validatedLines.length; i++) {
        const line = validatedLines[i];
        const pDoc = productDocs[i];
        const pData = pDoc.data() || {};

        itemsPayload.push({
          productId: line.productId,
          productName: pData.name || '',
          quantity: line.quantity,
          agreedUnitPriceCents: pData.basePriceCents,
          iceBp: pData.iceBp || 0,
          ivaBp,
        });
      }

      // D4.2: Guardar solicitud con items[] y nada más en su lugar: la transición terminó y los seis campos
      // planos ya no se escriben (TRD §2.8 «Cuándo termina», §3.2.D paso 12; WP-6.11-B).
      const firstItem = itemsPayload[0];
      const requestPayload = {
        id: newRequestId,
        clientId: uid,
        clientName,
        items: itemsPayload,
        status: 'PENDING_DISPATCH',
        actionDateString: actionDate,
        proformaId: null,
        cancelledReason: null,
        audit: {
          createdBy: uid,
          createdAt: FieldValue.serverTimestamp(),
          readyBy: null,
          readyAt: null,
          finalizedBy: null,
          finalizedAt: null,
          cancelledBy: null,
          cancelledAt: null,
          updatedBy: uid,
          updatedAt: FieldValue.serverTimestamp(),
        },
      };
      transaction.set(productRequestRef, requestPayload);

      // D4.3: Incrementar contador diario en 1
      if (dailyDoc.exists) {
        transaction.update(dailyCounterRef, {
          productRequestsCount: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(dailyCounterRef, {
          userId: uid,
          actionDate,
          appointmentsCount: 0,
          productRequestsCount: 1,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      // D4.4: Respuesta con las claves de hoy y valores de items[0]
      responsePayload = {
        success: true,
        requestId: newRequestId,
        status: 'PENDING_DISPATCH',
        actionDateString: actionDate,
        productName: firstItem.productName,
        agreedUnitPriceCents: firstItem.agreedUnitPriceCents,
        iceBp: firstItem.iceBp,
        ivaBp: firstItem.ivaBp,
        quantity: firstItem.quantity,
      };

      // Si se proporcionó requestId del cliente para idempotencia, registrar resultado
      if (requestId && typeof requestId === 'string') {
        const idempotencyRef = db.collection('idempotency').doc(requestId);
        transaction.set(idempotencyRef, {
          requestId,
          userId: uid,
          action: 'createProductRequest',
          response: responsePayload,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
    });

    return responsePayload;
  }
);
