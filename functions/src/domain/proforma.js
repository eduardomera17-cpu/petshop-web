// functions/src/domain/proforma.js
// Módulo de dominio para validación, composición y recálculo de proformas (TRD §3.3, §2.10, FA-03, FA-04, FA-09, ADR-001, ADR-005)

import { FieldValue } from 'firebase-admin/firestore';
import { PROFORMA_MAX_ITEMS } from '../config/constants.js';
import { calculateDocumentPricing } from './pricing.js';
import { requestBillingLines } from './product_request.js';

export const PROFORMA_STATUS = Object.freeze({
  DRAFT: 'DRAFT',
  DELIVERED: 'DELIVERED',
  FINALIZED: 'FINALIZED',
  VOIDED: 'VOIDED',
});

export const ADJUSTMENT_TYPES = Object.freeze({
  DISCOUNT: 'DISCOUNT',
  SURCHARGE: 'SURCHARGE',
});

export const ITEM_TYPES = Object.freeze({
  SERVICE: 'SERVICE',
  PRODUCT: 'PRODUCT',
});

/**
 * Construye una línea de proforma a partir de una cita completada (TRD §3.3.C, §2.10).
 * Congela los importes y porcentajes impositivos acordados en la cita.
 *
 * @param {Object} appointment
 * @returns {Object} Línea normalizada para proforma
 */
export function buildProformaItemFromAppointment(appointment) {
  if (!appointment || typeof appointment !== 'object') {
    throw new TypeError('appointment debe ser un objeto.');
  }

  const id = appointment.id;
  if (!id || typeof id !== 'string') {
    throw new TypeError('appointment.id debe ser un string válido.');
  }

  const concept = appointment.serviceName || appointment.concept || 'Servicio';
  const unitBasePriceCents = appointment.basePriceCents;
  if (unitBasePriceCents !== undefined && unitBasePriceCents !== null) {
    if (typeof unitBasePriceCents !== 'number' || !Number.isInteger(unitBasePriceCents) || unitBasePriceCents < 0) {
      throw new TypeError('appointment.basePriceCents debe ser un entero no negativo en céntimos.');
    }
  }

  const iceBp = appointment.iceBp ?? 0;
  const ivaBp = appointment.ivaBp;

  return {
    itemType: ITEM_TYPES.SERVICE,
    refId: id,
    refLineId: null,
    concept: String(concept).trim(),
    quantity: 1,
    unitBasePriceCents,
    lineSubtotalCents: unitBasePriceCents,
    iceBp,
    ivaBp,
  };
}

/**
 * Construye las líneas de proforma a partir de una solicitud de producto lista para retirar (TRD v1.22 §3.3.C, §2.10).
 * Una solicitud produce varias líneas de concepto, una por producto (CA-AD-63).
 * Congela los importes y porcentajes impositivos acordados en la solicitud sin inventar ceros.
 *
 * @param {Object} productRequest
 * @returns {Array<Object>} Arreglo de líneas normalizadas para proforma
 */
export function buildProformaItemsFromProductRequest(productRequest) {
  if (!productRequest || typeof productRequest !== 'object') {
    throw new TypeError('productRequest debe ser un objeto.');
  }

  const id = productRequest.id;
  if (!id || typeof id !== 'string') {
    throw new TypeError('productRequest.id debe ser un string válido.');
  }

  const lines = requestBillingLines(productRequest);
  return lines.map((line) => {
    const concept = line.productName || 'Producto';
    const quantity = line.quantity;
    const unitBasePriceCents = line.agreedUnitPriceCents;
    const lineSubtotalCents =
      typeof quantity === 'number' && typeof unitBasePriceCents === 'number'
        ? quantity * unitBasePriceCents
        : undefined;

    return {
      itemType: ITEM_TYPES.PRODUCT,
      refId: id,
      refLineId: line.productId,
      concept: String(concept).trim(),
      quantity,
      unitBasePriceCents,
      lineSubtotalCents,
      iceBp: line.iceBp,
      ivaBp: line.ivaBp,
    };
  });
}

/**
 * Valida y normaliza un ajuste individual de proforma (TRD §3.3.D, FA-04).
 * El concepto es OBLIGATORIO. No admite parámetros de impuestos.
 *
 * @param {Object} adjustment
 * @param {number} index
 * @returns {Object} Ajuste validado
 */
