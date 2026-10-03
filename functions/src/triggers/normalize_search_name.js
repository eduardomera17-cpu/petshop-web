// functions/src/triggers/normalize_search_name.js
// Triggers reactivos de normalización autoritativa de searchName (TRD §3.5.G, CL-01, CL-04, PR-03, ADR-012, ADR-015, ADR-022)

import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { FIRESTORE_DATABASE_ID, REGIONS } from '../config/constants.js';

/**
 * Normaliza autoritativamente el campo searchName en users/{userId} (TRD §3.5.G, A-01, CF-07, ADR-012, ADR-015, ADR-022)
 *
 * Reglas de diseño e implementación:
 * 1. Declaración obligatoria de base nombrada: database: FIRESTORE_DATABASE_ID y region: REGIONS.FIRESTORE (ADR-015, ADR-022).
 * 2. Origen: campo 'fullName' (cota máxima de 100 caracteres según regla y TRD §3.5.G).
 * 3. Tipado defensivo: si no existe, es nulo o no es cadena con caracteres visibles, retorna null sin escrituras.
 * 4. Algoritmo canónico: source.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim()
 * 5. Idempotencia estricta: si data.searchName === canonicalSearchName, 0 escrituras (evita bucles infinitos de auto-disparo).
 */
export const normalizeUserSearchName = onDocumentWritten(
  {
    document: 'users/{userId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    // 1. Si el documento fue borrado, no se realiza ninguna operación
    if (!event.data?.after?.exists) {
      return null;
    }

    const data = event.data.after.data();

    // 2. Tipado defensivo: validar presencia y tipo del campo 'fullName'
    const rawFullName = data?.fullName;
    if (!rawFullName || typeof rawFullName !== 'string') {
      return null;
    }

    const trimmed = rawFullName.trim();
    if (trimmed.length === 0) {
      return null;
    }

    // Aplicar cota máxima de 100 caracteres (A-01, CF-07)
    const source = trimmed.length > 100 ? trimmed.slice(0, 100) : trimmed;

    // 3. Algoritmo canónico de normalización Unicode NFD (sin tildes, diéresis, ni caracteres combinados)
    const canonicalSearchName = source
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();

    if (canonicalSearchName.length === 0) {
      return null;
    }

    // 4. Salvaguarda estricta de idempotencia: cero mutaciones si el valor ya es idéntico
    if (data.searchName === canonicalSearchName) {
      return null;
    }

    const userId = event.params?.userId || event.data.after.id;
    console.log(`[normalizeUserSearchName] Normalizando users/${userId}`);

    try {
      // 5. Actualización autoritativa en la base nombrada 'petshopdev'
      await event.data.after.ref.update({
        searchName: canonicalSearchName,
      });

      console.log(`[normalizeUserSearchName] users/${userId} actualizado exitosamente`);
      return { searchName: canonicalSearchName };
    } catch (err) {
      if (err.code === 5 || err.message?.includes('NOT_FOUND') || err.message?.includes('no entity to update')) {
        console.warn(`[normalizeUserSearchName] Documento users/${userId} ya no existe al intentar actualizar.`);
        return null;
      }
      throw err;
    }
  }
);

/**
 * Normaliza autoritativamente el campo searchName en pets/{petId} (TRD §3.5.G, CL-04, AUD-107, ADR-012, ADR-015, ADR-022)
 *
 * Reglas de diseño e implementación:
 * 1. Declaración obligatoria de base nombrada: database: FIRESTORE_DATABASE_ID y region: REGIONS.FIRESTORE.
 * 2. Origen: campo 'name' (cota máxima de 60 caracteres según regla y AUD-107).
 * 3. Tipado defensivo: si no existe, es nulo o no es cadena con caracteres visibles, retorna null sin escrituras.
 * 4. Algoritmo canónico: source.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim()
 * 5. Idempotencia estricta: si data.searchName === canonicalSearchName, 0 escrituras (evita bucles de auto-disparo).
 */
export const normalizePetSearchName = onDocumentWritten(
  {
    document: 'pets/{petId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    if (!event.data?.after?.exists) {
      return null;
    }

    const data = event.data.after.data();
    const rawName = data?.name;
    if (!rawName || typeof rawName !== 'string') {
      return null;
    }

    const trimmed = rawName.trim();
    if (trimmed.length === 0) {
      return null;
    }

    // Aplicar cota máxima de 60 caracteres (AUD-107, firestore.rules)
    const source = trimmed.length > 60 ? trimmed.slice(0, 60) : trimmed;

    const canonicalSearchName = source
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();

    if (canonicalSearchName.length === 0) {
      return null;
    }

    if (data.searchName === canonicalSearchName) {
      return null;
    }

    const petId = event.params?.petId || event.data.after.id;
    console.log(`[normalizePetSearchName] Normalizando pets/${petId}: "${data.name}" -> "${canonicalSearchName}"`);

    try {
      await event.data.after.ref.update({
        searchName: canonicalSearchName,
      });
      console.log(`[normalizePetSearchName] pets/${petId} actualizado exitosamente con searchName: "${canonicalSearchName}"`);
      return { searchName: canonicalSearchName };
    } catch (err) {
      if (err.code === 5 || err.message?.includes('NOT_FOUND') || err.message?.includes('no entity to update')) {
        console.warn(`[normalizePetSearchName] Documento pets/${petId} ya no existe al intentar actualizar.`);
        return null;
      }
      throw err;
    }
  }
);

