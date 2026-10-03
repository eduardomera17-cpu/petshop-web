// functions/src/triggers/dispatch_mail.js
// Despachador del correo de AG-09 (TRD v1.15 §1.6, §3.5.H, ADR-011, ADR-021 Ruta B, AUD-INT-16).
//
// ÚNICO módulo del proyecto autorizado a importar un cliente SMTP. La guardia de
// TRD v1.15 §5.2.D regla 1 falla la compilación si 'nodemailer', 'createTransport' o
// 'sendMail' aparecen en cualquier otro fichero de functions/src/.
//
// Sustituye a la extensión oficial 'Trigger Email from Firestore', retirada del proyecto
// por el cierre del servicio Firebase Extensions el 31/03/2027 (ADR-021).

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import nodemailer from 'nodemailer';
import { db, FieldValue } from '../config/firebase.js';
import {
  FIRESTORE_DATABASE_ID,
  REGIONS,
  SMTP_HOST,
  SMTP_PORT,
  SMTP_USER,
  MAIL_FROM,
} from '../config/constants.js';

// La clave vive en Secret Manager y se enlaza SÓLO a esta función mediante `secrets`.
// Nunca se registra, nunca se escribe en Firestore (TRD v1.15 §1.6).
export const BREVO_SMTP_KEY = defineSecret('BREVO_SMTP_KEY');

/** Estados del acuse de entrega escritos en el campo `delivery` del documento de /mail. */
export const DELIVERY_STATE = {
  PROCESSING: 'PROCESSING',
  SUCCESS: 'SUCCESS',
  ERROR: 'ERROR',
};

/**
 * Sustituye los marcadores {{clave}} de una plantilla con los valores de `data`.
 * Un marcador sin valor se sustituye por cadena vacía: el cliente nunca debe recibir
 * la plantilla en crudo (TRD v1.15 §3.5.H paso 3).
 */
export function renderTemplate(source, data) {
  if (typeof source !== 'string') return '';
  const values = data && typeof data === 'object' ? data : {};
  return source.replace(/\{\{\s*([A-Za-z0-9_.]+)\s*\}\}/g, (_match, key) => {
    const value = values[key];
    if (value === undefined || value === null) return '';
    return String(value);
  });
}

/**
 * Recorta y limpia el mensaje de error antes de archivarlo. Nunca se persiste la
 * credencial, ni cabeceras, ni el cuerpo del mensaje (TRD v1.15 §3.5.H paso 5).
 */
export function sanitizeError(err) {
  const raw = err && err.message ? String(err.message) : 'Error desconocido de entrega';
  const withoutSecrets = raw
    .replace(/xsmtpsib-[A-Za-z0-9-]+/gi, '[REDACTADO]')
    .replace(/(pass(word)?|key|secret|token|authorization)\s*[:=]\s*\S+/gi, '$1=[REDACTADO]');
  return withoutSecrets.slice(0, 300);
}

/**
 * Construye el transporte SMTP. Aislado para poder inyectarlo en pruebas sin red.
 */
export function createMailTransport(apiKey) {
  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: false, // STARTTLS sobre el puerto 587
    requireTLS: true,
    auth: { user: SMTP_USER, pass: apiKey },
  });
}

/**
 * Núcleo del despachador, sin acoplar al contexto de Cloud Functions, para poder
 * probarlo contra el emulador con un transporte simulado.
 *
 * El despachador NO nombra la colección /mail: opera exclusivamente sobre la referencia
 * del documento que lo disparó. Así la puerta única de escritura de §3.5.F sigue siendo
 * `src/lib/mail.js` y la regla 2 de §5.2.D se mantiene intacta.
 *
 * @param {Object} params
 * @param {import('firebase-admin/firestore').DocumentReference} params.mailRef
 *        Referencia del documento que disparó la función (`event.data.ref`)
 * @param {Object} params.mailData Contenido del documento recién creado
 * @param {Object} params.transport Objeto con `sendMail(...)`
 */
export async function dispatchMailDocument({ mailRef, mailData, transport }) {
  const mailId = mailRef.id;

  // 1. Guarda de idempotencia. Cloud Functions garantiza at-least-once (TRD §3.7):
  //    un reintento de plataforma no puede producir un segundo correo al cliente.
  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(mailRef);
    if (!snap.exists) return false;

    const current = snap.data() || {};
    const state = current.delivery?.state;
    if (state === DELIVERY_STATE.SUCCESS || state === DELIVERY_STATE.PROCESSING) {
      return false;
    }

    tx.update(mailRef, {
      'delivery.state': DELIVERY_STATE.PROCESSING,
      'delivery.attempts': FieldValue.increment(1),
      'delivery.startTime': FieldValue.serverTimestamp(),
    });
    return true;
  });

  if (!claimed) {
    console.log(`[dispatchMail] ${mailId}: ya entregado o en curso. 0 envíos.`);
    return { skipped: true };
  }

  try {
    // 2. Resolución de plantilla.
    const templateName = mailData?.template?.name;
    if (!templateName || typeof templateName !== 'string') {
      throw new Error('TEMPLATE_NOT_SPECIFIED');
    }

    const templateSnap = await db.collection('mail_templates').doc(templateName).get();
    if (!templateSnap.exists) {
      throw new Error(`TEMPLATE_NOT_FOUND: ${templateName}`);
    }

    const template = templateSnap.data() || {};
    const data = mailData?.template?.data || {};

    // 3. Sustitución de variables.
    const subject = renderTemplate(template.subject, data);
    const html = renderTemplate(template.html, data);
    const text = renderTemplate(template.text, data);

    const recipients = Array.isArray(mailData.to) ? mailData.to : [mailData.to];
    const validRecipients = recipients.filter((r) => typeof r === 'string' && r.includes('@'));
    if (validRecipients.length === 0) {
      throw new Error('NO_VALID_RECIPIENT');
    }

    // 4. Entrega.
    const info = await transport.sendMail({
      from: MAIL_FROM,
      to: validRecipients.join(', '),
      subject,
      text,
      html,
    });

    // 5. Acuse. No se notifica al panel: N-AD-09 prohíbe el acuse en la interfaz.
    await mailRef.update({
      'delivery.state': DELIVERY_STATE.SUCCESS,
      'delivery.endTime': FieldValue.serverTimestamp(),
      'delivery.messageId': info?.messageId ?? null,
      'delivery.error': null,
    });

    console.log(`[dispatchMail] ${mailId}: entregado (plantilla ${templateName}).`);
    return { delivered: true };
  } catch (err) {
    const sanitized = sanitizeError(err);
    await mailRef.update({
      'delivery.state': DELIVERY_STATE.ERROR,
      'delivery.endTime': FieldValue.serverTimestamp(),
      'delivery.error': sanitized,
    });

    // Un proveedor caído deja el documento en ERROR y la cola se acumula. Ninguna
    // operación de agenda se bloquea (AG-09, TRD v1.15 §1.6).
    console.error(`[dispatchMail] ${mailId}: fallo de entrega — ${sanitized}`);
    return { delivered: false, error: sanitized };
  }
}

export const dispatchMail = onDocumentCreated(
  {
    document: 'mail/{mailId}',
    database: FIRESTORE_DATABASE_ID,
    region: REGIONS.FIRESTORE,
    secrets: [BREVO_SMTP_KEY],
  },
  async (event) => {
    if (!event.data) {
      return null;
    }

    const mailData = event.data.data() || {};

    const transport = createMailTransport(BREVO_SMTP_KEY.value());
    await dispatchMailDocument({ mailRef: event.data.ref, mailData, transport });

    return null;
  }
);
