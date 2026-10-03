// functions/src/callables/cancelAppointmentByClient.js
// Callable de cancelación de citas por el cliente (TRD §3.2.C, C-09, CA-13, CA-22, CA-26, CA-58, N-11, AUD-133, AUD-149, AUD-150)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { REGIONS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { removeConceptFromDraftProforma, ITEM_TYPES, PROFORMA_STATUS } from '../domain/proforma.js';

export const cancelAppointmentByClient = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    const uid = request.auth.uid;
    const appointmentId = request.data?.appointmentId;

    if (!appointmentId || typeof appointmentId !== 'string') {
      throw new HttpsError('invalid-argument', 'appointmentId es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const appointmentRef = db.collection('appointments').doc(appointmentId);

    // 2. Transacción atómica de cancelación
    await db.runTransaction(async (transaction) => {
      // --- FASE 1: LECTURAS ---
      const appointmentDoc = await transaction.get(appointmentRef);

      // Verificación de propiedad (TRD §3.2.C paso 1):
      // Si la cita no existe o pertenece a otro usuario, retornar NOT_FOUND (no PERMISSION_DENIED)
      // para evitar divulgar la existencia de IDs ajenos.
      if (!appointmentDoc.exists || appointmentDoc.data()?.clientId !== uid) {
        throw new HttpsError('not-found', 'Cita no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const appointmentData = appointmentDoc.data();
      const currentStatus = appointmentData.status;

      // Verificaciones de estado (TRD §3.2.C paso 2)
      if (currentStatus === 'COMPLETED') {
        throw new HttpsError('failed-precondition', 'Una cita completada no puede ser cancelada.', {
          errorCode: 'APPOINTMENT_NOT_CANCELLABLE',
        });
      }

      if (currentStatus === 'CANCELLED') {
        throw new HttpsError('failed-precondition', 'La cita ya se encuentra cancelada.', {
          errorCode: 'ALREADY_CANCELLED',
        });
      }

      // Solo citas PENDING o CONFIRMED pueden ser canceladas.
      // Sin ventana de proximidad: Se permite cancelar el mismo día y a cualquier hora (C-09, CA-58).

      // PASO 3 (AUD-133): Si la cita está vinculada a una proforma, leer la proforma
      let proformaDoc = null;
      if (appointmentData.proformaId) {
        const proformaRef = db.collection('proformas').doc(appointmentData.proformaId);
        proformaDoc = await transaction.get(proformaRef);

        if (proformaDoc.exists) {
          const pData = proformaDoc.data();
          if (pData.status !== PROFORMA_STATUS.DRAFT) {
            throw new HttpsError(
              'failed-precondition',
              'El concepto está bloqueado porque pertenece a una proforma ya entregada o procesada.',
              { errorCode: 'CONCEPT_LOCKED_BY_DELIVERED_PROFORMA' }
            );
          }
        }
      }

      // --- FASE 2: ESCRITURAS ---
      const nowTimestamp = FieldValue.serverTimestamp();

      // PASO 4: Actualización de la cita a CANCELLED con auditoría y razón CLIENT
      transaction.update(appointmentRef, {
        status: 'CANCELLED',
        cancelledReason: 'CLIENT',
        'audit.cancelledBy': uid,
        'audit.cancelledAt': nowTimestamp,
        'audit.updatedBy': uid,
        'audit.updatedAt': nowTimestamp,
      });

      // PASO 5: Borrado físico de cerrojos /slot_locks y /pet_day_locks (TRD §2.9, CA-22)
      // Los cerrojos no son datos de negocio sino centinelas de concurrencia; eliminarlos no vulnera N-19.
      if (appointmentData.slotKey) {
        const slotLockRef = db.collection('slot_locks').doc(appointmentData.slotKey);
        transaction.delete(slotLockRef);
      }

      if (appointmentData.petDayKey) {
        const petDayLockRef = db.collection('pet_day_locks').doc(appointmentData.petDayKey);
        transaction.delete(petDayLockRef);
      }

      // Retiro de línea de borrador si aplica (AUD-023)
      if (appointmentData.proformaId && proformaDoc && proformaDoc.exists) {
        await removeConceptFromDraftProforma(transaction, db, {
          proformaId: appointmentData.proformaId,
          itemType: ITEM_TYPES.SERVICE,
          refId: appointmentId,
          proformaDoc,
        });
      }

      // PASO 6 (N-11, CA-13): PROHIBICIÓN ESTRICTA: NO restar ni devolver cupo en /user_daily_counters.
      // PASO 7 (CA-26): PROHIBICIÓN ESTRICTA: NO encolar nada en /mail ni emitir notificaciones salientes.
    });

    return {
      success: true,
      appointmentId,
      status: 'CANCELLED',
    };
  }
);
