// functions/src/domain/pricing.js
// Cálculo impositivo normativo de línea en cascada (ADR-001, TRD §3.3.A, FA-09)
// SÓLO cálculo a nivel de línea. El algoritmo de documento se implementará en la Etapa 3.

import { roundHalfUp } from './money.js';

/**
 * Calcula el desglose impositivo y precio final para una línea individual (ADR-001, TRD §3.3.A).
 * El IVA nunca entra en la base imponible del ICE.
 *
 * @param {Object} params
 * @param {number} params.basePriceCents - Precio base en céntimos enteros (no negativo)
 * @param {number} [params.iceBp=0] - ICE en puntos básicos (ej. 2000 = 20.00%)
 * @param {number} [params.ivaBp=0] - IVA en puntos básicos (ej. 1500 = 15.00%)
 * @param {boolean} [params.iceIncludedInIvaBase=true] - Si true, el ICE se suma a la base imponible del IVA (LRTI art. 58)
 * @returns {{
 *   basePriceCents: number,
 *   iceBp: number,
 *   ivaBp: number,
 *   iceAmountCents: number,
 *   ivaAmountCents: number,
 *   finalPriceCents: number,
 * }}
 */
export function calculateLinePricing({
  basePriceCents,
  iceBp = 0,
  ivaBp = 0,
  iceIncludedInIvaBase = true,
}) {
  if (typeof basePriceCents !== 'number' || !Number.isInteger(basePriceCents) || basePriceCents < 0) {
    throw new TypeError('basePriceCents debe ser un número entero no negativo en céntimos.');
  }
  if (typeof iceBp !== 'number' || !Number.isInteger(iceBp) || iceBp < 0) {
    throw new TypeError('iceBp debe ser un número entero no negativo en puntos básicos.');
  }
  if (typeof ivaBp !== 'number' || !Number.isInteger(ivaBp) || ivaBp < 0) {
    throw new TypeError('ivaBp debe ser un número entero no negativo en puntos básicos.');
  }
  if (typeof iceIncludedInIvaBase !== 'boolean') {
    throw new TypeError('iceIncludedInIvaBase debe ser un booleano.');
  }

  // 1. ICE por línea = base imponible × iceBp / 10000 (el IVA NUNCA entra aquí)
  const iceAmountCents = roundHalfUp((basePriceCents * iceBp) / 10000);

  // 2. IVA por línea en cascada sobre (base + ICE) si iceIncludedInIvaBase es true
  const ivaBase = iceIncludedInIvaBase ? (basePriceCents + iceAmountCents) : basePriceCents;
  const ivaAmountCents = roundHalfUp((ivaBase * ivaBp) / 10000);

  // 3. Precio final de la línea = base + ICE + IVA
  const finalPriceCents = basePriceCents + iceAmountCents + ivaAmountCents;

  return {
    basePriceCents,
    iceBp,
    ivaBp,
    iceAmountCents,
    ivaAmountCents,
    finalPriceCents,
  };
}

/**
 * Calcula los importes normativos completos de una proforma/documento en aritmética entera (TRD §3.3.A, FA-09).
 *
 * @param {Object} params
 * @param {Array<Object>} params.items - Arreglo de conceptos/líneas
 * @param {Array<Object>} [params.adjustments=[]] - Arreglo de ajustes (descuentos y recargos)
 * @param {boolean} [params.iceIncludedInIvaBase=true] - Si true, el ICE se suma a la base imponible del IVA (LRTI art. 58)
 * @returns {Object} Desglose completo de documento y líneas con invariante comprobado
 */
