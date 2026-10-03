// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: billing_parameters_dto.dart
// Propósito: DTO para la persistencia y lectura de parámetros de configuración fiscal y facturación en Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mipetshop/domain/models/billing_parameters.dart';

part 'billing_parameters_dto.g.dart';

/// Objeto de Transferencia de Datos (DTO) para los parámetros de facturación del Petshop.
///
/// Gestiona la configuración tributaria institucional (RUC, razón social, IVA, ICE)
/// y la secuencia de emisión de proformas almacenada en Cloud Firestore.
@JsonSerializable(explicitToJson: true)
class BillingParametersDto {
  /// Razón social o nombre legal del establecimiento comercial.
  final String businessName;

  /// Número de identificación tributaria (RUC / Cédula) del Petshop.
  final String taxId;

  /// Dirección física principal del establecimiento.
  final String address;

  /// Teléfono de contacto oficial para fines de emisión y comprobantes.
  final String phone;

  /// Serie o prefijo alfanumérico para la emisión secuencial de proformas.
  final String proformaSeries;

  /// Porcentaje de Impuesto al Valor Agregado (IVA) expresado en puntos base (ej. 1500 = 15%).
  final int ivaBp;

  /// Determina si el Impuesto a los Consumos Especiales (ICE) se suma a la base imponible del IVA.
  final bool iceIncludedInIvaBase;

  /// Ruta o URL del logotipo del establecimiento comercial para la impresión de proformas.
  final String? logoPath;

  /// Siguiente número secuencial disponible para la generación de proformas.
  final int? nextProformaNumber;

  /// Indicador de bloqueo temporal por proceso de entrega/emisión en curso.
  final bool? deliveryLock;

  /// Constructor inmutable para inicializar la configuración fiscal.
  const BillingParametersDto({
    required this.businessName,
    required this.taxId,
    required this.address,
    required this.phone,
    required this.proformaSeries,
    required this.ivaBp,
    required this.iceIncludedInIvaBase,
    this.logoPath,
    this.nextProformaNumber,
    this.deliveryLock,
  });

  /// Construye un [BillingParametersDto] desde un mapa en formato JSON.
  factory BillingParametersDto.fromJson(Map<String, dynamic> json) =>
      _$BillingParametersDtoFromJson(json);

  /// Serializa la instancia a un mapa en formato JSON.
  Map<String, dynamic> toJson() => _$BillingParametersDtoToJson(this);

  /// Construye el DTO a partir de un [DocumentSnapshot] obtenido de Cloud Firestore.
  ///
  /// Normaliza el campo `deliveryLock` para garantizar compatibilidad con mapas complejos
  /// persistidos en la base de datos sin romper la deserialización tipada.
  factory BillingParametersDto.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BillingParametersDto.fromJson({
      ...data,
      'deliveryLock': _normalizeDeliveryLock(data['deliveryLock']),
    });
  }

  /// Normaliza el valor de `deliveryLock`.
  ///
  /// En Firestore el arriendo de entrega puede guardarse como un mapa o un valor nulo.
  /// Esta función garantiza que se convierta de forma segura en un booleano sin generar excepciones.
  static bool? _normalizeDeliveryLock(Object? raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is Map) return raw['proformaId'] != null || raw['leaseId'] != null;
    return null;
  }

  /// Mapea este DTO a la entidad de dominio puro [BillingParameters].
  BillingParameters toDomain() {
    return BillingParameters(
      businessName: businessName,
      taxId: taxId,
      address: address,
      phone: phone,
      proformaSeries: proformaSeries,
      ivaBp: ivaBp,
      iceIncludedInIvaBase: iceIncludedInIvaBase,
      logoPath: logoPath,
      nextProformaNumber: nextProformaNumber,
      deliveryLock: deliveryLock,
    );
  }

  /// Convierte la entidad de dominio [BillingParameters] en una instancia de [BillingParametersDto].
  factory BillingParametersDto.fromDomain(BillingParameters domain) {
    return BillingParametersDto(
      businessName: domain.businessName,
      taxId: domain.taxId,
      address: domain.address,
      phone: domain.phone,
      proformaSeries: domain.proformaSeries,
      ivaBp: domain.ivaBp,
      iceIncludedInIvaBase: domain.iceIncludedInIvaBase,
      logoPath: domain.logoPath,
      nextProformaNumber: domain.nextProformaNumber,
      deliveryLock: domain.deliveryLock,
    );
  }
}
