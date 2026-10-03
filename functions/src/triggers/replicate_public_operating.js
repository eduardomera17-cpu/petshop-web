// functions/src/triggers/replicate_public_operating.js
// Trigger reactivo de réplica de parámetros operativos públicos (TRD §3.5.D-bis, ADR-010, ADR-015, ADR-022, CA-AD-60)

import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { FIRESTORE_DATABASE_ID, REGIONS } from '../config/constants.js';

/**
 * Compara si dos arreglos de enteros son idénticos.
 */
function areArraysEqual(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b)) return false;
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}

/**
 * Trigger reactivo para propagar la configuración operativa pública hacia
 * /business_config/public_operating — destino único (TRD §3.5.D-bis, AUD-184).
 *
 * Contratos normativos:
 * 1. Escucha: onDocumentUpdated sobre business_config/operating_parameters.
 * 2. Base nombrada: FIRESTORE_DATABASE_ID (petshopdev).
 * 3. Región: REGIONS.FIRESTORE (us-east1).
 * 4. Datos propagados: openingTime, closingTime, slotDurationMinutes, timezone, workingWeekdays y updatedAt.
 * 5. Exclusiones expresas: lowStockThreshold y el bloque audit QUEDAN FUERA.
 * 6. Idempotencia estricta: Si los campos públicos no cambiaron o si el destino ya está sincronizado,
 *    se omiten escrituras adicionales (0 mutaciones).
 */
export const replicatePublicOperating = onDocumentUpdated(
  {
    document: 'business_config/operating_parameters',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap) {
      return null;
    }

    const exists =
      typeof afterSnap.exists === 'function' ? afterSnap.exists() : Boolean(afterSnap.exists);
    if (!exists) {
      return null;
    }

    const afterData =
      (typeof afterSnap.data === 'function' ? afterSnap.data() : afterSnap) || {};
    const beforeData =
      (typeof event.data?.before?.data === 'function'
        ? event.data.before.data()
        : event.data?.before) || {};

    const publicPayload = {
      openingTime: afterData.openingTime ?? '08:00',
      closingTime: afterData.closingTime ?? '18:00',
      slotDurationMinutes: afterData.slotDurationMinutes ?? 30,
      timezone: afterData.timezone ?? 'America/Guayaquil',
      workingWeekdays: afterData.workingWeekdays ?? [1, 2, 3, 4, 5, 6],
    };

    // 1. Idempotencia respecto al cambio previo: verificar si algún campo público cambió
    const hasPublicChanges =
      beforeData.openingTime !== publicPayload.openingTime ||
      beforeData.closingTime !== publicPayload.closingTime ||
      beforeData.slotDurationMinutes !== publicPayload.slotDurationMinutes ||
      beforeData.timezone !== publicPayload.timezone ||
      !areArraysEqual(beforeData.workingWeekdays, publicPayload.workingWeekdays);

    if (!hasPublicChanges) {
      console.log(
        '[replicatePublicOperating] Sin cambios en campos operativos públicos (ej. sólo lowStockThreshold o audit modificados). Omitiendo réplica.'
      );
      return null;
    }

    const primaryPublicRef = db.collection('business_config').doc('public_operating');

    // 2. Idempotencia estricta contra el documento destino principal
    const currentSnap = await primaryPublicRef.get();
    if (currentSnap.exists) {
      const cur = currentSnap.data() || {};
      const isFullyInSync =
        cur.openingTime === publicPayload.openingTime &&
        cur.closingTime === publicPayload.closingTime &&
        cur.slotDurationMinutes === publicPayload.slotDurationMinutes &&
        cur.timezone === publicPayload.timezone &&
        areArraysEqual(cur.workingWeekdays, publicPayload.workingWeekdays);

      if (isFullyInSync) {
        console.log(
          '[replicatePublicOperating] public_operating ya se encuentra sincronizado con los nuevos valores. 0 escrituras.'
        );
        return null;
      }
    }

    console.log(
      `[replicatePublicOperating] Replicando parámetros públicos: ${publicPayload.openingTime}-${publicPayload.closingTime}, ` +
      `slot: ${publicPayload.slotDurationMinutes}m, timezone: ${publicPayload.timezone}`
    );

    const writeData = {
      ...publicPayload,
      updatedAt: FieldValue.serverTimestamp(),
    };

    // Destino único contratado por el TRD §3.5.D-bis (AUD-184): la réplica va
    // exclusivamente a /business_config/public_operating.
    await primaryPublicRef.set(writeData, { merge: true });

    console.log('[replicatePublicOperating] Replicación pública completada exitosamente.');
    return publicPayload;
  }
);

