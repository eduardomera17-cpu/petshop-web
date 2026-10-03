// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: product_request.dart
// Propósito: Entidades inmutables de dominio que representan solicitudes de compra y líneas de pedidos de productos.
// =========================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_request.freezed.dart';

/// Entidad inmutable de dominio que representa un ítem individual dentro de un pedido de compra.
@freezed
class ProductRequestLine with _$ProductRequestLine {
  /// Constructor de fábrica inmutable para una línea de pedido de producto.
  const factory ProductRequestLine({
    /// Identificador del producto solicitado.
    required String productId,

    /// Nombre comercial del producto al momento de realizar la solicitud.
    required String productName,

    /// Cantidad de unidades requeridas.
    required int quantity,

    /// Precio unitario pactado en centavos de dólar.
    required int agreedUnitPriceCents,

    /// Puntos base del Impuesto a los Consumos Especiales (ICE).
    required int iceBp,

    /// Puntos base del Impuesto al Valor Agregado (IVA).
    required int ivaBp,
  }) = _ProductRequestLine;
}

/// Entidad inmutable de dominio para la solicitud o carrito de pedido de productos de un cliente.
///
/// Soporta pedidos multi-línea, congelamiento de precios tributarios y vinculación con proformas.
@freezed
class ProductRequest with _$ProductRequest {
  /// Constructor de fábrica inmutable para la solicitud global de compra.
  const factory ProductRequest({
    /// Identificador único del pedido.
    required String id,

    /// Identificador del cliente solicitante.
    required String clientId,

    /// Nombre del cliente para visualización en paneles de gestión.
    required String clientName,

    /// Lista de ítems detallados que componen la totalidad de la orden: la única fuente de sus líneas
    /// (WP-6.11-B; los campos planos de la transición se retiraron).
    @Default([]) List<ProductRequestLine> items,

    /// Estado actual de la solicitud ('PENDING', 'PROCESSED', 'CANCELLED').
    required String status,

    /// Fecha y hora en formato texto en la que se radicó el pedido.
    required String actionDateString,

    /// Identificador de la proforma que consolida este pedido, si ya fue facturado.
    String? proformaId,

    /// Justificación registrada en caso de haberse cancelado el pedido.
    String? cancelledReason,
  }) = _ProductRequest;
}
