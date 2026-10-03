// functions/src/callables/completeAppointment.js
// Callable de finalización de citas por el personal administrativo (TRD §3.2.G, AG-03, CL-10, CA-AD-44)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';

export const completeAppointment = onCall(
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

    // Verificación de revocación si viene bearer token (TRD §4.2, §4.6)
    if (request.rawRequest?.headers?.authorization) {
      const authHeader = request.rawRequest.headers.authorization;
      if (typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
        const idToken = authHeader.split('Bearer ')[1];
        try {
          await auth.verifyIdToken(idToken, true);
        } catch (err) {
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
    const { appointmentId } = requestData;

    if (!appointmentId || typeof appointmentId !== 'string' || appointmentId.trim() === '') {
      throw new HttpsError('invalid-argument', 'El identificador de cita (appointmentId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedAppointmentId = appointmentId.trim();
    const appointmentRef = db.collection('appointments').doc(trimmedAppointmentId);

    let resultPayload = null;

    // 2. Transacción atómica de completado (TRD §3.2.G)
    await db.runTransaction(async (transaction) => {
      const appointmentDoc = await transaction.get(appointmentRef);
      if (!appointmentDoc.exists) {
        throw new HttpsError('not-found', 'Cita no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const appointmentData = appointmentDoc.data();
      const currentStatus = appointmentData.status;

      // Inviolabilidad terminal: COMPLETED -> * prohibido
      if (currentStatus === 'COMPLETED') {
        throw new HttpsError(
          'failed-precondition',
          'Una cita completada no admite transiciones.',
          { errorCode: 'INVALID_TRANSITION' }
        );
      }

      // Transición única permitida: CONFIRMED -> COMPLETED
      if (currentStatus !== 'CONFIRMED') {
        throw new HttpsError(
          'failed-precondition',
          `Transición no permitida desde ${currentStatus}. Solo se pueden completar citas en estado CONFIRMED.`,
          { errorCode: 'INVALID_TRANSITION' }
        );
      }

      const nowTimestamp = FieldValue.serverTimestamp();
      const isClinical = appointmentData.isClinical === true;

      // Actualizaciones del documento de la cita
      const updateData = {
        status: 'COMPLETED',
        completedBy: uid,
        completedAt: nowTimestamp,
        'audit.completedBy': uid,
        'audit.completedAt': nowTimestamp,
        'audit.updatedBy': uid,
        'audit.updatedAt': nowTimestamp,
      };

      // Si la cita es clínica: marcar hasPendingClinicalRecord: true (TRD §3.2.G, CL-10)
      if (isClinical) {
        updateData.hasPendingClinicalRecord = true;
      }

      transaction.update(appointmentRef, updateData);

      // Gestión de centinelas (TRD §2.9, §3.2.G):
      // 1. Borrar el centinela de franja horaria (/slot_locks) para liberar el calendario
      if (appointmentData.slotKey) {
        const slotLockRef = db.collection('slot_locks').doc(appointmentData.slotKey);
        transaction.delete(slotLockRef);
      }
      // Soporte defensivo para centinela con clave calculada si no estuviera explícito el slotKey
      if (!appointmentData.slotKey && appointmentData.dateString && appointmentData.timeSlot) {
        const fallbackSlotKey = `${appointmentData.dateString}_${appointmentData.timeSlot}`;
        transaction.delete(db.collection('slot_locks').doc(fallbackSlotKey));
      }

      // 2. CONSERVAR el centinela de mascota-día (/pet_day_locks):
      // Deliberadamente NO se borra petDayKey para preservar la regla de C-12 (una cita por mascota y día)

      // Completar no dispara correos ni avisos salientes (TRD §3.2.G, ADR-003)

      resultPayload = {
        success: true,
        appointmentId: trimmedAppointmentId,
        status: 'COMPLETED',
        requiresClinicalForm: isClinical,
      };
    });

    return resultPayload;
  }
);
