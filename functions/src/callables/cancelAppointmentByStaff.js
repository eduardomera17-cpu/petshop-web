// functions/src/callables/cancelAppointmentByStaff.js
// Callable de cancelación de citas por el personal administrativo (TRD §3.2.G, AG-05, AG-09, CA-AD-16, ADR-003, ADR-011)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { removeConceptFromDraftProforma, ITEM_TYPES, PROFORMA_STATUS } from '../domain/proforma.js';
import { enqueueAppointmentMail } from '../lib/mail.js';

export const cancelAppointmentByStaff = onCall(
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

    // 2. Transacción atómica de cancelación por personal (TRD §3.2.G)
    await db.runTransaction(async (transaction) => {
      // --- FASE 1: LECTURAS ---
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
          'Una cita completada no puede ser cancelada.',
          { errorCode: 'APPOINTMENT_NOT_CANCELLABLE' }
        );
      }

      if (currentStatus === 'CANCELLED') {
        throw new HttpsError(
          'failed-precondition',
          'La cita ya se encuentra cancelada.',
          { errorCode: 'ALREADY_CANCELLED' }
        );
      }

      // Solo PENDING o CONFIRMED son cancelables
      if (currentStatus !== 'PENDING' && currentStatus !== 'CONFIRMED') {
        throw new HttpsError(
          'failed-precondition',
          `Transición no permitida desde ${currentStatus}. Solo citas activas pueden cancelarse.`,
          { errorCode: 'INVALID_TRANSITION' }
        );
      }

      // Bloqueo por Proforma Entregada (Precondición 2 / §0.1, AUD-133)
      let proformaDoc = null;
      if (appointmentData.proformaId) {
        const proformaRef = db.collection('proformas').doc(appointmentData.proformaId);
        proformaDoc = await transaction.get(proformaRef);

        if (proformaDoc.exists) {
          const pData = proformaDoc.data();
          if (pData.status === PROFORMA_STATUS.DELIVERED) {
            throw new HttpsError(
              'failed-precondition',
              'El concepto está bloqueado porque pertenece a una proforma ya entregada o procesada.',
              { errorCode: 'CONCEPT_LOCKED_BY_DELIVERED_PROFORMA' }
            );
          }
        }
      }

      // Lectura del cliente para el correo de AG-09 (TRD §3.5.F)
      let clientDoc = null;
      if (appointmentData.clientId) {
        const clientRef = db.collection('users').doc(appointmentData.clientId);
        clientDoc = await transaction.get(clientRef);
      }

      // Lectura de parámetros de negocio para datos del correo
      const billingDoc = await transaction.get(db.collection('business_config').doc('billing_parameters'));
      const billingData = billingDoc.exists ? billingDoc.data() : {};

      // --- FASE 2: ESCRITURAS ---
      const nowTimestamp = FieldValue.serverTimestamp();

      // 1. Actualización de la cita con cancelledReason: ADMIN
      transaction.update(appointmentRef, {
        status: 'CANCELLED',
        cancelledReason: 'ADMIN',
        cancelledBy: uid,
        cancelledAt: nowTimestamp,
        'audit.cancelledBy': uid,
        'audit.cancelledAt': nowTimestamp,
        'audit.updatedBy': uid,
        'audit.updatedAt': nowTimestamp,
      });

      // 2. Eliminación de ambos centinelas asociados a la cita (TRD §2.9, §3.2.G, CA-22)
      if (appointmentData.slotKey) {
        transaction.delete(db.collection('slot_locks').doc(appointmentData.slotKey));
      } else if (appointmentData.dateString && appointmentData.timeSlot) {
        const fallbackSlot = `${appointmentData.dateString}_${appointmentData.timeSlot}`;
        transaction.delete(db.collection('slot_locks').doc(fallbackSlot));
      }

      if (appointmentData.petDayKey) {
        transaction.delete(db.collection('pet_day_locks').doc(appointmentData.petDayKey));
      } else if (appointmentData.petId && appointmentData.dateString) {
        const fallbackPetDay = `${appointmentData.petId}_${appointmentData.dateString}`;
        transaction.delete(db.collection('pet_day_locks').doc(fallbackPetDay));
      }

      // 3. Retiro de línea del Borrador de proforma si aplica (AUD-133)
      if (appointmentData.proformaId && proformaDoc && proformaDoc.exists) {
        const pData = proformaDoc.data();
        if (pData.status === PROFORMA_STATUS.DRAFT) {
          await removeConceptFromDraftProforma(transaction, db, {
            proformaId: appointmentData.proformaId,
            itemType: ITEM_TYPES.SERVICE,
            refId: trimmedAppointmentId,
            proformaDoc,
          });
        }
      }

      // 4. Encolado indivisible de correo en /mail (AG-09, TRD §3.5.F, Caso Crítico 15)
      // "Se comprueba que el cliente tenga cuenta activa y correo antes de encolar; si no lo tiene, no se encola y la operación de agenda sigue adelante igualmente."
      // "Con la escritura en /mail forzada a fallar, la cita se cancela igualmente."
      try {
        const clientData = clientDoc && clientDoc.exists ? clientDoc.data() : null;
        const clientEmail = clientData?.email || appointmentData.clientEmail;
        const isClientActive = clientData ? clientData.status === USER_STATUS.ACTIVE : true;

        if (clientEmail && isClientActive) {
          const staffName = token.name || 'Personal Administrativo';
          const resolvedClientName = clientData?.fullName || appointmentData.clientName || 'Cliente';
          const resolvedPetName = appointmentData.petName || 'Mascota';
          const resolvedServiceName = appointmentData.serviceName || 'Servicio';

          enqueueAppointmentMail(transaction, {
            to: clientEmail,
            kind: 'APPOINTMENT_CANCELLED',
            data: {
              clientName: resolvedClientName,
              petName: resolvedPetName,
              serviceName: resolvedServiceName,
              fromDateString: appointmentData.dateString || null,
              fromTimeSlot: appointmentData.timeSlot || null,
              toDateString: null,
              toTimeSlot: null,
              actorName: staffName,
              businessName: billingData.businessName || 'PetShop',
              businessPhone: billingData.phone || '+593999999999',
            },
            appointmentId: trimmedAppointmentId,
          });
        }
      } catch (mailError) {
        // La operación de agenda manda; fallo de correo no condiciona la cancelación (ADR-003, Caso 15)
        console.warn(`[cancelAppointmentByStaff] Advertencia al encolar correo en /mail: ${mailError.message}`);
      }

      // 5. PROHIBICIÓN ESTRICTA: NO alterar contadores en /user_daily_counters (N-11, CA-13)

      resultPayload = {
        success: true,
        appointmentId: trimmedAppointmentId,
        status: 'CANCELLED',
      };
    });

    return resultPayload;
  }
);
