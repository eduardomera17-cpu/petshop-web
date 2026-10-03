// functions/src/lib/image_pipeline.js
// Pipeline autoritativo de optimización de imágenes con Sharp (TRD §3.5.A, ADR-018, ADR-019, N-22, CA-09, CA-12, CA-51)

import sharp from 'sharp';
import { getStorage } from 'firebase-admin/storage';
import { FieldValue } from '../config/firebase.js';

/// Tamaño máximo permitido: 5 MB (TRD §3.5.A, N-22, CA-12)
export const MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024;

/// Formatos autorizados taxativamente (ADR-018, storage.rules)
export const ALLOWED_FORMATS = ['jpeg', 'png', 'webp', 'avif'];

/// Formatos expresamente excluidos: HEIC/HEIF (sin códecs en precompilados) y SVG (seguridad)
export const BLOCKED_FORMATS = ['heic', 'heif', 'svg'];

/// Cota de resolución en el lado mayor
export const MAX_DIMENSION = 1080;

/// Calidad de compresión WebP
export const WEBP_QUALITY = 80;

/**
 * Valida y procesa un buffer de imagen con Sharp conforme a ADR-018 y TRD §3.5.A.
 *
 * @param {Buffer} buffer
 * @returns {Promise<{ processedBuffer: Buffer, metadata: sharp.Metadata, originalMetadata: sharp.Metadata }>}
 */
export async function validateAndProcessImage(buffer) {
  if (!buffer || !Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw new Error('Buffer de imagen vacío o inválido');
  }

  if (buffer.length > MAX_IMAGE_SIZE_BYTES) {
    throw new Error(`Tamaño de archivo (${buffer.length} bytes) supera el límite de 5 MB`);
  }

  // Inspección por números mágicos con Sharp
  let originalMetadata;
  try {
    originalMetadata = await sharp(buffer).metadata();
  } catch (err) {
    throw new Error(`sharp no pudo interpretar la imagen: ${err.message}`);
  }

  const format = originalMetadata?.format?.toLowerCase();
  if (!format) {
    throw new Error('Formato de imagen indeterminado');
  }

  if (BLOCKED_FORMATS.includes(format)) {
    throw new Error(`Formato bloqueado por política de seguridad y arquitectura: ${format}`);
  }

  if (!ALLOWED_FORMATS.includes(format)) {
    throw new Error(`Formato no autorizado: ${format}. Permitidos: ${ALLOWED_FORMATS.join(', ')}`);
  }

  // Transformaciones autoritativas (TRD §3.4.4, §5.2.F, ADR-011):
  // 1. rotate() -> normaliza la orientación según etiquetas EXIF antes de despojarlas
  // 2. Comportamiento por omisión de Sharp -> despoja todos los metadatos EXIF / geolocalización (privacidad)
  // 3. resize() -> máx 1080 px en lado mayor sin ampliar
  // 4. webp({ quality: 80 }) -> compresión estándar WebP q80
  const processedBuffer = await sharp(buffer)
    .rotate()
    .resize({
      width: MAX_DIMENSION,
      height: MAX_DIMENSION,
      fit: 'inside',
      withoutEnlargement: true,
    })
    .webp({ quality: WEBP_QUALITY })
    .toBuffer();

  const metadata = await sharp(processedBuffer).metadata();

  return {
    processedBuffer,
    metadata,
    originalMetadata,
  };
}

/**
 * Comprueba si un UID pertenece al personal (ADMIN o SUPERADMIN) en Firestore.
 *
 * @param {import('firebase-admin/firestore').Firestore} db
 * @param {string} uid
 * @returns {Promise<boolean>}
 */
export async function isStaff(db, uid) {
  if (!uid) return false;
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return false;
    const role = userDoc.data()?.role;
    return role === 'ADMIN' || role === 'SUPERADMIN';
  } catch (err) {
    console.error(`[isStaff] Error al verificar rol para ${uid}:`, err);
    return false;
  }
}

/**
 * Deriva autoritativamente el destino en Firestore a partir del campo purpose (§2.12).
 * Prohibido leer targetPath o targetField del cliente (no existen en el modelo).
 *
 * @param {string} purpose
 * @param {string} ownerUid
 * @param {string|null} [targetId]
 * @returns {{ collection: string|null, docId: string|null, field: string|null } | null}
 */
