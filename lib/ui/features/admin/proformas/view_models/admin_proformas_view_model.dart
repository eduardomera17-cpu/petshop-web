// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/view_models/admin_proformas_view_model.dart
// Propósito: ViewModel para la administración del ciclo de vida de proformas,
//            creación de borradores, ajustes, entrega, finalización y anulación justificada.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/domain/models/proforma.dart';

/// Gestor de estado para el ciclo de vida completo de las proformas administrativas.
///
/// Implementa la máquina de estados de facturación/cotización (DRAFT -> DELIVERED -> FINALIZED / VOIDED):
/// creación de borradores iniciales vinculados a un cliente, incorporación de ítems y conceptos,
/// aplicación de recargos y descuentos comerciales, entrega al cliente con generación de PDF,
/// confirmación de cobro (finalización) y anulación justificada con motivo obligatorio.
class AdminProformasViewModel extends ChangeNotifier {
  /// Repositorio de emisión, cálculo y transición de estados de proformas.
  final ProformasRepository proformasRepository;

  StreamSubscription<List<Proforma>>? _subscription;

  List<Proforma> _allProformas = [];
  String? _selectedStatus; // null para todas
  bool _isLoading = true;
  String? _errorMessage;
  Failure? _failure;

  /// Detalle tipado del último fallo reportado por el repositorio.
  Failure? get failure => _failure;

  bool _isProcessing = false;

  /// Construye el ViewModel e inicia la escucha reactiva de proformas administrativas.
  AdminProformasViewModel({
    required this.proformasRepository,
  }) {
    _initStream();
  }

  /// Lista de proformas recuperadas según el filtro de estado seleccionado.
  List<Proforma> get proformas => _allProformas;

  /// Filtro de estado activo ('DRAFT', 'DELIVERED', 'FINALIZED', 'VOIDED' o null para todas).
  String? get selectedStatus => _selectedStatus;

  /// Indica si la lista de proformas está en proceso de carga.
  bool get isLoading => _isLoading;

  /// Mensaje o código de error ante anomalías de red o validación.
  String? get errorMessage => _errorMessage;

  /// Indica si se encuentra en ejecución una transición o mutación de estado.
  bool get isProcessing => _isProcessing;

  void _initStream() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = proformasRepository.streamAdminProformas(status: _selectedStatus).listen(
      (items) {
        _allProformas = items;
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

  /// Aplica un filtro reactivo por estado sobre el listado de proformas.
  void filterStatus(String? status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    _initStream();
  }

  /// Crea un nuevo borrador de proforma.
  Future<String?> createDraft({
    required String clientId,
    List<Map<String, dynamic>> items = const [],
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await proformasRepository.createProformaDraft(
      clientId: clientId,
      items: items,
    );

    _isProcessing = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _failure?.code;
      notifyListeners();
      return null;
    }

    notifyListeners();
    return res.dataOrNull;
  }

  /// Añade ítems a un borrador.
  Future<bool> addItems({
    required String proformaId,
    required List<Map<String, dynamic>> items,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await proformasRepository.addProformaItems(
      proformaId: proformaId,
      items: items,
    );

    _isProcessing = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _mapErrorCode(_failure);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Aplica descuentos y recargos.
  Future<bool> setAdjustments({
    required String proformaId,
    required List<Map<String, dynamic>> adjustments,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await proformasRepository.setProformaAdjustments(
      proformaId: proformaId,
      adjustments: adjustments,
    );

    _isProcessing = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _mapErrorCode(_failure);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Entrega la proforma al cliente y genera su documento PDF en memoria/almacenamiento.
  Future<bool> deliver(Proforma proforma) async {
    if (proforma.items.isEmpty) {
      _failure = const DomainFailure(code: 'PROFORMA_EMPTY');
      _errorMessage = 'PROFORMA_EMPTY';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await proformasRepository.deliverProforma(
      proformaId: proforma.id,
    );

    _isProcessing = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _mapErrorCode(_failure);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Finaliza una proforma entregada tras confirmación de cobro.
  Future<bool> finalize(String proformaId) async {
    _isProcessing = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await proformasRepository.finalizeProforma(
      proformaId: proformaId,
    );

    _isProcessing = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _mapErrorCode(_failure);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Anula una proforma registrando el motivo mandatorio (<= 300 caracteres).
  Future<bool> voidDocument({
    required String proformaId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty || reason.trim().length > 300) {
      _failure = const DomainFailure(code: 'INVALID_VOID_REASON');
      _errorMessage = 'INVALID_VOID_REASON';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await proformasRepository.voidProforma(
      proformaId: proformaId,
      reason: reason.trim(),
    );

    _isProcessing = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _mapErrorCode(_failure);
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  String _mapErrorCode(Failure? failure) {
    if (failure == null) return 'Error inesperado';
    return failure.code;
  }

  /// Cancela la suscripción reactiva de proformas al desmontar el ViewModel.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
