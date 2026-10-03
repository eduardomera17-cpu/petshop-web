// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/inventory/view_models/admin_inventory_view_model.dart
// Propósito: ViewModel para el monitoreo de existencias de inventario, alertas de
//            stock bajo reactivas y ajuste de inventario mediante Cloud Functions.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/domain/models/product.dart';

/// Gestor de estado para el monitoreo y ajuste del inventario de productos.
///
/// Supervisa en tiempo real las existencias de todos los artículos, sincroniza el umbral
/// institucional de stock mínimo configurado en los parámetros operativos del petshop,
/// permite filtrar artículos en nivel crítico y ejecutar ajustes manuales de stock mediante
/// transacciones atómicas seguras en Cloud Functions.
class AdminInventoryViewModel extends ChangeNotifier {
  /// Repositorio para la consulta y ajuste de inventario de productos.
  final ProductsRepository productsRepository;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<int>? _thresholdSub;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  int _lowStockThreshold = 5;
  String _searchQuery = '';
  bool _onlyLowStock = false;
  bool _isLoading = true;
  String? _errorMessage;
  Failure? _failure;

  /// Detalle tipado de la falla reportada por el repositorio.
  Failure? get failure => _failure;

  bool _isAdjusting = false;

  /// Construye e inicializa el ViewModel suscribiendo los flujos de inventario y umbral crítico.
  AdminInventoryViewModel({
    required this.productsRepository,
  }) {
    _initStreams();
  }

  /// Lista de productos que satisfacen los filtros vigentes de búsqueda y stock bajo.
  List<Product> get products => _filteredProducts;

  /// Umbral dinámico vigente para clasificar un producto en stock bajo o crítico.
  int get lowStockThreshold => _lowStockThreshold;

  /// Indica si el inventario inicial se encuentra en proceso de carga.
  bool get isLoading => _isLoading;

  /// Código o descripción legible de fallo.
  String? get errorMessage => _errorMessage;

  /// Indica si se está ejecutando una transacción de ajuste de existencias.
  bool get isAdjusting => _isAdjusting;

  /// Indica si el filtro de productos críticos se encuentra activo.
  bool get onlyLowStock => _onlyLowStock;

  /// Término de búsqueda textual ingresado.
  String get searchQuery => _searchQuery;

  void _initStreams() {
    _isLoading = true;
    notifyListeners();

    _thresholdSub = productsRepository.streamLowStockThreshold().listen(
      (threshold) {
        _lowStockThreshold = threshold;
        _applyFilters();
        notifyListeners();
      },
    );

    _productsSub = productsRepository.streamAllProducts().listen(
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

  /// Aplica un filtro de búsqueda textual por nombre o descripción del producto.
  void search(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  /// Alterna el filtro de visualización para mostrar exclusivamente artículos con stock bajo.
  void toggleOnlyLowStock(bool value) {
    _onlyLowStock = value;
    _applyFilters();
    notifyListeners();
  }

  /// Evalúa si el stock disponible de un producto es menor o igual al umbral crítico.
  bool isLowStock(Product product) {
    return product.stock <= _lowStockThreshold;
  }

  void _applyFilters() {
    _filteredProducts = _allProducts.where((p) {
      if (_onlyLowStock && !isLowStock(p)) {
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

  /// Ajusta inventario invocando la callable con un delta con signo y motivo obligatorio.
  Future<bool> adjustStock({
    required String productId,
    required int delta,
  }) async {
    _isAdjusting = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      final res = await productsRepository.adjustStock(
        productId: productId,
        delta: delta,
      );

      _isAdjusting = false;
      if (res.isErr) {
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _isAdjusting = false;
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      notifyListeners();
      return false;
    }
  }

  /// Cancela suscripciones activas al desmontarse el ViewModel.
  @override
  void dispose() {
    _productsSub?.cancel();
    _thresholdSub?.cancel();
    super.dispose();
  }
}
