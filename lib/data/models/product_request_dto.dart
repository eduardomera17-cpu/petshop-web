// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: product_request_dto.dart
// Propósito: DTO para pedidos de productos y carritos de compra de clientes en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mipetshop/domain/models/product_request.dart';

part 'product_request_dto.g.dart';

/// DTO que representa una línea o ítem individual dentro de un pedido de productos.
@JsonSerializable(explicitToJson: true)
class ProductRequestLineDto {
  /// Identificador del producto solicitado.
  final String productId;

  /// Nombre comercial del producto en el momento del pedido.
  final String productName;

  /// Unidades solicitadas del producto.
  final int quantity;

  /// Precio unitario pactado al momento de la orden expresado en centavos de dólar.
  final int agreedUnitPriceCents;

  /// Puntos base del Impuesto a los Consumos Especiales (ICE).
  final int iceBp;

  /// Puntos base del Impuesto al Valor Agregado (IVA).
  final int ivaBp;

  /// Constructor inmutable de la línea de producto.
  const ProductRequestLineDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.agreedUnitPriceCents,
    required this.iceBp,
    required this.ivaBp,
  });

  /// Deserializa la línea a partir de un mapa JSON.
  factory ProductRequestLineDto.fromJson(Map<String, dynamic> json) =>
      _$ProductRequestLineDtoFromJson(json);

  /// Serializa la línea a formato JSON.
  Map<String, dynamic> toJson() => _$ProductRequestLineDtoToJson(this);

  /// Convierte este DTO en la entidad de dominio [ProductRequestLine].
  ProductRequestLine toDomain() {
    return ProductRequestLine(
      productId: productId,
      productName: productName,
      quantity: quantity,
      agreedUnitPriceCents: agreedUnitPriceCents,
      iceBp: iceBp,
      ivaBp: ivaBp,
    );
  }

  /// Construye un [ProductRequestLineDto] desde la entidad de dominio [ProductRequestLine].
  factory ProductRequestLineDto.fromDomain(ProductRequestLine domain) {
    return ProductRequestLineDto(
      productId: domain.productId,
      productName: domain.productName,
      quantity: domain.quantity,
      agreedUnitPriceCents: domain.agreedUnitPriceCents,
      iceBp: domain.iceBp,
      ivaBp: domain.ivaBp,
    );
  }
}

/// Objeto de Transferencia de Datos (DTO) para la solicitud o pedido de compra de productos.
///
/// Modela los documentos almacenados en la colección `/product_requests` de Cloud Firestore,
/// soportando órdenes multi-artículo, congelación de precios y vinculación a proformas.
///
/// WP-6.11-B: la transición a `items[]` terminó (TRD §2.8, «Cuándo termina»). El DTO ya no lee ni
/// escribe los campos planos de la raíz: `items[]` es la única fuente de las líneas.
@JsonSerializable(explicitToJson: true)
class ProductRequestDto {
  /// Identificador único de la solicitud en Firestore.
  final String? id;

  /// Identificador del cliente que generó el pedido.
  final String clientId;

  /// Nombre del cliente para visualización en paneles de gestión.
  final String clientName;

  /// Lista de productos detallados que componen el pedido.
  @JsonKey(defaultValue: [])
  final List<ProductRequestLineDto> items;

  /// Estado del pedido ('PENDING', 'PROCESSED', 'CANCELLED').
  final String status;

  /// Fecha en la que se generó la solicitud en formato texto.
  final String actionDateString;

  /// Identificador de la proforma formal a la que se integró este pedido.
  final String? proformaId;

  /// Justificación registrada en caso de cancelación del pedido.
  final String? cancelledReason;

  /// Metadatos de auditoría para trazabilidad de la orden de compra.
  final Map<String, dynamic>? audit;

  /// Constructor inmutable de la solicitud de productos.
  const ProductRequestDto({
    this.id,
    required this.clientId,
    required this.clientName,
    this.items = const [],
    required this.status,
    required this.actionDateString,
    this.proformaId,
    this.cancelledReason,
    this.audit,
  });

  /// Construye un [ProductRequestDto] desde su JSON; las líneas salen sólo de `items[]`.
  factory ProductRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ProductRequestDtoFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$ProductRequestDtoToJson(this);

  /// Construye un [ProductRequestDto] a partir de un [DocumentSnapshot] de Firestore.
  factory ProductRequestDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de solicitud de producto no puede ser nula.');
    }
    return ProductRequestDto.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Mapea la instancia a formato compatible con Cloud Firestore.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  /// Convierte este DTO a la entidad de dominio puro [ProductRequest].
  ProductRequest toDomain() {
    return ProductRequest(
      id: id ?? '',
      clientId: clientId,
      clientName: clientName,
      items: items.map((i) => i.toDomain()).toList(),
      status: status,
      actionDateString: actionDateString,
      proformaId: proformaId,
      cancelledReason: cancelledReason,
    );
  }

  /// Construye una instancia de [ProductRequestDto] desde la entidad [ProductRequest].
  factory ProductRequestDto.fromDomain(
    ProductRequest request, {
    Map<String, dynamic>? audit,
  }) {
    return ProductRequestDto(
      id: request.id.isEmpty ? null : request.id,
      clientId: request.clientId,
      clientName: request.clientName,
      items: request.items
          .map((line) => ProductRequestLineDto.fromDomain(line))
          .toList(),
      status: request.status,
      actionDateString: request.actionDateString,
      proformaId: request.proformaId,
      cancelledReason: request.cancelledReason,
      audit: audit,
    );
  }
}
