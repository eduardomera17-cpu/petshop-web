// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/agenda/view_models/admin_agenda_view_model.dart
// Propósito: ViewModel de administración para la agenda interactiva de citas,
//            bloqueos de disponibilidad, resolución de conflictos y atajos operativos.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';

/// Modalidad de presentación temporal para el calendario de citas administrativas.
enum AgendaViewMode {
  /// Despliegue de la ventana semanal (lunes a domingo).
  week,

  /// Despliegue de la vista en cuadrícula de mes completo.
  month,
}

/// Gestor de estado para la agenda interactiva del panel de administración.
///
/// Centraliza la escucha en tiempo real de citas programadas y bloqueos de disponibilidad,
/// permite alternar entre vistas semanal y mensual, aplicar filtros por servicio y estado,
/// confirmar, completar, cancelar o reagendar citas indivisiblemente, y gestionar el bloqueo
/// de franjas horarias con detección inmediata de conflictos operativos.
class AdminAgendaViewModel extends ChangeNotifier {
  /// Repositorio de operaciones y suscripciones de la agenda.
  final AgendaRepository agendaRepository;

  StreamSubscription<List<Appointment>>? _appointmentsSub;
  StreamSubscription<List<AvailabilityBlock>>? _blocksSub;

  AgendaViewMode _viewMode = AgendaViewMode.week;

  /// Modalidad de visualización activa (semana o mes).
  AgendaViewMode get viewMode => _viewMode;

  DateTime _selectedDate = BusinessClock.now();

  /// Fecha de referencia seleccionada en el selector de agenda.
  DateTime get selectedDate => _selectedDate;

  String? _filterServiceId;

  /// Filtro activo por identificador de servicio veterinario.
  String? get filterServiceId => _filterServiceId;

  String? _filterStatus;

  /// Filtro activo por estado de la cita ('PENDING', 'CONFIRMED', 'ALL', etc.).
  String? get filterStatus => _filterStatus;

  List<Appointment> _appointments = [];

  /// Lista integral de citas cargadas desde Firestore.
  List<Appointment> get appointments => _appointments;

  List<AvailabilityBlock> _blocks = [];

  /// Lista de bloqueos de disponibilidad vigentes.
  List<AvailabilityBlock> get blocks => _blocks;

  List<BlockConflictItem> _pendingConflicts = [];

  /// Citas en conflicto resultantes tras intentar registrar un bloqueo de agenda.
  List<BlockConflictItem> get pendingConflicts => _pendingConflicts;

  Appointment? _selectedAppointment;

  /// Cita seleccionada activamente en la interfaz para acciones rápidas o detalle.
  Appointment? get selectedAppointment => _selectedAppointment;

  bool _isLoading = true;

  /// Indica si se encuentra cargando la agenda inicial.
  bool get isLoading => _isLoading;

  bool _isActionInProgress = false;

  /// Indica si se está ejecutando una mutación asíncrona sobre una cita o bloqueo.
  bool get isActionInProgress => _isActionInProgress;

  String? _errorMessage;

  /// Código o descripción legible del error suscitado.
  String? get errorMessage => _errorMessage;

  Failure? _failure;

  /// Objeto de falla tipada retornado por el repositorio.
  Failure? get failure => _failure;

  /// Construye el ViewModel inicializando la fecha de referencia y cargando los flujos de datos.
  AdminAgendaViewModel({
    required this.agendaRepository,
    DateTime? initialDate,
  }) {
    if (initialDate != null) {
      _selectedDate = initialDate;
    }
    init();
  }

  /// Inicia la sincronización en tiempo real de citas y bloqueos de agenda.
  void init() {
    _isLoading = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    _appointmentsSub?.cancel();
    _appointmentsSub = agendaRepository.streamAppointments().listen(
      (items) {
        _appointments = items;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        _isLoading = false;
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        notifyListeners();
      },
    );

    _blocksSub?.cancel();
    _blocksSub = agendaRepository.streamAvailabilityBlocks().listen(
      (items) {
        _blocks = items;
        notifyListeners();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        notifyListeners();
      },
    );
  }

