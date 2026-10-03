// functions/src/callables/addProformaItems.js
// Callable transaccional para incorporar conceptos a una proforma en borrador (TRD §3.3.C, §2.10, FA-03, FA-04, ADR-005)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, PROFORMA_MAX_ITEMS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import {
  PROFORMA_STATUS,
  buildProformaItemFromAppointment,
  buildProformaItemsFromProductRequest,
  recalculateProformaDocument,
} from '../domain/proforma.js';

export const addProformaItems = onCall(
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

    // Verificación de revocación de token si viene en cabeceras
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

    // 2. Validación de argumentos de entrada
    const requestData = request.data || {};
    const { proformaId, items } = requestData;

    if (!proformaId || typeof proformaId !== 'string' || proformaId.trim() === '') {
      throw new HttpsError('invalid-argument', 'proformaId es obligatorio y debe ser texto no vacío.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (!Array.isArray(items) || items.length === 0) {
      throw new HttpsError('invalid-argument', 'items es obligatorio y debe ser un arreglo no vacío de referencias.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    // FA-04: Prohibición estricta de parámetros que intenten alterar precios unitarios o impuestos
    for (const itemRef of items) {
      if (!itemRef || typeof itemRef !== 'object') {
        throw new HttpsError('invalid-argument', 'Cada elemento de items debe ser un objeto { itemType, refId }.', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      if ('unitBasePriceCents' in itemRef || 'basePriceCents' in itemRef || 'price' in itemRef || 'customPrice' in itemRef) {
        throw new HttpsError('invalid-argument', 'Queda estrictamente prohibido alterar precios unitarios de conceptos ya acordados (FA-04).', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
    }

    const trimmedProformaId = proformaId.trim();
    const proformaRef = db.collection('proformas').doc(trimmedProformaId);
    const billingRef = db.collection('business_config').doc('billing_parameters');

    let resultPayload = null;

    // 3. Transacción atómica de adición de conceptos (TRD §3.3.C)
    await db.runTransaction(async (transaction) => {
      // 3.1. Leer proforma
      const proformaDoc = await transaction.get(proformaRef);
      if (!proformaDoc.exists) {
        throw new HttpsError('not-found', 'Proforma no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const proformaData = proformaDoc.data();
      if (proformaData.status !== PROFORMA_STATUS.DRAFT) {
        throw new HttpsError('failed-precondition', 'Solo se pueden incorporar conceptos a una proforma en estado DRAFT.', {
          errorCode: 'PROFORMA_NOT_DRAFT',
        });
      }

      const currentItems = Array.isArray(proformaData.items) ? proformaData.items : [];

      // 3.2. Leer billing_parameters para configuración fiscal
      const billingDoc = await transaction.get(billingRef);
      // ADR-016 y caso crítico 23 (AUD-326): la regla de cascada se congela con la
      // proforma la primera vez que recibe contenido, igual que ya hace la retirada de
      // línea en domain/proforma.js. Si el documento ya la tiene, manda el documento:
      // CF-13 puede cambiar después sin mover un céntimo de lo que el cliente ya vio.
      const iceIncludedInIvaBase = typeof proformaData.iceIncludedInIvaBase === 'boolean'
        ? proformaData.iceIncludedInIvaBase
        : (billingDoc.exists && typeof billingDoc.data()?.iceIncludedInIvaBase === 'boolean'
          ? billingDoc.data().iceIncludedInIvaBase
          : true);

      // 3.3. Leer y validar cada concepto en Firestore (fase de lecturas, TRD §3.3.C)
      const newItemsToAdd = [];
      const appointmentsToLock = [];
      const requestsToLock = [];

      for (const itemRef of items) {
        const itemType = itemRef.itemType;
        const refId = typeof itemRef.refId === 'string' ? itemRef.refId.trim() : null;

        if (!refId) {
          throw new HttpsError('invalid-argument', 'Cada concepto requiere refId válido.', {
            errorCode: 'INVALID_ARGUMENT',
          });
        }

        if (itemType === 'APPOINTMENT' || itemType === 'SERVICE') {
          const aptRef = db.collection('appointments').doc(refId);
          const aptDoc = await transaction.get(aptRef);
          if (!aptDoc.exists) {
            throw new HttpsError('not-found', `Cita no encontrada: ${refId}.`, {
              errorCode: 'NOT_FOUND',
            });
          }

          const aptData = aptDoc.data();
          if (aptData.clientId !== proformaData.clientId) {
            throw new HttpsError('failed-precondition', 'La cita pertenece a otro cliente.', {
              errorCode: 'PERMISSION_DENIED',
            });
          }

          // Invariante de cita para proforma: status == 'COMPLETED', isBilled == false, proformaId == null
          if (aptData.status !== 'COMPLETED') {
            throw new HttpsError('failed-precondition', `La cita ${refId} no está en estado COMPLETED (estado actual: ${aptData.status}).`, {
              errorCode: 'FAILED_PRECONDITION',
            });
          }
          if (aptData.isBilled === true) {
            throw new HttpsError('failed-precondition', `La cita ${refId} ya fue facturada previamente.`, {
              errorCode: 'FAILED_PRECONDITION',
            });
          }
          if (aptData.proformaId != null) {
            throw new HttpsError('failed-precondition', `La cita ${refId} ya está asignada a la proforma ${aptData.proformaId}.`, {
              errorCode: 'FAILED_PRECONDITION',
            });
          }

          let builtItem;
          try {
            builtItem = buildProformaItemFromAppointment({ ...aptData, id: refId });
          } catch (err) {
            throw new HttpsError(
              'failed-precondition',
              `La cita ${refId} tiene una estructura no facturable: ${err.message}`,
              {
                errorCode: 'CONCEPT_NOT_BILLABLE',
                refId,
                refLineId: null,
              }
            );
          }
          const price = builtItem.unitBasePriceCents;
          const iva = builtItem.ivaBp;
          if (
            typeof price !== 'number' ||
            !Number.isInteger(price) ||
            price < 0 ||
            typeof iva !== 'number' ||
            !Number.isInteger(iva) ||
            iva < 0
          ) {
            throw new HttpsError(
              'failed-precondition',
              `La cita ${refId} no tiene precio o IVA congelados válidos.`,
              {
                errorCode: 'CONCEPT_NOT_BILLABLE',
                refId,
                refLineId: null,
              }
            );
          }

          newItemsToAdd.push(builtItem);
          appointmentsToLock.push(aptRef);
        } else if (itemType === 'PRODUCT_REQUEST' || itemType === 'PRODUCT') {
          const reqRef = db.collection('product_requests').doc(refId);
          const reqDoc = await transaction.get(reqRef);
          if (!reqDoc.exists) {
            throw new HttpsError('not-found', `Solicitud de producto no encontrada: ${refId}.`, {
              errorCode: 'NOT_FOUND',
            });
          }

          const reqData = reqDoc.data();
          if (reqData.clientId !== proformaData.clientId) {
            throw new HttpsError('failed-precondition', 'La solicitud pertenece a otro cliente.', {
              errorCode: 'PERMISSION_DENIED',
            });
          }

          // Invariante de solicitud para proforma: status == 'READY_FOR_PICKUP', proformaId == null
          if (reqData.status !== 'READY_FOR_PICKUP') {
            throw new HttpsError('failed-precondition', `La solicitud ${refId} no está en estado READY_FOR_PICKUP (estado actual: ${reqData.status}).`, {
              errorCode: 'FAILED_PRECONDITION',
            });
          }
          if (reqData.proformaId != null) {
            throw new HttpsError('failed-precondition', `La solicitud ${refId} ya está asignada a la proforma ${reqData.proformaId}.`, {
              errorCode: 'FAILED_PRECONDITION',
            });
          }

          let builtItems;
          try {
            builtItems = buildProformaItemsFromProductRequest({ ...reqData, id: refId });
          } catch (err) {
            throw new HttpsError(
              'failed-precondition',
              `La solicitud ${refId} tiene una estructura no facturable: ${err.message}`,
              {
                errorCode: 'CONCEPT_NOT_BILLABLE',
                refId,
                refLineId: null,
              }
            );
          }

          for (const lineItem of builtItems) {
            const price = lineItem.unitBasePriceCents;
            const iva = lineItem.ivaBp;
            if (
              typeof price !== 'number' ||
              !Number.isInteger(price) ||
              price < 0 ||
              typeof iva !== 'number' ||
              !Number.isInteger(iva) ||
              iva < 0
            ) {
              throw new HttpsError(
                'failed-precondition',
                `La solicitud ${refId} (línea ${lineItem.refLineId}) no tiene precio o IVA congelados válidos.`,
                {
                  errorCode: 'CONCEPT_NOT_BILLABLE',
                  refId,
                  refLineId: lineItem.refLineId,
                }
              );
            }
            newItemsToAdd.push(lineItem);
          }
          requestsToLock.push(reqRef);
        } else {
          throw new HttpsError('invalid-argument', `itemType inválido: '${itemType}'. Debe ser APPOINTMENT o PRODUCT_REQUEST.`, {
            errorCode: 'INVALID_ARGUMENT',
          });
        }
      }

      // 3.4. Tope de 100 líneas (ADR-005, FA-03, AUD-267):
      // líneas actuales de la proforma + total de líneas a incorporar > PROFORMA_MAX_ITEMS
      if (currentItems.length + newItemsToAdd.length > PROFORMA_MAX_ITEMS) {
        throw new HttpsError(
          'resource-exhausted',
          `Se ha superado el límite de ${PROFORMA_MAX_ITEMS} líneas. Actualmente tiene ${currentItems.length} líneas y se intentó agregar ${newItemsToAdd.length}.`,
          { errorCode: 'TOO_MANY_ITEMS' }
        );
      }

      // 3.5. Unicidad de (refId, refLineId) dentro de la proforma y dentro de la llamada (TRD §3.3.C)
      const existingKeys = new Set(
        currentItems.map((it) => `${it.refId}::${it.refLineId ?? 'null'}`)
      );
      const seenNewKeys = new Set();
      for (const item of newItemsToAdd) {
        const key = `${item.refId}::${item.refLineId ?? 'null'}`;
        if (existingKeys.has(key) || seenNewKeys.has(key)) {
          throw new HttpsError(
            'failed-precondition',
            `El concepto ${item.refId} (${item.refLineId || 'cita'}) ya está incorporado en la proforma o duplicado en la llamada.`,
            { errorCode: 'CONCEPT_NO_LONGER_VALID' }
          );
        }
        seenNewKeys.add(key);
      }

      // 3.6. Combinar líneas y recalcular documento
      const combinedItems = [...currentItems, ...newItemsToAdd];
      const recalculatedDoc = recalculateProformaDocument({
        items: combinedItems,
        adjustments: proformaData.adjustments || [],
        iceIncludedInIvaBase,
      });

      // 3.7. Bloqueo atómico por persistencia: escribir proformaId en cada cita y solicitud
      for (const aptRef of appointmentsToLock) {
        transaction.update(aptRef, {
          proformaId: trimmedProformaId,
          'audit.updatedBy': uid,
          'audit.updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (const reqRef of requestsToLock) {
        transaction.update(reqRef, {
          proformaId: trimmedProformaId,
          'audit.updatedBy': uid,
          'audit.updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3.7. Actualizar la proforma en /proformas/{proformaId}
      transaction.update(proformaRef, {
        items: recalculatedDoc.items,
        // Se persiste la regla con la que se acaba de calcular (AUD-326). A partir de
        // aquí el documento la lleva puesta y la entrega la respeta.
        iceIncludedInIvaBase,
        subtotalCents: recalculatedDoc.subtotalCents,
        totalDiscountCents: recalculatedDoc.totalDiscountCents,
        totalSurchargeCents: recalculatedDoc.totalSurchargeCents,
        taxableBaseCents: recalculatedDoc.taxableBaseCents,
        totalIceCents: recalculatedDoc.totalIceCents,
        totalIvaCents: recalculatedDoc.totalIvaCents,
        totalCents: recalculatedDoc.totalCents,
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      });

      resultPayload = {
        success: true,
        proformaId: trimmedProformaId,
        itemCount: recalculatedDoc.items.length,
        subtotalCents: recalculatedDoc.subtotalCents,
        totalCents: recalculatedDoc.totalCents,
      };
    });

    return resultPayload;
  }
);