export function calculateDocumentPricing({
  items,
  adjustments = [],
  iceIncludedInIvaBase = true,
}) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new TypeError('items debe ser un arreglo no vacío de líneas.');
  }
  if (!Array.isArray(adjustments)) {
    throw new TypeError('adjustments debe ser un arreglo.');
  }
  if (typeof iceIncludedInIvaBase !== 'boolean') {
    throw new TypeError('iceIncludedInIvaBase debe ser un booleano.');
  }

  // 1. Validar líneas y calcular subtotal = Σ (quantity_i * unitBasePriceCents_i)
  let subtotalCents = 0;
  const validatedItems = items.map((item, index) => {
    if (!item || typeof item !== 'object') {
      throw new TypeError(`El ítem en índice ${index} debe ser un objeto.`);
    }

    const quantity = item.quantity ?? 1;
    if (typeof quantity !== 'number' || !Number.isInteger(quantity) || quantity <= 0) {
      throw new TypeError(`quantity en el ítem ${index} debe ser un número entero positivo.`);
    }

    const unitBasePriceCents = item.unitBasePriceCents ?? item.basePriceCents;
    if (
      typeof unitBasePriceCents !== 'number' ||
      !Number.isInteger(unitBasePriceCents) ||
      unitBasePriceCents < 0
    ) {
      throw new TypeError(
        `unitBasePriceCents en el ítem ${index} debe ser un número entero no negativo en céntimos.`
      );
    }

    const iceBp = item.iceBp ?? 0;
    if (typeof iceBp !== 'number' || !Number.isInteger(iceBp) || iceBp < 0) {
      throw new TypeError(`iceBp en el ítem ${index} debe ser un entero no negativo en puntos básicos.`);
    }

    const ivaBp = item.ivaBp ?? 0;
    if (typeof ivaBp !== 'number' || !Number.isInteger(ivaBp) || ivaBp < 0) {
      throw new TypeError(`ivaBp en el ítem ${index} debe ser un entero no negativo en puntos básicos.`);
    }

    const lineSubtotalCents = quantity * unitBasePriceCents;
    subtotalCents += lineSubtotalCents;

    return {
      ...item,
      quantity,
      unitBasePriceCents,
      lineSubtotalCents,
      iceBp,
      ivaBp,
    };
  });

  // 2. Procesar ajustes de documento (DISCOUNT y SURCHARGE)
  let totalDiscountCents = 0;
  let totalSurchargeCents = 0;

  const processedAdjustments = adjustments.map((adj, index) => {
    if (!adj || typeof adj !== 'object') {
      throw new TypeError(`El ajuste en índice ${index} debe ser un objeto.`);
    }

    const { type, percentBp, amountCents } = adj;
    if (type !== 'DISCOUNT' && type !== 'SURCHARGE') {
      throw new TypeError(`Tipo de ajuste inválido en índice ${index}: debe ser 'DISCOUNT' o 'SURCHARGE'.`);
    }

    let calculatedAmountCents;
    if (percentBp !== undefined && percentBp !== null) {
      if (typeof percentBp !== 'number' || !Number.isInteger(percentBp) || percentBp < 0 || percentBp > 10000) {
        throw new TypeError(`percentBp en ajuste ${index} debe ser un entero entre 0 y 10000.`);
      }
      calculatedAmountCents = roundHalfUp((subtotalCents * percentBp) / 10000);
    } else {
      if (typeof amountCents !== 'number' || !Number.isInteger(amountCents) || amountCents < 0) {
        throw new TypeError(`amountCents en ajuste ${index} debe ser un número entero no negativo en céntimos.`);
      }
      calculatedAmountCents = amountCents;
    }

    if (type === 'DISCOUNT') {
      totalDiscountCents += calculatedAmountCents;
    } else {
      totalSurchargeCents += calculatedAmountCents;
    }

    return {
      ...adj,
      type,
      percentBp: percentBp ?? null,
      amountCents: calculatedAmountCents,
    };
  });

  // 3. Base imponible del documento
  const taxableBaseCents = subtotalCents - totalDiscountCents + totalSurchargeCents;

  // 4. Ajuste neto de documento con signo (recargos positivos, descuentos negativos)
  const netAdjustmentCents = totalSurchargeCents - totalDiscountCents;

  // 5. Reparto proporcional del ajuste y asignación del sobrante a la línea L de mayor importe
  // L = índice de la línea con mayor lineSubtotalCents (empate => la primera línea de menor índice)
  let L = 0;
  let maxSubtotal = validatedItems[0].lineSubtotalCents;
  for (let i = 1; i < validatedItems.length; i++) {
    if (validatedItems[i].lineSubtotalCents > maxSubtotal) {
      maxSubtotal = validatedItems[i].lineSubtotalCents;
      L = i;
    }
  }

  let allocatedSumOthers = 0;
  const itemsWithAllocations = validatedItems.map((item, i) => {
    let allocatedAdjustmentCents;
    if (i !== L) {
      allocatedAdjustmentCents = subtotalCents === 0
        ? 0
        : roundHalfUp((netAdjustmentCents * item.lineSubtotalCents) / subtotalCents);
      allocatedSumOthers += allocatedAdjustmentCents;
    } else {
      allocatedAdjustmentCents = 0; // Se resolverá tras calcular todos los i !== L
    }
    return {
      ...item,
      allocatedAdjustmentCents,
    };
  });

  // El residuo/sobrante entero se adjudica forzosamente a la línea L
  const allocatedL = netAdjustmentCents - allocatedSumOthers;
  itemsWithAllocations[L].allocatedAdjustmentCents = allocatedL;

  // adjustedBase_i = lineSubtotal_i + allocated_i
  for (let i = 0; i < itemsWithAllocations.length; i++) {
    itemsWithAllocations[i].adjustedBaseCents =
      itemsWithAllocations[i].lineSubtotalCents + itemsWithAllocations[i].allocatedAdjustmentCents;
  }

  // 6. Comprobación del Invariante (Código de Producción): Σ adjustedBase_i === taxableBase
  const sumAdjustedBaseCents = itemsWithAllocations.reduce(
    (sum, item) => sum + item.adjustedBaseCents,
    0
  );

  if (sumAdjustedBaseCents !== taxableBaseCents) {
    throw new Error(
      `DOCUMENT_PRICING_INVARIANT_VIOLATION: Invariante falló. Σ adjustedBase (${sumAdjustedBaseCents}) !== taxableBase (${taxableBaseCents}).`
    );
  }

  // 7. Impuestos por línea sobre base ajustada en cascada
  let totalIceCents = 0;
  let totalIvaCents = 0;

  const finalItems = itemsWithAllocations.map((item) => {
    const { adjustedBaseCents, iceBp, ivaBp } = item;

    // ice_i = roundHalfUp(adjustedBase_i × iceBp_i / 10000) (el IVA NUNCA entra aquí)
    const iceAmountCents = roundHalfUp((adjustedBaseCents * iceBp) / 10000);

    // iva_i = iceIncludedInIvaBase ? roundHalfUp((adjustedBase_i + ice_i) × ivaBp_i / 10000)
    //                              : roundHalfUp(adjustedBase_i × ivaBp_i / 10000)
    const ivaBaseCents = iceIncludedInIvaBase ? (adjustedBaseCents + iceAmountCents) : adjustedBaseCents;
    const ivaAmountCents = roundHalfUp((ivaBaseCents * ivaBp) / 10000);

    // lineTotal_i = adjustedBase_i + ice_i + iva_i
    const lineTotalCents = adjustedBaseCents + iceAmountCents + ivaAmountCents;

    totalIceCents += iceAmountCents;
    totalIvaCents += ivaAmountCents;

    return {
      ...item,
      iceAmountCents,
      ivaAmountCents,
      lineTotalCents,
    };
  });

  // 8. totalIce = Σ ice_i · totalIva = Σ iva_i · total = taxableBase + totalIce + totalIva
  const totalCents = taxableBaseCents + totalIceCents + totalIvaCents;

  return {
    items: finalItems,
    adjustments: processedAdjustments,
    subtotalCents,
    totalDiscountCents,
    totalSurchargeCents,
    taxableBaseCents,
    netAdjustmentCents,
    totalIceCents,
    totalIvaCents,
    totalCents,
    iceIncludedInIvaBase,
  };
}

