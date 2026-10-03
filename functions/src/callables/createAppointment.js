// functions/src/callables/createAppointment.js
// Callable de agendamiento de citas con exclusividad transaccional determinista (D-T3, TRD §3.2.B, C-01 a C-12, N-11, N-12, CA-10, CA-11, CA-13, CA-20, CA-21, AUD-134, AUD-149, AUD-150)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import {
  REGIONS, USER_STATUS, DAILY_APPOINTMENTS_LIMIT, APPOINTMENT_NOTES_MAX_LENGTH, ENFORCE_APP_CHECK } from '../config/constants.js';
import { todayBusinessDate } from '../domain/clock.js';
import { calculateLinePricing } from '../domain/pricing.js';

export const createAppointment = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
    // Sin instancias mínimas: una instancia mínima factura aunque no haya tráfico.
    // Se acepta el arranque en frío. Ajusta minInstances si tu despliegue necesita baja latencia.
  },
  async (request) => {
    // 1. Verificación de autenticación y estado del usuario
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    const uid = request.auth.uid;
    const token = request.auth.token || {};

    if (token.status && token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const requestData = request.data || {};
    const { petId, serviceId, dateString, timeSlot, clientNotes, requestId } = requestData;

    // 2. Soporte de Idempotencia (TRD §3.7)
    if (requestId && typeof requestId === 'string') {
      const idempotencyDoc = await db.collection('idempotency').doc(requestId).get();
      if (idempotencyDoc.exists) {
        return idempotencyDoc.data()?.response;
      }
    }

    // 3. Validaciones sintácticas previas fuera de la transacción
    if (!petId || typeof petId !== 'string') {
      throw new HttpsError('invalid-argument', 'El identificador de mascota (petId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (!serviceId || typeof serviceId !== 'string') {
      throw new HttpsError('invalid-argument', 'El identificador de servicio (serviceId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (!dateString || typeof dateString !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
      throw new HttpsError('invalid-argument', 'dateString debe tener formato canónico YYYY-MM-DD.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (!timeSlot || typeof timeSlot !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(timeSlot)) {
      throw new HttpsError('invalid-argument', 'timeSlot debe tener formato HH:mm.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (clientNotes !== undefined && clientNotes !== null) {
      if (typeof clientNotes !== 'string' || clientNotes.length > APPOINTMENT_NOTES_MAX_LENGTH) {
        throw new HttpsError('invalid-argument', `clientNotes no puede exceder ${APPOINTMENT_NOTES_MAX_LENGTH} caracteres.`, {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
    }

    // 4. Verificación de fecha presente o futura (C-01, N-12)
    const actionDate = todayBusinessDate();
    if (dateString < actionDate) {
      throw new HttpsError('failed-precondition', 'No se pueden agendar citas en fechas pasadas.', {
        errorCode: 'DATE_IN_THE_PAST',
      });
    }

    // 5. Verificación de horario comercial y días laborables (C-01)
    const operatingDoc = await db.collection('business_config').doc('operating_parameters').get();
    if (operatingDoc.exists) {
      const op = operatingDoc.data();
      if (Array.isArray(op.workingWeekdays) && op.workingWeekdays.length > 0) {
        const [y, m, d] = dateString.split('-').map(Number);
        const dt = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
        const jsDay = dt.getUTCDay();
        const isoWeekday = jsDay === 0 ? 7 : jsDay;
        if (!op.workingWeekdays.includes(isoWeekday)) {
          throw new HttpsError('failed-precondition', 'La fecha seleccionada no es un día laborable del negocio.', {
            errorCode: 'OUT_OF_HOURS',
          });
        }
      }
      if (op.openingTime && op.closingTime) {
        if (timeSlot < op.openingTime || timeSlot >= op.closingTime) {
          throw new HttpsError('failed-precondition', 'La franja seleccionada está fuera del horario de atención.', {
            errorCode: 'OUT_OF_HOURS',
          });
        }
      }
    }

    const appointmentId = db.collection('appointments').doc().id;
    const slotKey = `${dateString}_${timeSlot}`;
    const petDayKey = `${petId}_${dateString}`;
    const counterId = `${uid}_${actionDate}`;

    // 6. Transacción Determinista de 9 Pasos (TRD §3.2.B)
    let result;
    try {
      result = await db.runTransaction(async (transaction) => {
        // PASO 1: /user_daily_counters/{uid}_{actionDate}
        const counterRef = db.collection('user_daily_counters').doc(counterId);
        const counterDoc = await transaction.get(counterRef);
        const counterData = counterDoc.exists ? counterDoc.data() : null;
        if ((counterData?.appointmentsCount || 0) >= DAILY_APPOINTMENTS_LIMIT) {
          throw new HttpsError('resource-exhausted', 'Límite diario de citas alcanzado (máximo 5 por día).', {
            errorCode: 'DAILY_LIMIT_APPOINTMENTS',
          });
        }

        // PASO 1b (B-02): Lectura de /users/{uid} para denormalización de identidad
        const userRef = db.collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists || userDoc.data()?.status !== 'ACTIVE') {
          throw new HttpsError('failed-precondition', 'Usuario no activo o perfil inexistente.', {
            errorCode: 'USER_NOT_ACTIVE',
          });
        }
        const userData = userDoc.data();
        const resolvedClientName = userData.fullName || token.name || 'Cliente';

        // PASO 2: /pets/{petId}
        const petRef = db.collection('pets').doc(petId);
        const petDoc = await transaction.get(petRef);
        if (!petDoc.exists || petDoc.data()?.ownerId !== uid || petDoc.data()?.status !== 'ACTIVE') {
          throw new HttpsError('failed-precondition', 'La mascota no está disponible para agendamiento.', {
            errorCode: 'PET_NOT_AVAILABLE',
          });
        }
        const petData = petDoc.data();

        // PASO 3: /services/{serviceId}
        const serviceRef = db.collection('services').doc(serviceId);
        const serviceDoc = await transaction.get(serviceRef);
        if (!serviceDoc.exists || serviceDoc.data()?.isActive !== true) {
          throw new HttpsError('failed-precondition', 'El servicio no está disponible.', {
            errorCode: 'SERVICE_NOT_AVAILABLE',
          });
        }
        const serviceData = serviceDoc.data();

        // PASO 4: /business_config/billing_parameters
        const billingRef = db.collection('business_config').doc('billing_parameters');
        const billingDoc = await transaction.get(billingRef);
        if (!billingDoc.exists) {
          throw new HttpsError('failed-precondition', 'Configuración de facturación no disponible.', {
            errorCode: 'CONFIG_UNAVAILABLE',
          });
        }
        const billingData = billingDoc.data();
        const ivaBp = typeof billingData.ivaBp === 'number' ? billingData.ivaBp : 1500;
        const iceIncludedInIvaBase =
          typeof billingData.iceIncludedInIvaBase === 'boolean'
            ? billingData.iceIncludedInIvaBase
            : true;

        // PASO 4b (AUD-134): Verificación de bloqueos administrativos
        const dateBlockRef = db.collection('availability_blocks').doc(dateString);
        const slotBlockRef = db.collection('availability_blocks').doc(slotKey);
        const [dateBlockDoc, slotBlockDoc] = await Promise.all([
          transaction.get(dateBlockRef),
          transaction.get(slotBlockRef),
        ]);
        if (dateBlockDoc.exists || slotBlockDoc.exists) {
          throw new HttpsError(
            'failed-precondition',
            'La fecha u hora seleccionada se encuentra bloqueada por administración.',
            { errorCode: 'SLOT_BLOCKED' }
          );
        }

        // PASO 5: Verificación y create() de /slot_locks/{slotKey} (D-T3, C-11)
        const slotLockRef = db.collection('slot_locks').doc(slotKey);
        const slotLockDoc = await transaction.get(slotLockRef);
        if (slotLockDoc.exists) {
          throw new HttpsError('already-exists', 'La franja horaria seleccionada ya ha sido reservada.', {
            errorCode: 'SLOT_TAKEN',
          });
        }

        // PASO 6: Verificación y create() de /pet_day_locks/{petDayKey} (D-T3, C-12)
        const petDayLockRef = db.collection('pet_day_locks').doc(petDayKey);
        const petDayLockDoc = await transaction.get(petDayLockRef);
        if (petDayLockDoc.exists) {
          throw new HttpsError('already-exists', 'La mascota ya tiene una cita reservada para esta fecha.', {
            errorCode: 'PET_ALREADY_BOOKED_THAT_DAY',
          });
        }

        // Emitir mutaciones de los cerrojos con Transaction.create()
        transaction.create(slotLockRef, {
          appointmentId,
          dateString,
          timeSlot,
          createdAt: FieldValue.serverTimestamp(),
        });

        transaction.create(petDayLockRef, {
          appointmentId,
          petId,
          dateString,
          createdAt: FieldValue.serverTimestamp(),
        });

        // PASO 7: Cálculo impositivo y congelación de precio en servidor (CA-10)
        // Se ignora cualquier valor de precio enviado por el cliente.
        const pricing = calculateLinePricing({
          basePriceCents: serviceData.basePriceCents,
          iceBp: serviceData.iceBp || 0,
          ivaBp: ivaBp,
          iceIncludedInIvaBase: iceIncludedInIvaBase,
        });

        // PASO 8: Transaction.create() de /appointments/{id} con status: PENDING
        const appointmentRef = db.collection('appointments').doc(appointmentId);
        const nowTimestamp = FieldValue.serverTimestamp();

        const appointmentPayload = {
          id: appointmentId,
          clientId: uid,
          clientName: resolvedClientName,
          petId: petId,
          petName: petData.name || '',
          serviceId: serviceId,
          serviceName: serviceData.name || '',
          isClinical: Boolean(serviceData.isClinical),
          dateString: dateString,
          timeSlot: timeSlot,
          slotKey: slotKey,
          petDayKey: petDayKey,
          actionDateString: actionDate,
          status: 'PENDING',
          basePriceCents: pricing.basePriceCents,
          iceBp: pricing.iceBp,
          ivaBp: pricing.ivaBp,
          iceAmountCents: pricing.iceAmountCents,
          ivaAmountCents: pricing.ivaAmountCents,
          finalPriceCents: pricing.finalPriceCents,
          clientNotes: clientNotes ? clientNotes.trim() : null,
          hasPendingClinicalRecord: false,
          isBilled: false,
          proformaId: null,
          cancelledReason: null,
          rescheduleCount: 0,
          rescheduleHistory: [],
          hasBlockConflict: false,
          audit: {
            createdBy: uid,
            createdAt: nowTimestamp,
            confirmedBy: null,
            confirmedAt: null,
            completedBy: null,
            completedAt: null,
            cancelledBy: null,
            cancelledAt: null,
            rescheduledBy: null,
            rescheduledAt: null,
            updatedBy: uid,
            updatedAt: nowTimestamp,
          },
        };

        transaction.create(appointmentRef, appointmentPayload);

        // PASO 9: Incremento de appointmentsCount con FieldValue.increment(1)
        transaction.set(
          counterRef,
          {
            userId: uid,
            actionDate: actionDate,
            appointmentsCount: FieldValue.increment(1),
            productRequestsCount: counterData?.productRequestsCount || 0,
            updatedAt: nowTimestamp,
          },
          { merge: true }
        );

        return {
          appointmentId,
          appointment: appointmentPayload,
        };
      });
    } catch (err) {
      if (err instanceof HttpsError) {
        throw err;
      }
      // Detección de colisión concurrente en create() sobre los cerrojos
      if (
        err.code === 6 ||
        err.code === 'already-exists' ||
        err.message?.includes('ALREADY_EXISTS') ||
        err.message?.includes('already exists')
      ) {
        if (err.message?.includes('pet_day_locks')) {
          throw new HttpsError(
            'already-exists',
            'La mascota ya tiene una cita reservada para esta fecha.',
            { errorCode: 'PET_ALREADY_BOOKED_THAT_DAY' }
          );
        }
        throw new HttpsError(
          'already-exists',
          'La franja horaria seleccionada ya ha sido reservada.',
          { errorCode: 'SLOT_TAKEN' }
        );
      }
      throw new HttpsError('internal', 'Error al procesar la reserva de cita: ' + err.message);
    }

    // Registro de idempotencia en caso de éxito
    if (requestId && typeof requestId === 'string') {
      await db.collection('idempotency').doc(requestId).set({
        response: result,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    return result;
  }
);
