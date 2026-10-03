// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/catalog/view_models/catalog_view_model.dart
// Propósito: ViewModel del catálogo público de productos con búsqueda por prefijo,
//            filtrado reactivo por categoría, cálculo impositivo y selección por lote.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/limits.dart' as limits;
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/data/repositories/products_repository.dart';
import 'package:mipetshop/domain/models/product.dart';

/// Representación inmutable de un producto seleccionado en la vista de catálogo
/// junto con la cantidad de unidades solicitadas por el cliente.
class CatalogSelectedItem {
  /// Producto del catálogo asociado a la selección.
  final Product product;

  /// Cantidad de unidades seleccionadas para este producto.
  final int quantity;

  /// Construye un elemento seleccionado de catálogo.
  const CatalogSelectedItem({
    required this.product,
    required this.quantity,
  });

  /// Crea una copia inmutable del elemento modificando opcionalmente sus atributos.
  CatalogSelectedItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CatalogSelectedItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Gestor de estado para la pantalla de catálogo público de productos.
///
/// Coordina la escucha en tiempo real de productos activos, configuración impositiva
/// pública (IVA/ICE), filtrado por categoría y búsqueda textual por prefijo normalizado.
/// Además, mantiene el carrito temporal de selección por lotes y despacha la
/// solicitud de reserva de inventario al backend mediante Cloud Functions.
class CatalogViewModel extends ChangeNotifier {
  /// Cantidad mínima permitida por línea de solicitud.
  static const int minRequestQuantity = 1;

  /// Cantidad máxima permitida por línea de solicitud según políticas del negocio.
  static const int maxRequestQuantity = limits.maxRequestQuantity;

  /// Cantidad máxima de líneas de productos distintas que pueden incluirse en un pedido.
  static const int maxRequestLines = limits.maxRequestLines;

  /// Repositorio para la consulta reactiva de productos del catálogo.
  final ProductsRepository productsRepository;

  /// Repositorio para la obtención y sincronización de parámetros impositivos públicos.
  final CatalogRepository catalogRepository;

  /// Repositorio para la emisión y registro de solicitudes de compra/reserva.
  final ProductRequestsRepository? requestsRepository;

  List<Product> _products = [];
  PublicPricingConfig? _pricingConfig;
  bool _isLoading = false;
  Failure? _loadFailure;
  String? _selectedCategory;
  String _searchQuery = '';

  final Map<String, CatalogSelectedItem> _selectedItems = {};
  bool _isSubmitting = false;
  String? _submissionError;
  Failure? _submissionFailure;
  String? _submissionSuccessId;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<PublicPricingConfig>? _pricingSub;

  /// Inicializa el ViewModel inyectando los repositorios necesarios.
  CatalogViewModel({
    required this.productsRepository,
    required this.catalogRepository,
    this.requestsRepository,
  });

  /// Lista de productos disponibles filtrados por categoría y búsqueda textual.
  List<Product> get products => _products;

  /// Configuración impositiva pública vigente (tasas IVA e ICE).
  PublicPricingConfig? get pricingConfig => _pricingConfig;

  /// Indica si se encuentra en proceso de carga inicial de datos.
  bool get isLoading => _isLoading;

  /// Error resultante de la carga de catálogo o configuración impositiva.
  Failure? get loadFailure => _loadFailure;

  /// Identificador de la categoría seleccionada actualmente para filtrar.
  String? get selectedCategory => _selectedCategory;

  /// Término de búsqueda textual ingresado por el usuario.
  String get searchQuery => _searchQuery;

  /// Mapa inmutable de productos seleccionados indexados por su identificador.
  Map<String, CatalogSelectedItem> get selectedItems =>
      Map.unmodifiable(_selectedItems);

  /// Lista de elementos seleccionados para solicitud en lote.
  List<CatalogSelectedItem> get selectedList => _selectedItems.values.toList();

  /// Cantidad de líneas de productos distintos seleccionados.
  int get totalSelectedLines => _selectedItems.length;

  /// Cantidad total de unidades sumando todos los productos seleccionados.
  int get totalSelectedUnits =>
      _selectedItems.values.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Indica si se está ejecutando el envío de la solicitud de productos al backend.
  bool get isSubmitting => _isSubmitting;

  /// Código o mensaje de error en caso de fallo durante el envío de la solicitud.
  String? get submissionError => _submissionError;

  /// Detalle de la falla ocurrida durante la emisión de la solicitud.
  Failure? get submissionFailure => _submissionFailure;