export function deriveDestination(purpose, ownerUid, targetId = null) {
  if (purpose === 'USER_PHOTO') {
    return {
      collection: 'users',
      docId: ownerUid,
      field: 'photoPath',
    };
  }
  if (purpose === 'PET_PHOTO') {
    return {
      collection: 'pets',
      docId: targetId,
      field: 'photoPath',
    };
  }
  if (purpose === 'CHAT_IMAGE') {
    // CHAT_IMAGE no muta documentos de entidad en Firestore (TRD §2.12)
    return {
      collection: null,
      docId: null,
      field: null,
    };
  }
  return null;
}

/**
 * Manejador principal para el evento onObjectFinalized de Cloud Storage.
 *
 * @param {import('firebase-functions/v2/storage').StorageEvent} event
 * @param {{ db: import('firebase-admin/firestore').Firestore, storage: import('@google-cloud/storage').Bucket }} context
 */
export async function handleObjectFinalized(event, { db, storage }) {
  const objectName = event.data?.name;
  if (!objectName || !objectName.startsWith('uploads/')) {
    return null;
  }

  const parts = objectName.split('/');
  // Estructura obligatoria: uploads/{userId}/{intentId}/{fileName}
  if (parts.length < 4) {
    console.warn(`[handleObjectFinalized] Ruta descartada por estructura no válida: ${objectName}`);
    return null;
  }

  const userId = parts[1];
  const intentId = parts[2];

  const bucket = event.data?.bucket ? getStorage().bucket(event.data.bucket) : storage;
  const originalFile = bucket.file(objectName);

  // 1. Validación de la Intención de subida en Firestore (base nombrada 'petshopdev')
  const intentRef = db.collection('upload_intents').doc(intentId);
  const intentSnap = await intentRef.get();

  if (!intentSnap.exists) {
    console.warn(`[handleObjectFinalized] upload_intents/${intentId} no existe. Borrando objeto temporal.`);
    await originalFile.delete().catch(() => {});
    return null;
  }

  const intentData = intentSnap.data();

  // Si la intención ya está procesada o el ownerUid no coincide con el uid de la ruta -> borrar y terminar
  if (intentData.status === 'PROCESSED' || intentData.ownerUid !== userId) {
    console.warn(`[handleObjectFinalized] Intención rechazada por estado (${intentData.status}) o discordancia de owner (${intentData.ownerUid} != ${userId}). Borrando objeto.`);
    await originalFile.delete().catch(() => {});
    return null;
  }

  // 2. Derivación estricta de destino y comprobación previa en el servidor (TRD §2.12, §3.5.A)
  let resultPath;
  let destination = null;

  if (intentData.purpose === 'USER_PHOTO') {
    destination = {
      collection: 'users',
      docId: intentData.ownerUid,
      field: 'photoPath',
    };
    resultPath = `media/users/${intentData.ownerUid}/${intentId}.webp`;
  } else if (intentData.purpose === 'PET_PHOTO') {
    const petId = intentData.targetId;
    if (!petId || typeof petId !== 'string' || petId.trim().length === 0) {
      console.warn(`[handleObjectFinalized] PET_PHOTO sin targetId válido: ${intentId}. Marcando REJECTED y eliminando.`);
      await intentRef.update({
        status: 'REJECTED',
        rejectionCode: 'PIPELINE_FAILURE',
        updatedAt: FieldValue.serverTimestamp(),
      }).catch(() => {});
      await originalFile.delete().catch(() => {});
      return null;
    }

    const petDoc = await db.collection('pets').doc(petId).get();
    if (!petDoc.exists) {
      console.warn(`[handleObjectFinalized] Mascota ${petId} no existe para intención ${intentId}. Marcando REJECTED y eliminando.`);
      await intentRef.update({
        status: 'REJECTED',
        rejectionCode: 'PIPELINE_FAILURE',
        updatedAt: FieldValue.serverTimestamp(),
      }).catch(() => {});
      await originalFile.delete().catch(() => {});
      return null;
    }

    const petData = petDoc.data();
    const ownerId = petData?.ownerId;
    const staff = await isStaff(db, intentData.ownerUid);
    const isAuthorized = staff || (ownerId && intentData.ownerUid === ownerId);

    if (!isAuthorized) {
      console.warn(`[handleObjectFinalized] Usuario ${intentData.ownerUid} no autorizado para mascota ${petId}. Marcando REJECTED y eliminando.`);
      await intentRef.update({
        status: 'REJECTED',
        rejectionCode: 'PIPELINE_FAILURE',
        updatedAt: FieldValue.serverTimestamp(),
      }).catch(() => {});
      await originalFile.delete().catch(() => {});
      return null;
    }

    destination = {
      collection: 'pets',
      docId: petId,
      field: 'photoPath',
    };
    resultPath = `media/pets/${ownerId}/${petId}/${intentId}.webp`;
  } else if (intentData.purpose === 'CHAT_IMAGE') {
    const chatId = intentData.targetId;
    if (!chatId || typeof chatId !== 'string' || chatId.trim().length === 0) {
      console.warn(`[handleObjectFinalized] CHAT_IMAGE sin targetId válido: ${intentId}. Marcando REJECTED y eliminando.`);
      await intentRef.update({
        status: 'REJECTED',
        rejectionCode: 'PIPELINE_FAILURE',
        updatedAt: FieldValue.serverTimestamp(),
      }).catch(() => {});
      await originalFile.delete().catch(() => {});
      return null;
    }

    // Comprobación previa en el servidor (TRD §2.12):
    // "participante de la sala | targetId es una sala en la que participa"
    const staff = await isStaff(db, intentData.ownerUid);
    const isParticipant = chatId === 'STAFF_INTERNAL'
      ? staff
      : (staff || intentData.ownerUid === chatId);

    if (!isParticipant) {
      console.warn(`[handleObjectFinalized] Usuario ${intentData.ownerUid} no autorizado para sala ${chatId}. Marcando REJECTED y eliminando.`);
      await intentRef.update({
        status: 'REJECTED',
        rejectionCode: 'PIPELINE_FAILURE',
        updatedAt: FieldValue.serverTimestamp(),
      }).catch(() => {});
      await originalFile.delete().catch(() => {});
      return null;
    }

    destination = null;
    resultPath = `media/chat/${chatId}/${intentId}.webp`;
  } else {
    console.warn(`[handleObjectFinalized] Propósito no soportado: "${intentData.purpose}". Marcando REJECTED y eliminando.`);
    await intentRef.update({
      status: 'REJECTED',
      rejectionCode: 'PIPELINE_FAILURE',
      updatedAt: FieldValue.serverTimestamp(),
    });
    await originalFile.delete().catch(() => {});
    return null;
  }

  // 3. Procesamiento y Manejo Integral de Errores con try/catch (CA-12)
  try {
    const [downloadBuffer] = await originalFile.download();

    const { processedBuffer, metadata } = await validateAndProcessImage(downloadBuffer);

    const destinationFile = bucket.file(resultPath);

    await destinationFile.save(processedBuffer, {
      contentType: 'image/webp',
      metadata: {
        cacheControl: 'public, max-age=31536000',
      },
    });

    // Actualización atómica de Firestore sólo si hay documento destino (USER_PHOTO)
    if (destination) {
      await db.collection(destination.collection).doc(destination.docId).update({
        [destination.field]: resultPath,
      });
    }

    await intentRef.update({
      status: 'PROCESSED',
      resultPath: resultPath,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Borrado del original en uploads/
    await originalFile.delete().catch((err) => {
      console.warn(`[handleObjectFinalized] Error al eliminar archivo temporal ${objectName}:`, err);
    });

    console.log(`[handleObjectFinalized] Imagen procesada con éxito: ${resultPath} (${metadata.width}x${metadata.height})`);
    return {
      status: 'PROCESSED',
      resultPath,
      width: metadata.width,
      height: metadata.height,
      format: metadata.format,
    };
  } catch (error) {
    console.error(`[handleObjectFinalized] Fallo en pipeline para ${objectName}:`, error);

    // Bloque catch: marcar REJECTED con PIPELINE_FAILURE y eliminar binario en uploads/ (CA-12)
    try {
      await intentRef.update({
        status: 'REJECTED',
        rejectionCode: 'PIPELINE_FAILURE',
        updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (dbErr) {
      console.error(`[handleObjectFinalized] Error al actualizar estado de upload_intents a REJECTED:`, dbErr);
    }

    try {
      await originalFile.delete().catch(() => {});
    } catch (storageErr) {
      console.error(`[handleObjectFinalized] Error al eliminar binario tras fallo:`, storageErr);
    }

    return null;
  }
}
