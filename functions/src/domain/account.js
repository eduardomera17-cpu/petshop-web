// functions/src/domain/account.js
// Lógica de dominio unificada para el ciclo de vida y desactivación de cuentas de usuario
// (TRD §3.4.G, §3.4.I, P-06, N-19, D-03, CA-43, CA-46, CA-59, CA-64, CA-AD-19, CF-09, CF-12)

import { HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { ROLES, USER_STATUS } from '../config/constants.js';
import { removeConceptFromDraftProforma, ITEM_TYPES, PROFORMA_STATUS } from './proforma.js';
import { requestStockLines } from './product_request.js';
import { recordAuditLog } from '../lib/audit.js';

/**
 * Ejecuta la desactivación atómica de una cuenta de usuario en Firestore y Firebase Auth.
 * Reutilizado sin duplicación por deactivateOwnAccount (titular) y deactivateUserAccount (Super Usuario).
 *
 * Invariantes normativas:
 * 1. Prohibido desactivar al Super Usuario (SUPERADMIN_IMMUTABLE, CA-AD-19, CF-11).
 * 2. Si la cuenta ya está DEACTIVATED, falla con ACCOUNT_ALREADY_DEACTIVATED.
 * 3. Cancela citas activas liberando cerrojos y retirando líneas de borradores de proforma.
 * 4. Excepción D-03: Cancela solicitudes no facturadas y repone stock; conserva solicitudes facturadas.
 * 5. Registra traza inmutable en /audit_log.
 * 6. Deshabilita usuario y revoca sesiones en Firebase Auth.
 *
 * @param {Object} params
 * @param {string} params.targetUid - UID de la cuenta a desactivar
 * @param {string} params.actorUid - UID del actor que ejecuta la desactivación
 * @param {string} [params.actorName] - Nombre del actor para la auditoría
 * @param {string} [params.actorRole] - Rol del actor para la auditoría
 * @returns {Promise<Object>} Resultado con contadores de citas y solicitudes canceladas/retenidas
 */
export async function executeAccountDeactivation({
  targetUid,
  actorUid,
  actorName = 'Sistema',
  actorRole = ROLES.SUPERADMIN,
}) {
  if (!targetUid || typeof targetUid !== 'string' || targetUid.trim() === '') {
    throw new HttpsError('invalid-argument', 'targetUid es obligatorio.', {
      errorCode: 'INVALID_ARGUMENT',
    });
  }

  const uid = targetUid.trim();
  const userRef = db.collection('users').doc(uid);

  let cancelledAppointmentsCount = 0;
  let cancelledRequestsCount = 0;
  let retainedRequestsCount = 0;

  // Consulta previa de candidatos fuera de la transacción (TRD §3.4.G, ADR-029)
  const candidateAppointmentsSnap = await db
    .collection('appointments')
    .where('clientId', '==', uid)
    .where('status', 'in', ['PENDING', 'CONFIRMED'])
    .get();

  const candidateRequestsSnap = await db
    .collection('product_requests')
    .where('clientId', '==', uid)
    .where('status', 'in', ['PENDING_DISPATCH', 'READY_FOR_PICKUP'])
    .get();

  // 1. Transacción atómica en Firestore (Pasos 1 a 5 de TRD §3.4.G / §3.4.I, ADR-029)
  await db.runTransaction(async (transaction) => {
    // --- FASE 1: LECTURAS ---

    // Paso 1: Leer documento de usuario
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'Usuario no encontrado.', {
        errorCode: 'NOT_FOUND',
      });
    }

    const userData = userDoc.data() || {};

    // Invariante de gobierno: Super Usuario es inmutable (CA-AD-19, CF-11)
    if (userData.role === ROLES.SUPERADMIN) {
      throw new HttpsError('permission-denied', 'El Super Usuario es inmutable.', {
        errorCode: 'SUPERADMIN_IMMUTABLE',
      });
    }

    if (userData.status === USER_STATUS.DEACTIVATED) {
      throw new HttpsError('failed-precondition', 'La cuenta ya se encuentra desactivada.', {
        errorCode: 'ACCOUNT_ALREADY_DEACTIVATED',
      });
    }

    // Paso 2: Lectura transaccional y revalidación de citas activas (PENDING, CONFIRMED)
    const readAppointmentDocs = await Promise.all(
      candidateAppointmentsSnap.docs.map((d) => transaction.get(d.ref))
    );
    const appointmentDocs = readAppointmentDocs.filter(
      (d) =>
        d.exists &&
        d.data()?.clientId === uid &&
        (d.data()?.status === 'PENDING' || d.data()?.status === 'CONFIRMED')
    );

    // Paso 3: Lectura transaccional y revalidación de solicitudes activas (PENDING_DISPATCH, READY_FOR_PICKUP)
    const readRequestDocs = await Promise.all(
      candidateRequestsSnap.docs.map((d) => transaction.get(d.ref))
    );
    const requestDocs = readRequestDocs.filter(
      (d) =>
        d.exists &&
        d.data()?.clientId === uid &&
        (d.data()?.status === 'PENDING_DISPATCH' || d.data()?.status === 'READY_FOR_PICKUP')
    );

    // Lectura previa de proformas vinculadas
    const proformaDocsMap = new Map();
    for (const aDoc of appointmentDocs) {
      const pId = aDoc.data().proformaId;
      if (pId && !proformaDocsMap.has(pId)) {
        const pRef = db.collection('proformas').doc(pId);
        const pDoc = await transaction.get(pRef);
        proformaDocsMap.set(pId, pDoc);
      }
    }

    for (const rDoc of requestDocs) {
      const pId = rDoc.data().proformaId;
      if (pId && !proformaDocsMap.has(pId)) {
        const pRef = db.collection('proformas').doc(pId);
        const pDoc = await transaction.get(pRef);
        proformaDocsMap.set(pId, pDoc);
      }
    }

    // Líneas de las solicitudes cancelables (TRD v1.21 §2.8 regla 3, §3.4.G paso 3): las de items[]. La forma
    // plana se retiró (WP-6.11-B): una solicitud sin items[], o mal formada, hace lanzar a requestStockLines y la
    // transacción aborta sin escribir nada. Las solicitudes facturadas (D-03) no mueven stock y no se leen como líneas.
    const restockLines = [];
    for (const rDoc of requestDocs) {
      const rData = rDoc.data();
      let isBilled = false;
      if (rData.proformaId && proformaDocsMap.has(rData.proformaId)) {
        const pDoc = proformaDocsMap.get(rData.proformaId);
        if (pDoc.exists && pDoc.data()?.status !== PROFORMA_STATUS.DRAFT) {
          isBilled = true;
        }
      }
      if (!isBilled) {
        restockLines.push(...requestStockLines(rData));
      }
    }

    // Reposición acumulada por producto: una sola actualización por documento, con la suma de sus líneas
    const restockByProduct = new Map();
    for (const line of restockLines) {
      restockByProduct.set(line.productId, (restockByProduct.get(line.productId) || 0) + line.quantity);
    }

    // Lectura previa de cada producto a reponer, antes de cualquier escritura (ADR-027, §3.2.E paso 2)
    for (const productId of restockByProduct.keys()) {
      const productDoc = await transaction.get(db.collection('products').doc(productId));
      if (!productDoc.exists) {
        throw new HttpsError('not-found', `Producto a reponer ${productId} no encontrado.`, {
          errorCode: 'NOT_FOUND',
        });
      }
    }

    // --- FASE 2: ESCRITURAS ---
    const nowTimestamp = FieldValue.serverTimestamp();
    cancelledAppointmentsCount = 0;
    cancelledRequestsCount = 0;
    retainedRequestsCount = 0;

    // Paso 1: Mutar /users/{uid} a DEACTIVATED
    transaction.update(userRef, {
      status: USER_STATUS.DEACTIVATED,
      deactivatedAt: nowTimestamp,
      deactivatedBy: actorUid,
      'audit.updatedBy': actorUid,
      'audit.updatedAt': nowTimestamp,
    });

    // Paso 2: Cancelar citas activas y borrar cerrojos
    for (const aDoc of appointmentDocs) {
      const aData = aDoc.data();
      cancelledAppointmentsCount++;
      transaction.update(aDoc.ref, {
        status: 'CANCELLED',
        cancelledReason: 'ACCOUNT_DEACTIVATED',
        'audit.cancelledBy': actorUid,
        'audit.cancelledAt': nowTimestamp,
        'audit.updatedBy': actorUid,
        'audit.updatedAt': nowTimestamp,
      });

      if (aData.slotKey) {
        transaction.delete(db.collection('slot_locks').doc(aData.slotKey));
      }
      if (aData.petDayKey) {
        transaction.delete(db.collection('pet_day_locks').doc(aData.petDayKey));
      }

      // Retiro de línea de borrador si aplica
      if (aData.proformaId && proformaDocsMap.has(aData.proformaId)) {
        const pDoc = proformaDocsMap.get(aData.proformaId);
        if (pDoc.exists && pDoc.data()?.status === PROFORMA_STATUS.DRAFT) {
          await removeConceptFromDraftProforma(transaction, db, {
            proformaId: aData.proformaId,
            itemType: ITEM_TYPES.SERVICE,
            refId: aDoc.id,
            proformaDoc: pDoc,
          });
        }
      }
    }

    // Paso 3: Cancelar solicitudes no facturadas y reponer stock; conservar solicitudes facturadas (D-03)
    for (const rDoc of requestDocs) {
      const rData = rDoc.data();
      let isBilled = false;

      if (rData.proformaId && proformaDocsMap.has(rData.proformaId)) {
        const pDoc = proformaDocsMap.get(rData.proformaId);
        if (pDoc.exists && pDoc.data()?.status !== PROFORMA_STATUS.DRAFT) {
          isBilled = true;
        }
      }

      if (isBilled) {
        // Solicitud en proforma DELIVERED o FINALIZED: NO cancelarla ni reponer stock (D-03)
        retainedRequestsCount++;
      } else {
        // Solicitud cancelable: cancelar y reponer inventario
        cancelledRequestsCount++;
        transaction.update(rDoc.ref, {
          status: 'CANCELLED',
          cancelledReason: 'ACCOUNT_DEACTIVATED',
          'audit.cancelledBy': actorUid,
          'audit.cancelledAt': nowTimestamp,
          'audit.updatedBy': actorUid,
          'audit.updatedAt': nowTimestamp,
        });

        // Retiro de línea de borrador si aplica
        if (rData.proformaId && proformaDocsMap.has(rData.proformaId)) {
          const pDoc = proformaDocsMap.get(rData.proformaId);
          if (pDoc.exists && pDoc.data()?.status === PROFORMA_STATUS.DRAFT) {
            await removeConceptFromDraftProforma(transaction, db, {
              proformaId: rData.proformaId,
              itemType: ITEM_TYPES.PRODUCT,
              refId: rDoc.id,
              proformaDoc: pDoc,
            });
          }
        }
      }
    }

    // Reposición de inventario (TRD v1.21 §3.4.G paso 3): una actualización por producto, con la suma de las
    // líneas canceladas; cada actualización lleva dos transformaciones y el límite es de 500 por documento
    for (const [productId, quantity] of restockByProduct) {
      transaction.update(db.collection('products').doc(productId), {
        stock: FieldValue.increment(quantity),
        'audit.updatedBy': actorUid,
        'audit.updatedAt': nowTimestamp,
      });
    }

    // Paso 5: Registro inmutable en /audit_log (TRD §2.12, N-AD-08)
    recordAuditLog(transaction, {
      actorUid: actorUid,
      actorName: actorName || 'Sistema',
      actorRole: actorRole || ROLES.CLIENT,
      action: 'ACCOUNT_DEACTIVATE',
      targetType: 'USER',
      targetId: uid,
      metadata: {
        clientId: uid,
        cancelledAppointmentsCount,
        cancelledRequestsCount,
        retainedRequestsCount,
      },
    });
  });

  // 2. Operaciones de Firebase Auth (FUERA de la transacción de Firestore, TRD §3.4.G / §3.4.I / §4.2)
  try {
    const authUser = await auth.getUser(uid);
    const existingClaims = authUser.customClaims || {};
    await auth.setCustomUserClaims(uid, {
      ...existingClaims,
      status: USER_STATUS.DEACTIVATED,
    });
    await auth.updateUser(uid, { disabled: true });
    await auth.revokeRefreshTokens(uid);
  } catch (authError) {
    console.error(`[executeAccountDeactivation] Error sincronizando usuario ${uid} en Firebase Auth:`, authError);
  }

  return {
    success: true,
    uid,
    status: USER_STATUS.DEACTIVATED,
    cancelledAppointmentsCount,
    cancelledRequestsCount,
    retainedRequestsCount,
  };
}
