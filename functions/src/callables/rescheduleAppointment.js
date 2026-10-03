// functions/src/callables/rescheduleAppointment.js
// Callable de reagendamiento indivisible de citas por personal (TRD §3.2.H, AG-08, CA-61, CA-AD-54, ADR-002)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { todayBusinessDate } from '../domain/clock.js';
import { enqueueAppointmentMail } from '../lib/mail.js';

export const rescheduleAppointment = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación y rol exclusivo de personal (ADMIN o SUPERADMIN)
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

    // 2. Validación de parámetros de entrada fuera de la transacción (TRD §3.2.H)
    const requestData = request.data || {};
    const { appointmentId } = requestData;
    const targetDateString = requestData.dateString || requestData.toDateString;
    const targetTimeSlot = requestData.timeSlot || requestData.toTimeSlot;

    if (!appointmentId || typeof appointmentId !== 'string' || appointmentId.trim() === '') {
      throw new HttpsError('invalid-argument', 'El identificador de cita (appointmentId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!targetDateString || typeof targetDateString !== 'string' || !dateRegex.test(targetDateString)) {
      throw new HttpsError('invalid-argument', 'Formato de fecha inválido. Se espera YYYY-MM-DD.', {
        errorCode: 'INVALID_DATE_FORMAT',
      });
    }

    const timeRegex = /^\d{2}:\d{2}$/;
    if (!targetTimeSlot || typeof targetTimeSlot !== 'string' || !timeRegex.test(targetTimeSlot)) {
      throw new HttpsError('invalid-argument', 'Formato de franja horaria inválido. Se espera HH:mm.', {
        errorCode: 'INVALID_TIME_FORMAT',
      });
    }

    // Validar que la fecha no sea pasada
    const today = todayBusinessDate();
    if (targetDateString < today) {
      throw new HttpsError('invalid-argument', 'No se puede reagendar a una fecha pasada.', {
        errorCode: 'PAST_DATE',
      });
    }

    // Validar horario comercial y días laborables fuera de la transacción
    const opDoc = await db.collection('business_config').doc('operating_parameters').get();
    if (opDoc.exists) {
      const op = opDoc.data();
      const targetDateObj = new Date(`${targetDateString}T12:00:00Z`);
      let isoWeekday = targetDateObj.getUTCDay();
      if (isoWeekday === 0) isoWeekday = 7;

      if (Array.isArray(op.workingWeekdays) && op.workingWeekdays.length > 0) {
        if (!op.workingWeekdays.includes(isoWeekday)) {
          throw new HttpsError('failed-precondition', 'La fecha seleccionada no es un día laborable del negocio.', {
            errorCode: 'OUT_OF_HOURS',
          });
        }
      }

      if (op.openingTime && op.closingTime) {
        if (targetTimeSlot < op.openingTime || targetTimeSlot >= op.closingTime) {
          throw new HttpsError('failed-precondition', 'La franja seleccionada está fuera del horario de atención.', {
            errorCode: 'OUT_OF_HOURS',
          });
        }
      }
    }

    const trimmedAppointmentId = appointmentId.trim();
    const appointmentRef = db.collection('appointments').doc(trimmedAppointmentId);
    const targetSlotKey = `${targetDateString}_${targetTimeSlot}`;

    let resultPayload = null;

    // 3. Transacción atómica indivisible: 8 pasos normativos de TRD §3.2.H
    await db.runTransaction(async (transaction) => {
      // --- FASE 1: LECTURAS TRANSACCIONALES ---
      // Paso 1 (Lectura): Cita original
      const appointmentDoc = await transaction.get(appointmentRef);
      if (!appointmentDoc.exists) {
        throw new HttpsError('not-found', 'Cita no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const appointmentData = appointmentDoc.data();
      const currentStatus = appointmentData.status;

      // Paso 1 (Validación): Estado activo (PENDING o CONFIRMED). Inviolabilidad terminal si CANCELLED o COMPLETED
      if (currentStatus !== 'PENDING' && currentStatus !== 'CONFIRMED') {
        throw new HttpsError(
          'failed-precondition',
          `La cita se encuentra en estado ${currentStatus} y no puede ser reagendada.`,
          { errorCode: 'APPOINTMENT_NOT_RESCHEDULABLE' }
        );
      }

      // Paso 2: Si el destino coincide con el origen, abortar sin cambios
      if (appointmentData.dateString === targetDateString && appointmentData.timeSlot === targetTimeSlot) {
        throw new HttpsError(
          'failed-precondition',
          'La fecha y franja de destino coinciden con la fecha y franja actual de la cita.',
          { errorCode: 'NO_CHANGE' }
        );
      }

      // Paso 3 (Lectura): Bloqueos de disponibilidad administrativos en destino
      const targetDateBlockRef = db.collection('availability_blocks').doc(targetDateString);
      const targetSlotBlockRef = db.collection('availability_blocks').doc(targetSlotKey);
      const [targetDateBlockDoc, targetSlotBlockDoc] = await Promise.all([
        transaction.get(targetDateBlockRef),
        transaction.get(targetSlotBlockRef),
      ]);

      // Paso 4 (Lectura): Centinela de franja de destino (/slot_locks)
      const targetSlotLockRef = db.collection('slot_locks').doc(targetSlotKey);
      const targetSlotLockDoc = await transaction.get(targetSlotLockRef);

      // Paso 5 (Lectura): Centinela de mascota-día de destino (/pet_day_locks) solo si cambia la fecha
      const dateChanged = targetDateString !== appointmentData.dateString;
      const targetPetDayKey = `${appointmentData.petId}_${targetDateString}`;
      const targetPetDayLockRef = db.collection('pet_day_locks').doc(targetPetDayKey);
      let targetPetDayLockDoc = null;
      if (dateChanged) {
        targetPetDayLockDoc = await transaction.get(targetPetDayLockRef);
      }

      // Lecturas accesorias para notificación por correo (Paso 8)
      let clientDoc = null;
      if (appointmentData.clientId) {
        clientDoc = await transaction.get(db.collection('users').doc(appointmentData.clientId));
      }
      const billingDoc = await transaction.get(db.collection('business_config').doc('billing_parameters'));

      // --- FASE 2: EVALUACIÓN DE RESTRICCIONES ---
      // Paso 3 (Validación): Verificar que destino no esté bloqueado
      if (targetDateBlockDoc.exists || targetSlotBlockDoc.exists) {
        throw new HttpsError(
          'failed-precondition',
          'La fecha u hora seleccionada se encuentra bloqueada por administración.',
          { errorCode: 'SLOT_BLOCKED' }
        );
      }

      // Paso 4 (Validación): Colisión de franja horaria (C-11)
      if (targetSlotLockDoc.exists) {
        throw new HttpsError('already-exists', 'La franja horaria seleccionada ya ha sido reservada.', {
          errorCode: 'SLOT_TAKEN',
        });
      }

      // Paso 5 (Validación): Colisión de mascota por día (C-12)
      if (dateChanged && targetPetDayLockDoc && targetPetDayLockDoc.exists) {
        throw new HttpsError('already-exists', 'La mascota ya tiene una cita reservada para esta fecha.', {
          errorCode: 'PET_ALREADY_BOOKED_THAT_DAY',
        });
      }

      // --- FASE 3: ESCRITURAS TRANSACCIONALES (INVARIANTE CREAR-ANTES-DE-BORRAR) ---
      const nowTimestamp = FieldValue.serverTimestamp();

      // Paso 4: create() del centinela de franja de destino
      transaction.create(targetSlotLockRef, {
        appointmentId: trimmedAppointmentId,
        dateString: targetDateString,
        timeSlot: targetTimeSlot,
        createdAt: nowTimestamp,
      });

      // Paso 5: create() del centinela de mascota-día de destino si cambió la fecha
      if (dateChanged) {
        transaction.create(targetPetDayLockRef, {
          appointmentId: trimmedAppointmentId,
          petId: appointmentData.petId,
          dateString: targetDateString,
          createdAt: nowTimestamp,
        });
      }

      // Paso 6: delete() de los centinelas de origen
      const originSlotKey = appointmentData.slotKey || `${appointmentData.dateString}_${appointmentData.timeSlot}`;
      transaction.delete(db.collection('slot_locks').doc(originSlotKey));

      if (dateChanged) {
        const originPetDayKey = appointmentData.petDayKey || `${appointmentData.petId}_${appointmentData.dateString}`;
        transaction.delete(db.collection('pet_day_locks').doc(originPetDayKey));
      }

      // Paso 7: Actualización de la cita (invariantes AG-08: no recalcular precio, no cambiar status, mismo ID)
      const existingHistory = Array.isArray(appointmentData.rescheduleHistory)
        ? appointmentData.rescheduleHistory
        : [];

      const historyEntry = {
        fromDateString: appointmentData.dateString,
        fromTimeSlot: appointmentData.timeSlot,
        toDateString: targetDateString,
        toTimeSlot: targetTimeSlot,
        by: uid,
        byName: token.name || 'Personal Administrativo',
        at: Timestamp.now(),
      };

      const updatedHistory = [...existingHistory, historyEntry];
      const newPetDayKey = dateChanged
        ? targetPetDayKey
        : (appointmentData.petDayKey || `${appointmentData.petId}_${appointmentData.dateString}`);

      transaction.update(appointmentRef, {
        dateString: targetDateString,
        timeSlot: targetTimeSlot,
        slotKey: targetSlotKey,
        petDayKey: newPetDayKey,
        hasBlockConflict: false,
        rescheduleCount: FieldValue.increment(1),
        rescheduleHistory: updatedHistory,
        'audit.rescheduledBy': uid,
        'audit.rescheduledAt': nowTimestamp,
        'audit.updatedBy': uid,
        'audit.updatedAt': nowTimestamp,
      });

      // Paso 8: Encolado de correo en /mail dentro de la misma transacción (AG-09, TRD §3.5.F, ADR-003)
      try {
        const clientData = clientDoc && clientDoc.exists ? clientDoc.data() : null;
        const clientEmail = clientData?.email || appointmentData.clientEmail;
        const isClientActive = clientData ? clientData.status === USER_STATUS.ACTIVE : true;

        if (clientEmail && isClientActive) {
          const billingData = billingDoc && billingDoc.exists ? billingDoc.data() : {};
          const staffName = token.name || 'Personal Administrativo';
          const resolvedClientName = clientData?.fullName || appointmentData.clientName || 'Cliente';
          const resolvedPetName = appointmentData.petName || 'Mascota';
          const resolvedServiceName = appointmentData.serviceName || 'Servicio';

          enqueueAppointmentMail(transaction, {
            to: clientEmail,
            kind: 'APPOINTMENT_RESCHEDULED',
            data: {
              clientName: resolvedClientName,
              petName: resolvedPetName,
              serviceName: resolvedServiceName,
              fromDateString: appointmentData.dateString || null,
              fromTimeSlot: appointmentData.timeSlot || null,
              toDateString: targetDateString,
              toTimeSlot: targetTimeSlot,
              actorName: staffName,
              businessName: billingData.businessName || 'PetShop',
              businessPhone: billingData.phone || '+593999999999',
            },
            appointmentId: trimmedAppointmentId,
          });
        }
      } catch (mailError) {
        // La operación de agenda manda; fallo no condiciona el reagendamiento (ADR-003, Caso 15)
        console.warn(`[rescheduleAppointment] Advertencia al encolar correo en /mail: ${mailError.message}`);
      }

      resultPayload = {
        success: true,
        appointmentId: trimmedAppointmentId,
        dateString: targetDateString,
        timeSlot: targetTimeSlot,
        status: currentStatus,
        rescheduleCount: (appointmentData.rescheduleCount || 0) + 1,
      };
    });

    return resultPayload;
  }
);
