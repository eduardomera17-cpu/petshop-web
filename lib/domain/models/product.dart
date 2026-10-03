// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: product.dart
// Propósito: Entidad inmutable de dominio que modela los artículos comercializables del catálogo de la tienda.
// =========================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

/// Entidad inmutable de dominio que representa un Producto en el Petshop.
///
/// Encapsula las reglas comerciales de categorización, precios en centavos,
/// tributación especial (ICE), existencia en almacén y visibilidad.
@freezed
class Product with _$Product {
  /// Constructor de fábrica inmutable para la entidad [Product].
  const factory Product({
    /// Identificador único del producto en el catálogo.
    required String id,

    /// Nombre comercial del artículo.
    required String name,

    /// Nombre en minúsculas y sin acentos para filtrado predictivo.
    required String searchName,

    /// Descripción funcional o técnica del producto.
    required String description,

    /// Categoría comercial (ej. Alimentos, Juguetes, Fármacos).
    required String category,

    /// Precio unitario base en centavos de dólar.
    required int basePriceCents,

    /// Puntos base del gravamen ICE (0 si no aplica).
    @Default(0) int iceBp,

    /// Cantidad física disponible en el inventario.
    required int stock,

    /// Ruta de la fotografía del producto en Cloud Storage.
    String? imagePath,

    /// Indica si el producto está disponible y visible para los clientes.
    required bool isActive,
  }) = _Product;
}