/**
 * Normaliza autoritativamente el campo searchName en services/{serviceId} (TRD §3.5.G, SE-01, AUD-075, AUD-084, ADR-012, ADR-015, ADR-022)
 *
 * Reglas de diseño e implementación:
 * 1. Declaración obligatoria de base nombrada: database: FIRESTORE_DATABASE_ID y region: REGIONS.FIRESTORE.
 * 2. Origen: campo 'name' (cota máxima de 80 caracteres según TRD §2.6 y AUD-075/AUD-084).
 * 3. Tipado defensivo: si no existe, es nulo o no es cadena con caracteres visibles, retorna null sin escrituras.
 * 4. Algoritmo canónico: source.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim()
 * 5. Idempotencia estricta: si data.searchName === canonicalSearchName, 0 escrituras (evita bucles de auto-disparo).
 */
export const normalizeServiceSearchName = onDocumentWritten(
  {
    document: 'services/{serviceId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    if (!event.data?.after?.exists) {
      return null;
    }

    const data = event.data.after.data();
    const rawName = data?.name;
    if (!rawName || typeof rawName !== 'string') {
      return null;
    }

    const trimmed = rawName.trim();
    if (trimmed.length === 0) {
      return null;
    }

    // Aplicar cota máxima de 80 caracteres (TRD §2.6, AUD-075, AUD-084)
    const source = trimmed.length > 80 ? trimmed.slice(0, 80) : trimmed;

    const canonicalSearchName = source
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();

    if (canonicalSearchName.length === 0) {
      return null;
    }

    if (data.searchName === canonicalSearchName) {
      return null;
    }

    const serviceId = event.params?.serviceId || event.data.after.id;
    console.log(`[normalizeServiceSearchName] Normalizando services/${serviceId}: "${data.name}" -> "${canonicalSearchName}"`);

    try {
      await event.data.after.ref.update({
        searchName: canonicalSearchName,
      });
      console.log(`[normalizeServiceSearchName] services/${serviceId} actualizado exitosamente con searchName: "${canonicalSearchName}"`);
      return { searchName: canonicalSearchName };
    } catch (err) {
      if (err.code === 5 || err.message?.includes('NOT_FOUND') || err.message?.includes('no entity to update')) {
        console.warn(`[normalizeServiceSearchName] Documento services/${serviceId} ya no existe al intentar actualizar.`);
        return null;
      }
      throw err;
    }
  }
);

/**
 * Trigger reactivo para mantener `searchName` canónico en /products/{productId} (TRD §2.6, §3.5.B, AUD-075, AUD-084)
 *
 * Contratos:
 * 1. Evento: onDocumentWritten sobre products/{productId}.
 * 2. Base nombrada: FIRESTORE_DATABASE_ID (petshopdev).
 * 3. Región: REGIONS.FIRESTORE (us-east1).
 * 4. Normalización canónica: minúsculas, remoción de tildes/diacríticos NFD, trim, cota máx 80 caracteres.
 * 5. Idempotencia estricta: si data.searchName === canonicalSearchName, 0 escrituras (evita bucles de auto-disparo).
 */
export const normalizeProductSearchName = onDocumentWritten(
  {
    document: 'products/{productId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    if (!event.data?.after?.exists) {
      return null;
    }

    const data = event.data.after.data();
    const rawName = data?.name;
    if (!rawName || typeof rawName !== 'string') {
      return null;
    }

    const trimmed = rawName.trim();
    if (trimmed.length === 0) {
      return null;
    }

    // Aplicar cota máxima de 80 caracteres (TRD §2.6, AUD-075, AUD-084)
    const source = trimmed.length > 80 ? trimmed.slice(0, 80) : trimmed;

    const canonicalSearchName = source
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .trim();

    if (canonicalSearchName.length === 0) {
      return null;
    }

    if (data.searchName === canonicalSearchName) {
      return null;
    }

    const productId = event.params?.productId || event.data.after.id;
    console.log(`[normalizeProductSearchName] Normalizando products/${productId}: "${data.name}" -> "${canonicalSearchName}"`);

    try {
      await event.data.after.ref.update({
        searchName: canonicalSearchName,
      });
      console.log(`[normalizeProductSearchName] products/${productId} actualizado exitosamente con searchName: "${canonicalSearchName}"`);
      return { searchName: canonicalSearchName };
    } catch (err) {
      if (err.code === 5 || err.message?.includes('NOT_FOUND') || err.message?.includes('no entity to update')) {
        console.warn(`[normalizeProductSearchName] Documento products/${productId} ya no existe al intentar actualizar.`);
        return null;
      }
      throw err;
    }
  }
);


