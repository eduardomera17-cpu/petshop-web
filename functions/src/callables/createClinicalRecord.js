// functions/src/callables/createClinicalRecord.js
// Callable de creación de entrada clínica con snapshot congelado (TRD §2.4.1, §3.4.A, CL-03, CL-10, CL-11, ADR-005, ADR-007, Caso Crítico 18)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { isFutureBusinessDate, todayBusinessDate } from '../domain/clock.js';

const VALID_TYPES = ['CONSULTATION', 'FOLLOW_UP', 'PREVENTION', 'PREVENTIVE', 'EMERGENCY'];
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
const VALID_PREVENTION_SUBTYPES = [
  'VACCINE',
  'INTERNAL_DEWORMING',
  'EXTERNAL_DEWORMING',
  'PREVENTIVE_TEST',
];

/**
 * Calcula la edad aproximada a la fecha de atención.
 * @param {string} birthDateStr 'YYYY-MM-DD'
 * @param {string} attentionDateStr 'YYYY-MM-DD'
 * @returns {string}
 */
function computeAgeAtAttention(birthDateStr, attentionDateStr) {
  if (!birthDateStr || typeof birthDateStr !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(birthDateStr)) {
    return '__NOT_REGISTERED__';
  }
  const [bY, bM, bD] = birthDateStr.split('-').map(Number);
  const [aY, aM, aD] = attentionDateStr.split('-').map(Number);

  let years = aY - bY;
  let months = aM - bM;
  if (aD < bD) {
    months -= 1;
  }
  if (months < 0) {
    years -= 1;
    months += 12;
  }
  if (years < 0) {
    return '__NOT_REGISTERED__';
  }

  if (years === 0) {
    return `${months} ${months === 1 ? 'mes' : 'meses'}`;
  }
  if (months === 0) {
    return `${years} ${years === 1 ? 'año' : 'años'}`;
  }
  return `${years} ${years === 1 ? 'año' : 'años'}, ${months} ${months === 1 ? 'mes' : 'meses'}`;
}

