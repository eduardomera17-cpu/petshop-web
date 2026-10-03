// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: proforma_dto.dart
// Propósito: DTO para la emisión, liquidación y auditoría de proformas y comprobantes en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mipetshop/domain/models/proforma.dart';

part 'proforma_dto.g.dart';

/// Convertidor para marcas de tiempo [Timestamp] no nulas en [DateTime].
class _TimestampConverter implements JsonConverter<DateTime, Object> {
  const _TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Object toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Convertidor para marcas de tiempo [Timestamp] opcionales en [DateTime].
class _NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const _NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.parse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? object) =>
      object != null ? Timestamp.fromDate(object) : null;
}

/// DTO que representa un ítem o concepto individual liquidado dentro de una proforma.
@JsonSerializable(explicitToJson: true)
class ProformaItemDto {
  /// Tipo de ítem liquidado ('SERVICE' o 'PRODUCT').
  @JsonKey(name: 'itemType')
  final String type;

  /// Identificador de referencia de la cita o del producto asociado.
  @JsonKey(name: 'refId')
  final String referenceId;

  /// Identificador de la línea específica en caso de pedidos multi-producto.
  final String? refLineId;

  /// Descripción o concepto comercial impreso en el comprobante.
  @JsonKey(name: 'concept')
  final String title;

  /// Precio unitario base sin impuestos expresado en centavos de dólar.
  @JsonKey(name: 'unitBasePriceCents')
  final int basePriceCents;

  /// Puntos base del Impuesto a los Consumos Especiales (ICE).
  final int iceBp;

  /// Puntos base del Impuesto al Valor Agregado (IVA).
  final int ivaBp;

  /// Cantidad facturada de este concepto.
  final int quantity;

  /// Subtotal de la línea sin impuestos expresado en centavos.
  @JsonKey(name: 'lineSubtotalCents')
  final int subtotalCents;

  /// Monto liquidado de ICE para esta línea en centavos.
  final int iceAmountCents;

  /// Monto liquidado de IVA para esta línea en centavos.
  final int ivaAmountCents;

  /// Total final acumulado de la línea con impuestos en centavos.
  @JsonKey(name: 'lineTotalCents')
  final int totalCents;

  /// Constructor inmutable para el ítem de proforma.
  const ProformaItemDto({
    required this.type,
    required this.referenceId,
    this.refLineId,
    required this.title,
    required this.basePriceCents,
    required this.iceBp,
    required this.ivaBp,
    required this.quantity,
    required this.subtotalCents,
    required this.iceAmountCents,
    required this.ivaAmountCents,
    required this.totalCents,
  });

  /// Deserializa la línea desde un mapa JSON.
  factory ProformaItemDto.fromJson(Map<String, dynamic> json) =>
      _$ProformaItemDtoFromJson(json);

  /// Serializa la línea a formato JSON.
  Map<String, dynamic> toJson() => _$ProformaItemDtoToJson(this);

  /// Mapea este DTO a la entidad de dominio puro [ProformaItem].
  ProformaItem toDomain() {
    return ProformaItem(
      type: type,
      referenceId: referenceId,
      refLineId: refLineId,
      title: title,
      basePriceCents: basePriceCents,
      iceBp: iceBp,
      ivaBp: ivaBp,
      quantity: quantity,
      subtotalCents: subtotalCents,
      iceAmountCents: iceAmountCents,
      ivaAmountCents: ivaAmountCents,
      totalCents: totalCents,
    );
  }

  /// Construye un [ProformaItemDto] a partir de la entidad [ProformaItem].
  factory ProformaItemDto.fromDomain(ProformaItem domain) {
    return ProformaItemDto(
      type: domain.type,
      referenceId: domain.referenceId,
      refLineId: domain.refLineId,
      title: domain.title,
      basePriceCents: domain.basePriceCents,
      iceBp: domain.iceBp,
      ivaBp: domain.ivaBp,
      quantity: domain.quantity,
      subtotalCents: domain.subtotalCents,
      iceAmountCents: domain.iceAmountCents,
      ivaAmountCents: domain.ivaAmountCents,
      totalCents: domain.totalCents,
    );
  }
}

/// Objeto de Transferencia de Datos (DTO) para el documento de Proforma.
///
/// Modela los documentos almacenados en la colección `/proformas` de Cloud Firestore,
/// gestionando totales financieros en centavos, desglose de impuestos, control
/// de estados (borrador, entregada, finalizada, anulada) y enlace al PDF emitido.
@JsonSerializable(explicitToJson: true)
class ProformaDto {
  /// Identificador único del documento de la proforma en Firestore.
  final String? id;

  /// Identificador del cliente al que se emite la proforma.
  final String clientId;

  /// Nombre del cliente congelado tras la formalización de entrega.
  final String clientName;

  /// Colección de conceptos detallados facturados en la proforma.
  @JsonKey(defaultValue: [])
  final List<ProformaItemDto> items;

