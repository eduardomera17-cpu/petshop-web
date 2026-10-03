// functions/src/lib/audit.js
// Módulo centralizado y único de registro en /audit_log (TRD §2.1 regla 5, §2.12, §4.4 bloque 15, N-AD-08, WP-5.5)
//
// Invariantes normativos:
// 1. La auditoría no la escribe quien la protagoniza: actorUid y createdAt los fija
//    exclusivamente el servidor a partir del token autenticado y FieldValue.serverTimestamp().
// 2. Prohibido registrar datos clínicos (diagnósticos, anamnesis, recetas) o texto
//    plano de mensajes de chat en el campo metadata de /audit_log.
// 3. Ninguna vía de acceso desde el SDK cliente tiene permiso de escritura (allow write: if false;).
// 4. Persistencia transaccional atómica compatible con transacciones de Firestore o escrituras directas.

import { FieldValue } from 'firebase-admin/firestore';
import { db } from '../config/firebase.js';

// Patrones de claves prohibidas por privacidad y confidencialidad clínica/mensajería
const FORBIDDEN_KEY_PATTERNS = [
  /diagnos/i,          // diagnosis, diagnostico, diagnósticos
  /anamnes/i,          // anamnesis
  /recet/i,            // receta, recetas
  /prescri/i,          // prescription, prescriptions
  /tratamient/i,       // tratamiento, tratamientos
  /treatment/i,        // treatment
  /clinical.*note/i,   // clinicalNotes
  /nota.*clinica/i,    // notasClinicas
  /signos.*vital/i,    // signosVitales, vitalSigns
  /temperatura/i,      // temperatura, temperature
  /sintoma/i,          // sintoma, symptoms
  /examen.*fisico/i,   // examenFisico, physicalExam
  /message.*text/i,    // messageText
  /texto.*mensaje/i,   // textoMensaje
  /raw.*text/i,        // rawText
  /chat.*text/i,       // chatText
  /message.*body/i,    // messageBody
  /body.*text/i,       // bodyText
];

const EXACT_FORBIDDEN_KEYS = new Set([
  'text',
  'texto',
  'content',
  'contenido',
  'message',
  'mensaje',
  'diagnosis',
  'diagnostico',
  'anamnesis',
  'prescription',
  'prescriptions',
  'receta',
  'recetas',
  'treatment',
  'tratamiento',
]);

/**
 * Sanitiza recursivamente el objeto metadata eliminando campos con datos clínicos
 * o texto de mensajes de chat, asegurando el cumplimiento de TRD §2.1 regla 5 y §2.12.
 *
 * @param {any} rawMetadata
 * @returns {Record<string, any>}
 */
export function sanitizeAuditMetadata(rawMetadata) {
  if (!rawMetadata || typeof rawMetadata !== 'object' || Array.isArray(rawMetadata)) {
    return {};
  }

  const clean = {};

  for (const [key, val] of Object.entries(rawMetadata)) {
    // 1. Omitir campos de auditoría interna de Firestore
    if (key.startsWith('audit.')) {
      continue;
    }

    const lowerKey = key.toLowerCase();

    // 2. Verificar contra claves prohibidas exactas
    if (EXACT_FORBIDDEN_KEYS.has(lowerKey)) {
      continue;
    }

    // 3. Verificar contra patrones de datos clínicos o texto plano de mensajes
    const isForbiddenPattern = FORBIDDEN_KEY_PATTERNS.some((pattern) => pattern.test(key));
    if (isForbiddenPattern) {
      continue;
    }

    // 4. Manejo recursivo de objetos anidados
    if (val && typeof val === 'object' && !Array.isArray(val) && !(val instanceof Date)) {
      clean[key] = sanitizeAuditMetadata(val);
    } else if (Array.isArray(val)) {
      clean[key] = val.map((item) => {
        if (item && typeof item === 'object' && !(item instanceof Date)) {
          return sanitizeAuditMetadata(item);
        }
        return item;
      });
    } else {
      clean[key] = val;
    }
  }

  return clean;
}

