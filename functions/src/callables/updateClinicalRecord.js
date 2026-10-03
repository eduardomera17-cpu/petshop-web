// functions/src/callables/updateClinicalRecord.js
// Callable de corrección de entrada clínica con versionado íntegro en subcolección (TRD §2.4.2, §3.4.B, CL-12, D-T8, CA-AD-52, ADR-007, Caso Crítico 18)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { isFutureBusinessDate } from '../domain/clock.js';

const VALID_SYSTEMS = [
  'mucous',
  'skin',
  'eyes',
  'ears',
  'cardiovascular',
  'respiratory',
  'gastrointestinal',
  'nervous',
  'musculoskeletal',
  'genitourinary',
];
const VALID_SYSTEM_STATES = ['NOT_EXAMINED', 'NORMAL', 'ABNORMAL'];
const VALID_ROUTES = [
  'ORAL',
  'TOPICAL',
  'SUBCUTANEOUS',
  'INTRAMUSCULAR',
  'INTRAVENOUS',
  'OTIC',
  'OPHTHALMIC',
  'OTHER',
];
const VALID_MODALITIES = ['PRESCRIBED', 'ADMINISTERED_IN_CLINIC'];

export const updateClinicalRecord = onCall(
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
    const callerRole = request.auth.token?.role;
    const callerName = request.auth.token?.name || 'Personal Veterinario';

    const data = request.data || {};
    const { petId, recordId } = data;

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

    const trimmedPetId = petId.trim();
    const trimmedRecordId = recordId.trim();
    const recordRef = db
      .collection('pets')
      .doc(trimmedPetId)
      .collection('clinical_records')
      .doc(trimmedRecordId);

    // Extraer campos a actualizar (soportando payload directo o dentro de updates)
    const updates = data.updates || data;
    const { consultation, anamnesis, physicalExam, vitalSigns, systemsExam, plan, treatment, followUp, prevention, attachments } = updates;

    const newConsultation = consultation || anamnesis;
    const newPhysicalExam = physicalExam || (vitalSigns || systemsExam ? {
      vitals: vitalSigns,
      systems: systemsExam,
    } : undefined);
    const newPlan = plan || (treatment ? { treatment } : undefined);
    const newFollowUp = followUp;
    const newPrevention = prevention;
    const newAttachments = attachments;

    // Validar signos vitales si se actualizan
    if (newPhysicalExam?.vitals) {
      const v = newPhysicalExam.vitals;
      if (v.temperatureDeciC !== undefined && v.temperatureDeciC !== null) {
        if (typeof v.temperatureDeciC !== 'number' || v.temperatureDeciC < 300 || v.temperatureDeciC > 450) {
          throw new HttpsError('invalid-argument', 'temperatureDeciC fuera de rango fisiológico (300..450).', {
            errorCode: 'VITAL_SIGNS_OUT_OF_RANGE',
          });
        }
      }
      if (v.heartRateBpm !== undefined && v.heartRateBpm !== null) {
        if (typeof v.heartRateBpm !== 'number' || v.heartRateBpm < 10 || v.heartRateBpm > 400) {
          throw new HttpsError('invalid-argument', 'heartRateBpm fuera de rango fisiológico (10..400).', {
            errorCode: 'VITAL_SIGNS_OUT_OF_RANGE',
          });
        }
      }
      if (v.respiratoryRateRpm !== undefined && v.respiratoryRateRpm !== null) {
        if (typeof v.respiratoryRateRpm !== 'number' || v.respiratoryRateRpm < 5 || v.respiratoryRateRpm > 200) {
          throw new HttpsError('invalid-argument', 'respiratoryRateRpm fuera de rango fisiológico (5..200).', {
            errorCode: 'VITAL_SIGNS_OUT_OF_RANGE',
          });
        }
      }
      if (v.weightGrams !== undefined && v.weightGrams !== null) {
        if (typeof v.weightGrams !== 'number' || v.weightGrams < 50 || v.weightGrams > 150000) {
          throw new HttpsError('invalid-argument', 'weightGrams fuera de rango fisiológico (50..150000).', {
            errorCode: 'VITAL_SIGNS_OUT_OF_RANGE',
          });
        }
      }
      if (v.bodyConditionScore !== undefined && v.bodyConditionScore !== null) {
        if (typeof v.bodyConditionScore !== 'number' || v.bodyConditionScore < 1 || v.bodyConditionScore > 9) {
          throw new HttpsError('invalid-argument', 'bodyConditionScore fuera de rango fisiológico (1..9).', {
            errorCode: 'VITAL_SIGNS_OUT_OF_RANGE',
          });
        }
      }
    }

    // Validar sistemas si se actualizan
    if (newPhysicalExam?.systems && typeof newPhysicalExam.systems === 'object') {
      for (const [sysKey, sysVal] of Object.entries(newPhysicalExam.systems)) {
        if (VALID_SYSTEMS.includes(sysKey)) {
          const state = sysVal?.state || 'NOT_EXAMINED';
          if (!VALID_SYSTEM_STATES.includes(state)) {
            throw new HttpsError('invalid-argument', `Estado inválido para sistema ${sysKey}.`, {
              errorCode: 'INVALID_ARGUMENT',
            });
          }
          if (state === 'ABNORMAL') {
            const findings = sysVal?.findings;
            if (!findings || typeof findings !== 'string' || findings.trim() === '') {
              throw new HttpsError(
                'invalid-argument',
                `El sistema ${sysKey} marcado como ABNORMAL exige hallazgos descriptivos.`,
                { errorCode: 'ABNORMAL_SYSTEM_REQUIRES_FINDINGS' }
              );
            }
          }
        }
      }
    }

    // Validar tratamiento si se actualiza
    if (newPlan?.treatment && Array.isArray(newPlan.treatment)) {
      for (const line of newPlan.treatment) {
        if (line.medication && typeof line.medication === 'string' && line.medication.trim() !== '') {
          const { dose, route, duration, startDate, modality } = line;
          if (
            !dose || !route || !VALID_ROUTES.includes(route) ||
            !duration || !startDate || !/^\d{4}-\d{2}-\d{2}$/.test(startDate) ||
            !modality || !VALID_MODALITIES.includes(modality)
          ) {
            throw new HttpsError(
              'invalid-argument',
              'Toda línea de tratamiento con medicamento exige dose, route, duration, startDate y modality completos.',
              { errorCode: 'INCOMPLETE_TREATMENT_LINE' }
            );
          }
          if (isFutureBusinessDate(startDate)) {
            throw new HttpsError(
              'invalid-argument',
              'La fecha de inicio de tratamiento no puede ser futura.',
              { errorCode: 'FUTURE_DATE_NOT_ALLOWED' }
            );
          }
        }
      }
    }

    if (newPrevention?.applicationDate && isFutureBusinessDate(newPrevention.applicationDate)) {
      throw new HttpsError(
        'invalid-argument',
        'prevention.applicationDate no puede ser futura.',
        { errorCode: 'FUTURE_DATE_NOT_ALLOWED' }
      );
    }

    if (Array.isArray(newAttachments) && newAttachments.length > 20) {
      throw new HttpsError('resource-exhausted', 'Máximo 20 adjuntos permitidos.', {
        errorCode: 'TOO_MANY_ATTACHMENTS',
      });
    }

    let updatedVersion = 1;

    // 2. Transacción Atómica de Versionado (TRD §3.4.B, D-T8)
    await db.runTransaction(async (transaction) => {
      const recordDoc = await transaction.get(recordRef);
      if (!recordDoc.exists) {
        throw new HttpsError('not-found', 'Registro clínico no encontrado.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const prevData = recordDoc.data() || {};

      // Rechazo si se encuentra en estado ANNULLED (TRD §3.4.B)
      if (prevData.status === 'ANNULLED') {
        throw new HttpsError('failed-precondition', 'No se puede editar un registro clínico anulado.', {
          errorCode: 'ENTRY_ANNULLED_NOT_EDITABLE',
        });
      }

      // Comprobación estricta de autoría: sólo el autor original o SUPERADMIN (CA-AD-52)
      const isOriginalAuthor = prevData.authorUid === callerUid;
      const isSuperAdmin = callerRole === ROLES.SUPERADMIN;

      if (!isOriginalAuthor && !isSuperAdmin) {
        throw new HttpsError(
          'permission-denied',
          'Sólo el autor original o el Super Usuario pueden editar este registro.',
          { errorCode: 'PERMISSION_DENIED' }
        );
      }

      const currentVersion = prevData.version || 1;
      const versionDocId = String(currentVersion).padStart(4, '0');
      const versionRef = recordRef.collection('versions').doc(versionDocId);

      // PASO A: Guardar snapshot íntegro en subcolección versions/{version} (D-T8, CL-12)
      transaction.set(versionRef, {
        versionNumber: currentVersion,
        editedBy: callerUid,
        editedByName: callerName,
        editedAt: FieldValue.serverTimestamp(),
        snapshot: prevData,
      });

      // PASO B: Aplicar cambios sobre el documento principal
      // INVARIANTES ESTRICTAS: authorUid, authorName, createdAt y patientSnapshot NO se tocan jamás.
      updatedVersion = currentVersion + 1;
      const patch = {
        version: updatedVersion,
        isEdited: true,
        lastEditedAt: FieldValue.serverTimestamp(),
        lastEditedBy: callerUid,
        lastEditedByName: callerName,
      };

      if (newConsultation !== undefined) patch.consultation = newConsultation;
      if (newPhysicalExam !== undefined) patch.physicalExam = newPhysicalExam;
      if (newPlan !== undefined) patch.plan = newPlan;
      if (newFollowUp !== undefined) patch.followUp = newFollowUp;
      if (newPrevention !== undefined) patch.prevention = newPrevention;
      if (newAttachments !== undefined) patch.attachments = newAttachments;

      transaction.update(recordRef, patch);
    });

    return {
      success: true,
      recordId: trimmedRecordId,
      petId: trimmedPetId,
      version: updatedVersion,
    };
  }
);
