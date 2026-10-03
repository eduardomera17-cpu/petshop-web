// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: history_view_model.dart
// Propósito: ViewModel para el historial y seguimiento de citas del cliente, con soporte de filtrado temporal, paginación por cursor y cancelación segura.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';

/// Pestañas de clasificación temporal en la vista de historial de citas.
enum HistoryTab {
  /// Citas activas programadas para hoy o fechas futuras.
  upcoming,

  /// Citas concluidas, canceladas o de fechas pasadas.
  past,
}

/// ViewModel para la gestión de citas históricas y próximas del cliente.
///
/// Implementa arquitectura MVVM estricta, división entre citas activas y pasadas,
/// paginación por cursor mediante Firestore (`startAfterDocument`) y cancelación atómica
/// sin escritura optimista mediante la Cloud Function `cancelAppointmentByClient`.
class HistoryViewModel extends ChangeNotifier {
  /// Repositorio de agendamiento para consulta y cancelación de citas.
  final AppointmentsRepository repository;

  /// Identificador único del cliente autenticado.
  final String clientId;

  HistoryTab _selectedTab = HistoryTab.upcoming;
  List<Appointment> _allAppointments = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Failure? _failure;
  Failure? get failure => _failure;
  bool _isCancelling = false;
  String? _cancellingAppointmentId;

  StreamSubscription<List<Appointment>>? _appointmentsSub;

  /// Constructor con inyección del repositorio y cliente.
  HistoryViewModel({
    required this.repository,
    required this.clientId,
  });

  /// Pestaña activa actualmente seleccionada.
  HistoryTab get selectedTab => _selectedTab;

  /// Lista global de citas recuperadas de Firestore.
  List<Appointment> get allAppointments => _allAppointments;

  /// Indica si existen más registros en Firestore para paginar.
  bool get hasMore => _hasMore;

  /// Indica si hay una consulta de carga principal en progreso.
  bool get isLoading => _isLoading;

  /// Indica si se está cargando la siguiente página de citas en segundo plano.
  bool get isLoadingMore => _isLoadingMore;

  /// Mensaje de error para despliegue visual.
  String? get errorMessage => _errorMessage;

  /// Indica si hay una solicitud de cancelación en ejecución.
  bool get isCancelling => _isCancelling;

  /// Identificador de la cita actualmente en proceso de cancelación.
  String? get cancellingAppointmentId => _cancellingAppointmentId;

  /// Cambia la pestaña activa ([HistoryTab.upcoming] frente a [HistoryTab.past]).
  void setSelectedTab(HistoryTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  /// Da formato `YYYY-MM-DD` a una fecha dada.
  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Citas activas o futuras (estado `PENDING` o `CONFIRMED` y fecha mayor o igual a la actual).
  ///
  /// Se presentan ordenadas cronológicamente ascendente (la cita más próxima primero).
  List<Appointment> get upcomingAppointments {
    final now = BusinessClock.now();
    final todayString = _formatDate(now);

    final filtered = _allAppointments.where((a) {
      if (a.status == 'CANCELLED' || a.status == 'COMPLETED') return false;
      return a.dateString.compareTo(todayString) >= 0;
    }).toList();

    filtered.sort((a, b) {
      final dateCmp = a.dateString.compareTo(b.dateString);
      if (dateCmp != 0) return dateCmp;
      return a.timeSlot.compareTo(b.timeSlot);
    });

    return filtered;
  }

  /// Citas pasadas o históricas (`COMPLETED`, `CANCELLED` o con fecha previa a hoy).
  ///
  /// Se presentan ordenadas cronológicamente inversa (la cita más reciente primero).
  List<Appointment> get pastAppointments {
    final now = BusinessClock.now();
    final todayString = _formatDate(now);

    final filtered = _allAppointments.where((a) {
      if (a.status == 'CANCELLED' || a.status == 'COMPLETED') return true;
      return a.dateString.compareTo(todayString) < 0;
    }).toList();

    filtered.sort((a, b) {
      final dateCmp = b.dateString.compareTo(a.dateString);
      if (dateCmp != 0) return dateCmp;
      return b.timeSlot.compareTo(a.timeSlot);
    });

    return filtered;
  }

  /// Retorna las citas correspondientes a la pestaña actualmente seleccionada.
  List<Appointment> get currentTabAppointments {
    return _selectedTab == HistoryTab.upcoming
        ? upcomingAppointments
        : pastAppointments;
  }

  /// Inicia la escucha en tiempo real de citas del cliente mediante Stream en Firestore.
  void startListening() {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    _appointmentsSub?.cancel();
    _appointmentsSub = repository.streamClientAppointments(clientId).listen(
      (appointments) {
        _allAppointments = appointments;
        _isLoading = false;
        _failure = null;
        notifyListeners();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Carga inicial de citas mediante consulta paginada utilizando el límite [limit].
  Future<void> loadInitialAppointments({int limit = 10}) async {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    final result = await repository.getClientAppointments(
      clientId: clientId,
      limit: limit,
    );

    if (result.isOk) {
      final paginated = result.dataOrNull!;
      _allAppointments = paginated.appointments;
      _lastDocument = paginated.lastDocument;
      _hasMore = paginated.hasMore;
      _isLoading = false;
      _failure = null;
      notifyListeners();
    } else {
      _failure = result.failureOrNull;
      _errorMessage = _failure?.code;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la siguiente página de citas utilizando el cursor documental `startAfterDocument`.
  Future<void> loadMoreAppointments({int limit = 10}) async {
    if (!_hasMore || _isLoading || _isLoadingMore) return;

    _isLoadingMore = true;
    _failure = null;
    notifyListeners();

    final result = await repository.getClientAppointments(
      clientId: clientId,
      limit: limit,
      startAfter: _lastDocument,
    );

    if (result.isOk) {
      final paginated = result.dataOrNull!;
      _allAppointments = [..._allAppointments, ...paginated.appointments];
      _lastDocument = paginated.lastDocument;
      _hasMore = paginated.hasMore;
      _isLoadingMore = false;
      _failure = null;
      notifyListeners();
    } else {
      _failure = result.failureOrNull;
      _errorMessage = _failure?.code;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Cancela la cita delegando la operación atómica a la Cloud Function `cancelAppointmentByClient`.
  ///
  /// No realiza escritura directa en Firestore ni altera cupos en cliente. En caso de éxito,
  /// actualiza reactivamente el estado local a `CANCELLED` para reflejar el cambio inmediato.
  Future<Result<void>> cancelAppointment(String appointmentId) async {
    _isCancelling = true;
    _cancellingAppointmentId = appointmentId;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final result = await repository.cancelAppointmentByClient(appointmentId);

    _isCancelling = false;
    _cancellingAppointmentId = null;

    if (result.isOk) {
      _failure = null;
      // Actualización reactiva local del estado de la cita a CANCELLED
      _allAppointments = _allAppointments.map((appt) {
        if (appt.id == appointmentId) {
          return appt.copyWith(status: 'CANCELLED');
        }
        return appt;
      }).toList();
      notifyListeners();
      return const Ok(null);
    } else {
      _failure = result.failureOrNull;
      _errorMessage = _failure?.code;
      notifyListeners();
      return Err(_failure!);
    }
  }

  /// Libera la suscripción activa al Stream de Firestore.
  @override
  void dispose() {
    _appointmentsSub?.cancel();
    super.dispose();
  }
}