  /// Modifica el modo de vista (semanal o mensual) y notifica a los escuchas.
  void setViewMode(AgendaViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  /// Establece la fecha de foco del calendario administrativo.
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Aplica o limpia el filtro de citas por servicio.
  void setFilterService(String? serviceId) {
    _filterServiceId = serviceId;
    notifyListeners();
  }

  /// Aplica o limpia el filtro de citas por estado de atención.
  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  /// Selecciona una cita específica para acciones rápidas o visualización de detalle.
  void selectAppointment(Appointment? appt) {
    _selectedAppointment = appt;
    notifyListeners();
  }

  /// Limpia la lista de conflictos detectados tras gestionar o descartar un bloqueo.
  void clearConflicts() {
    _pendingConflicts = [];
    notifyListeners();
  }

  /// Filtra las citas en memoria según los criterios activos y la fecha/modo de vista.
  List<Appointment> get filteredAppointments {
    return _appointments.where((appt) {
      if (_filterServiceId != null && _filterServiceId!.isNotEmpty) {
        if (appt.serviceId != _filterServiceId) return false;
      }
      if (_filterStatus != null && _filterStatus!.isNotEmpty && _filterStatus != 'ALL') {
        if (appt.status != _filterStatus) return false;
      }

      if (_viewMode == AgendaViewMode.week) {
        // Ventana semanal alrededor de _selectedDate (lunes a domingo)
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final apptDate = DateTime.tryParse(appt.dateString);
        if (apptDate != null) {
          final isAfterOrSame = apptDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
          final isBeforeOrSame = apptDate.isBefore(endOfWeek.add(const Duration(days: 1)));
          if (!isAfterOrSame || !isBeforeOrSame) return false;
        }
      } else {
        // Ventana mensual
        final apptDate = DateTime.tryParse(appt.dateString);
        if (apptDate != null) {
          if (apptDate.year != _selectedDate.year || apptDate.month != _selectedDate.month) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  /// Formatea la fecha en la zona horaria del negocio (America/Guayaquil).
  String get formattedSelectedDate {
    return DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  /// Confirmar una cita pendiente (AG-02, CA-AD-16).
  Future<bool> confirmAppointment(String appointmentId) async {
    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    final result = await agendaRepository.confirmAppointment(appointmentId);
    _isActionInProgress = false;

    return result.when(
      ok: (_) {
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Completar una cita (AG-03, CL-10, CA-AD-44).
  Future<bool> completeAppointment(String appointmentId) async {
    if (_isActionInProgress) return false;
    _isActionInProgress = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await agendaRepository.completeAppointment(appointmentId);
    _isActionInProgress = false;

    return result.when(
      ok: (requiresClinical) {
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Cancelar una cita por parte del personal administrativo (AG-05, AG-09, CA-AD-16).
  Future<bool> cancelAppointment(String appointmentId) async {
    _isActionInProgress = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await agendaRepository.cancelAppointmentByStaff(appointmentId);
    _isActionInProgress = false;

    return result.when(
      ok: (_) {
        // Si la cita estaba en la lista de conflictos, eliminarla
        _pendingConflicts.removeWhere((c) => c.appointmentId == appointmentId);
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Reagendar indivisiblemente una cita (AG-08, CA-61, CA-AD-54).
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required String toDateString,
    required String toTimeSlot,
  }) async {
    _isActionInProgress = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await agendaRepository.rescheduleAppointment(
      appointmentId: appointmentId,
      toDateString: toDateString,
      toTimeSlot: toTimeSlot,
    );
    _isActionInProgress = false;

    return result.when(
      ok: (_) {
        _pendingConflicts.removeWhere((c) => c.appointmentId == appointmentId);
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Crear un bloqueo de disponibilidad (AG-06, CA-AD-55, Caso Crítico 14).
  ///
  /// Si se detectan citas en conflicto, se cargan en [_pendingConflicts] para
  /// desplegar el modal de resolución inmediata.
  Future<bool> createAvailabilityBlock({
    required String dateString,
    String? timeSlot,
    String? reason,
  }) async {
    _isActionInProgress = true;
    _failure = null;
    _errorMessage = null;
    notifyListeners();

    final result = await agendaRepository.setAvailabilityBlock(
      dateString: dateString,
      timeSlot: timeSlot,
      reason: reason,
      action: 'BLOCK',
    );
    _isActionInProgress = false;

    return result.when(
      ok: (conflicts) {
        if (conflicts.isNotEmpty) {
          _pendingConflicts = conflicts;
        } else {
          _pendingConflicts = [];
        }
        notifyListeners();
        return true;
      },
      err: (failure) {
        _failure = failure;
        _errorMessage = failure.code;
        notifyListeners();
        return false;
      },
    );
  }

  /// Atajo de teclado: Confirmar la cita seleccionada actualmente (N-AD-10 parcial).
  Future<void> confirmSelectedAppointment() async {
    if (_selectedAppointment != null && _selectedAppointment!.status == 'PENDING') {
      await confirmAppointment(_selectedAppointment!.id);
    }
  }

  /// Atajo de teclado: Completar la cita seleccionada actualmente (N-AD-10 parcial).
  Future<void> completeSelectedAppointment() async {
    if (_selectedAppointment != null && _selectedAppointment!.status == 'CONFIRMED') {
      await completeAppointment(_selectedAppointment!.id);
    }
  }

  /// Cancela las suscripciones reactivas de citas y bloqueos de agenda.
  @override
  void dispose() {
    _appointmentsSub?.cancel();
    _blocksSub?.cancel();
    super.dispose();
  }
}