  /// Total de descuentos aplicados en centavos.
  @JsonKey(name: 'totalDiscountCents', defaultValue: 0)
  final int discountsCents;

  /// Total de recargos aplicados en centavos.
  @JsonKey(name: 'totalSurchargeCents', defaultValue: 0)
  final int surchargesCents;

  /// Subtotal neto acumulado sin tributos en centavos.
  @JsonKey(defaultValue: 0)
  final int subtotalCents;

  /// Monto total liquidado por concepto de ICE en centavos.
  @JsonKey(name: 'totalIceCents', defaultValue: 0)
  final int iceTotalCents;

  /// Monto total liquidado por concepto de IVA en centavos.
  @JsonKey(name: 'totalIvaCents', defaultValue: 0)
  final int ivaTotalCents;

  /// Monto final total a pagar expresado en centavos de dólar.
  @JsonKey(defaultValue: 0)
  final int totalCents;

  /// Estado actual del comprobante ('DRAFT', 'DELIVERED', 'FINALIZED', 'VOIDED').
  final String status;

  /// Fecha y hora oficial de emisión del comprobante.
  @JsonKey(name: 'createdAt')
  @_TimestampConverter()
  final DateTime issuedAt;

  /// Fecha y hora en que se efectuó la entrega formal al cliente.
  @_NullableTimestampConverter()
  final DateTime? deliveredAt;

  /// Fecha y hora en que se finalizó o pagó la proforma.
  @_NullableTimestampConverter()
  final DateTime? finalizedAt;

  /// Fecha y hora en caso de haber sido anulada.
  @_NullableTimestampConverter()
  final DateTime? voidedAt;

  /// Motivo formal registrado para la anulación de la proforma.
  final String? voidReason;

  /// Ruta del archivo PDF generado y alojado en Firebase Cloud Storage.
  @JsonKey(name: 'pdfPath')
  final String? pdfStoragePath;

  /// Constructor inmutable de la proforma.
  const ProformaDto({
    this.id,
    required this.clientId,
    required this.clientName,
    this.items = const [],
    this.discountsCents = 0,
    this.surchargesCents = 0,
    this.subtotalCents = 0,
    this.iceTotalCents = 0,
    this.ivaTotalCents = 0,
    this.totalCents = 0,
    required this.status,
    required this.issuedAt,
    this.deliveredAt,
    this.finalizedAt,
    this.voidedAt,
    this.voidReason,
    this.pdfStoragePath,
  });

  /// Deserializa un mapa JSON garantizando la normalización del nombre del cliente desde la instantánea legal.
  factory ProformaDto.fromJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    final snapshot = normalized['clientSnapshot'];
    final fullName = snapshot is Map ? snapshot['fullName'] : null;
    normalized['clientName'] = fullName is String ? fullName : '';
    return _$ProformaDtoFromJson(normalized);
  }

  /// Serializa la proforma a formato JSON.
  Map<String, dynamic> toJson() => _$ProformaDtoToJson(this);

  /// Construye un [ProformaDto] a partir de un [DocumentSnapshot] de Cloud Firestore.
  factory ProformaDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final mapped = Map<String, dynamic>.from(data);
    mapped['id'] = doc.id;
    return ProformaDto.fromJson(mapped);
  }

  /// Mapea la instancia a un mapa apto para persistencia en Firestore excluyendo el 'id'.
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  /// Construye una instancia de [ProformaDto] desde la entidad de dominio [Proforma].
  factory ProformaDto.fromDomain(Proforma domain) {
    return ProformaDto(
      id: domain.id,
      clientId: domain.clientId,
      clientName: domain.clientName,
      items: domain.items.map((i) => ProformaItemDto.fromDomain(i)).toList(),
      discountsCents: domain.discountsCents,
      surchargesCents: domain.surchargesCents,
      subtotalCents: domain.subtotalCents,
      iceTotalCents: domain.iceTotalCents,
      ivaTotalCents: domain.ivaTotalCents,
      totalCents: domain.totalCents,
      status: domain.status,
      issuedAt: domain.issuedAt,
      deliveredAt: domain.deliveredAt,
      finalizedAt: domain.finalizedAt,
      voidedAt: domain.voidedAt,
      voidReason: domain.voidReason,
      pdfStoragePath: domain.pdfStoragePath,
    );
  }

  /// Convierte este DTO en la entidad de dominio puro [Proforma].
  Proforma toDomain() {
    return Proforma(
      id: id ?? '',
      clientId: clientId,
      clientName: clientName,
      items: items.map((i) => i.toDomain()).toList(),
      discountsCents: discountsCents,
      surchargesCents: surchargesCents,
      subtotalCents: subtotalCents,
      iceTotalCents: iceTotalCents,
      ivaTotalCents: ivaTotalCents,
      totalCents: totalCents,
      status: status,
      issuedAt: issuedAt,
      deliveredAt: deliveredAt,
      finalizedAt: finalizedAt,
      voidedAt: voidedAt,
      voidReason: voidReason,
      pdfStoragePath: pdfStoragePath,
    );
  }
}
