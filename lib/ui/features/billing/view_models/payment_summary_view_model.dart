// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: payment_summary_view_model.dart
// Propósito: ViewModel para el cálculo y visualización del resumen consolidado de pago inmediato («A pagar hoy»), integrando pedidos listos y citas sin duplicar lecturas de Firestore.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/domain/models/product_request.dart';
import 'package:mipetshop/domain/models/proforma.dart';
import 'package:mipetshop/domain/use_cases/build_cart.dart';
import 'package:mipetshop/domain/use_cases/build_payment_summary.dart';
import 'package:mipetshop/ui/features/billing/view_models/cart_view_model.dart';

/// ViewModel para el cálculo y visualización del resumen consolidado a pagar (FA-01, CA-48, CA-57, D-07, TRD §1.3.7).
///
/// Se alimenta preferentemente de la lectura compartida del carrito (vía [cartViewModel] o flujos compartidos,
/// evitando duplicar lecturas en Firestore) y extrae estrictamente la partición de rubros exigibles de inmediato
/// («A pagar hoy»). Delega el cómputo final a [BuildPaymentSummaryUseCase].
class PaymentSummaryViewModel extends ChangeNotifier {
  /// Caso de uso para el cálculo matemático del resumen impositivo.
  final BuildPaymentSummaryUseCase useCase;

  /// Repositorio de catálogo para consulta de tarifas vigentes.
  final CatalogRepository catalogRepository;

  /// Repositorio opcional de solicitudes de productos.
  final ProductRequestsRepository? productRequestsRepository;

  /// Repositorio opcional de citas.
  final AppointmentsRepository? appointmentsRepository;

  /// Caso de uso de construcción del carrito.
  final BuildCartUseCase buildCartUseCase;

  /// Identificador único del cliente autenticado.
  final String? clientId;

  /// Instancia compartida del ViewModel del carrito para sincronización directa.
  final CartViewModel? cartViewModel;

  List<ProformaItem> _items = [];
  List<DocumentAdjustmentInput> _adjustments = [];
  PublicPricingConfig? _pricingConfig;
  DocumentPricingResult? _summaryResult;
  bool _isLoading = false;
  String? _errorMessage;
  Failure? _failure;

  bool _hasPricing = false;
  bool _hasRequests = false;
  bool _hasAppointments = false;

  List<ProductRequest> _requests = const [];
  List<Appointment> _appointments = const [];

  StreamSubscription<PublicPricingConfig>? _pricingSub;
  StreamSubscription<List<ProductRequest>>? _requestsSub;
  StreamSubscription<List<Appointment>>? _appointmentsSub;
  VoidCallback? _cartVmListener;

  /// Constructor flexible que permite inyección de repositorios, instancias de carrito o ítems directos.
  PaymentSummaryViewModel({
    this.useCase = const BuildPaymentSummaryUseCase(),
    required this.catalogRepository,
    this.productRequestsRepository,
    this.appointmentsRepository,
    this.buildCartUseCase = const BuildCartUseCase(),
    this.clientId,
    this.cartViewModel,
    List<ProformaItem>? initialItems,
    List<DocumentAdjustmentInput>? initialAdjustments,
  })  : _items = initialItems ?? [],
        _adjustments = initialAdjustments ?? [];

  /// Lista de rubros computados a liquidar hoy.
  List<ProformaItem> get items => _items;

  /// Ajustes comerciales (descuentos o recargos).
  List<DocumentAdjustmentInput> get adjustments => _adjustments;

  /// Configuración de tarifas tributarias vigentes.
  PublicPricingConfig? get pricingConfig => _pricingConfig;

  /// Resultado liquidado con subtotal, IVA, ICE y total general a pagar.
  DocumentPricingResult? get summaryResult => _summaryResult;

  /// Indica si los datos de precios o partidas se encuentran cargando.
  bool get isLoading => _isLoading;

  /// Mensaje de error para despliegue en interfaz.
  String? get errorMessage => _errorMessage;

  /// Fallo tipado en caso de error.
  Failure? get failure => _failure;

  /// Inicializa la sincronización de datos evaluando tres modos de operación:
  /// 1. Sincronización directa desde una instancia existente de [CartViewModel] (patrón preferido sin lecturas extra).
  /// 2. Suscripción compartida a los streams de pedidos, citas y tarifas desde repositorios.
  /// 3. Modo aislado: lee y escucha solo las tarifas públicas, sin carrito ni repositorios.
  void init() {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    _hasPricing = false;
    _hasRequests = false;
    _hasAppointments = false;
    notifyListeners();

    // Caso 1: Alimentación directa desde una instancia existente de CartViewModel
    if (cartViewModel != null) {
      _syncFromCartViewModel();
      _cartVmListener = () => _syncFromCartViewModel();
      cartViewModel!.addListener(_cartVmListener!);
      return;
    }

    // Caso 2: Alimentación reactiva compartida con el carrito desde repositorios (D-07, TRD §1.3.7)
    if (productRequestsRepository != null &&
        appointmentsRepository != null &&
        clientId != null) {
      _initFromSharedCartStreams();
      return;
    }

    // Caso 3: Modo aislado tradicional
    _initIsolated();
  }

