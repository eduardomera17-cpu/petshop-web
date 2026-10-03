// functions/src/callables/voidProforma.js
// Callable de anulación de proforma con preservación documental y liberación de conceptos (TRD §3.3.G, N-19, FA-07, CA-AD-43)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, PROFORMA_VOID_REASON_MAX_LENGTH, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { PROFORMA_STATUS } from '../domain/proforma.js';
import { recordAuditLog } from '../lib/audit.js';

export const voidProforma = onCall(
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
    const { proformaId, voidReason } = requestData;

    if (!proformaId || typeof proformaId !== 'string' || proformaId.trim() === '') {
      throw new HttpsError('invalid-argument', 'proformaId es obligatorio y debe ser texto no vacío.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (
      !voidReason ||
      typeof voidReason !== 'string' ||
      voidReason.trim() === '' ||
      voidReason.trim().length > PROFORMA_VOID_REASON_MAX_LENGTH
    ) {
      throw new HttpsError(
        'invalid-argument',
        `voidReason es obligatorio, texto no vacío y máximo ${PROFORMA_VOID_REASON_MAX_LENGTH} caracteres.`,
        { errorCode: 'INVALID_ARGUMENT' }
      );
    }

    const trimmedProformaId = proformaId.trim();
    const trimmedVoidReason = voidReason.trim();
    const proformaRef = db.collection('proformas').doc(trimmedProformaId);

    // 2. Transacción atómica de anulación (TRD §3.3.G)
    await db.runTransaction(async (transaction) => {
      // --- LECTURAS ---
      const proformaDoc = await transaction.get(proformaRef);
      if (!proformaDoc.exists) {
        throw new HttpsError('not-found', 'Proforma no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const proformaData = proformaDoc.data();

      // Asimetría normativa: Una proforma FINALIZED nunca se anula (FA-06)
      if (proformaData.status === PROFORMA_STATUS.FINALIZED) {
        throw new HttpsError('failed-precondition', 'Una proforma finalizada no puede ser anulada.', {
          errorCode: 'PROFORMA_NOT_VOIDABLE',
        });
      }

      // Validar que el estado sea estrictamente DELIVERED
      if (proformaData.status !== PROFORMA_STATUS.DELIVERED) {
        throw new HttpsError('failed-precondition', 'Solo proformas en estado DELIVERED pueden ser anuladas.', {
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

      // 1. Mutar proforma a VOIDED (conservando intactos number, formattedNumber, series y pdfPath, N-19, FA-07)
      transaction.update(proformaRef, {
        status: PROFORMA_STATUS.VOIDED,
        voidReason: trimmedVoidReason,
        voidedAt: now,
        voidedBy: uid,
        'audit.voidedBy': uid,
        'audit.voidedAt': now,
        'audit.updatedBy': uid,
        'audit.updatedAt': now,
      });

      // 2. Liberación de conceptos: desvincular proformaId para devolverlos a estado cancelable
      for (const { item, ref } of itemDocs) {
        if (item.itemType === 'SERVICE') {
          transaction.update(ref, {
            proformaId: null,
            isBilled: false,
            'audit.updatedBy': uid,
            'audit.updatedAt': now,
          });
        } else if (item.itemType === 'PRODUCT') {
          transaction.update(ref, {
            proformaId: null,
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
        action: 'PROFORMA_VOID',
        targetType: 'PROFORMA',
        targetId: trimmedProformaId,
        metadata: {
          proformaId: trimmedProformaId,
          formattedNumber: proformaData.formattedNumber || null,
          number: proformaData.number || null,
          series: proformaData.series || null,
          voidReason: trimmedVoidReason,
          clientId: proformaData.clientId || null,
          totalCents: proformaData.totalCents || 0,
          itemsCount: items.length,
        },
      });
    });

    return {
      success: true,
      proformaId: trimmedProformaId,
      status: PROFORMA_STATUS.VOIDED,
    };
  }
);