export function validateAdjustment(adjustment, index = 0) {
  if (!adjustment || typeof adjustment !== 'object') {
    const error = new TypeError(`El ajuste en índice ${index} debe ser un objeto.`);
    error.errorCode = 'INVALID_ARGUMENT';
    throw error;
  }

  const concept = adjustment.concept;
  if (typeof concept !== 'string' || concept.trim() === '') {
    const error = new Error(`El concepto del ajuste en índice ${index} es obligatorio.`);
    error.errorCode = 'ADJUSTMENT_CONCEPT_REQUIRED';
    throw error;
  }

  const type = adjustment.type;
  if (type !== ADJUSTMENT_TYPES.DISCOUNT && type !== ADJUSTMENT_TYPES.SURCHARGE) {
    const error = new TypeError(`Tipo de ajuste inválido en índice ${index}: debe ser DISCOUNT o SURCHARGE.`);
    error.errorCode = 'INVALID_ARGUMENT';
    throw error;
  }

  // Rechazo de cualquier intento de fijar impuestos en el ajuste (FA-09, CA-AD-41)
  if ('tax' in adjustment || 'ivaBp' in adjustment || 'iceBp' in adjustment || 'taxRate' in adjustment) {
    const error = new TypeError(`El ajuste en índice ${index} no admite parámetros de impuestos.`);
    error.errorCode = 'INVALID_ARGUMENT';
    throw error;
  }

  const { percentBp, amountCents } = adjustment;
  if (percentBp !== undefined && percentBp !== null) {
    if (typeof percentBp !== 'number' || !Number.isInteger(percentBp) || percentBp < 0 || percentBp > 10000) {
      const error = new TypeError(`percentBp en ajuste ${index} debe ser un entero entre 0 y 10000.`);
      error.errorCode = 'INVALID_ARGUMENT';
      throw error;
    }
  } else {
    if (typeof amountCents !== 'number' || !Number.isInteger(amountCents) || amountCents < 0) {
      const error = new TypeError(`amountCents en ajuste ${index} debe ser un entero no negativo en céntimos.`);
      error.errorCode = 'INVALID_ARGUMENT';
      throw error;
    }
  }

  return {
    id: adjustment.id ? String(adjustment.id).trim() : `adj_${index + 1}`,
    type,
    concept: concept.trim(),
    percentBp: percentBp ?? null,
    amountCents: amountCents ?? 0,
  };
}

/**
 * Recalcula el documento completo de proforma respetando los invariantes normativos (TRD §3.3.A, FA-09).
 * Maneja el caso de borrador vacío devolviendo totales en cero.
 *
 * @param {Object} params
 * @param {Array<Object>} [params.items=[]]
 * @param {Array<Object>} [params.adjustments=[]]
 * @param {boolean} [params.iceIncludedInIvaBase=true]
 * @returns {Object} Resultado del cálculo de documento
 */
export function recalculateProformaDocument({
  items = [],
  adjustments = [],
  iceIncludedInIvaBase = true,
}) {
  if (!Array.isArray(items)) {
    throw new TypeError('items debe ser un arreglo.');
  }
  if (!Array.isArray(adjustments)) {
    throw new TypeError('adjustments debe ser un arreglo.');
  }
  if (typeof iceIncludedInIvaBase !== 'boolean') {
    throw new TypeError('iceIncludedInIvaBase debe ser un booleano.');
  }

  if (items.length > PROFORMA_MAX_ITEMS) {
    const error = new Error(`Se ha superado el límite máximo de ${PROFORMA_MAX_ITEMS} líneas por proforma.`);
    error.errorCode = 'TOO_MANY_ITEMS';
    throw error;
  }

  // Borrador vacío (ADR-008): sin líneas, totales en 0
  if (items.length === 0) {
    return {
      items: [],
      adjustments: adjustments.map((adj, i) => validateAdjustment(adj, i)),
      subtotalCents: 0,
      totalDiscountCents: 0,
      totalSurchargeCents: 0,
      taxableBaseCents: 0,
      netAdjustmentCents: 0,
      totalIceCents: 0,
      totalIvaCents: 0,
      totalCents: 0,
      iceIncludedInIvaBase,
    };
  }

  const validatedAdjustments = adjustments.map((adj, i) => validateAdjustment(adj, i));

  return calculateDocumentPricing({
    items,
    adjustments: validatedAdjustments,
    iceIncludedInIvaBase,
  });
}

