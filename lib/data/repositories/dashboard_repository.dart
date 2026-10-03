// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: dashboard_repository.dart
// Propósito: Repositorio para la agregación de métricas y analítica del panel administrativo mediante AggregateQuery.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';

/// Contenedor inmutable de las seis métricas agregadas del panel de control administrativo.
class DashboardMetrics {
  /// Citas programadas para el día en curso.
  final int todayAppointmentsCount;

  /// Citas pendientes de confirmación o atención.
  final int pendingAppointmentsCount;

  /// Solicitudes de compra de productos listas para despacho.
  final int pendingRequestsCount;

  /// Nuevos clientes registrados en el mes calendario.
  final int monthlyClientsCount;

  /// Productos cuyo inventario actual está en o por debajo del umbral de stock bajo.
  final int lowStockProductsCount;

  /// Citas activas que colisionan con un bloqueo de agenda programado.
  final int conflictedAppointmentsCount;

  /// Señala si alguna de las consultas superó el tiempo límite y se presenta información parcial.
  final bool isDegraded;

  /// Explicación textual del estado degradado para feedback en la UI.
  final String? degradationMessage;

  /// Constructor inmutable de las métricas del dashboard.
  const DashboardMetrics({
    this.todayAppointmentsCount = 0,
    this.pendingAppointmentsCount = 0,
    this.pendingRequestsCount = 0,
    this.monthlyClientsCount = 0,
    this.lowStockProductsCount = 0,
    this.conflictedAppointmentsCount = 0,
    this.isDegraded = false,
    this.degradationMessage,
  });

  /// Fábrica para inicializar métricas en modo de degradación controlada ante timeout.
  factory DashboardMetrics.degraded({
    int todayAppointmentsCount = 0,
    int pendingAppointmentsCount = 0,
    int pendingRequestsCount = 0,
    int monthlyClientsCount = 0,
    int lowStockProductsCount = 0,
    int conflictedAppointmentsCount = 0,
    String? message,
  }) {
    return DashboardMetrics(
      todayAppointmentsCount: todayAppointmentsCount,
      pendingAppointmentsCount: pendingAppointmentsCount,
      pendingRequestsCount: pendingRequestsCount,
      monthlyClientsCount: monthlyClientsCount,
      lowStockProductsCount: lowStockProductsCount,
      conflictedAppointmentsCount: conflictedAppointmentsCount,
      isDegraded: true,
      degradationMessage: message ??
          'Tiempo de respuesta excedido (DEADLINE_EXCEEDED). Datos presentados en estado degradado.',
    );
  }
}

