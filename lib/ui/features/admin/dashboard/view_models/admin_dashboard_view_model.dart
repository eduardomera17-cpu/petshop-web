// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/dashboard/view_models/admin_dashboard_view_model.dart
// Propósito: ViewModel para el panel principal de métricas administrativas del Petshop,
//            lecturas puntuales directas al servidor (ADR-020) y detección de degradación.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/dashboard_repository.dart';

/// Gestor de estado para el panel principal (dashboard) administrativo.
///
/// Implementa lecturas puntuales del servidor de agregación sin suscripciones reactivas continuas
/// (cumpliendo estrictamente el ADR-020 para mitigar cuotas de lectura en Firestore).
/// Expone las 6 métricas operativas del petshop y detecta estados de degradación en la agregación.
class AdminDashboardViewModel extends ChangeNotifier {
  /// Repositorio de consulta de métricas agregadas del dashboard.
  final DashboardRepository dashboardRepository;

  bool _isLoading = false;

  /// Indica si las métricas se encuentran en proceso de consulta al servidor.
  bool get isLoading => _isLoading;

  String? _errorMessage;

  /// Código o descripción legible del error en caso de fallo al recuperar métricas.
  String? get errorMessage => _errorMessage;

  Failure? _failure;

  /// Objeto de falla tipada retornado por el repositorio.
  Failure? get failure => _failure;

  DashboardMetrics _metrics = const DashboardMetrics();

  /// Conjunto de métricas operativas obtenidas (citas, clientes, ingresos, solicitudes).
  DashboardMetrics get metrics => _metrics;

  /// Indica si el cálculo de métricas opera en modo degradado por indisponibilidad parcial.
  bool get isDegraded => _metrics.isDegraded;

  /// Mensaje explicativo cuando el sistema reporta métricas degradadas.
  String? get degradationMessage => _metrics.degradationMessage;

  /// Inicializa el ViewModel y desencadena de inmediato la lectura puntual de métricas.
  AdminDashboardViewModel({
    required this.dashboardRepository,
  }) {
    loadMetrics();
  }

  /// Ejecuta la lectura puntual directa al servidor de las seis agregaciones métricas (ADR-020).
  /// Prohibido taxativamente el uso de snapshots().
  Future<void> loadMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final result = await dashboardRepository.getDashboardMetrics();

    _isLoading = false;
    result.when(
      ok: (data) {
        _metrics = data;
        _errorMessage = null;
        _failure = null;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
      },
    );

    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _disposed = false;

  /// Marca el ViewModel como desechado para evitar notificaciones posteriores.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
