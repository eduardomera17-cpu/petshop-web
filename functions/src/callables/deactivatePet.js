// functions/src/callables/deactivatePet.js
// Callable de desactivación de mascota e indivisibilidad en cascada (TRD v1.13 §3.4.H, M-04, CA-27, CA-60, CA-AD-39, AUD-023, AUD-124, AUD-133, AUD-149, AUD-150, D-03)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { REGIONS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { removeConceptFromDraftProforma, ITEM_TYPES, PROFORMA_STATUS } from '../domain/proforma.js';

export const deactivatePet = onCall(
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
    const petId = request.data?.petId;

    if (!petId || typeof petId !== 'string') {
      throw new HttpsError('invalid-argument', 'petId es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const petRef = db.collection('pets').doc(petId);
    let cancelledCount = 0;

    // Consulta previa de candidatos fuera de la transacción (TRD §3.4.H, ADR-029)
    const appointmentsQuery = db
      .collection('appointments')
      .where('petId', '==', petId)
      .where('status', 'in', ['PENDING', 'CONFIRMED']);
    const candidateSnap = await appointmentsQuery.get();

    // 2. Transacción de 7 pasos atómicos (TRD v1.22 §3.4.H, M-04: un solo acto indivisible)
    await db.runTransaction(async (transaction) => {
      // --- FASE 1: LECTURAS ---

      // PASO 1: Lee /pets/{petId}. Debe existir y ownerId == uid.
      // Si no, NOT_FOUND (no PERMISSION_DENIED) para evitar divulgar la existencia de IDs ajenos.
      const petDoc = await transaction.get(petRef);
      if (!petDoc.exists || petDoc.data()?.ownerId !== uid) {
        throw new HttpsError('not-found', 'Mascota no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const petData = petDoc.data();

      // PASO 2: Si ya está desactivada, aborta sin tocar nada
      if (petData.status === 'DEACTIVATED') {
        throw new HttpsError('failed-precondition', 'La mascota ya se encuentra desactivada.', {
          errorCode: 'PET_ALREADY_DEACTIVATED',
        });
      }

      // PASO 3 (TRD v1.22 §3.4.H, ADR-029): Lectura transaccional y revalidación de citas activas
      const readDocs = await Promise.all(candidateSnap.docs.map((d) => transaction.get(d.ref)));
      const candidateDocs = readDocs.filter(
        (d) =>
          d.exists &&
          d.data()?.petId === petId &&
          (d.data()?.status === 'PENDING' || d.data()?.status === 'CONFIRMED')
      );

      // Lectura previa de proformas asociadas a las citas activas
      const proformaDocsMap = new Map();
      for (const appDoc of candidateDocs) {
        const data = appDoc.data();
        if (data.proformaId && !proformaDocsMap.has(data.proformaId)) {
          const pRef = db.collection('proformas').doc(data.proformaId);
          const pDoc = await transaction.get(pRef);
          proformaDocsMap.set(data.proformaId, pDoc);
        }
      }

      // --- FASE 2: ESCRITURAS ---
      const nowTimestamp = FieldValue.serverTimestamp();
      cancelledCount = 0;

      // PASO 4: Por cada cita activa: status: CANCELLED, cancelledReason: PET_DEACTIVATED,
      // auditoría, y borrado físico de /slot_locks y /pet_day_locks (§2.9).
      // Las COMPLETED no se tocan (N-19).
      for (const appDoc of candidateDocs) {
        const data = appDoc.data();
        cancelledCount++;
        transaction.update(appDoc.ref, {
          status: 'CANCELLED',
          cancelledReason: 'PET_DEACTIVATED',
          'audit.cancelledBy': uid,
          'audit.cancelledAt': nowTimestamp,
          'audit.updatedBy': uid,
          'audit.updatedAt': nowTimestamp,
        });

        if (data.slotKey) {
          transaction.delete(db.collection('slot_locks').doc(data.slotKey));
        }
        if (data.petDayKey) {
          transaction.delete(db.collection('pet_day_locks').doc(data.petDayKey));
        }

        // PASO 5 (AUD-023, AUD-133, D-03): Retiro de líneas de Borrador en /proformas
        // Si la proforma no está en DRAFT, no aborta la desactivación de mascota (D-03):
        // la cita se cancela igualmente y la línea se conserva facturada.
        if (data.proformaId && proformaDocsMap.has(data.proformaId)) {
          const pDoc = proformaDocsMap.get(data.proformaId);
          if (pDoc.exists && pDoc.data()?.status === PROFORMA_STATUS.DRAFT) {
            await removeConceptFromDraftProforma(transaction, db, {
              proformaId: data.proformaId,
              itemType: ITEM_TYPES.SERVICE,
              refId: appDoc.id,
              proformaDoc: pDoc,
            });
          }
        }
      }

      // PASO 6: /pets/{petId}: status: DEACTIVATED, deactivatedAt, deactivatedBy, auditoría
      transaction.update(petRef, {
        status: 'DEACTIVATED',
        deactivatedAt: nowTimestamp,
        deactivatedBy: uid,
        'audit.updatedBy': uid,
        'audit.updatedAt': nowTimestamp,
      });

      // PASO 7: No toca /user_daily_counters (N-11, CA-13) y no encola en /mail (CA-26).
      // El registro clínico de la mascota NO se toca (CA-AD-39).
    });

    return {
      success: true,
      petId,
      status: 'DEACTIVATED',
      cancelledAppointmentsCount: cancelledCount,
    };
  }
);
