// functions/src/callables/previewPetDeactivation.js
// Callable de previsualización de citas afectadas al desactivar una mascota (TRD v1.13 §3.4.H, AUD-124, N-20, CA-44, CA-60, AUD-149, AUD-150)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db } from '../config/firebase.js';
import { REGIONS, ENFORCE_APP_CHECK } from '../config/constants.js';

export const previewPetDeactivation = onCall(
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

    // 2. Comprobación de propiedad y existencia de la mascota
    // Si no existe o pertenece a otro usuario, retornar NOT_FOUND (no PERMISSION_DENIED)
    const petRef = db.collection('pets').doc(petId);
    const petDoc = await petRef.get();

    if (!petDoc.exists || petDoc.data()?.ownerId !== uid) {
      throw new HttpsError('not-found', 'Mascota no encontrada.', {
        errorCode: 'NOT_FOUND',
      });
    }

    const petData = petDoc.data();

    // 3. Si ya está desactivada, retornar PET_ALREADY_DEACTIVATED
    if (petData.status === 'DEACTIVATED') {
      throw new HttpsError('failed-precondition', 'La mascota ya se encuentra desactivada.', {
        errorCode: 'PET_ALREADY_DEACTIVATED',
      });
    }

    // 4. Consulta de citas activas de la mascota (PENDING y CONFIRMED)
    // Las citas COMPLETED no se devuelven ni se tocan (N-19).
    const appointmentsSnap = await db
      .collection('appointments')
      .where('petId', '==', petId)
      .where('status', 'in', ['PENDING', 'CONFIRMED'])
      .get();

    // Mapeo estricto: SIN ningún campo clínico (N-20, CA-44)
    const activeAppointments = appointmentsSnap.docs.map((doc) => {
      const data = doc.data();
      return {
        appointmentId: doc.id,
        dateString: data.dateString,
        timeSlot: data.timeSlot,
        serviceName: data.serviceName,
      };
    });

    // Ordenar cronológicamente por dateString y timeSlot ascendentes
    activeAppointments.sort((a, b) => {
      const dateCmp = (a.dateString || '').localeCompare(b.dateString || '');
      if (dateCmp !== 0) return dateCmp;
      return (a.timeSlot || '').localeCompare(b.timeSlot || '');
    });

    // Devuelve activeAppointmentsCount: 0 cuando no hay ninguna (CA-60, §5.1.B).
    return {
      petName: petData.name || '',
      activeAppointmentsCount: activeAppointments.length,
      activeAppointments: activeAppointments,
    };
  }
);
