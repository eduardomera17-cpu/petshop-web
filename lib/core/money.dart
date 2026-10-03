// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/money.dart
// Propósito: Motor de cálculo monetario normativo en aritmética de enteros (centavos de dólar), redondeo medio-arriba y liquidación tributaria (IVA e ICE).
// =========================================================================

import 'package:flutter/foundation.dart';

/// Redondeo matemático al entero más próximo con medio punto hacia arriba (half-up).
///
/// En concordancia matemática estricta con el motor backend:
/// `roundHalfUp(x) = (x + 0.5).floor()`, consistente para valores positivos y negativos.
int roundHalfUp(num x) {
  return (x + 0.5).floor();
}

/// Convierte un importe decimal en dólares a céntimos enteros con redondeo medio-arriba.
///
/// Queda terminantemente prohibido el uso de `double` o punto flotante para almacenar
/// o transferir importes monetarios en modelos, DTOs o documentos de Firestore (D-T2).
int toCents(num amount) {
  return roundHalfUp(amount * 100);
}

/// Formatea un importe entero en céntimos a una cadena estándar con dos decimales (ej. 8280 -> "82.80").
String formatCents(int cents) {
  final isNegative = cents < 0;
  final absCents = cents.abs();
  final dollars = absCents ~/ 100;
  final remainder = absCents % 100;
  final formatted = '$dollars.${remainder.toString().padLeft(2, '0')}';
  return isNegative ? '-$formatted' : formatted;
}

/// Calcula el importe de impuesto sobre una base en céntimos dado el porcentaje en puntos básicos (1% = 100 bp).
int calculateTax(int baseCents, int taxBp) {
  return roundHalfUp((baseCents * taxBp) / 10000);
}

/// {@template line_pricing_result}
/// Resultado inmutable del desglose impositivo y precio final para una línea individual de producto o servicio.
/// {@endtemplate}
@immutable
class LinePricingResult {
  /// Precio base sin tributos en centavos de dólar.
  final int basePriceCents;

  /// Tarifa de Impuesto a los Consumos Especiales en puntos básicos (1% = 100 bp).
  final int iceBp;

  /// Tarifa de Impuesto al Valor Agregado en puntos básicos (1% = 100 bp).
  final int ivaBp;

  /// Importe calculado de ICE en centavos de dólar.
  final int iceAmountCents;

  /// Importe calculado de IVA en centavos de dólar.
  final int ivaAmountCents;

  /// Precio final de la línea con todos los impuestos incluidos en centavos.
  final int finalPriceCents;

