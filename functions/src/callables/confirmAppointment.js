// functions/src/callables/confirmAppointment.js
// Callable de confirmación de citas por el personal administrativo (TRD §3.2.G, AG-02, CA-AD-16)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';

export const confirmAppointment = onCall(
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
    const { appointmentId } = requestData;

    if (!appointmentId || typeof appointmentId !== 'string' || appointmentId.trim() === '') {
      throw new HttpsError('invalid-argument', 'El identificador de cita (appointmentId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedAppointmentId = appointmentId.trim();
    const appointmentRef = db.collection('appointments').doc(trimmedAppointmentId);

    let resultPayload = null;

    // 2. Transacción atómica de confirmación (TRD §3.2.G)
    await db.runTransaction(async (transaction) => {
      const appointmentDoc = await transaction.get(appointmentRef);
      if (!appointmentDoc.exists) {
        throw new HttpsError('not-found', 'Cita no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const appointmentData = appointmentDoc.data();
      const currentStatus = appointmentData.status;

      // Inviolabilidad terminal: COMPLETED -> * prohibido para todos los roles
      if (currentStatus === 'COMPLETED') {
        throw new HttpsError(
          'failed-precondition',
          'Una cita completada no admite transiciones.',
          { errorCode: 'INVALID_TRANSITION' }
        );
      }

      // Transición única permitida: PENDING -> CONFIRMED
      if (currentStatus !== 'PENDING') {
        throw new HttpsError(
          'failed-precondition',
          `Transición no permitida desde ${currentStatus}. Solo se pueden confirmar citas en estado PENDING.`,
          { errorCode: 'INVALID_TRANSITION' }
        );
      }

      const nowTimestamp = FieldValue.serverTimestamp();

      // Actualizar estado y registrar metadata de confirmación
      transaction.update(appointmentRef, {
        status: 'CONFIRMED',
        confirmedBy: uid,
        confirmedAt: nowTimestamp,
        'audit.confirmedBy': uid,
        'audit.confirmedAt': nowTimestamp,
        'audit.updatedBy': uid,
        'audit.updatedAt': nowTimestamp,
      });

      // Confirmar no dispara correos ni avisos salientes (TRD §3.2.G, ADR-003)

      resultPayload = {
        success: true,
        appointmentId: trimmedAppointmentId,
        status: 'CONFIRMED',
      };
    });

    return resultPayload;
  }
);