export const createClinicalRecord = onCall(
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
    const { petId, type, attentionDate, attentionTime, sourceAppointmentId } = data;

    // 2. Validación de petId y lectura de la mascota
    if (!petId || typeof petId !== 'string' || petId.trim() === '') {
      throw new HttpsError('invalid-argument', 'petId es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedPetId = petId.trim();
    const petRef = db.collection('pets').doc(trimmedPetId);
    const petDoc = await petRef.get();

    if (!petDoc.exists) {
      throw new HttpsError('not-found', 'Mascota no encontrada.', {
        errorCode: 'NOT_FOUND',
      });
    }

    // CASO CRÍTICO 18 (ADR-007): NO se restringe por pet.status == 'DEACTIVATED'.
    // Funciona igual sobre mascotas activas o desactivadas.
    const petData = petDoc.data() || {};
    const ownerId = petData.ownerId;

    // Lectura del propietario para componer patientSnapshot
    let ownerData = {};
    if (ownerId) {
      const ownerDoc = await db.collection('users').doc(ownerId).get();
      if (ownerDoc.exists) {
        ownerData = ownerDoc.data() || {};
      }
    }

    // 3. Validación de Tipo de Atención
    if (!type || typeof type !== 'string' || !VALID_TYPES.includes(type.trim())) {
      throw new HttpsError(
        'invalid-argument',
        `type debe ser uno de: ${VALID_TYPES.join(', ')}.`,
        { errorCode: 'INVALID_ARGUMENT' }
      );
    }
    const recordType = type.trim();

    // 4. Validación de Fechas
    const validAttentionDate = (attentionDate && typeof attentionDate === 'string')
      ? attentionDate.trim()
      : todayBusinessDate();

    if (!/^\d{4}-\d{2}-\d{2}$/.test(validAttentionDate)) {
      throw new HttpsError('invalid-argument', 'attentionDate debe tener formato YYYY-MM-DD.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    // Prohibición de fecha futura en atención
    if (isFutureBusinessDate(validAttentionDate)) {
      throw new HttpsError('invalid-argument', 'La fecha de atención no puede ser futura.', {
        errorCode: 'FUTURE_DATE_NOT_ALLOWED',
      });
    }

    const validAttentionTime = (attentionTime && typeof attentionTime === 'string')
      ? attentionTime.trim()
      : '10:00';

    // 5. Construcción del Bloque Congelado: patientSnapshot (TRD §2.4.1, PRD §3.5.2)
    const petBirthDate = petData.birthDate || null;
    const ageAtAttention = computeAgeAtAttention(petBirthDate, validAttentionDate);

    const patientSnapshot = {
      pet: {
        name: petData.name || '__NOT_REGISTERED__',
        species: petData.species || '__NOT_REGISTERED__',
        breed: petData.breed || '__NOT_REGISTERED__',
        sex: petData.sex || '__NOT_REGISTERED__',
        reproductiveStatus: petData.reproductiveStatus || '__NOT_REGISTERED__',
        birthDate: petBirthDate || '__NOT_REGISTERED__',
        ageAtAttention: ageAtAttention,
      },
      owner: {
        fullName: ownerData.fullName || '__NOT_REGISTERED__',
        documentType: ownerData.documentType || '__NOT_REGISTERED__',
        documentNumber: ownerData.documentNumber || '__NOT_REGISTERED__',
        phone: ownerData.phone || '__NOT_REGISTERED__',
        address: ownerData.address || '__NOT_REGISTERED__',
        email: ownerData.email || '__NOT_REGISTERED__',
      },
    };

    // 6. Validación de Bloques Opcionales
    const consultation = data.consultation || data.anamnesis || null;
    const physicalExam = data.physicalExam || (data.vitalSigns || data.systemsExam ? {
      vitals: data.vitalSigns,
      systems: data.systemsExam,
    } : null);
    const plan = data.plan || (data.treatment ? { treatment: data.treatment } : null);
    const followUp = data.followUp || null;
    const prevention = data.prevention || null;
    const attachments = data.attachments || [];

    // Validaciones por Tipo (TRD §3.4.A)
    if (recordType === 'CONSULTATION' || recordType === 'EMERGENCY') {
      if (!consultation || !consultation.reason || typeof consultation.reason !== 'string' || consultation.reason.trim() === '') {
        throw new HttpsError('invalid-argument', 'consultation.reason es obligatorio para consultas.', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      if (consultation.reason.length > 500) {
        throw new HttpsError('invalid-argument', 'consultation.reason no puede superar 500 caracteres.', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
    }

    if (recordType === 'FOLLOW_UP') {
      if (!followUp || !followUp.consultationRecordId || !followUp.treatmentResponse) {
        throw new HttpsError('invalid-argument', 'followUp exige consultationRecordId y treatmentResponse.', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      // Verificar que consultationRecordId exista para la misma mascota
      const prevConsultRef = db
        .collection('pets')
        .doc(trimmedPetId)
        .collection('clinical_records')
        .doc(followUp.consultationRecordId);
      const prevConsultDoc = await prevConsultRef.get();
      if (!prevConsultDoc.exists) {
        throw new HttpsError('not-found', 'Consulta previa asociada no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }
    }

    if (recordType === 'PREVENTION' || recordType === 'PREVENTIVE') {
      if (!prevention || !prevention.subType || !prevention.applicationDate || !prevention.productOrActiveIngredient) {
        throw new HttpsError('invalid-argument', 'prevention exige subType, applicationDate y productOrActiveIngredient.', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      if (!VALID_PREVENTION_SUBTYPES.includes(prevention.subType)) {
        throw new HttpsError('invalid-argument', `subType inválido. Permitidos: ${VALID_PREVENTION_SUBTYPES.join(', ')}`, {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      if (isFutureBusinessDate(prevention.applicationDate)) {
        throw new HttpsError('invalid-argument', 'prevention.applicationDate no puede ser futura.', {
          errorCode: 'FUTURE_DATE_NOT_ALLOWED',
        });
      }
      if (prevention.subType === 'PREVENTIVE_TEST' && (!prevention.result || prevention.result.trim() === '')) {
        throw new HttpsError('invalid-argument', 'Las pruebas preventivas exigen registrar el resultado.', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      // prevention.nextApplicationDate es la ÚNICA fecha que puede ser futura (TRD §2.4.1, PRD §3.5.4)
    }

    // 7. Validación de Examen Físico y Signos Vitales
    if (physicalExam) {
      if (physicalExam.vitals) {
        const v = physicalExam.vitals;
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

      // Validación de Sistemas: ABNORMAL exige texto descriptivo de hallazgos
      if (physicalExam.systems && typeof physicalExam.systems === 'object') {
        for (const [sysKey, sysVal] of Object.entries(physicalExam.systems)) {
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
              if (findings.length > 300) {
                throw new HttpsError(
                  'invalid-argument',
                  `Los hallazgos del sistema ${sysKey} no pueden superar 300 caracteres.`,
                  { errorCode: 'INVALID_ARGUMENT' }
                );
              }
            }
          }
        }
      }
    }

    // 8. Validación de Tratamiento / Prescripción Médica
    if (plan && plan.treatment && Array.isArray(plan.treatment)) {
      for (const line of plan.treatment) {
        if (line.medication && typeof line.medication === 'string' && line.medication.trim() !== '') {
          const { dose, route, duration, startDate, modality } = line;
          if (
            !dose || typeof dose !== 'string' || dose.trim() === '' ||
            !route || !VALID_ROUTES.includes(route) ||
            !duration || typeof duration !== 'string' || duration.trim() === '' ||
            !startDate || typeof startDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(startDate) ||
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

    // 9. Tope Máximo de 20 Adjuntos (CL-11, ADR-005)
    if (Array.isArray(attachments) && attachments.length > 20) {
      throw new HttpsError('resource-exhausted', 'Máximo 20 adjuntos por entrada clínica.', {
        errorCode: 'TOO_MANY_ATTACHMENTS',
      });
    }

    // 10. Persistencia del Documento Único (TRD §2.4.1)
    const newRecordRef = db
      .collection('pets')
      .doc(trimmedPetId)
      .collection('clinical_records')
      .doc();

    const recordPayload = {
      id: newRecordRef.id,
      petId: trimmedPetId,
      ownerId: ownerId || '__NOT_REGISTERED__',
      type: recordType,
      status: 'ACTIVE',

      // Autenticación e Invariantes fijadas por el servidor (PRD §3.5.6 regla 4)
      authorUid: callerUid,
      authorName: callerName,
      createdAt: FieldValue.serverTimestamp(),
      attentionDate: validAttentionDate,
      attentionTime: validAttentionTime,

      sourceAppointmentId: sourceAppointmentId || null,

      patientSnapshot: patientSnapshot,

      consultation: consultation || null,
      physicalExam: physicalExam || null,
      plan: plan || null,
      followUp: followUp || null,
      prevention: prevention || null,
      annulment: null,

      annulledAt: null,
      annulledBy: null,
      annulledByRecordId: null,
      annulmentReason: null,

      attachments: attachments || [],

      isEdited: false,
      version: 1,
      lastEditedAt: null,
      lastEditedBy: null,
      lastEditedByName: null,
    };

    await newRecordRef.set(recordPayload);

    return {
      success: true,
      recordId: newRecordRef.id,
      petId: trimmedPetId,
      version: 1,
      status: 'ACTIVE',
    };
  }
);