  const LinePricingResult({
    required this.basePriceCents,
    required this.iceBp,
    required this.ivaBp,
    required this.iceAmountCents,
    required this.ivaAmountCents,
    required this.finalPriceCents,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinePricingResult &&
          runtimeType == other.runtimeType &&
          basePriceCents == other.basePriceCents &&
          iceBp == other.iceBp &&
          ivaBp == other.ivaBp &&
          iceAmountCents == other.iceAmountCents &&
          ivaAmountCents == other.ivaAmountCents &&
          finalPriceCents == other.finalPriceCents;

  @override
  int get hashCode => Object.hash(
        basePriceCents,
        iceBp,
        ivaBp,
        iceAmountCents,
        ivaAmountCents,
        finalPriceCents,
      );

  @override
  String toString() =>
      'LinePricingResult(basePriceCents: $basePriceCents, iceBp: $iceBp, ivaBp: $ivaBp, '
      'iceAmountCents: $iceAmountCents, ivaAmountCents: $ivaAmountCents, finalPriceCents: $finalPriceCents)';
}

/// Calcula el desglose impositivo y precio final para una línea individual en cascada normativa (ADR-001, TRD §3.3.A).
///
/// El IVA nunca forma parte de la base imponible del ICE.
/// Si [iceIncludedInIvaBase] es `true`, la base del IVA se incrementa con el valor del ICE calculado.
LinePricingResult calculateLinePricing({
  required int basePriceCents,
  int iceBp = 0,
  int ivaBp = 0,
  bool iceIncludedInIvaBase = true,
}) {
  if (basePriceCents < 0) {
    throw ArgumentError.value(
      basePriceCents,
      'basePriceCents',
      'El precio base en céntimos debe ser no negativo.',
    );
  }
  if (iceBp < 0) {
    throw ArgumentError.value(
      iceBp,
      'iceBp',
      'El ICE en puntos básicos debe ser no negativo.',
    );
  }
  if (ivaBp < 0) {
    throw ArgumentError.value(
      ivaBp,
      'ivaBp',
      'El IVA en puntos básicos debe ser no negativo.',
    );
  }

  final iceAmountCents = roundHalfUp((basePriceCents * iceBp) / 10000);
  final ivaBase = iceIncludedInIvaBase
      ? (basePriceCents + iceAmountCents)
      : basePriceCents;
  final ivaAmountCents = roundHalfUp((ivaBase * ivaBp) / 10000);
  final finalPriceCents = basePriceCents + iceAmountCents + ivaAmountCents;

  return LinePricingResult(
    basePriceCents: basePriceCents,
    iceBp: iceBp,
    ivaBp: ivaBp,
    iceAmountCents: iceAmountCents,
    ivaAmountCents: ivaAmountCents,
    finalPriceCents: finalPriceCents,
  );
}

/// {@template document_pricing_item_input}
/// Estructura de entrada inmutable para el cálculo documental de una línea de producto o servicio.
/// {@endtemplate}
@immutable
class DocumentPricingItemInput {
  /// Identificador de referencia opcional del ítem.
  final String? id;

  /// Cantidad de unidades (por defecto 1).
  final int quantity;

  /// Precio base unitario en centavos de dólar.
  final int unitBasePriceCents;

  /// Puntos básicos de ICE aplicables al ítem.
  final int iceBp;

  /// Puntos básicos de IVA aplicables al ítem.
  final int ivaBp;

  const DocumentPricingItemInput({
    this.id,
    this.quantity = 1,
    required this.unitBasePriceCents,
    this.iceBp = 0,
    this.ivaBp = 0,
  });
}

/// {@template document_pricing_item_result}
/// Resultado del cálculo y desglose impositivo de una línea dentro del documento proforma.
///
/// Refleja la asignación proporcional de ajustes (descuentos o recargos), la base ajustada resultante
/// y los valores finales de ICE e IVA liquidados.
/// {@endtemplate}
@immutable
class DocumentPricingItemResult {
  /// Identificador del ítem.
  final String? id;

  /// Cantidad facturada.
  final int quantity;

  /// Precio unitario base en centavos.
  final int unitBasePriceCents;

  /// Subtotal de la línea (cantidad * unitBasePriceCents) antes de ajustes e impuestos.
  final int lineSubtotalCents;

  /// Monto de ajuste global asignado proporcionalmente a esta línea en centavos.
  final int allocatedAdjustmentCents;

  /// Base imponible ajustada después de aplicar la prorrata de descuentos o recargos.
  final int adjustedBaseCents;

  /// Tarifa de ICE en puntos básicos.
  final int iceBp;

  /// Monto calculado de ICE en centavos.
  final int iceAmountCents;

  /// Tarifa de IVA en puntos básicos.
  final int ivaBp;

  /// Monto calculado de IVA en centavos.
  final int ivaAmountCents;

  /// Total final de la línea en centavos (base ajustada + ICE + IVA).
  final int lineTotalCents;

  const DocumentPricingItemResult({
    this.id,
    required this.quantity,
    required this.unitBasePriceCents,
    required this.lineSubtotalCents,
    required this.allocatedAdjustmentCents,
    required this.adjustedBaseCents,
    required this.iceBp,
    required this.iceAmountCents,
    required this.ivaBp,
    required this.ivaAmountCents,
    required this.lineTotalCents,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentPricingItemResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          quantity == other.quantity &&
          unitBasePriceCents == other.unitBasePriceCents &&
          lineSubtotalCents == other.lineSubtotalCents &&
          allocatedAdjustmentCents == other.allocatedAdjustmentCents &&
          adjustedBaseCents == other.adjustedBaseCents &&
          iceBp == other.iceBp &&
          iceAmountCents == other.iceAmountCents &&
          ivaBp == other.ivaBp &&
          ivaAmountCents == other.ivaAmountCents &&
          lineTotalCents == other.lineTotalCents;

  @override
  int get hashCode => Object.hash(
        id,
        quantity,
        unitBasePriceCents,
        lineSubtotalCents,
        allocatedAdjustmentCents,
        adjustedBaseCents,
        iceBp,
        iceAmountCents,
        ivaBp,
        ivaAmountCents,
        lineTotalCents,
      );
}

/// {@template document_adjustment_input}
/// Parámetro de entrada inmutable para un ajuste general (descuento o recargo) sobre el documento.
/// {@endtemplate}
@immutable
class DocumentAdjustmentInput {
  /// Identificador opcional del ajuste.
  final String? id;

  /// Tipo de ajuste: 'DISCOUNT' para descuento comercial o 'SURCHARGE' para recargo/propina.
  final String type;

  /// Concepto o motivo descriptivo del ajuste.
  final String? concept;

  /// Porcentaje de ajuste expresado en puntos básicos (opcional si se especifica amountCents).
  final int? percentBp;

  /// Monto fijo de ajuste en centavos de dólar (opcional si se especifica percentBp).
  final int? amountCents;

  const DocumentAdjustmentInput({
    this.id,
    required this.type,
    this.concept,
    this.percentBp,
    this.amountCents,
  });
}

/// {@template document_adjustment_result}
/// Resultado procesado de una línea de ajuste de documento con su importe definitivo en centavos.
/// {@endtemplate}
@immutable
class DocumentAdjustmentResult {
  /// Identificador del ajuste.
  final String? id;

  /// Tipo de ajuste ('DISCOUNT' o 'SURCHARGE').
  final String type;

  /// Concepto o motivo descriptivo.
  final String? concept;

  /// Porcentaje aplicado en puntos básicos si fue definido de forma porcentual.
  final int? percentBp;

  /// Monto final liquidado del ajuste en centavos de dólar.
  final int amountCents;

  const DocumentAdjustmentResult({
    this.id,
    required this.type,
    this.concept,
    this.percentBp,
    required this.amountCents,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentAdjustmentResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          concept == other.concept &&
          percentBp == other.percentBp &&
          amountCents == other.amountCents;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        concept,
        percentBp,
        amountCents,
      );
}

/// {@template document_pricing_result}
/// Resultado inmutable del desglose impositivo y de ajustes a nivel de documento completo.
///
/// Consolida las líneas de ítems, ajustes procesados, base imponible global (taxableBaseCents),
/// acumulados de impuestos y total final liquidado.
/// {@endtemplate}
@immutable
class DocumentPricingResult {
  /// Lista de líneas de ítems calculadas con sus bases ajustadas y tributos individuales.
  final List<DocumentPricingItemResult> items;

  /// Lista de ajustes globales procesados.
  final List<DocumentAdjustmentResult> adjustments;

  /// Subtotal base previo a descuentos y recargos en centavos.
  final int subtotalCents;

  /// Total acumulado de descuentos en centavos.
  final int totalDiscountCents;

  /// Total acumulado de recargos en centavos.
  final int totalSurchargeCents;

  /// Base imponible global sujeta a tributación en centavos (subtotal - descuentos + recargos).
  final int taxableBaseCents;

  /// Ajuste neto con signo en centavos (recargos - descuentos).
  final int netAdjustmentCents;

  /// Total acumulado de ICE en centavos.
  final int totalIceCents;

  /// Total acumulado de IVA en centavos.
  final int totalIvaCents;

  /// Importe total definitivo del documento en centavos.
  final int totalCents;

  /// Indica si el ICE se integró en la base imponible del IVA.
  final bool iceIncludedInIvaBase;

  const DocumentPricingResult({
    required this.items,
    required this.adjustments,
    required this.subtotalCents,
    required this.totalDiscountCents,
    required this.totalSurchargeCents,
    required this.taxableBaseCents,
    required this.netAdjustmentCents,
    required this.totalIceCents,
    required this.totalIvaCents,
    required this.totalCents,
    required this.iceIncludedInIvaBase,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentPricingResult &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          listEquals(adjustments, other.adjustments) &&
          subtotalCents == other.subtotalCents &&
          totalDiscountCents == other.totalDiscountCents &&
          totalSurchargeCents == other.totalSurchargeCents &&
          taxableBaseCents == other.taxableBaseCents &&
          netAdjustmentCents == other.netAdjustmentCents &&
          totalIceCents == other.totalIceCents &&
          totalIvaCents == other.totalIvaCents &&
          totalCents == other.totalCents &&
          iceIncludedInIvaBase == other.iceIncludedInIvaBase;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        Object.hashAll(adjustments),
        subtotalCents,
        totalDiscountCents,
        totalSurchargeCents,
        taxableBaseCents,
        netAdjustmentCents,
        totalIceCents,
        totalIvaCents,
        totalCents,
        iceIncludedInIvaBase,
      );
}

/// Calcula los importes normativos completos de una proforma o documento en aritmética entera (TRD §3.3.A, FA-09).
///
/// Ejecuta la liquidación tributaria ecuatoriana con las siguientes fases:
/// 1. Validación de cantidades y bases imponibles no negativas.
/// 2. Procesamiento de ajustes porcentuales y fijos (descuentos y recargos).
/// 3. Determinación de la base imponible global `taxableBaseCents`.
/// 4. Prorrata proporcional de ajustes entre las líneas, asignando el residuo/sobrante
///    por redondeo entero forzosamente a la línea de mayor importe (L) para garantizar
///    el invariante contable: `Σ adjustedBase_i == taxableBaseCents`.
/// 5. Liquidación en cascada de ICE e IVA por cada línea según sus puntos básicos.
/// 6. Consolidación de totales generales del documento.
DocumentPricingResult calculateDocumentPricing({
  required List<DocumentPricingItemInput> items,
  List<DocumentAdjustmentInput> adjustments = const [],
  bool iceIncludedInIvaBase = true,
}) {
  if (items.isEmpty) {
    throw ArgumentError.value(items, 'items', 'La lista de ítems no puede estar vacía.');
  }

  // 1. Validar líneas y calcular subtotal = Σ (quantity_i * unitBasePriceCents_i)
  int subtotalCents = 0;
  final List<DocumentPricingItemResult> initialItems = [];

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item.quantity <= 0) {
      throw ArgumentError.value(
        item.quantity,
        'items[$i].quantity',
        'La cantidad debe ser un entero positivo.',
      );
    }
    if (item.unitBasePriceCents < 0) {
      throw ArgumentError.value(
        item.unitBasePriceCents,
        'items[$i].unitBasePriceCents',
        'El precio unitario base en céntimos debe ser no negativo.',
      );
    }
    if (item.iceBp < 0) {
      throw ArgumentError.value(
        item.iceBp,
        'items[$i].iceBp',
        'El ICE en puntos básicos debe ser no negativo.',
      );
    }
    if (item.ivaBp < 0) {
      throw ArgumentError.value(
        item.ivaBp,
        'items[$i].ivaBp',
        'El IVA en puntos básicos debe ser no negativo.',
      );
    }

    final lineSubtotalCents = item.quantity * item.unitBasePriceCents;
    subtotalCents += lineSubtotalCents;

    initialItems.add(
      DocumentPricingItemResult(
        id: item.id,
        quantity: item.quantity,
        unitBasePriceCents: item.unitBasePriceCents,
        lineSubtotalCents: lineSubtotalCents,
        allocatedAdjustmentCents: 0,
        adjustedBaseCents: lineSubtotalCents,
        iceBp: item.iceBp,
        iceAmountCents: 0,
        ivaBp: item.ivaBp,
        ivaAmountCents: 0,
        lineTotalCents: lineSubtotalCents,
      ),
    );
  }

  // 2. Procesar ajustes de documento (DISCOUNT y SURCHARGE)
  int totalDiscountCents = 0;
  int totalSurchargeCents = 0;
  final List<DocumentAdjustmentResult> processedAdjustments = [];

  for (int i = 0; i < adjustments.length; i++) {
    final adj = adjustments[i];
    if (adj.type != 'DISCOUNT' && adj.type != 'SURCHARGE') {
      throw ArgumentError.value(
        adj.type,
        'adjustments[$i].type',
        "El tipo de ajuste debe ser 'DISCOUNT' o 'SURCHARGE'.",
      );
    }

    int calculatedAmountCents;
    if (adj.percentBp != null) {
      final percentBp = adj.percentBp!;
      if (percentBp < 0 || percentBp > 10000) {
        throw ArgumentError.value(
          percentBp,
          'adjustments[$i].percentBp',
          'El porcentaje en puntos básicos debe estar entre 0 y 10000.',
        );
      }
      calculatedAmountCents = roundHalfUp((subtotalCents * percentBp) / 10000);
    } else {
      final amountCents = adj.amountCents ?? 0;
      if (amountCents < 0) {
        throw ArgumentError.value(
          amountCents,
          'adjustments[$i].amountCents',
          'El importe en céntimos debe ser no negativo.',
        );
      }
      calculatedAmountCents = amountCents;
    }

    if (adj.type == 'DISCOUNT') {
      totalDiscountCents += calculatedAmountCents;
    } else {
      totalSurchargeCents += calculatedAmountCents;
    }

    processedAdjustments.add(
      DocumentAdjustmentResult(
        id: adj.id,
        type: adj.type,
        concept: adj.concept,
        percentBp: adj.percentBp,
        amountCents: calculatedAmountCents,
      ),
    );
  }

  // 3. Base imponible del documento
  final taxableBaseCents = subtotalCents - totalDiscountCents + totalSurchargeCents;

  // 4. Ajuste neto con signo
  final netAdjustmentCents = totalSurchargeCents - totalDiscountCents;

  // 5. Reparto proporcional y asignación del sobrante a la línea L de mayor importe
  int lIndex = 0;
  int maxSubtotal = initialItems[0].lineSubtotalCents;
  for (int i = 1; i < initialItems.length; i++) {
    if (initialItems[i].lineSubtotalCents > maxSubtotal) {
      maxSubtotal = initialItems[i].lineSubtotalCents;
      lIndex = i;
    }
  }

  int allocatedSumOthers = 0;
  final List<int> allocations = List<int>.filled(initialItems.length, 0);

  for (int i = 0; i < initialItems.length; i++) {
    if (i != lIndex) {
      final allocated = subtotalCents == 0
          ? 0
          : roundHalfUp((netAdjustmentCents * initialItems[i].lineSubtotalCents) / subtotalCents);
      allocations[i] = allocated;
      allocatedSumOthers += allocated;
    }
  }

  // El residuo/sobrante entero se adjudica forzosamente a la línea L
  allocations[lIndex] = netAdjustmentCents - allocatedSumOthers;

  // 6. Comprobación del Invariante (Código de Producción): Σ adjustedBase_i == taxableBase
  int sumAdjustedBaseCents = 0;
  final List<int> adjustedBases = List<int>.filled(initialItems.length, 0);
  for (int i = 0; i < initialItems.length; i++) {
    adjustedBases[i] = initialItems[i].lineSubtotalCents + allocations[i];
    sumAdjustedBaseCents += adjustedBases[i];
  }

  if (sumAdjustedBaseCents != taxableBaseCents) {
    throw StateError(
      'DOCUMENT_PRICING_INVARIANT_VIOLATION: Invariante falló. '
      'Σ adjustedBase ($sumAdjustedBaseCents) != taxableBase ($taxableBaseCents).',
    );
  }

  // 7. Impuestos por línea sobre base ajustada en cascada
  int totalIceCents = 0;
  int totalIvaCents = 0;
  final List<DocumentPricingItemResult> finalItems = [];

  for (int i = 0; i < initialItems.length; i++) {
    final item = initialItems[i];
    final adjustedBase = adjustedBases[i];
    final allocated = allocations[i];

    // ice_i = roundHalfUp(adjustedBase_i × iceBp_i / 10000)
    final iceAmountCents = roundHalfUp((adjustedBase * item.iceBp) / 10000);

    // iva_i = iceIncludedInIvaBase ? roundHalfUp((adjustedBase_i + ice_i) × ivaBp_i / 10000)
    //                              : roundHalfUp(adjustedBase_i × ivaBp_i / 10000)
    final ivaBaseCents = iceIncludedInIvaBase ? (adjustedBase + iceAmountCents) : adjustedBase;
    final ivaAmountCents = roundHalfUp((ivaBaseCents * item.ivaBp) / 10000);

    final lineTotalCents = adjustedBase + iceAmountCents + ivaAmountCents;

    totalIceCents += iceAmountCents;
    totalIvaCents += ivaAmountCents;

    finalItems.add(
      DocumentPricingItemResult(
        id: item.id,
        quantity: item.quantity,
        unitBasePriceCents: item.unitBasePriceCents,
        lineSubtotalCents: item.lineSubtotalCents,
        allocatedAdjustmentCents: allocated,
        adjustedBaseCents: adjustedBase,
        iceBp: item.iceBp,
        iceAmountCents: iceAmountCents,
        ivaBp: item.ivaBp,
        ivaAmountCents: ivaAmountCents,
        lineTotalCents: lineTotalCents,
      ),
    );
  }

  // 8. totalIce = Σ ice_i · totalIva = Σ iva_i · total = taxableBase + totalIce + totalIva
  final totalCents = taxableBaseCents + totalIceCents + totalIvaCents;

  return DocumentPricingResult(
    items: finalItems,
    adjustments: processedAdjustments,
    subtotalCents: subtotalCents,
    totalDiscountCents: totalDiscountCents,
    totalSurchargeCents: totalSurchargeCents,
    taxableBaseCents: taxableBaseCents,
    netAdjustmentCents: netAdjustmentCents,
    totalIceCents: totalIceCents,
    totalIvaCents: totalIvaCents,
    totalCents: totalCents,
    iceIncludedInIvaBase: iceIncludedInIvaBase,
  );
}

