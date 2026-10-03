// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/requests/view_models/admin_requests_view_model.dart
// Propósito: ViewModel administrativo para la cola de despacho de pedidos y solicitudes,
//            filtrado de estados y avance operativo a estado listo para retiro.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/domain/models/product_request.dart';

/// Gestor de estado administrativo para la cola de despacho de solicitudes de productos.
///
/// Supervisa en tiempo real las solicitudes de artículos emitidas por los clientes,
/// permite filtrar por estado operativo ('PENDING_DISPATCH', 'READY_FOR_PICKUP', etc.),
/// avanzar las solicitudes a listas para entrega física y consolidar los subtotales base
/// sin alterar los impuestos congelados en cada línea de compra.
class AdminRequestsViewModel extends ChangeNotifier {
  /// Repositorio para la consulta y avance de solicitudes de productos.
  final ProductRequestsRepository requestsRepository;

  StreamSubscription<List<ProductRequest>>? _subscription;

  List<ProductRequest> _allRequests = [];
  String? _selectedStatus; // null para todas
  bool _isLoading = true;
  Failure? _failure;
  bool _isAdvancing = false;

  /// Construye el ViewModel e inicia la escucha reactiva de la cola de pedidos.
  AdminRequestsViewModel({
    required this.requestsRepository,
  }) {
    _initStream();
  }

  /// Lista reactiva de solicitudes que coinciden con el filtro de estado seleccionado.
  List<ProductRequest> get requests => _allRequests;

  /// Filtro de estado activo sobre la cola de pedidos.
  String? get selectedStatus => _selectedStatus;

  /// Indica si la cola de despacho se encuentra en proceso de carga.
  bool get isLoading => _isLoading;

  /// Detalle tipado de la última falla detectada.
  Failure? get failure => _failure;

  /// Indica si se está ejecutando el avance de una solicitud a lista para retiro.
  bool get isAdvancing => _isAdvancing;

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = requestsRepository.streamAdminRequests(status: _selectedStatus).listen(
      (items) {
        _allRequests = items;
        _isLoading = false;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        // N-15: ni trazas ni códigos técnicos en pantalla. El fallo se tipa aquí
        // y la vista lo traduce con toLocalizedMessage (AUD-309, AUD-310).
        _failure = Failure.fromException(error);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Aplica un filtro reactivo por estado sobre la cola de despacho.
  void filterStatus(String? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    _initStream();
  }

  /// Avanza la solicitud a lista para retiro (única transición admitida desde la cola de despacho).
  Future<bool> advanceToReady(String requestId) async {
    _isAdvancing = true;
    _failure = null;
    notifyListeners();

    final res = await requestsRepository.advanceProductRequest(requestId: requestId);
    _isAdvancing = false;

    if (res.isErr) {
      _failure = res.failureOrNull ?? const UnexpectedFailure();
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Las líneas de la solicitud: sólo `items`. La forma plana se retiró
  /// (WP-6.11-B, TRD §2.8 «Cuándo termina») y ya no se deriva ninguna línea de
  /// la raíz; una solicitud sin `items` no tiene líneas.
  List<ProductRequestLine> linesOf(ProductRequest request) => request.items;

  /// Σ cantidad × precio acordado, en céntimos enteros, SIN impuestos.
  /// Los impuestos se calculan en la proforma con los porcentajes congelados de
  /// cada línea (FA-09); el panel no lee `iceIncludedInIvaBase` y no puede
  /// calcularlos sin inventarse la configuración vigente.
  int totalBeforeTaxesCents(ProductRequest request) {
    var total = 0;
    for (final line in linesOf(request)) {
      total += line.quantity * line.agreedUnitPriceCents;
    }
    return total;
  }

  /// Cancela la suscripción reactiva a la cola de pedidos de Firestore.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
