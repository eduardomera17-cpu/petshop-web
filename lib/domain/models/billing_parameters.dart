// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: billing_parameters.dart
// Propósito: Entidad de dominio canónica para los parámetros de configuración fiscal y emisión de proformas.
// =========================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_parameters.freezed.dart';
part 'billing_parameters.g.dart';

/// Entidad inmutable de dominio que define la parametrización fiscal del Petshop.
///
/// Centraliza la razón social, RUC, tarifa general de IVA, reglas impositivas
/// del ICE y numeración secuencial para la emisión de documentos mercantiles.
@freezed
class BillingParameters with _$BillingParameters {
  /// Constructor fábrica con los parámetros de facturación legal del establecimiento.
  const factory BillingParameters({
    /// Razón social legal registrada ante la autoridad tributaria.
    required String businessName,

    /// Número de Registro Único de Contribuyentes (RUC) o identificación tributaria.
    required String taxId,

    /// Dirección física del establecimiento comercial.
    required String address,

    /// Número telefónico de atención comercial.
    required String phone,

    /// Prefijo o serie alfanumérica para proformas (ej. "001-001").
    required String proformaSeries,

    /// Tarifa del Impuesto al Valor Agregado (IVA) en puntos base (ej. 1500 representa 15.00%).
    required int ivaBp,

    /// Indica si el impuesto ICE forma parte de la base imponible sujeta a IVA.
    required bool iceIncludedInIvaBase,

    /// Ruta del logotipo comercial en Cloud Storage para cabeceras de reportes.
    String? logoPath,

    /// Contador correlativo para la siguiente proforma a generarse.
    int? nextProformaNumber,

    /// Bandera de control de concurrencia para emisión y entrega.
    bool? deliveryLock,
  }) = _BillingParameters;

  /// Construye una instancia de [BillingParameters] deserializando un mapa JSON.
  factory BillingParameters.fromJson(Map<String, dynamic> json) =>
      _$BillingParametersFromJson(json);
}
