// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/domain/use_cases/preview_proforma_pricing.dart
// Propósito: Caso de uso de dominio para previsualizar en tiempo real el desglose tributario, ajustes y totales de proformas administrativas.
// =========================================================================

import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';

/// {@template preview_proforma_pricing_use_case}
/// Caso de uso para la simulación y previsualización de precios y tributos en proformas.
///
/// Permite al módulo administrativo calcular en pantalla los totales de bases imponibles,
/// ICE, IVA, descuentos y recargos antes de persistir o emitir el documento proforma.
/// {@endtemplate}
class PreviewProformaPricingUseCase {
  /// Constructor constante del caso de uso de previsualización de precios.
  const PreviewProformaPricingUseCase();

  /// Ejecuta la previsualización tributaria para la lista de ítems y ajustes suministrados.
  DocumentPricingResult execute({
    required List<DocumentPricingItemInput> items,
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

    return calculateDocumentPricing(
      items: items,
      adjustments: adjustments,
      iceIncludedInIvaBase: pricingConfig.iceIncludedInIvaBase,
    );
  }
}
