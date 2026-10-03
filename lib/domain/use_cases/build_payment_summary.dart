// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/domain/use_cases/build_payment_summary.dart
// Propósito: Caso de uso de dominio para consolidar la liquidación tributaria y el desglose de importes a pagar con IVA e ICE normativos.
// =========================================================================

import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/domain/models/proforma.dart';

/// {@template build_payment_summary_use_case}
/// Caso de uso centralizado para la liquidación del resumen de pago del cliente.
///
/// Transforma la lista de [ProformaItem] en entradas de cálculo documental [DocumentPricingItemInput]
/// y aplica el motor tributario [calculateDocumentPricing], considerando la configuración
/// vigente de inclusión del ICE en la base imponible del IVA.
/// {@endtemplate}
class BuildPaymentSummaryUseCase {
  /// Constructor constante del caso de uso de resumen de pago.
  const BuildPaymentSummaryUseCase();

  /// Ejecuta el cálculo y genera el [DocumentPricingResult] con bases imponibles y tributos discriminados.
  DocumentPricingResult execute({
    required List<ProformaItem> items,
    List<DocumentAdjustmentInput> adjustments = const [],
    required PublicPricingConfig pricingConfig,
  }) {
    if (items.isEmpty) {
      return DocumentPricingResult(
        items: const [],
        adjustments: const [],
        subtotalCents: 0,
        totalDiscountCents: 0,
        totalSurchargeCents: 0,
        taxableBaseCents: 0,
        netAdjustmentCents: 0,
        totalIceCents: 0,
        totalIvaCents: 0,
        totalCents: 0,
        iceIncludedInIvaBase: pricingConfig.iceIncludedInIvaBase,
      );
    }

    final inputs = items.map((item) {
      return DocumentPricingItemInput(
        id: item.referenceId,
        quantity: item.quantity,
        unitBasePriceCents: item.basePriceCents,
        iceBp: item.iceBp,
        ivaBp: item.ivaBp,
      );
    }).toList();

    return calculateDocumentPricing(
      items: inputs,
      adjustments: adjustments,
      iceIncludedInIvaBase: pricingConfig.iceIncludedInIvaBase,
    );
  }
}
