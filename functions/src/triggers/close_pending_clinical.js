// functions/src/triggers/close_pending_clinical.js
// Trigger reactivo de cierre de pendiente clínico en citas (TRD §2.5, §3.5.E, CL-10, ADR-015, ADR-022)

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { FIRESTORE_DATABASE_ID, REGIONS } from '../config/constants.js';

export const closePendingClinical = onDocumentCreated(
  {
    document: 'pets/{petId}/clinical_records/{recordId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    if (!event.data) {
      return null;
    }

    const recordData = event.data.data() || {};
    const sourceAppointmentId = recordData.sourceAppointmentId;

    if (!sourceAppointmentId || typeof sourceAppointmentId !== 'string') {
      return null;
    }

    const trimmedAppointmentId = sourceAppointmentId.trim();
    const appointmentRef = db.collection('appointments').doc(trimmedAppointmentId);
    const appointmentDoc = await appointmentRef.get();

    if (!appointmentDoc.exists) {
      return null;
    }

    const apptData = appointmentDoc.data() || {};

    // Si ya está en false, no realizar escritura redundante
    if (apptData.hasPendingClinicalRecord === false) {
      return null;
    }

    // Apagar automáticamente el flag hasPendingClinicalRecord (TRD §3.5.E, CL-10)
    await appointmentRef.update({
      hasPendingClinicalRecord: false,
      'audit.updatedAt': FieldValue.serverTimestamp(),
    });

    return { appointmentId: trimmedAppointmentId, hasPendingClinicalRecord: false };
  }
);
