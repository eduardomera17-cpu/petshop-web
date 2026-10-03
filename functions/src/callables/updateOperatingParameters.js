// functions/src/callables/updateOperatingParameters.js
// Callable de configuración operativa del negocio (TRD §3.4.J, ADR-010, CF-01, CF-02, IN-03, CA-AD-06, CA-AD-60)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { recordAuditLog } from '../lib/audit.js';

const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/;
const ALLOWED_FIELDS = [
  'openingTime',
  'closingTime',
  'slotDurationMinutes',
  'workingWeekdays',
  'lowStockThreshold',
];

/**
 * Permite al personal administrativo (ADMIN o SUPERADMIN) modificar los parámetros
 * operativos del negocio (/business_config/operating_parameters).
 *
 * Invariantes normativos:
 * 1. La escritura directa en /business_config/operating_parameters está bloqueada por reglas (ADR-010).
 * 2. La zona horaria ('America/Guayaquil') es inmutable; cualquier intento de alterarla se rechaza (CA-AD-60).
 * 3. Las mutaciones se aplican de forma atómica registrando traza en el documento y en /audit_log.
 */
export const updateOperatingParameters = onCall(
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

    // Verificación de revocación de token si viene encabezado Authorization
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

    if (token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa para realizar operaciones.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const data = request.data || {};

    // 2. Rechazo innegociable de mutación de timezone (CA-AD-60)
    if ('timezone' in data) {
      throw new HttpsError('invalid-argument', 'Timezone modification is prohibited', {
        errorCode: 'TIMEZONE_IMMUTABLE',
      });
    }

    // 3. Validaciones de esquema y campos no reconocidos
    const providedFields = Object.keys(data).filter((k) => k !== 'recaptchaToken');
    if (providedFields.length === 0) {
      throw new HttpsError(
        'invalid-argument',
        'Se debe proporcionar al menos un campo operativo válido para actualizar.',
        { errorCode: 'INVALID_ARGUMENT' }
      );
    }

    for (const key of providedFields) {
      if (!ALLOWED_FIELDS.includes(key)) {
        throw new HttpsError(
          'invalid-argument',
          `El campo '${key}' no está permitido o no es editable.`,
          { errorCode: 'INVALID_ARGUMENT' }
        );
      }
    }

    const updates = {};

    // openingTime: string en formato HH:mm
    if (data.openingTime !== undefined) {
      if (typeof data.openingTime !== 'string' || !TIME_REGEX.test(data.openingTime)) {
        throw new HttpsError(
          'invalid-argument',
          "openingTime debe tener formato 'HH:mm' válido (00:00 - 23:59).",
          { errorCode: 'INVALID_ARGUMENT' }
        );
      }
      updates.openingTime = data.openingTime;
    }

    // closingTime: string en formato HH:mm
    if (data.closingTime !== undefined) {
      if (typeof data.closingTime !== 'string' || !TIME_REGEX.test(data.closingTime)) {
        throw new HttpsError(
          'invalid-argument',
          "closingTime debe tener formato 'HH:mm' válido (00:00 - 23:59).",
          { errorCode: 'INVALID_ARGUMENT' }
        );
      }
      updates.closingTime = data.closingTime;
    }

    // slotDurationMinutes: entero positivo
    if (data.slotDurationMinutes !== undefined) {
      if (
        typeof data.slotDurationMinutes !== 'number' ||
        !Number.isInteger(data.slotDurationMinutes) ||
        data.slotDurationMinutes <= 0
      ) {
        throw new HttpsError(
          'invalid-argument',
          'slotDurationMinutes debe ser un número entero mayor que 0.',
          { errorCode: 'INVALID_ARGUMENT' }
        );
      }
      updates.slotDurationMinutes = data.slotDurationMinutes;
    }

    // workingWeekdays: lista no vacía de enteros del 1 al 7 (1 = Lunes, 7 = Domingo)
    if (data.workingWeekdays !== undefined) {
      if (
        !Array.isArray(data.workingWeekdays) ||
        data.workingWeekdays.length === 0 ||
        data.workingWeekdays.some(
          (d) => typeof d !== 'number' || !Number.isInteger(d) || d < 1 || d > 7
        )
      ) {
        throw new HttpsError(
          'invalid-argument',
          'workingWeekdays debe ser un subconjunto válido y no vacío de {1..7}.',
          { errorCode: 'INVALID_ARGUMENT' }
        );
      }
      const uniqueDays = Array.from(new Set(data.workingWeekdays)).sort((a, b) => a - b);
      updates.workingWeekdays = uniqueDays;
    }

    // lowStockThreshold: entero mayor o igual a 0
    if (data.lowStockThreshold !== undefined) {
      if (
        typeof data.lowStockThreshold !== 'number' ||
        !Number.isInteger(data.lowStockThreshold) ||
        data.lowStockThreshold < 0
      ) {
        throw new HttpsError(
          'invalid-argument',
          'lowStockThreshold debe ser un número entero mayor o igual a 0.',
          { errorCode: 'INVALID_ARGUMENT' }
        );
      }
      updates.lowStockThreshold = data.lowStockThreshold;
    }

    const configRef = db.collection('business_config').doc('operating_parameters');

    let resultingData = null;

    // 4. Persistencia transaccional atómica
    await db.runTransaction(async (transaction) => {
      const docSnap = await transaction.get(configRef);
      const currentConfig = docSnap.exists
        ? docSnap.data()
        : {
            timezone: 'America/Guayaquil',
            openingTime: '08:00',
            closingTime: '18:00',
            slotDurationMinutes: 30,
            workingWeekdays: [1, 2, 3, 4, 5, 6],
            lowStockThreshold: 5,
          };

      const effectiveOpening = updates.openingTime ?? currentConfig.openingTime;
      const effectiveClosing = updates.closingTime ?? currentConfig.closingTime;

      // Validación lógica de coherencia horaria
      if (effectiveOpening >= effectiveClosing) {
        throw new HttpsError(
          'invalid-argument',
          `La hora de apertura (${effectiveOpening}) debe ser estrictamente anterior a la hora de cierre (${effectiveClosing}).`,
          { errorCode: 'INVALID_ARGUMENT' }
        );
      }

      const patch = {
        ...updates,
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      };

      if (!docSnap.exists) {
        transaction.set(configRef, {
          timezone: 'America/Guayaquil',
          openingTime: effectiveOpening,
          closingTime: effectiveClosing,
          slotDurationMinutes: updates.slotDurationMinutes ?? currentConfig.slotDurationMinutes,
          workingWeekdays: updates.workingWeekdays ?? currentConfig.workingWeekdays,
          lowStockThreshold: updates.lowStockThreshold ?? currentConfig.lowStockThreshold,
          audit: {
            updatedBy: uid,
            updatedAt: FieldValue.serverTimestamp(),
          },
        });
      } else {
        transaction.update(configRef, patch);
      }

      // Registro de trazabilidad en /audit_log (TRD §2.12, N-AD-08)
      recordAuditLog(transaction, {
        actorUid: uid,
        actorName: token.name || 'Personal',
        actorRole: token.role || ROLES.ADMIN,
        action: 'UPDATE_OPERATING_PARAMETERS',
        targetType: 'BUSINESS_CONFIG',
        targetId: 'operating_parameters',
        metadata: {
          updatedFields: Object.keys(updates),
          previousValues: {
            openingTime: currentConfig.openingTime,
            closingTime: currentConfig.closingTime,
            slotDurationMinutes: currentConfig.slotDurationMinutes,
            workingWeekdays: currentConfig.workingWeekdays,
            lowStockThreshold: currentConfig.lowStockThreshold,
          },
          appliedUpdates: updates,
        },
      });

      resultingData = {
        timezone: 'America/Guayaquil',
        openingTime: effectiveOpening,
        closingTime: effectiveClosing,
        slotDurationMinutes: updates.slotDurationMinutes ?? currentConfig.slotDurationMinutes,
        workingWeekdays: updates.workingWeekdays ?? currentConfig.workingWeekdays,
        lowStockThreshold: updates.lowStockThreshold ?? currentConfig.lowStockThreshold,
      };
    });

    return {
      success: true,
      message: 'Parámetros operativos actualizados correctamente.',
      parameters: resultingData,
    };
  }
);