/**
 * Retira un concepto de una proforma si y solo si se encuentra en estado DRAFT (TRD §3.2.C, §3.2.E, §3.4.G, §3.4.H, AUD-023, D-03).
 * Recalcula el documento entero y emite un aviso en la subcolección /proformas/{proformaId}/notices.
 * Si proformaId es null o no existe, retorna sin error.
 * Si la proforma no está en DRAFT, no retira la línea (D-03).
 *
 * @param {FirebaseFirestore.Transaction} transaction
 * @param {FirebaseFirestore.Firestore} db
 * @param {Object} params
 * @param {string|null} params.proformaId
 * @param {string} params.itemType 'SERVICE' | 'PRODUCT'
 * @param {string} params.refId ID del appointment o product_request
 * @param {FirebaseFirestore.DocumentSnapshot} [params.proformaDoc=null]
 * @returns {Promise<{ removed: boolean, status: string|null, remainingItemsCount: number }>}
 */
export async function removeConceptFromDraftProforma(transaction, db, {
  proformaId,
  itemType,
  refId,
  proformaDoc = null,
}) {
  if (!proformaId || typeof proformaId !== 'string' || proformaId.trim() === '') {
    return { removed: false, status: null, remainingItemsCount: 0 };
  }

  const trimmedProformaId = proformaId.trim();
  const proformaRef = db.collection('proformas').doc(trimmedProformaId);
  const resolvedDoc = proformaDoc || (await transaction.get(proformaRef));

  if (!resolvedDoc.exists) {
    return { removed: false, status: null, remainingItemsCount: 0 };
  }

  const proformaData = resolvedDoc.data();
  if (proformaData.status !== PROFORMA_STATUS.DRAFT) {
    // Si no está en DRAFT (está DELIVERED, FINALIZED o VOIDED), la línea no se retira (D-03)
    return {
      removed: false,
      status: proformaData.status,
      remainingItemsCount: Array.isArray(proformaData.items) ? proformaData.items.length : 0,
    };
  }

  const existingItems = Array.isArray(proformaData.items) ? proformaData.items : [];
  const removedItems = [];
  const remainingItems = [];

  for (const itm of existingItems) {
    if (itm.refId === refId && itm.itemType === itemType) {
      removedItems.push(itm);
    } else {
      remainingItems.push(itm);
    }
  }

  // Calcular suma de todas las líneas retiradas y concatenar sus conceptos (AUD-245, §3.3.C)
  let totalRemovedAmountCents = 0;
  const removedConcepts = [];

  for (const itm of removedItems) {
    const lineAmt = itm.lineTotalCents
      ?? itm.lineSubtotalCents
      ?? (typeof itm.unitBasePriceCents === 'number' ? itm.unitBasePriceCents * (itm.quantity ?? 1) : 0);
    totalRemovedAmountCents += lineAmt;
    removedConcepts.push(itm.concept || 'Concepto');
  }

  const resolvedConceptName = removedConcepts.join(', ');

  const existingAdjustments = Array.isArray(proformaData.adjustments) ? proformaData.adjustments : [];
  const iceIncludedInIvaBase = typeof proformaData.iceIncludedInIvaBase === 'boolean'
    ? proformaData.iceIncludedInIvaBase
    : true;

  // Recalcular documento respetando invariantes normativos (TRD §3.3.A)
  const recalculated = recalculateProformaDocument({
    items: remainingItems,
    adjustments: existingAdjustments,
    iceIncludedInIvaBase,
  });

  const now = FieldValue.serverTimestamp();

  // Actualizar proforma
  transaction.update(proformaRef, {
    items: recalculated.items,
    adjustments: recalculated.adjustments,
    subtotalCents: recalculated.subtotalCents,
    totalDiscountCents: recalculated.totalDiscountCents,
    totalSurchargeCents: recalculated.totalSurchargeCents,
    taxableBaseCents: recalculated.taxableBaseCents,
    totalIceCents: recalculated.totalIceCents,
    totalIvaCents: recalculated.totalIvaCents,
    totalCents: recalculated.totalCents,
    'audit.updatedAt': now,
  });

  // Crear aviso inmutable en /proformas/{proformaId}/notices
  const noticeRef = proformaRef.collection('notices').doc();
  transaction.set(noticeRef, {
    kind: 'ITEM_REMOVED_BY_CLIENT_CANCELLATION',
    itemType,
    refId,
    concept: resolvedConceptName,
    removedAmountCents: totalRemovedAmountCents,
    createdAt: now,
  });

  return {
    removed: true,
    status: PROFORMA_STATUS.DRAFT,
    remainingItemsCount: remainingItems.length,
  };
}