/**
 * Registra de forma unificada e inmutable una entrada en /audit_log (TRD §2.12).
 * Soporta transacciones de Firestore (atómica) o escrituras directas.
 *
 * @param {import('firebase-admin/firestore').Firestore | import('firebase-admin/firestore').Transaction | null | undefined} dbOrTransaction
 * @param {Object} params
 * @param {string} params.actorUid - UID verificado del actor (OBLIGATORIO, server-side)
 * @param {string} [params.actorName] - Nombre del actor
 * @param {string} [params.actorRole] - Rol del actor ('SUPERADMIN', 'ADMIN', 'CLIENT', etc.)
 * @param {string} params.action - Acción auditada (OBLIGATORIO)
 * @param {string} params.targetType - Tipo de entidad afectada (OBLIGATORIO)
 * @param {string} params.targetId - ID de la entidad afectada (OBLIGATORIO)
 * @param {Record<string, any>} [params.metadata] - Metadatos de contexto (sanitizados)
 * @param {import('firebase-admin/firestore').DocumentReference} [params.docRef] - Referencia pre-asignada opcional
 * @param {Record<string, any>} [params.extraFields] - Campos adicionales de nivel superior (ej. delta, resultingStock)
 * @returns {import('firebase-admin/firestore').DocumentReference | Promise<import('firebase-admin/firestore').DocumentReference>}
 */
export function recordAuditLog(dbOrTransaction, params = {}) {
  const {
    actorUid,
    actorName,
    actorRole,
    action,
    targetType,
    targetId,
    metadata,
    docRef,
    extraFields,
  } = params;

  // Validación de invariante: actorUid no falsificable y obligatorio
  if (!actorUid || typeof actorUid !== 'string' || actorUid.trim() === '') {
    throw new Error('Norma N-AD-08 violada: actorUid es obligatorio, no nulo y fijado por el servidor.');
  }

  if (!action || typeof action !== 'string' || action.trim() === '') {
    throw new Error('action es obligatoria para registrar en /audit_log.');
  }

  if (!targetType || typeof targetType !== 'string' || targetType.trim() === '') {
    throw new Error('targetType es obligatorio para registrar en /audit_log.');
  }

  if (!targetId || typeof targetId !== 'string' || targetId.trim() === '') {
    throw new Error('targetId es obligatorio para registrar en /audit_log.');
  }

  // Sanitizar metadata removiendo información sensible clínica y textos de chat
  const sanitizedMeta = sanitizeAuditMetadata(metadata);

  // Esquema canónico TRD §2.12
  // Invariante: createdAt es SIEMPRE FieldValue.serverTimestamp() fijado por el servidor
  const auditEntry = {
    actorUid: actorUid.trim(),
    actorName: typeof actorName === 'string' && actorName.trim() !== '' ? actorName.trim() : 'Sistema',
    actorRole: typeof actorRole === 'string' && actorRole.trim() !== '' ? actorRole.trim() : 'SYSTEM',
    action: action.trim(),
    targetType: targetType.trim(),
    targetId: targetId.trim(),
    metadata: sanitizedMeta,
    createdAt: FieldValue.serverTimestamp(),
    ...(extraFields && typeof extraFields === 'object' ? extraFields : {}),
  };

  const targetDocRef = docRef || db.collection('audit_log').doc();

  // Detección de Transaction o WriteBatch (posee método .set() pero NO .collection())
  const isTransactionOrBatch = Boolean(
    dbOrTransaction &&
    typeof dbOrTransaction.set === 'function' &&
    typeof dbOrTransaction.collection !== 'function'
  );

  if (isTransactionOrBatch) {
    dbOrTransaction.set(targetDocRef, auditEntry);
    return targetDocRef;
  }

  // Escritura directa vía Firestore Admin SDK
  return (async () => {
    await targetDocRef.set(auditEntry);
    return targetDocRef;
  })();
}