  /// Identificador devuelto por el backend tras registrar con éxito la solicitud.
  String? get submissionSuccessId => _submissionSuccessId;

  /// Comprueba si un producto específico se encuentra dentro de la selección activa.
  bool isSelected(String productId) => _selectedItems.containsKey(productId);

  /// Retorna la cantidad solicitada para un producto determinado.
  int getSelectedQuantity(String productId) =>
      _selectedItems[productId]?.quantity ?? 0;

  /// Retorna el nombre del producto seleccionado asociado al identificador provisto.
  String? productNameOf(String productId) =>
      _selectedItems[productId]?.product.name;

  /// Calcula el monto total en centavos de todos los productos seleccionados con impuestos aplicados.
  int calculateTotalSelectedPriceCents() {
    if (_pricingConfig == null) return 0;
    int total = 0;
    for (final item in _selectedItems.values) {
      final pricing = calculatePricingForProduct(item.product);
      if (pricing != null) {
        total += pricing.finalPriceCents * item.quantity;
      }
    }
    return total;
  }

  /// Agrega un producto a la selección. Si ya existe, acumula la cantidad hasta [maxRequestQuantity].
  /// Si excede [maxRequestLines], no agrega y notifica error.
  bool addProduct(Product product, {int quantity = 1}) {
    if (product.stock <= 0) return false;
    _submissionError = null;
    _submissionFailure = null;

    if (_selectedItems.containsKey(product.id)) {
      final current = _selectedItems[product.id]!;
      final newQty = (current.quantity + quantity).clamp(
        minRequestQuantity,
        maxRequestQuantity,
      );
      _selectedItems[product.id] = current.copyWith(quantity: newQty);
      notifyListeners();
      return true;
    }

    if (_selectedItems.length >= maxRequestLines) {
      _submissionError = 'TOO_MANY_REQUEST_LINES';
      _submissionFailure = const DomainFailure(code: 'TOO_MANY_REQUEST_LINES');
      notifyListeners();
      return false;
    }

    final initialQty = quantity.clamp(minRequestQuantity, maxRequestQuantity);
    _selectedItems[product.id] = CatalogSelectedItem(
      product: product,
      quantity: initialQty,
    );
    notifyListeners();
    return true;
  }

  /// Actualiza la cantidad solicitada para un producto existente, limitándola a los topes permitidos.
  void updateQuantity(String productId, int newQuantity) {
    if (!_selectedItems.containsKey(productId)) return;
    _submissionError = null;
    _submissionFailure = null;

    if (newQuantity < minRequestQuantity) {
      removeProduct(productId);
      return;
    }

    final clamped = newQuantity.clamp(minRequestQuantity, maxRequestQuantity);
    _selectedItems[productId] =
        _selectedItems[productId]!.copyWith(quantity: clamped);
    notifyListeners();
  }

  /// Incrementa en una unidad la cantidad del producto especificado si no sobrepasa el límite.
  void incrementQuantity(String productId) {
    if (!_selectedItems.containsKey(productId)) return;
    final current = _selectedItems[productId]!.quantity;
    if (current < maxRequestQuantity) {
      updateQuantity(productId, current + 1);
    }
  }

  /// Decrementa en una unidad la cantidad del producto especificado o lo elimina si llega a cero.
  void decrementQuantity(String productId) {
    if (!_selectedItems.containsKey(productId)) return;
    final current = _selectedItems[productId]!.quantity;
    if (current > minRequestQuantity) {
      updateQuantity(productId, current - 1);
    } else {
      removeProduct(productId);
    }
  }

  /// Elimina un producto específico del mapa de selección temporal.
  void removeProduct(String productId) {
    if (_selectedItems.remove(productId) != null) {
      _submissionError = null;
      _submissionFailure = null;
      notifyListeners();
    }
  }

  /// Limpia la totalidad de productos seleccionados del carrito de solicitud.
  void clearSelection() {
    _selectedItems.clear();
    _submissionError = null;
    _submissionFailure = null;
    notifyListeners();
  }

  /// Restablece las variables de estado asociadas al resultado del envío de solicitudes.
  void clearSubmissionState() {
    _submissionError = null;
    _submissionFailure = null;
    _submissionSuccessId = null;
    notifyListeners();
  }

