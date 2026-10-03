// functions/src/callables/finalizeProforma.js
// Callable de finalización de proforma y propagación en cascada (TRD §3.3.F, IN-04, FA-01, FA-06, CA-AD-43)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { PROFORMA_STATUS } from '../domain/proforma.js';
import { recordAuditLog } from '../lib/audit.js';

export const finalizeProforma = onCall(
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

    const requestData = request.data || {};
    const { proformaId } = requestData;

    if (!proformaId || typeof proformaId !== 'string' || proformaId.trim() === '') {
      throw new HttpsError('invalid-argument', 'proformaId es obligatorio y debe ser texto no vacío.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedProformaId = proformaId.trim();
    const proformaRef = db.collection('proformas').doc(trimmedProformaId);

    // 2. Transacción atómica de finalización (TRD §3.3.F)
    await db.runTransaction(async (transaction) => {
      // --- LECTURAS ---
      const proformaDoc = await transaction.get(proformaRef);
      if (!proformaDoc.exists) {
        throw new HttpsError('not-found', 'Proforma no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const proformaData = proformaDoc.data();

      // Validar que el estado sea estrictamente DELIVERED
      if (proformaData.status !== PROFORMA_STATUS.DELIVERED) {
        throw new HttpsError('failed-precondition', 'Solo proformas en estado DELIVERED pueden ser finalizadas.', {
          errorCode: 'PROFORMA_NOT_DELIVERED',
        });
      }

      const items = Array.isArray(proformaData.items) ? proformaData.items : [];
      const itemDocs = [];

      for (const item of items) {
        if (item.itemType === 'SERVICE') {
          const aptRef = db.collection('appointments').doc(item.refId);
          const aptDoc = await transaction.get(aptRef);
          itemDocs.push({ item, ref: aptRef, doc: aptDoc });
        } else if (item.itemType === 'PRODUCT') {
          const reqRef = db.collection('product_requests').doc(item.refId);
          const reqDoc = await transaction.get(reqRef);
          itemDocs.push({ item, ref: reqRef, doc: reqDoc });
        }
      }

      // --- ESCRITURAS ---
      const now = FieldValue.serverTimestamp();

      // 1. Mutar proforma a FINALIZED (estado terminal e irreversible)
      transaction.update(proformaRef, {
        status: PROFORMA_STATUS.FINALIZED,
        finalizedAt: now,
        finalizedBy: uid,
        'audit.finalizedBy': uid,
        'audit.finalizedAt': now,
        'audit.updatedBy': uid,
        'audit.updatedAt': now,
      });

      // 2. Propagar en cascada sobre los conceptos incluidos
      for (const { item, ref } of itemDocs) {
        if (item.itemType === 'SERVICE') {
          // Citas asociadas -> isBilled: true (FA-01: salen del resumen a pagar)
          transaction.update(ref, {
            isBilled: true,
            'audit.updatedBy': uid,
            'audit.updatedAt': now,
          });
        } else if (item.itemType === 'PRODUCT') {
          // Solicitudes de producto asociadas -> status: FINALIZED (IN-04)
          transaction.update(ref, {
            status: 'FINALIZED',
            'audit.updatedBy': uid,
            'audit.updatedAt': now,
          });
        }
      }

      // 3. Registro de auditoría (TRD §2.12, N-AD-08)
      recordAuditLog(transaction, {
        actorUid: uid,
        actorName: token.name || 'Personal',
        actorRole: token.role || ROLES.ADMIN,
        action: 'PROFORMA_FINALIZE',
        targetType: 'PROFORMA',
        targetId: trimmedProformaId,
        metadata: {
          proformaId: trimmedProformaId,
          formattedNumber: proformaData.formattedNumber || null,
          number: proformaData.number || null,
          series: proformaData.series || null,
          clientId: proformaData.clientId || null,
          totalCents: proformaData.totalCents || 0,
          itemsCount: items.length,
        },
      });
    });

    return {
      success: true,
      proformaId: trimmedProformaId,
      status: PROFORMA_STATUS.FINALIZED,
    };
  }
);
