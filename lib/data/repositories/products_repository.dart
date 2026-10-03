// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: products_repository.dart
// Propósito: Repositorio para la gestión del catálogo comercial de productos y control de stock de inventario.
// =========================================================================

import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/product_dto.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/domain/models/product.dart';

/// Repositorio de productos del catálogo e inventario en Cloud Firestore.
///
/// Gestiona la colección `/products`, implementando búsquedas por prefijo con delimitador
/// `\uf8ff`, lectura del umbral de stock bajo y ajuste atómico de existencias mediante Cloud Functions.
class ProductsRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Invocador de Cloud Functions de negocio.
  final FunctionsService _functionsService;

  /// Constructor del repositorio de productos.
  ProductsRepository({
    required this.firestore,
    FunctionsService? functionsService,
  })  : _functionsService = functionsService ?? FunctionsService();

  FirebaseFirestore get _firestore => firestore;

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection('products');

  DocumentReference<Map<String, dynamic>> get _operatingParamsDoc =>
      _firestore.collection('business_config').doc('operating_parameters');

  /// Deserializa documentos tolerando registros con esquemas parciales o corruptos.
  List<Product> _mapProductDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final products = <Product>[];
    for (final doc in docs) {
      try {
        products.add(ProductDto.fromFirestore(doc).toDomain());
      } catch (error, stackTrace) {
        developer.log(
          'Documento de producto descartado por esquema inválido: ${doc.id}',
          name: 'ProductsRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return products;
  }

  /// Retorna un flujo en tiempo real de productos activos, opcionalmente filtrados por categoría.
  ///
  /// @param category Categoría específica para filtrar.
  Stream<List<Product>> streamActiveProducts({String? category}) {
    Query<Map<String, dynamic>> query =
        _productsCol.where('isActive', isEqualTo: true);

    if (category != null && category.trim().isNotEmpty) {
      query = query.where('category', isEqualTo: category.trim());
    }

    return query.snapshots().map((snapshot) => _mapProductDocs(snapshot.docs));
  }

  /// Retorna un flujo en tiempo real de la totalidad de productos para el personal administrativo.
  Stream<List<Product>> streamAllProducts() {
    return _productsCol.snapshots().map((snapshot) => _mapProductDocs(snapshot.docs));
  }

  /// Búsqueda por prefijo sobre el campo indexado [searchName] utilizando el carácter '\uf8ff'.
  ///
  /// @param query Término de búsqueda introducido por el usuario.
  /// @param category Categoría opcional de filtrado.
  /// @param onlyActive Si restringe la búsqueda solo a productos activos.
  Future<Result<List<Product>>> searchProducts(
    String query, {
    String? category,
    bool onlyActive = true,
  }) async {
    try {
      final normalizedQuery = CatalogRepository.normalizeSearchName(query);

      Query<Map<String, dynamic>> firestoreQuery = _productsCol;

      if (onlyActive) {
        firestoreQuery = firestoreQuery.where('isActive', isEqualTo: true);
      }

      if (category != null && category.trim().isNotEmpty) {
        firestoreQuery =
            firestoreQuery.where('category', isEqualTo: category.trim());
      }

      if (normalizedQuery.isNotEmpty) {
        firestoreQuery = firestoreQuery
            .where('searchName', isGreaterThanOrEqualTo: normalizedQuery)
            .where('searchName', isLessThan: '$normalizedQuery\uf8ff');
      }

      final snapshot = await firestoreQuery.get();
      final products = _mapProductDocs(snapshot.docs);

      return Ok(products);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Obtiene un producto individual por su ID en `/products/{productId}`.
  Future<Result<Product>> getProductById(String productId) async {
    try {
      final doc = await _productsCol.doc(productId).get();
      if (!doc.exists || doc.data() == null) {
        return const Err(
          DomainFailure(
            code: 'NOT_FOUND',
            debugMessage: 'Producto no encontrado.',
          ),
        );
      }
      return Ok(ProductDto.fromFirestore(doc).toDomain());
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Consulta el umbral de stock bajo desde `/business_config/operating_parameters`.
  Future<Result<int>> getLowStockThreshold() async {
    try {
      final doc = await _operatingParamsDoc.get();
      if (!doc.exists || doc.data() == null) {
        return const Ok(5);
      }
      final data = doc.data()!;
      final threshold = (data['lowStockThreshold'] as num?)?.toInt() ?? 5;
      return Ok(threshold);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real el umbral de stock bajo configurado para alertas en el dashboard.
  Stream<int> streamLowStockThreshold() {
    return _operatingParamsDoc.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return 5;
      return (data['lowStockThreshold'] as num?)?.toInt() ?? 5;
    });
  }

  /// Registra un nuevo producto en el inventario.
  ///
  /// El stock físico se inicializa directamente en la creación y luego solo se muta vía deltas.
  Future<Result<String>> createProduct({
    required String uid,
    required String name,
    required String description,
    required String category,
    required int basePriceCents,
    int iceBp = 0,
    required int initialStock,
    String? imagePath,
    bool isActive = true,
    String? customId,
  }) async {
    try {
      final docRef = customId != null && customId.isNotEmpty
          ? _productsCol.doc(customId)
          : _productsCol.doc();

      final productId = docRef.id;
      final trimmedName = name.trim();
      final searchName = CatalogRepository.normalizeSearchName(trimmedName);

      final payload = <String, dynamic>{
        'id': productId,
        'name': trimmedName,
        'searchName': searchName,
        'description': description.trim(),
        'category': category.trim(),
        'basePriceCents': basePriceCents,
        'iceBp': iceBp,
        'stock': initialStock < 0 ? 0 : initialStock,
        'imagePath': imagePath,
        'isActive': isActive,
        'audit': <String, dynamic>{
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      };

      await docRef.set(payload);
      return Ok(productId);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Actualiza los atributos comerciales de un producto existente excluyendo el stock directo.
  Future<Result<void>> updateProduct({
    required String productId,
    required String uid,
    required String name,
    required String description,
    required String category,
    required int basePriceCents,
    int iceBp = 0,
    String? imagePath,
    required bool isActive,
  }) async {
    try {
      final trimmedName = name.trim();
      final searchName = CatalogRepository.normalizeSearchName(trimmedName);

      final payload = <String, dynamic>{
        'id': productId,
        'name': trimmedName,
        'searchName': searchName,
        'description': description.trim(),
        'category': category.trim(),
        'basePriceCents': basePriceCents,
        'iceBp': iceBp,
        'imagePath': imagePath,
        'isActive': isActive,
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      };

      await _productsCol.doc(productId).update(payload);
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Conmuta el estado de activación lógica de un producto en catálogo.
  Future<Result<void>> toggleProductActive({
    required String productId,
    required String uid,
    required bool isActive,
  }) async {
    try {
      await _productsCol.doc(productId).update({
        'isActive': isActive,
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      });
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Ajusta existencias en inventario mediante la Cloud Function [adjustProductStock] con un delta relativo.
  ///
  /// @param productId ID del producto a ajustar.
  /// @param delta Diferencia con signo a aplicar sobre el stock (+5, -2, etc.).
  /// @return [Result] con el stock resultante tras la transacción.
  Future<Result<int>> adjustStock({
    required String productId,
    required int delta,
  }) async {
    final res = await _functionsService.adjustProductStock(
      productId: productId,
      delta: delta,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    final data = res.dataOrNull ?? {};
    final resultingStock = (data['resultingStock'] as num?)?.toInt() ?? 0;
    return Ok(resultingStock);
  }
}
