// functions/src/lib/mail.js
// El ÚNICO módulo autorizado a escribir en /mail (TRD §1.6, §2.12, §3.5.F, §5.2.D, ADR-003, ADR-011)

import { db } from '../config/firebase.js';

// Lista cerrada de las dos únicas plantillas autorizadas por TRD §1.6, §2.12, §5.2.D y ADR-003
const ALLOWED_TEMPLATE_KINDS = {
  APPOINTMENT_CANCELLED: 'appointment_cancelled',
  APPOINTMENT_RESCHEDULED: 'appointment_rescheduled',
  appointment_cancelled: 'appointment_cancelled',
  appointment_rescheduled: 'appointment_rescheduled',
};

// Claves clínicas y financieras prohibidas en data (ADR-003, TRD §3.5.F)
const FORBIDDEN_KEY_PATTERNS = [
  // Financiero
  /price/i,
  /amount/i,
  /cents/i,
  /tax/i,
  /iva/i,
  /\bice\b/i,
  /iceCents/i,
  /iceBp/i,
  /discount/i,
  /subtotal/i,
  /total/i,
  /cost/i,
  /payment/i,
  /fee/i,
  /proforma/i,
  /currency/i,
  /money/i,
  // Clínico
  /clinical/i,
  /diagnosis/i,
  /treatment/i,
  /vital/i,
  /symptom/i,
  /prescription/i,
  /weight/i,
  /allerg/i,
  /anamnesis/i,
  /finding/i,
  /pathology/i,
  /medication/i,
  /dose/i,
  /exam/i,
];

function assertNoClinicalOrFinancialData(dataObj) {
  if (!dataObj || typeof dataObj !== 'object') {
    return;
  }

  for (const key of Object.keys(dataObj)) {
    for (const pattern of FORBIDDEN_KEY_PATTERNS) {
      if (pattern.test(key)) {
        throw new TypeError(
          `Parámetro prohibido en data de correo: "${key}". ` +
          'No se permiten datos clínicos ni importes financieros en la plantilla de correo (ADR-003, TRD §3.5.F).'
        );
      }
    }

    const val = dataObj[key];
    if (val && typeof val === 'object' && !Array.isArray(val)) {
      assertNoClinicalOrFinancialData(val);
    }
  }
}

/**
 * Encola un correo transaccional en /mail.
 * Es la ÚNICA puerta autorizada para escribir en dicha colección.
 * 
 * @param {import('firebase-admin/firestore').Transaction} transaction
 * @param {Object} params
 * @param {string|string[]} params.to Correo del destinatario
 * @param {string} params.kind 'APPOINTMENT_CANCELLED' | 'APPOINTMENT_RESCHEDULED'
 * @param {Object} params.data Variables para la plantilla
 * @param {string} [params.appointmentId] Identificador de cita (trazabilidad)
 */
export function enqueueAppointmentMail(transaction, { to, kind, data, appointmentId } = {}) {
  if (!transaction || typeof transaction.create !== 'function') {
    throw new TypeError('enqueueAppointmentMail requiere una transacción válida de Firestore como primer argumento.');
  }

  if (!to || (typeof to !== 'string' && !Array.isArray(to)) || (Array.isArray(to) && to.length === 0)) {
    throw new TypeError('enqueueAppointmentMail requiere un destinatario válido ("to").');
  }

  const recipients = Array.isArray(to) ? to : [to];
  for (const r of recipients) {
    if (typeof r !== 'string' || !r.includes('@')) {
      throw new TypeError(`Destinatario de correo inválido: "${r}".`);
    }
  }

  const templateName = ALLOWED_TEMPLATE_KINDS[kind];
  if (!templateName) {
    throw new TypeError(
      `Tipo de plantilla no autorizado: "${kind}". ` +
      'Solo se admiten APPOINTMENT_CANCELLED y APPOINTMENT_RESCHEDULED (TRD §5.2.D regla 3, ADR-003).'
    );
  }

  const mailData = data && typeof data === 'object' ? { ...data } : {};
  assertNoClinicalOrFinancialData(mailData);

  const mailRef = db.collection('mail').doc();
  const mailDoc = {
    to: recipients,
    template: {
      name: templateName,
      data: mailData,
    },
  };

  if (appointmentId && typeof appointmentId === 'string') {
    mailDoc.appointmentId = appointmentId;
  }

  transaction.create(mailRef, mailDoc);
}
