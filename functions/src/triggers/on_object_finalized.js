// functions/src/triggers/on_object_finalized.js
// Trigger Cloud Storage de optimización de imágenes (TRD §1.4, §3.5.A, AUD-111, ADR-018, ADR-022)

import { onObjectFinalized as onStorageObjectFinalized } from 'firebase-functions/v2/storage';
import { REGIONS, STORAGE_BUCKET } from '../config/constants.js';
import { db, storage } from '../config/firebase.js';
import { handleObjectFinalized } from '../lib/image_pipeline.js';

export const onObjectFinalized = onStorageObjectFinalized(
  {
    // Sin STORAGE_BUCKET el disparador usa el bucket por defecto del proyecto.
    ...(STORAGE_BUCKET ? { bucket: STORAGE_BUCKET } : {}),
    region: REGIONS.STORAGE, // debe coincidir con la ubicación del bucket
  },
  async (event) => {
    // 1. Filtrado inicial obligatorio (AUD-111, TRD §3.5.A):
    // La primera línea comprueba uploads/; la plataforma no ofrece filtro por prefijo en Eventarc.
    if (!event.data?.name || !event.data.name.startsWith('uploads/')) {
      return null;
    }

    return handleObjectFinalized(event, { db, storage });
  }
);

// Alias de conveniencia
export { onObjectFinalized as onImageFinalized };