/// Repositorio del Dashboard que ejecuta de forma puntual y directa las seis agregaciones métricas.
///
/// Cumple la regla de optimización de cuotas: prohibido el uso de streams/snapshots en esta capa;
/// utiliza exclusivamente `AggregateQuery.count().get()` con timeout estricto de 60 segundos.
class DashboardRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Plazo máximo de expiración oficial para consultas de agregación en Firestore (60 segundos).
  static const Duration aggregationTimeout = Duration(seconds: 60);

  /// Constructor del repositorio de analítica del dashboard.
  DashboardRepository({
    required this.firestore,
  });

  FirebaseFirestore get _firestore => firestore;

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _productRequestsCol =>
      _firestore.collection('product_requests');

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection('products');

  DocumentReference<Map<String, dynamic>> get _operatingParamsDoc =>
      _firestore.collection('business_config').doc('operating_parameters');

  /// 1. Consulta la cantidad de citas agendadas para el día de hoy en `/appointments`.
  ///
  /// @param todayDateString Fecha en formato YYYY-MM-DD (opcional).
  Future<Result<int>> getTodayAppointmentsCount({String? todayDateString}) async {
    try {
      final today = todayDateString ?? BusinessClock.todayBusinessDate();
      final aggregateQuery = _appointmentsCol
          .where('dateString', isEqualTo: today)
          .count();

      final snapshot = await aggregateQuery
          .get()
          .timeout(aggregationTimeout);

      return Ok(snapshot.count ?? 0);
    } catch (e) {
      if (_isDeadlineExceeded(e)) {
        return const Err(
          DomainFailure(
            code: 'DEADLINE_EXCEEDED',
            debugMessage: 'Timeout en consulta de citas de hoy (DEADLINE_EXCEEDED).',
          ),
        );
      }
      return Err(Failure.fromException(e));
    }
  }

  /// 2. Consulta la cantidad total de citas en estado 'PENDING'.
  Future<Result<int>> getPendingAppointmentsCount() async {
    try {
      final aggregateQuery = _appointmentsCol
          .where('status', isEqualTo: 'PENDING')
          .count();

      final snapshot = await aggregateQuery
          .get()
          .timeout(aggregationTimeout);

      return Ok(snapshot.count ?? 0);
    } catch (e) {
      if (_isDeadlineExceeded(e)) {
        return const Err(
          DomainFailure(
            code: 'DEADLINE_EXCEEDED',
            debugMessage: 'Timeout en consulta de citas pendientes (DEADLINE_EXCEEDED).',
          ),
        );
      }
      return Err(Failure.fromException(e));
    }
  }

  /// 3. Consulta la cantidad de pedidos en estado 'PENDING_DISPATCH' en `/product_requests`.
  Future<Result<int>> getPendingRequestsCount() async {
    try {
      final aggregateQuery = _productRequestsCol
          .where('status', isEqualTo: 'PENDING_DISPATCH')
          .count();

      final snapshot = await aggregateQuery
          .get()
          .timeout(aggregationTimeout);

      return Ok(snapshot.count ?? 0);
    } catch (e) {
      if (_isDeadlineExceeded(e)) {
        return const Err(
          DomainFailure(
            code: 'DEADLINE_EXCEEDED',
            debugMessage: 'Timeout en consulta de solicitudes pendientes (DEADLINE_EXCEEDED).',
          ),
        );
      }
      return Err(Failure.fromException(e));
    }
  }

  /// 4. Cuantifica clientes registrados durante el mes calendario actual en `/users`.
  ///
  /// @param startOfMonth Fecha inicial del mes a evaluar.
  Future<Result<int>> getMonthlyClientsCount({DateTime? startOfMonth}) async {
    try {
      DateTime start;
      if (startOfMonth != null) {
        start = startOfMonth;
      } else {
        final now = BusinessClock.now();
        start = DateTime(now.year, now.month, 1);
      }

      final startTimestamp = Timestamp.fromDate(start);

      final aggregateQuery = _usersCol
          .where('role', isEqualTo: 'CLIENT')
          .where('audit.createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .count();

      final snapshot = await aggregateQuery
          .get()
          .timeout(aggregationTimeout);

      return Ok(snapshot.count ?? 0);
    } catch (e) {
      if (_isDeadlineExceeded(e)) {
        return const Err(
          DomainFailure(
            code: 'DEADLINE_EXCEEDED',
            debugMessage: 'Timeout en consulta de clientes del mes (DEADLINE_EXCEEDED).',
          ),
        );
      }
      return Err(Failure.fromException(e));
    }
  }

  /// 5. Cuantifica productos con existencia igual o inferior al umbral de inventario crítico.
  ///
  /// @param threshold Umbral de existencias configurado.
  Future<Result<int>> getLowStockProductsCount({int? threshold}) async {
    try {
      int effectiveThreshold = threshold ?? 5;
      if (threshold == null) {
        try {
          final doc = await _operatingParamsDoc.get();
          if (doc.exists && doc.data() != null) {
            final raw = doc.data()!['lowStockThreshold'];
            if (raw is num) {
              effectiveThreshold = raw.toInt();
            }
          }
        } catch (_) {
          // Conserva el valor por omisión ante fallos de lectura
        }
      }

      final aggregateQuery = _productsCol
          .where('isActive', isEqualTo: true)
          .where('stock', isLessThanOrEqualTo: effectiveThreshold)
          .count();

      final snapshot = await aggregateQuery
          .get()
          .timeout(aggregationTimeout);

      return Ok(snapshot.count ?? 0);
    } catch (e) {
      if (_isDeadlineExceeded(e)) {
        return const Err(
          DomainFailure(
            code: 'DEADLINE_EXCEEDED',
            debugMessage: 'Timeout en consulta de stock bajo (DEADLINE_EXCEEDED).',
          ),
        );
      }
      return Err(Failure.fromException(e));
    }
  }

  /// 6. Cuantifica citas marcadas con conflicto de bloqueo de agenda en `/appointments`.
  Future<Result<int>> getConflictedAppointmentsCount() async {
    try {
      final aggregateQuery = _appointmentsCol
          .where('hasBlockConflict', isEqualTo: true)
          .count();

      final snapshot = await aggregateQuery
          .get()
          .timeout(aggregationTimeout);

      return Ok(snapshot.count ?? 0);
    } catch (e) {
      if (_isDeadlineExceeded(e)) {
        return const Err(
          DomainFailure(
            code: 'DEADLINE_EXCEEDED',
            debugMessage: 'Timeout en consulta de citas en conflicto (DEADLINE_EXCEEDED).',
          ),
        );
      }
      return Err(Failure.fromException(e));
    }
  }

  /// Ejecuta en paralelo las seis consultas de agregación y consolida [DashboardMetrics].
  ///
  /// Administra internamente la degradación de estado si una o varias consultas agotan el tiempo límite.
  Future<Result<DashboardMetrics>> getDashboardMetrics() async {
    bool isDegraded = false;
    String? degradationMessage;

    final todayRes = await getTodayAppointmentsCount();
    final pendingApptsRes = await getPendingAppointmentsCount();
    final pendingReqsRes = await getPendingRequestsCount();
    final monthlyClientsRes = await getMonthlyClientsCount();
    final lowStockRes = await getLowStockProductsCount();
    final conflictsRes = await getConflictedAppointmentsCount();

    final results = [
      todayRes,
      pendingApptsRes,
      pendingReqsRes,
      monthlyClientsRes,
      lowStockRes,
      conflictsRes,
    ];

    for (final res in results) {
      final failure = res.failureOrNull;
      if (failure != null && failure.code == 'DEADLINE_EXCEEDED') {
        isDegraded = true;
        degradationMessage =
            'Una o más consultas superaron el límite de tiempo de 60 segundos (DEADLINE_EXCEEDED). Métricas en estado degradado.';
        break;
      }
    }

    final metrics = DashboardMetrics(
      todayAppointmentsCount: todayRes.dataOrNull ?? 0,
      pendingAppointmentsCount: pendingApptsRes.dataOrNull ?? 0,
      pendingRequestsCount: pendingReqsRes.dataOrNull ?? 0,
      monthlyClientsCount: monthlyClientsRes.dataOrNull ?? 0,
      lowStockProductsCount: lowStockRes.dataOrNull ?? 0,
      conflictedAppointmentsCount: conflictsRes.dataOrNull ?? 0,
      isDegraded: isDegraded,
      degradationMessage: degradationMessage,
    );

    return Ok(metrics);
  }

  /// Verifica si el error capturado corresponde a un timeout de red o de Firestore.
  bool _isDeadlineExceeded(Object error) {
    if (error is TimeoutException) return true;
    if (error is FirebaseException &&
        (error.code == 'deadline-exceeded' ||
            error.message?.contains('DEADLINE_EXCEEDED') == true)) {
      return true;
    }
    final str = error.toString();
    return str.contains('DEADLINE_EXCEEDED') || str.contains('deadline-exceeded');
  }
}
