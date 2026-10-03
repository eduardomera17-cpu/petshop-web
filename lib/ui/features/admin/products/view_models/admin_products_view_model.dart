// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/products/view_models/admin_products_view_model.dart
// Propósito: ViewModel para la administración del catálogo de productos,
//            creación con stock inicial, edición sin alteración directa y baja lógica.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/domain/models/product.dart';

/// Gestor de estado administrativo para el catálogo de productos del Petshop.
///
/// Coordina la escucha en tiempo real de todos los artículos (activos e inactivos),
/// el filtrado por categoría y búsqueda textual, el registro de nuevos productos con
/// definición de stock inicial y la edición de atributos comerciales sin alterar
/// las existencias de inventario de forma no auditada.
class AdminProductsViewModel extends ChangeNotifier {
  /// Repositorio para la gestión comercial y persistencia de productos.
  final ProductsRepository productsRepository;

  StreamSubscription<List<Product>>? _subscription;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;
  Failure? _failure;

  /// Detalle tipado del último fallo reportado por el repositorio.
  Failure? get failure => _failure;

  bool _isSaving = false;

  /// Inicializa el ViewModel y suscribe la escucha reactiva de todos los productos.
  AdminProductsViewModel({
    required this.productsRepository,
  }) {
    _initStream();
  }

  /// Lista de productos que cumplen con los filtros de categoría y texto activos.
  List<Product> get products => _filteredProducts;

  /// Indica si la lista integral de productos se encuentra en proceso de carga.
  bool get isLoading => _isLoading;

  /// Mensaje o código de error ante anomalías durante operaciones de lectura o guardado.
  String? get errorMessage => _errorMessage;

  /// Indica si se encuentra en ejecución el guardado o actualización de un producto.
  bool get isSaving => _isSaving;

  /// Cadena de texto empleada para el filtrado en vivo.
  String get searchQuery => _searchQuery;

  /// Identificador de la categoría seleccionada para filtrar el catálogo.
  String? get selectedCategory => _selectedCategory;

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _subscription = productsRepository.streamAllProducts().listen(
      (items) {
        _allProducts = items;
        _applyFilters();
        _isLoading = false;
        _errorMessage = null;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = Failure.fromException(error);
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Aplica un filtro de búsqueda textual sobre el nombre y descripción del producto.
  void search(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  /// Filtra los productos expuestos según una categoría seleccionada o los muestra todos.
  void filterCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _allProducts.where((p) {
      if (_selectedCategory != null &&
          _selectedCategory!.isNotEmpty &&
          p.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final lower = _searchQuery.toLowerCase();
        final nameMatch = p.name.toLowerCase().contains(lower);
        final descMatch = p.description.toLowerCase().contains(lower);
        return nameMatch || descMatch;
      }
      return true;
    }).toList();
  }

  /// Guarda o actualiza un producto en el catálogo.
  /// En modo creación permite definir el stock inicial; en edición el stock no se actualiza directamente.
  Future<bool> saveProduct({
    String? productId,
    required String name,
    required String description,
    required String category,
    required int basePriceCents,
    required int iceBp,
    int? initialStock,
    bool isActive = true,
    required String uid,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      if (productId == null) {
        // Creación directa con stock inicial
        final res = await productsRepository.createProduct(
          name: name,
          description: description,
          category: category,
          basePriceCents: basePriceCents,
          iceBp: iceBp,
          initialStock: initialStock ?? 0,
          isActive: isActive,
          uid: uid,
        );
        _isSaving = false;
        if (res.isErr) {
          _failure = res.failureOrNull;
          _errorMessage = _failure?.code;
          notifyListeners();
          return false;
        }
        notifyListeners();
        return true;
      } else {
        // Actualización directa sin alterar stock
        final res = await productsRepository.updateProduct(
          productId: productId,
          name: name,
          description: description,
          category: category,
          basePriceCents: basePriceCents,
          iceBp: iceBp,
          isActive: isActive,
          uid: uid,
        );
        _isSaving = false;
        if (res.isErr) {
          _failure = res.failureOrNull;
          _errorMessage = _failure?.code;
          notifyListeners();
          return false;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isSaving = false;
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      notifyListeners();
      return false;
    }
  }

  /// Activa o desactiva lógicamente un producto.
  Future<bool> toggleActive(String productId, bool isActive, String uid) async {
    final res = await productsRepository.toggleProductActive(
      productId: productId,
      uid: uid,
      isActive: isActive,
    );
    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _failure?.code;
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Cancela la suscripción reactiva del catálogo al descartar el ViewModel.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