  /// Sincroniza el estado local directamente desde el [CartViewModel] vinculado.
  void _syncFromCartViewModel() {
    if (cartViewModel == null) return;
    _pricingConfig = cartViewModel!.pricingConfig;
    _isLoading = cartViewModel!.isLoading;
    _failure = cartViewModel!.loadFailure;
    if (_failure != null) {
      final errorText = _failure?.debugMessage;
      _errorMessage = (errorText != null && errorText.isNotEmpty)
          ? errorText
          : (_failure?.code ?? 'CART_ERROR');
    } else {
      _errorMessage = null;
    }

    final cart = cartViewModel!.cartResult;
    if (cart != null) {
      _items = cart.payableTodayItems;
      _summaryResult = cart.payableTodaySummary ??
          useCase.execute(
            items: _items,
            adjustments: _adjustments,
            pricingConfig: _pricingConfig ?? const PublicPricingConfig(ivaBp: 1500, iceIncludedInIvaBase: true),
          );
    }
    notifyListeners();
  }

  /// Conecta flujos reactivos de Firestore compartiendo el mismo criterio de consulta del carrito.
  void _initFromSharedCartStreams() {
    // Configuración fiscal inicial
    catalogRepository.getPublicPricing().then((res) {
      if (res.isOk) {
        _pricingConfig = res.dataOrNull;
        _hasPricing = true;
        _recalculateFromCart();
      } else {
        _isLoading = false;
        _failure = res.failureOrNull;
        final errorText = _failure?.debugMessage;
        _errorMessage = (errorText != null && errorText.isNotEmpty)
            ? errorText
            : (_failure?.code ?? 'PRICING_UNAVAILABLE');
        notifyListeners();
      }
    });

    // Flujo fiscal reactivo
    unawaited(_pricingSub?.cancel());
    _pricingSub = catalogRepository.streamPublicPricing().listen(
      (config) {
        _pricingConfig = config;
        _hasPricing = true;
        _recalculateFromCart();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _isLoading = false;
        final errorText = _failure?.debugMessage;
        _errorMessage = (errorText != null && errorText.isNotEmpty)
            ? errorText
            : (_failure?.code ?? 'PRICING_STREAM_ERROR');
        notifyListeners();
      },
    );

    // Flujo de solicitudes activas compartidas con el carrito
    unawaited(_requestsSub?.cancel());
    _requestsSub = productRequestsRepository!.streamCartRequests(clientId!).listen(
      (requests) {
        _requests = requests;
        _hasRequests = true;
        _recalculateFromCart();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _isLoading = false;
        final errorText = _failure?.debugMessage;
        _errorMessage = (errorText != null && errorText.isNotEmpty)
            ? errorText
            : (_failure?.code ?? 'REQUESTS_STREAM_ERROR');
        notifyListeners();
      },
    );

    // Flujo de citas no cobradas compartidas con el carrito
    unawaited(_appointmentsSub?.cancel());
    _appointmentsSub = appointmentsRepository!.streamCartAppointments(clientId!).listen(
      (appointments) {
        _appointments = appointments;
        _hasAppointments = true;
        _recalculateFromCart();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _isLoading = false;
        final errorText = _failure?.debugMessage;
        _errorMessage = (errorText != null && errorText.isNotEmpty)
            ? errorText
            : (_failure?.code ?? 'APPOINTMENTS_STREAM_ERROR');
        notifyListeners();
      },
    );
  }

  /// Recalcula los rubros liquidables a partir de los datos recibidos de los flujos de carrito.
  void _recalculateFromCart() {
    if (!_hasPricing || !_hasRequests || !_hasAppointments || _pricingConfig == null) {
      return;
    }

    final cartResult = buildCartUseCase.execute(
      requests: _requests,
      appointments: _appointments,
      pricingConfig: _pricingConfig!,
    );

    _items = cartResult.payableTodayItems;
    _summaryResult = cartResult.payableTodaySummary ??
        useCase.execute(
          items: _items,
          adjustments: _adjustments,
          pricingConfig: _pricingConfig!,
        );
    _isLoading = false;
    notifyListeners();
  }

  /// Inicializa la escucha fiscal en modo aislado.
  void _initIsolated() {
    catalogRepository.getPublicPricing().then((res) {
      if (res.isOk) {
        _pricingConfig = res.dataOrNull;
        _recalculateIsolated();
      } else {
        _isLoading = false;
        _failure = res.failureOrNull;
        final errorText = _failure?.debugMessage;
        _errorMessage = (errorText != null && errorText.isNotEmpty)
            ? errorText
            : (_failure?.code ?? 'PRICING_UNAVAILABLE');
        notifyListeners();
      }
    });

    unawaited(_pricingSub?.cancel());
    _pricingSub = catalogRepository.streamPublicPricing().listen(
      (config) {
        _pricingConfig = config;
        _recalculateIsolated();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _isLoading = false;
        final errorText = _failure?.debugMessage;
        _errorMessage = (errorText != null && errorText.isNotEmpty)
            ? errorText
            : (_failure?.code ?? 'PRICING_STREAM_ERROR');
        notifyListeners();
      },
    );
  }

  /// Permite establecer directamente rubros y recargos para escenarios de prueba.
  void setItems(List<ProformaItem> newItems, {List<DocumentAdjustmentInput>? adjustments}) {
    _items = newItems;
    if (adjustments != null) _adjustments = adjustments;
    _recalculateIsolated();
  }

  /// Ejecuta el caso de uso en modo aislado utilizando las partidas provistas directamente.
  void _recalculateIsolated() {
    if (_pricingConfig == null) return;

    _summaryResult = useCase.execute(
      items: _items,
      adjustments: _adjustments,
      pricingConfig: _pricingConfig!,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Cancela suscripciones de Firestore y desvincula listeners del carrito.
  @override
  void dispose() {
    _pricingSub?.cancel();
    _requestsSub?.cancel();
    _appointmentsSub?.cancel();
    if (_cartVmListener != null && cartViewModel != null) {
      cartViewModel!.removeListener(_cartVmListener!);
    }
    super.dispose();
  }
}
