// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: product_dto.dart
// Propósito: DTO para el inventario y catálogo de productos en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mipetshop/domain/models/product.dart';

part 'product_dto.g.dart';

/// Objeto de Transferencia de Datos (DTO) para la entidad Producto.
///
/// Modela los documentos almacenados en la colección `/products` de Cloud Firestore,
/// gestionando precios en centavos, stock disponible, impuestos y visibilidad en catálogo.
@JsonSerializable(explicitToJson: true)
class ProductDto {
  /// Identificador único del producto en Firestore.
  final String? id;

  /// Nombre comercial del producto.
  final String name;

  /// Nombre normalizado en minúsculas y sin tildes para búsquedas predictivas.
  final String searchName;

  /// Descripción detallada de las características o especificaciones del artículo.
  final String description;

  /// Categoría a la que pertenece el producto (ej. Alimentos, Medicinas, Accesorios).
  final String category;

  /// Precio base sin impuestos expresado en centavos de dólar.
  final int basePriceCents;

  /// Tasa impositiva del ICE en puntos base (0 si no aplica).
  final int iceBp;

  /// Cantidad física disponible en el inventario del petshop.
  final int stock;

  /// Ruta de la imagen ilustrativa del producto alojada en Cloud Storage.
  final String? imagePath;

  /// Indica si el producto se encuentra activo y visible para la venta.
  final bool isActive;

  /// Metadatos de auditoría para trazabilidad de creación y cambios.
  final Map<String, dynamic>? audit;

  /// Constructor inmutable de inicialización del DTO de Producto.
  const ProductDto({
    this.id,
    required this.name,
    required this.searchName,
    required this.description,
    required this.category,
    required this.basePriceCents,
    this.iceBp = 0,
    required this.stock,
    this.imagePath,
    required this.isActive,
    this.audit,
  });

  /// Construye una instancia a partir de un mapa JSON deserializado.
  factory ProductDto.fromJson(Map<String, dynamic> json) => _$ProductDtoFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$ProductDtoToJson(this);

  /// Construye un [ProductDto] a partir de un [DocumentSnapshot] de Firestore.
  ///
  /// Lanza un [StateError] si los datos recuperados son nulos.
  factory ProductDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de producto no puede ser nula.');
    }
    return ProductDto.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convierte el DTO a un mapa compatible para escritura en Firestore, omitiendo el 'id'.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  /// Mapea este DTO a la entidad de dominio puro [Product].
  Product toDomain() {
    return Product(
      id: id ?? '',
      name: name,
      searchName: searchName,
      description: description,
      category: category,
      basePriceCents: basePriceCents,
      iceBp: iceBp,
      stock: stock,
      imagePath: imagePath,
      isActive: isActive,
    );
  }

  /// Construye un [ProductDto] a partir de la entidad de dominio [Product].
  factory ProductDto.fromDomain(Product product, {Map<String, dynamic>? audit}) {
    return ProductDto(
      id: product.id.isEmpty ? null : product.id,
      name: product.name,
      searchName: product.searchName,
      description: product.description,
      category: product.category,
      basePriceCents: product.basePriceCents,
      iceBp: product.iceBp,
      stock: product.stock,
      imagePath: product.imagePath,
      isActive: product.isActive,
      audit: audit,
    );
  }
}
