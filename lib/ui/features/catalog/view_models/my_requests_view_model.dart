// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/catalog/view_models/my_requests_view_model.dart
// Propósito: ViewModel para el listado de solicitudes de productos del cliente,
//            desglose impositivo y cancelación reactiva con restitución de inventario.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/domain/models/product_request.dart';

/// Gestor de estado para la vista de "Mis Solicitudes de Productos" del cliente.
///
/// Gestiona la suscripción en tiempo real a las solicitudes emitidas por el cliente autenticado,
/// el cálculo impositivo de cada solicitud (con soporte tanto para formato multilínea como plano)
/// y la cancelación con reposición de inventario a través de Cloud Functions.
class MyRequestsViewModel extends ChangeNotifier {
  /// Repositorio de acceso a datos y operaciones de solicitudes de productos.
  final ProductRequestsRepository repository;

  /// Repositorio para la consulta de parámetros impositivos vigentes.
  final CatalogRepository? catalogRepository;

  /// Identificador único del cliente autenticado cuyas solicitudes se visualizan.
  final String clientId;

  List<ProductRequest> _requests = [];
  Set<String> _deliveredProformaIds = {};
  PublicPricingConfig? _pricingConfig;
  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;
  Failure? _failure;
  String? _successMessage;

  StreamSubscription<List<ProductRequest>>? _requestsSub;

  /// Inicializa el ViewModel vinculando repositorios, el cliente y conjunto opcional de proformas entregadas.
  MyRequestsViewModel({
    required this.repository,
    this.catalogRepository,
    required this.clientId,
    Set<String>? deliveredProformaIds,
  }) : _deliveredProformaIds = deliveredProformaIds ?? {};

  /// Lista reactiva de solicitudes de compra registradas por el cliente.
  List<ProductRequest> get requests => _requests;

  /// Indica si se encuentra cargando la lista de solicitudes.
  bool get isLoading => _isLoading;

  /// Indica si se encuentra procesando la cancelación de una solicitud.
  bool get isCancelling => _isCancelling;

  /// Mensaje de error legible o código de fallo actual.
  String? get errorMessage => _errorMessage;

  /// Detalle de la falla reportada por el repositorio.
  Failure? get failure => _failure;

  /// Mensaje de éxito tras completar satisfactoriamente una operación.
  String? get successMessage => _successMessage;

  /// Configuración impositiva pública vigente para el cálculo de totales.
  PublicPricingConfig? get pricingConfig => _pricingConfig;

  /// Inicia la escucha reactiva de las solicitudes del cliente y carga la configuración impositiva.
  void init() {
    _isLoading = true;
    notifyListeners();

    if (catalogRepository != null) {
      catalogRepository!.getPublicPricing().then((res) {
        if (res.isOk) {
          _pricingConfig = res.dataOrNull;
          notifyListeners();
        }
      });
    }

    unawaited(_requestsSub?.cancel());
    _requestsSub = repository.streamMyRequests(clientId).listen(
      (items) {
        _requests = items;
        _isLoading = false;
        _errorMessage = null;
        _failure = null;
        notifyListeners();
      },
      onError: (Object err) {
        _isLoading = false;
        _failure = Failure.fromException(err);
        _errorMessage = _failure?.code;
        notifyListeners();
      },
    );
  }

  /// Actualiza el conjunto de identificadores de proformas ya entregadas para restringir cancelaciones.
  void updateDeliveredProformaIds(Set<String> ids) {
    _deliveredProformaIds = ids;
    notifyListeners();
  }

  /// Indica si la solicitud puede ser cancelada por el cliente.
  /// La acción está disponible en PENDING_DISPATCH y READY_FOR_PICKUP, y
  /// desaparece cuando la proforma vinculada se encuentra entregada.
  bool canCancel(ProductRequest request) {
    if (request.status != 'PENDING_DISPATCH' &&
        request.status != 'READY_FOR_PICKUP') {
      return false;
    }
    if (request.proformaId != null &&
        _deliveredProformaIds.contains(request.proformaId)) {
      return false;
    }
    return true;
  }

  /// Calcula el precio con impuestos para una solicitud específica.
  /// Suma cada línea calculada por separado con sus propios impuestos congelados (ADR-016, TRD §3.3.A).
  /// Las líneas salen sólo de items: la forma plana se retiró (WP-6.11-B); sin items, la suma es cero.
  LinePricingResult calculatePricingForRequest(ProductRequest request) {
    final iceIncluded = _pricingConfig?.iceIncludedInIvaBase ?? true;

    int totalBasePrice = 0;
    int totalIceAmount = 0;
    int totalIvaAmount = 0;
    int totalFinalPrice = 0;

    for (final line in request.items) {
      final lineBasePrice = line.agreedUnitPriceCents * line.quantity;
      final res = calculateLinePricing(
        basePriceCents: lineBasePrice,
        iceBp: line.iceBp,
        ivaBp: line.ivaBp,
        iceIncludedInIvaBase: iceIncluded,
      );
      totalBasePrice += res.basePriceCents;
      totalIceAmount += res.iceAmountCents;
      totalIvaAmount += res.ivaAmountCents;
      totalFinalPrice += res.finalPriceCents;
    }

    return LinePricingResult(
      basePriceCents: totalBasePrice,
      iceBp: 0,
      ivaBp: 0,
      iceAmountCents: totalIceAmount,
      ivaAmountCents: totalIvaAmount,
      finalPriceCents: totalFinalPrice,
    );
  }

  /// Cancela la solicitud invocando la callable de reposición de stock.
  Future<bool> cancelRequest(String requestId) async {
    _isCancelling = true;
    _errorMessage = null;
    _failure = null;
    _successMessage = null;
    notifyListeners();

    final res = await repository.cancelProductRequestByClient(
      requestId: requestId,
    );

    _isCancelling = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _failure?.code ?? 'ERROR_GENERIC';
      notifyListeners();
      return false;
    }

    _successMessage = 'CANCELLED_SUCCESS';
    notifyListeners();
    return true;
  }

  /// Cancela suscripciones de Firestore al desmontarse el ViewModel.
  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
  }
}
