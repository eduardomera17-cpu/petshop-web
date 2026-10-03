// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: cart_view_model.dart
// Propósito: ViewModel reactivo para el carrito de compras del cliente, integrando pedidos de productos, citas pendientes de cobro y cálculo impositivo consolidado.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/domain/models/product_request.dart';
import 'package:mipetshop/domain/use_cases/build_cart.dart';

/// ViewModel reactivo para el carrito de compras del cliente (PR-08, D-05, CA-66, CA-69).
///
/// Compone reactivamente tres flujos de información en tiempo real sin mutar directamente Firestore:
/// 1. Solicitudes de productos activas del cliente (`PENDING_DISPATCH`, `READY_FOR_PICKUP`).
/// 2. Citas atendidas o confirmadas no facturadas.
/// 3. Parámetros tributarios de facturación institucional (alícuotas de IVA e ICE).
/// Delega el cálculo matemático determinista de subtotales, impuestos y totales al caso de uso puro [BuildCartUseCase].
class CartViewModel extends ChangeNotifier {
  /// Repositorio de pedidos de productos.
  final ProductRequestsRepository productRequestsRepository;

  /// Repositorio de agendamiento de citas.
  final AppointmentsRepository appointmentsRepository;

  /// Repositorio de catálogo y parámetros de precios públicos.
  final CatalogRepository catalogRepository;

  /// Caso de uso de dominio para construcción y liquidación matemática del carrito.
  final BuildCartUseCase buildCartUseCase;

  /// Identificador único del cliente autenticado.
  final String clientId;

  List<ProductRequest> _requests = const [];
  List<Appointment> _appointments = const [];
  PublicPricingConfig? _pricingConfig;
  CartResult? _cartResult;
  bool _isLoading = true;
  Failure? _loadFailure;

  bool _hasPricing = false;
  bool _hasRequests = false;
  bool _hasAppointments = false;

  StreamSubscription<List<ProductRequest>>? _requestsSub;
  StreamSubscription<List<Appointment>>? _appointmentsSub;
  StreamSubscription<PublicPricingConfig>? _pricingSub;

  /// Constructor con inyección de repositorios y cliente.
  CartViewModel({
    required this.productRequestsRepository,
    required this.appointmentsRepository,
    required this.catalogRepository,
    this.buildCartUseCase = const BuildCartUseCase(),
    required this.clientId,
  });

  /// Resultado consolidado del carrito de compras con ítems y desglose tributario.
  CartResult? get cartResult => _cartResult;

  /// Indica si los flujos iniciales del carrito se encuentran cargando.
  bool get isLoading => _isLoading;

  /// Fallo de infraestructura en caso de error en alguno de los flujos.
  Failure? get loadFailure => _loadFailure;

  /// Configuración de tarifas tributarias vigentes.
  PublicPricingConfig? get pricingConfig => _pricingConfig;

  /// Inicializa la escucha reactiva simultánea de precios, pedidos de productos y citas del cliente.
  void init() {
    _isLoading = true;
    _loadFailure = null;
    _hasPricing = false;
    _hasRequests = false;
    _hasAppointments = false;
    notifyListeners();

    // Cargar configuración de precios inicial
    catalogRepository.getPublicPricing().then((res) {
      if (res.isOk) {
        _pricingConfig = res.dataOrNull;
        _hasPricing = true;
        _recalculate();
      } else {
        _loadFailure = res.failureOrNull ?? const UnexpectedFailure();
        _isLoading = false;
        notifyListeners();
      }
    });

    // Escuchar flujo de configuración de precios
    _pricingSub?.cancel();
    _pricingSub = catalogRepository.streamPublicPricing().listen(
      (pricing) {
        _pricingConfig = pricing;
        _hasPricing = true;
        _recalculate();
      },
      onError: (Object e) {
        _loadFailure = Failure.fromException(e);
        _isLoading = false;
        notifyListeners();
      },
    );

    // Escuchar solicitudes activas para el carrito (Tarea B)
    _requestsSub?.cancel();
    _requestsSub = productRequestsRepository.streamCartRequests(clientId).listen(
      (requests) {
        _requests = requests;
        _hasRequests = true;
        _recalculate();
      },
      onError: (Object e) {
        _loadFailure = Failure.fromException(e);
        _isLoading = false;
        notifyListeners();
      },
    );

    // Escuchar citas no cobradas para el carrito (Tarea B)
    _appointmentsSub?.cancel();
    _appointmentsSub = appointmentsRepository.streamCartAppointments(clientId).listen(
      (appointments) {
        _appointments = appointments;
        _hasAppointments = true;
        _recalculate();
      },
      onError: (Object e) {
        _loadFailure = Failure.fromException(e);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Recalcula el carrito únicamente cuando las tres fuentes han emitido datos válidos.
  void _recalculate() {
    if (!_hasPricing || !_hasRequests || !_hasAppointments || _pricingConfig == null) {
      return;
    }

    _cartResult = buildCartUseCase.execute(
      requests: _requests,
      appointments: _appointments,
      pricingConfig: _pricingConfig!,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Cancela todas las suscripciones a Streams en Firestore al desmontar el ViewModel.
  @override
  void dispose() {
    _requestsSub?.cancel();
    _appointmentsSub?.cancel();
    _pricingSub?.cancel();
    super.dispose();
  }
}