  /// Envía la solicitud de todos los productos seleccionados en una única invocación callable.
  Future<bool> submitSelectedRequest({
    required String uid,
    ProductRequestsRepository? repository,
  }) async {
    final repo = repository ?? requestsRepository;
    if (repo == null) {
      _submissionError = 'CONFIG_UNAVAILABLE';
      _submissionFailure = const DomainFailure(code: 'CONFIG_UNAVAILABLE');
      notifyListeners();
      return false;
    }

    if (_selectedItems.isEmpty) {
      _submissionError = 'EMPTY_REQUEST';
      _submissionFailure = const DomainFailure(code: 'EMPTY_REQUEST');
      notifyListeners();
      return false;
    }

    if (_selectedItems.length > maxRequestLines) {
      _submissionError = 'TOO_MANY_REQUEST_LINES';
      _submissionFailure = const DomainFailure(code: 'TOO_MANY_REQUEST_LINES');
      notifyListeners();
      return false;
    }

    for (final item in _selectedItems.values) {
      if (item.quantity < minRequestQuantity ||
          item.quantity > maxRequestQuantity) {
        _submissionError = 'INVALID_QUANTITY';
        _submissionFailure = const DomainFailure(code: 'INVALID_QUANTITY');
        notifyListeners();
        return false;
      }
    }

    _isSubmitting = true;
    _submissionError = null;
    _submissionFailure = null;
    _submissionSuccessId = null;
    notifyListeners();

    final items = _selectedItems.values
        .map((item) => {
              'productId': item.product.id,
              'quantity': item.quantity,
            })
        .toList();

    final timestamp = BusinessClock.now().millisecondsSinceEpoch;
    final requestId = 'req_${uid}_batch_$timestamp';

    final result = await repo.createProductRequest(
      items: items,
      requestId: requestId,
    );

    _isSubmitting = false;

    if (result.isErr) {
      _submissionError = result.failureOrNull?.code ?? 'ERROR_GENERIC';
      _submissionFailure = result.failureOrNull ?? const UnexpectedFailure();
      notifyListeners();
      return false;
    }

    _submissionSuccessId = result.dataOrNull;
    _selectedItems.clear();
    notifyListeners();
    return true;
  }

  /// Inicializa la carga asíncrona de precios e inventario de productos.
  void init() {
    unawaited(_loadPricingAndProducts());
  }

  Future<void> _loadPricingAndProducts() async {
    _isLoading = true;
    _loadFailure = null;
    notifyListeners();

    final pricingRes = await catalogRepository.getPublicPricing();
    if (pricingRes.isErr) {
      _isLoading = false;
      _loadFailure = pricingRes.failureOrNull ?? const UnexpectedFailure();
      notifyListeners();
      return;
    }

    _pricingConfig = pricingRes.dataOrNull;

    unawaited(_pricingSub?.cancel());
    _pricingSub = catalogRepository.streamPublicPricing().listen(
      (config) {
        _pricingConfig = config;
        notifyListeners();
      },
      onError: (Object err) {
        _loadFailure = Failure.fromException(err);
        notifyListeners();
      },
    );

    _listenProducts();
  }

  void _listenProducts() {
    unawaited(_productsSub?.cancel());
    _productsSub = productsRepository
        .streamActiveProducts(category: _selectedCategory)
        .listen(
      (items) {
        if (_searchQuery.trim().isEmpty) {
          _products = items;
        } else {
          final q = CatalogRepository.normalizeSearchName(_searchQuery);
          _products = items.where((p) => p.searchName.startsWith(q)).toList();
        }
        _isLoading = false;
        _loadFailure = null;
        notifyListeners();
      },
      onError: (Object err) {
        _isLoading = false;
        _loadFailure = Failure.fromException(err);
        notifyListeners();
      },
    );
  }

  /// Aplica un filtro por categoría y recarga la suscripción de productos.
  void setCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _listenProducts();
  }

  /// Actualiza el término de búsqueda por texto prefijo y filtra los productos cargados.
  void search(String query) {
    _searchQuery = query;
    _listenProducts();
  }

  /// Calcula el desglose impositivo de un producto con la configuración impositiva vigente.
  LinePricingResult? calculatePricingForProduct(Product product) {
    if (_pricingConfig == null) return null;
    return calculateLinePricing(
      basePriceCents: product.basePriceCents,
      iceBp: product.iceBp,
      ivaBp: _pricingConfig!.ivaBp,
      iceIncludedInIvaBase: _pricingConfig!.iceIncludedInIvaBase,
    );
  }

  /// Libera suscripciones activas al desmontarse el ViewModel.
  @override
  void dispose() {
    _productsSub?.cancel();
    _pricingSub?.cancel();
    super.dispose();
  }
}
