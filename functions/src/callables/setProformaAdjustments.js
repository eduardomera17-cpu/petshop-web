// functions/src/callables/setProformaAdjustments.js
// Callable para reemplazar el conjunto de ajustes de una proforma en borrador (TRD §3.3.D, §2.10, FA-04, FA-09)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import {
  PROFORMA_STATUS,
  validateAdjustment,
  recalculateProformaDocument,
} from '../domain/proforma.js';

export const setProformaAdjustments = onCall(
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

    // 2. Validación de argumentos
    const requestData = request.data || {};
    const { proformaId, adjustments } = requestData;

    if (!proformaId || typeof proformaId !== 'string' || proformaId.trim() === '') {
      throw new HttpsError('invalid-argument', 'proformaId es obligatorio y debe ser texto no vacío.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (!Array.isArray(adjustments)) {
      throw new HttpsError('invalid-argument', 'adjustments es obligatorio y debe ser un arreglo.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    // Validar cada ajuste (concepto obligatorio, tipo DISCOUNT/SURCHARGE, sin impuestos)
    const validatedAdjustments = [];
    for (let i = 0; i < adjustments.length; i++) {
      try {
        const validated = validateAdjustment(adjustments[i], i);
        validatedAdjustments.push(validated);
      } catch (err) {
        if (err.errorCode === 'ADJUSTMENT_CONCEPT_REQUIRED') {
          throw new HttpsError('invalid-argument', err.message, {
            errorCode: 'ADJUSTMENT_CONCEPT_REQUIRED',
          });
        }
        throw new HttpsError('invalid-argument', err.message, {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
    }

    const trimmedProformaId = proformaId.trim();
    const proformaRef = db.collection('proformas').doc(trimmedProformaId);
    const billingRef = db.collection('business_config').doc('billing_parameters');

    let resultPayload = null;

    // 3. Transacción atómica de reemplazo de ajustes y recálculo
    await db.runTransaction(async (transaction) => {
      const proformaDoc = await transaction.get(proformaRef);
      if (!proformaDoc.exists) {
        throw new HttpsError('not-found', 'Proforma no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const proformaData = proformaDoc.data();
      if (proformaData.status !== PROFORMA_STATUS.DRAFT) {
        throw new HttpsError('failed-precondition', 'Los ajustes solo se pueden aplicar a proformas en estado DRAFT.', {
          errorCode: 'PROFORMA_NOT_DRAFT',
        });
      }

      const billingDoc = await transaction.get(billingRef);
      const iceIncludedInIvaBase = billingDoc.exists && typeof billingDoc.data()?.iceIncludedInIvaBase === 'boolean'
        ? billingDoc.data().iceIncludedInIvaBase
        : true;

      // Recalcular documento completo con los nuevos ajustes
      const currentItems = Array.isArray(proformaData.items) ? proformaData.items : [];
      const recalculatedDoc = recalculateProformaDocument({
        items: currentItems,
        adjustments: validatedAdjustments,
        iceIncludedInIvaBase,
      });

      // Actualizar documento con el arreglo completo de ajustes y los nuevos totales
      transaction.update(proformaRef, {
        items: recalculatedDoc.items,
        adjustments: recalculatedDoc.adjustments,
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
        adjustmentsCount: recalculatedDoc.adjustments.length,
        subtotalCents: recalculatedDoc.subtotalCents,
        totalDiscountCents: recalculatedDoc.totalDiscountCents,
        totalSurchargeCents: recalculatedDoc.totalSurchargeCents,
        taxableBaseCents: recalculatedDoc.taxableBaseCents,
        totalCents: recalculatedDoc.totalCents,
      };
    });

    return resultPayload;
  }
);
