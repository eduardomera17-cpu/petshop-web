// functions/src/callables/annulClinicalRecord.js
// Callable de anulación inmutable de registros clínicos (TRD §2.4.1, §3.4.C, CL-08, CA-AD-31, ADR-007, Caso Crítico 18)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { todayBusinessDate } from '../domain/clock.js';

export const annulClinicalRecord = onCall(
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

    if (request.auth.token?.status && request.auth.token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const callerUid = request.auth.uid;
    const callerName = request.auth.token?.name || 'Personal Veterinario';

    const data = request.data || {};
    const { petId, recordId, reason } = data;

    if (!petId || typeof petId !== 'string' || petId.trim() === '') {
      throw new HttpsError('invalid-argument', 'petId es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (!recordId || typeof recordId !== 'string' || recordId.trim() === '') {
      throw new HttpsError('invalid-argument', 'recordId es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (!reason || typeof reason !== 'string' || reason.trim() === '') {
      throw new HttpsError('invalid-argument', 'El motivo de anulación (reason) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedReason = reason.trim();
    if (trimmedReason.length > 500) {
      throw new HttpsError('invalid-argument', 'El motivo de anulación no puede superar 500 caracteres.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedPetId = petId.trim();
    const trimmedRecordId = recordId.trim();
    const recordRef = db
      .collection('pets')
      .doc(trimmedPetId)
      .collection('clinical_records')
      .doc(trimmedRecordId);

    let annulmentRecordId = '';

    // 2. Transacción Atómica de Anulación (TRD §3.4.C, CL-08)
    await db.runTransaction(async (transaction) => {
      const recordDoc = await transaction.get(recordRef);
      if (!recordDoc.exists) {
        throw new HttpsError('not-found', 'Registro clínico no encontrado.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const recordData = recordDoc.data() || {};

      // Rechazar si ya está anulado (TRD §3.4.C)
      if (recordData.status === 'ANNULLED') {
        throw new HttpsError('failed-precondition', 'El registro ya se encuentra anulado.', {
          errorCode: 'ENTRY_ALREADY_ANNULLED',
        });
      }

      // Rechazar anulación de una entrada de tipo ANNULMENT (TRD §3.4.C)
      if (recordData.type === 'ANNULMENT') {
        throw new HttpsError('failed-precondition', 'No se puede anular una entrada de anulación.', {
          errorCode: 'ANNULMENT_NOT_ANNULLABLE',
        });
      }

      // PASO A: Crear la nueva entrada de tipo ANNULMENT referenciando a la anulada
      const annulmentRef = db
        .collection('pets')
        .doc(trimmedPetId)
        .collection('clinical_records')
        .doc();

      annulmentRecordId = annulmentRef.id;

      const now = FieldValue.serverTimestamp();
      const currentDate = todayBusinessDate();

      transaction.set(annulmentRef, {
        id: annulmentRecordId,
        petId: trimmedPetId,
        ownerId: recordData.ownerId || '__NOT_REGISTERED__',
        type: 'ANNULMENT',
        status: 'ACTIVE',

        authorUid: callerUid,
        authorName: callerName,
        createdAt: now,
        attentionDate: currentDate,
        attentionTime: '12:00',

        annulment: {
          targetRecordId: trimmedRecordId,
          reason: trimmedReason,
        },

        patientSnapshot: recordData.patientSnapshot || {},

        isEdited: false,
        version: 1,
      });

      // PASO B: Marcar la entrada objetivo como ANNULLED y vincular la auditoría
      transaction.update(recordRef, {
        status: 'ANNULLED',
        annulledAt: now,
        annulledBy: callerUid,
        annulledByRecordId: annulmentRecordId,
        annulmentReason: trimmedReason,
      });
    });

    return {
      success: true,
      recordId: trimmedRecordId,
      petId: trimmedPetId,
      annulmentRecordId: annulmentRecordId,
      status: 'ANNULLED',
    };
  }
);
