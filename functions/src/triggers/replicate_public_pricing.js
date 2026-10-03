// functions/src/triggers/replicate_public_pricing.js
// Trigger reactivo de réplica de parámetros impositivos públicos (TRD §3.5.D, ADR-015, ADR-022)

import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';
import { FIRESTORE_DATABASE_ID, REGIONS } from '../config/constants.js';

/**
 * Trigger reactivo para replicar las tasas impositivas públicas hacia /business_config/public_pricing (TRD §3.5.D).
 *
 * Contratos:
 * 1. Evento: onDocumentUpdated sobre /business_config/billing_parameters.
 * 2. Base nombrada: FIRESTORE_DATABASE_ID (petshopdev).
 * 3. Región: REGIONS.FIRESTORE (us-east1).
 * 4. Datos propagados: Únicamente `ivaBp` e `iceIncludedInIvaBase`.
 * 5. Idempotencia estricta: Si `public_pricing` ya contiene los mismos valores de `ivaBp` e `iceIncludedInIvaBase`,
 *    no se ejecuta ninguna escritura hacia Firestore (0 mutaciones).
 */
export const replicatePublicPricing = onDocumentUpdated(
  {
    document: 'business_config/billing_parameters',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap) {
      return null;
    }

    const exists = typeof afterSnap.exists === 'function' ? afterSnap.exists() : Boolean(afterSnap.exists);
    if (!exists) {
      return null;
    }

    const afterData = (typeof afterSnap.data === 'function' ? afterSnap.data() : afterSnap) || {};
    const beforeData = (typeof event.data.before?.data === 'function'
      ? event.data.before.data()
      : event.data?.before) || {};

    const ivaBp = afterData.ivaBp;
    if (typeof ivaBp !== 'number') {
      console.log('[replicatePublicPricing] ivaBp no está definido o no es numérico. Omitiendo.');
      return null;
    }
    const iceIncludedInIvaBase = afterData.iceIncludedInIvaBase ?? true;

    // Si ni ivaBp ni iceIncludedInIvaBase han cambiado con respecto al snapshot anterior, omitir
    if (beforeData.ivaBp === ivaBp && beforeData.iceIncludedInIvaBase === iceIncludedInIvaBase) {
      console.log('[replicatePublicPricing] Sin cambios en ivaBp ni iceIncludedInIvaBase. Omitiendo.');
      return null;
    }

    const publicPricingRef = db.collection('business_config').doc('public_pricing');
    const publicPricingSnap = await publicPricingRef.get();
    const currentPublic = publicPricingSnap.data() || {};

    // Idempotencia estricta contra el documento destino
    if (
      publicPricingSnap.exists &&
      currentPublic.ivaBp === ivaBp &&
      currentPublic.iceIncludedInIvaBase === iceIncludedInIvaBase
    ) {
      console.log('[replicatePublicPricing] public_pricing ya se encuentra sincronizado. Idempotencia cumplida (0 escrituras).');
      return null;
    }

    console.log(
      `[replicatePublicPricing] Replicando a /business_config/public_pricing -> ivaBp: ${ivaBp}, iceIncludedInIvaBase: ${iceIncludedInIvaBase}`
    );

    await publicPricingRef.set(
      {
        ivaBp: ivaBp ?? 0,
        iceIncludedInIvaBase,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log('[replicatePublicPricing] Replicación completada con éxito.');
    return { ivaBp, iceIncludedInIvaBase };
  }
);
