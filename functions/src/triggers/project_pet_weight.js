// functions/src/triggers/project_pet_weight.js
// Trigger reactivo de proyección autoritativa de peso sobre la ficha de la mascota (TRD §2.3, §3.5.C, PRD §3.5.2, ADR-015, ADR-022)

import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { FIRESTORE_DATABASE_ID, REGIONS } from '../config/constants.js';

export const projectPetWeight = onDocumentWritten(
  {
    document: 'pets/{petId}/clinical_records/{recordId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    const petId = event.params.petId;
    if (!petId) {
      return null;
    }

    const petRef = db.collection('pets').doc(petId);
    const petDoc = await petRef.get();
    if (!petDoc.exists) {
      return null;
    }

    // Consultar todas las entradas clínicas ACTIVE de esta mascota (TRD §3.5.C)
    // Una anulación (ANNULLED) ignora la entrada anulada al proyectar
    const recordsSnap = await db
      .collection('pets')
      .doc(petId)
      .collection('clinical_records')
      .where('status', '==', 'ACTIVE')
      .get();

    let latestDate = null;
    let latestTime = null;
    let projectedWeight = null;

    for (const doc of recordsSnap.docs) {
      const data = doc.data();
      const weight =
        data.physicalExam?.vitals?.weightGrams ??
        data.vitalSigns?.weightGrams ??
        data.weightGrams ??
        null;

      if (weight !== null && typeof weight === 'number' && weight > 0) {
        const attDate = data.attentionDate || '';
        const attTime = data.attentionTime || '00:00';

        // Comparación lexicográfica YYYY-MM-DD y HH:mm
        if (
          latestDate === null ||
          attDate > latestDate ||
          (attDate === latestDate && attTime > latestTime)
        ) {
          latestDate = attDate;
          latestTime = attTime;
          projectedWeight = weight;
        }
      }
    }

    const currentPetData = petDoc.data() || {};
    const currentWeightGrams = currentPetData.lastWeightGrams ?? null;
    const currentWeightDate = currentPetData.lastWeightDate ?? null;

    // Salvaguarda de idempotencia: si los valores ya son idénticos, evitar mutaciones redundantes
    if (
      currentWeightGrams === projectedWeight &&
      currentWeightDate === latestDate
    ) {
      return null;
    }

    // Actualizar campos en el documento de la mascota (/pets/{petId})
    // Se proyecta lastWeightGrams y lastRecordedWeight para compatibilidad total (TRD §2.3, §3.5.C)
    await petRef.update({
      lastWeightGrams: projectedWeight,
      lastRecordedWeight: projectedWeight,
      lastWeightDate: latestDate,
      'audit.updatedAt': FieldValue.serverTimestamp(),
    });

    return { petId, projectedWeight, latestDate };
  }
);
