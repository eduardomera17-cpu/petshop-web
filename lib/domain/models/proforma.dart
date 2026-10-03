// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: proforma.dart
// Propósito: Entidades inmutables de dominio para la emisión, cálculo y control de proformas y sus conceptos.
// =========================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'proforma.freezed.dart';
part 'proforma.g.dart';

/// Entidad inmutable de dominio que modela una línea o ítem liquidado en la proforma.
@freezed
class ProformaItem with _$ProformaItem {
  /// Constructor de fábrica inmutable para el concepto de proforma.
  const factory ProformaItem({
    /// Tipo de concepto liquidado ('SERVICE' para servicios prestados o 'PRODUCT' para venta de artículos).
    required String type,

    /// Identificador de referencia de la cita o del producto origen.
    required String referenceId,

    /// Identificador de la sub-línea en pedidos agrupados.
    String? refLineId,

    /// Descripción legible que aparecerá en el documento impreso o digital.
    required String title,

    /// Precio unitario base antes de tributos en centavos de dólar.
    required int basePriceCents,

    /// Tasa de ICE en puntos base.
    required int iceBp,

    /// Tasa de IVA en puntos base.
    required int ivaBp,

    /// Cantidad de unidades facturadas.
    required int quantity,

    /// Subtotal neto de la línea sin impuestos en centavos.
    required int subtotalCents,

    /// Monto liquidado de ICE en centavos.
    required int iceAmountCents,

    /// Monto liquidado de IVA en centavos.
    required int ivaAmountCents,

    /// Importe total de la línea con impuestos incluidos en centavos.
    required int totalCents,
  }) = _ProformaItem;

  /// Construye una instancia a partir de un mapa JSON.
  factory ProformaItem.fromJson(Map<String, dynamic> json) =>
      _$ProformaItemFromJson(json);
}

/// Entidad inmutable de dominio que modela el comprobante formal de Proforma.
///
/// Consolida servicios veterinarios y productos adquiridos, calculando subtotales,
/// descuentos, recargos y tributos conforme a la normativa fiscal del establecimiento.
@freezed
class Proforma with _$Proforma {
  /// Constructor de fábrica inmutable para la proforma completa.
  const factory Proforma({
    /// Identificador único de la proforma.
    required String id,

    /// Identificador del cliente receptor.
    required String clientId,

    /// Nombre del cliente congelado al formalizar la entrega.
    required String clientName,

    /// Lista de conceptos o ítems agregados a la proforma.
    @Default([]) List<ProformaItem> items,

    /// Valor monetario de descuentos aplicados en centavos.
    @Default(0) int discountsCents,

    /// Valor monetario de recargos aplicados en centavos.
    @Default(0) int surchargesCents,

    /// Subtotal imponible acumulado en centavos.
    @Default(0) int subtotalCents,

    /// Monto total liquidado por concepto de ICE en centavos.
    @Default(0) int iceTotalCents,

    /// Monto total liquidado por concepto de IVA en centavos.
    @Default(0) int ivaTotalCents,

    /// Total general a cancelar expresado en centavos de dólar.
    @Default(0) int totalCents,

    /// Estado actual de la proforma ('DRAFT', 'DELIVERED', 'FINALIZED', 'VOIDED').
    required String status,

    /// Fecha y hora de creación y emisión.
    required DateTime issuedAt,

    /// Fecha y hora de entrega formal al cliente.
    DateTime? deliveredAt,

    /// Fecha y hora de cobro y finalización.
    DateTime? finalizedAt,

    /// Fecha y hora de anulación, si corresponde.
    DateTime? voidedAt,

    /// Justificación registrada para la anulación del documento.
    String? voidReason,

    /// Ruta del archivo PDF oficial generado en Cloud Storage.
    String? pdfStoragePath,
  }) = _Proforma;

  /// Construye una instancia a partir de un mapa JSON.
  factory Proforma.fromJson(Map<String, dynamic> json) =>
      _$ProformaFromJson(json);
}
