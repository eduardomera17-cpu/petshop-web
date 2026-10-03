// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: booking_view_model.dart
// Propósito: ViewModel para la máquina de estados del asistente de agendamiento de citas, control de concurrencia mediante cerrojos reactivos y cálculo de tarifas impositivas.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/appointments_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/domain/models/service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';

/// Pasos secuenciales del asistente o flujo de agendamiento de citas.
enum BookingStep {
  /// Selección del servicio veterinario o estético deseado.
  serviceSelection,

  /// Selección de la mascota activa que recibirá la atención.
  petSelection,

  /// Elección del día operativo y la franja horaria disponible.
  dateTimeSelection,

  /// Revisión del desglose preliminar de precios e impuestos antes del envío.
  confirmation,

  /// Pantalla final de éxito con el código identificador de la cita reservada.
  success,
}

/// ViewModel para la máquina de estados del flujo de agendamiento de citas.
///
/// Gestiona la reactividad de cerrojos (`slot_locks`), horarios de atención comercial,
/// exclusión de franjas ocupadas o pasadas según la hora de negocio [BusinessClock] y la
/// llamada atómica a Cloud Functions sin escrituras optimistas en cliente, garantizando
/// que ninguna reserva se confirme sin validación transaccional en el servidor.
class BookingViewModel extends ChangeNotifier {
  /// Repositorio de agendamiento para creación de citas y lectura de cerrojos.
  final AppointmentsRepository appointmentsRepository;

  /// Repositorio del catálogo de servicios veterinarios.
  final CatalogRepository catalogRepository;

  /// Repositorio de mascotas del cliente autenticado.
  final PetsRepository petsRepository;

  /// Identificador del cliente propietario de la cita.
  final String ownerId;

  BookingStep _step = BookingStep.serviceSelection;

  List<Service> _services = const [];
  List<Pet> _pets = const [];

  Service? _selectedService;
  Pet? _selectedPet;
  String? _selectedDate;
  String? _selectedTimeSlot;
  String _clientNotes = '';

  PublicOperatingConfig _operatingConfig = const PublicOperatingConfig(
    timezone: 'America/Guayaquil',
    openingTime: '08:00',
    closingTime: '18:00',
    slotDurationMinutes: 30,
    workingWeekdays: [1, 2, 3, 4, 5, 6],
  );

  PublicPricingConfig _pricingConfig = const PublicPricingConfig(
    ivaBp: 1500,
    iceIncludedInIvaBase: true,
  );

  Set<String> _slotLocks = const {};
  Set<String> _availabilityBlocks = const {};

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  Failure? _failure;
  Failure? get failure => _failure;
  String? _successAppointmentId;

  StreamSubscription<List<Service>>? _servicesSub;
  StreamSubscription<List<Pet>>? _petsSub;
  StreamSubscription<PublicOperatingConfig>? _operatingSub;
  StreamSubscription<PublicPricingConfig>? _pricingSub;
  StreamSubscription<Set<String>>? _locksSub;
  StreamSubscription<Set<String>>? _blocksSub;

  /// Constructor con inyección de repositorios y cliente.
  BookingViewModel({
    required this.appointmentsRepository,
    required this.catalogRepository,
    required this.petsRepository,
    required this.ownerId,
  });

  /// Paso actual en la secuencia del wizard.
  BookingStep get step => _step;

  /// Servicios activos disponibles para agendar.
  List<Service> get services => _services;

  /// Mascotas activas del cliente.
  List<Pet> get pets => _pets;

  /// Servicio actualmente seleccionado por el cliente.
  Service? get selectedService => _selectedService;

  /// Mascota actualmente seleccionada.
  Pet? get selectedPet => _selectedPet;

  /// Fecha seleccionada en formato ISO `YYYY-MM-DD`.
  String? get selectedDate => _selectedDate;

  /// Franja horaria seleccionada (ej. `'09:30'`).
  String? get selectedTimeSlot => _selectedTimeSlot;

  /// Notas u observaciones adicionales provistas por el cliente.
  String get clientNotes => _clientNotes;

  /// Configuración de horarios de atención y días laborables de la clínica.
  PublicOperatingConfig get operatingConfig => _operatingConfig;

  /// Configuración de parámetros impositivos vigentes (IVA e ICE).
  PublicPricingConfig get pricingConfig => _pricingConfig;

  /// Conjunto de claves de franjas reservadas actualmente (`fecha_hora`).
  Set<String> get slotLocks => _slotLocks;

  /// Conjunto de bloqueos manuales administrativos de agenda.
  Set<String> get availabilityBlocks => _availabilityBlocks;

  /// Indica si la información inicial se encuentra cargando desde Firestore.
  bool get isLoading => _isLoading;

  /// Indica si hay una transacción de reserva en progreso hacia Cloud Functions.
  bool get isSubmitting => _isSubmitting;

  /// Mensaje de error a desplegar en la interfaz gráfica.
  String? get errorMessage => _errorMessage;

  /// Identificador asignado a la cita confirmada tras completarse el agendamiento.
  String? get successAppointmentId => _successAppointmentId;

  /// Cálculo dinámico del desglose de precio estimado (base, IVA, ICE y total).
  LinePricingResult? get pricingPreview {
    if (_selectedService == null) return null;
    return calculateLinePricing(
      basePriceCents: _selectedService!.basePriceCents,
      iceBp: _selectedService!.iceBp,
      ivaBp: _pricingConfig.ivaBp,
      iceIncludedInIvaBase: _pricingConfig.iceIncludedInIvaBase,
    );
  }

  /// Inicia la escucha reactiva de disponibilidad, catálogo y configuración.
  ///
  /// Conecta 6 flujos de datos en tiempo real:
  /// 1. Servicios comerciales activos.
  /// 2. Mascotas activas registradas a nombre de [ownerId].
  /// 3. Parámetros operativos (horarios de apertura, cierre e intervalos).
  /// 4. Parámetros de facturación (tarifas de IVA e ICE vigentes).
  /// 5. Cerrojos atómicos de concurrencia (`slot_locks`).
  /// 6. Bloqueos manuales de disponibilidad administrativa.
  void init() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Catálogo de servicios activos
    _servicesSub = catalogRepository.streamServices(onlyActive: true).listen(
      (items) {
        _services = items;
        _checkLoadingComplete();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
      },
    );

    // 2. Mascotas activas del cliente
    _petsSub = petsRepository.streamPets(ownerId).listen(
      (items) {
        _pets = items.where((p) => p.status == 'ACTIVE').toList();
        _checkLoadingComplete();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
      },
    );

    // 3. Configuración operativa
    _operatingSub = appointmentsRepository.streamOperatingConfig().listen(
      (config) {
        _operatingConfig = config;
        _checkLoadingComplete();
      },
      onError: (_) {},
    );

    // 4. Configuración impositiva
    _pricingSub = appointmentsRepository.streamPricingConfig().listen(
      (pricing) {
        _pricingConfig = pricing;
        notifyListeners();
      },
      onError: (_) {},
    );

    // 5. Centinelas de franjas ocupadas
    _locksSub = appointmentsRepository.streamSlotLocks().listen(
      (locks) {
        _slotLocks = locks;
        notifyListeners();
      },
      onError: (_) {},
    );

    // 6. Bloqueos administrativos
    _blocksSub = appointmentsRepository.streamAvailabilityBlocks().listen(
      (blocks) {
        _availabilityBlocks = blocks;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Verifica si las consultas iniciales han emitido su primer estado para apagar el indicador de carga.
  void _checkLoadingComplete() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selecciona el [service] deseado y avanza a la selección de mascota.
  void selectService(Service service) {
    _selectedService = service;
    _errorMessage = null;
    _step = BookingStep.petSelection;
    notifyListeners();
  }

  /// Selecciona la [pet] que recibirá atención y avanza a la selección de fecha y hora.
  ///
  /// Valida que el estado de la mascota sea estrictamente `ACTIVE`.
  void selectPet(Pet pet) {
    if (pet.status != 'ACTIVE') {
      _errorMessage = 'Solo se pueden agendar citas para mascotas activas.';
      notifyListeners();
      return;
    }
    _selectedPet = pet;
    _errorMessage = null;
    _step = BookingStep.dateTimeSelection;
    notifyListeners();
  }

  /// Establece la fecha [dateString] en formato `YYYY-MM-DD` y restablece cualquier franja horaria previa.
  void selectDate(String dateString) {
    _selectedDate = dateString;
    _selectedTimeSlot = null; // Reiniciar franja al cambiar día
    _errorMessage = null;
    notifyListeners();
  }

  /// Establece la franja horaria [slot] seleccionada.
  void selectTimeSlot(String slot) {
    _selectedTimeSlot = slot;
    _errorMessage = null;
    notifyListeners();
  }

  /// Valida que se hayan completado todos los pasos previos y avanza a la pantalla de confirmación.
  void proceedToConfirm() {
    if (_selectedService == null ||
        _selectedPet == null ||
        _selectedDate == null ||
        _selectedTimeSlot == null) {
      _errorMessage = 'Por favor completa todos los pasos anteriores.';
      notifyListeners();
      return;
    }
    _step = BookingStep.confirmation;
    _errorMessage = null;
    notifyListeners();
  }

  /// Registra notas u observaciones del cliente para la cita (máximo 250 caracteres).
  void setClientNotes(String notes) {
    if (notes.length <= 250) {
      _clientNotes = notes;
      notifyListeners();
    }
  }

  /// Permite retroceder o navegar a un paso específico del wizard [targetStep].
  void goToStep(BookingStep targetStep) {
    if (targetStep == BookingStep.success) return;
    _step = targetStep;
    _errorMessage = null;
    notifyListeners();
  }

  /// Restablece completamente el formulario a su estado inicial.
  void reset() {
    _step = BookingStep.serviceSelection;
    _selectedService = null;
    _selectedPet = null;
    _selectedDate = null;
    _selectedTimeSlot = null;
    _clientNotes = '';
    _errorMessage = null;
    _successAppointmentId = null;
    notifyListeners();
  }

  /// Retorna las franjas horarias válidas y operativas para una fecha específica.
  ///
  /// Excluye:
  /// - Fechas pasadas o días no laborables de la veterinaria.
  /// - Franjas horarias que ya transcurrieron hoy calculadas según [BusinessClock.now].
  /// - Turnos ocupados por reservas confirmadas ([slotLocks]).
  /// - Días o franjas deshabilitadas administrativamente ([availabilityBlocks]).
  List<String> getSlotsForDate(String dateString) {
    final today = BusinessClock.todayBusinessDate();
    if (dateString.compareTo(today) < 0) {
      return const [];
    }

    final parts = dateString.split('-').map(int.parse).toList();
    final dt = DateTime(parts[0], parts[1], parts[2]);
    if (!_operatingConfig.workingWeekdays.contains(dt.weekday)) {
      return const [];
    }

    final openParts = _operatingConfig.openingTime.split(':').map(int.parse).toList();
    final closeParts = _operatingConfig.closingTime.split(':').map(int.parse).toList();

    var currentMinute = openParts[0] * 60 + openParts[1];
    final endMinute = closeParts[0] * 60 + closeParts[1];
    final step = _operatingConfig.slotDurationMinutes > 0
        ? _operatingConfig.slotDurationMinutes
        : 30;

    final nowTz = BusinessClock.now();
    final isToday = dateString == today;
    final currentBusinessMinutes = nowTz.hour * 60 + nowTz.minute;

    final slots = <String>[];
    while (currentMinute < endMinute) {
      final hour = currentMinute ~/ 60;
      final minute = currentMinute % 60;
      final slotString =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      // Si es hoy, excluir franjas del pasado
      final isPast = isToday && currentMinute <= currentBusinessMinutes;

      final slotKey = '${dateString}_$slotString';
      final isLocked = _slotLocks.contains(slotKey);
      final isBlocked = _availabilityBlocks.contains(slotKey) ||
          _availabilityBlocks.contains(dateString);

      if (!isPast && !isLocked && !isBlocked) {
        slots.add(slotString);
      }

      currentMinute += step;
    }

    return slots;
  }

  /// Evalúa puntualmente si una franja horaria específica [slotString] se encuentra disponible en [dateString].
  bool isSlotAvailable(String dateString, String slotString) {
    final slotKey = '${dateString}_$slotString';
    if (_slotLocks.contains(slotKey)) return false;
    if (_availabilityBlocks.contains(slotKey) || _availabilityBlocks.contains(dateString)) {
      return false;
    }

    final today = BusinessClock.todayBusinessDate();
    if (dateString == today) {
      final nowTz = BusinessClock.now();
      final currentBusinessMinutes = nowTz.hour * 60 + nowTz.minute;
      final slotParts = slotString.split(':').map(int.parse).toList();
      final slotMinute = slotParts[0] * 60 + slotParts[1];
      if (slotMinute <= currentBusinessMinutes) return false;
    }

    return true;
  }

  /// Ejecuta el agendamiento atómico de la cita mediante Cloud Functions.
  ///
  /// Valida la conectividad [isOnline] y la presencia de todos los datos requeridos.
  /// Si la función responde exitosamente, fija [successAppointmentId] y transiciona
  /// al estado [BookingStep.success].
  Future<bool> confirmBooking({
    required bool isOnline,
    AppLocalizations? l10n,
  }) async {
    if (!isOnline) {
      _errorMessage = l10n?.offlineWarning ?? 'Sin conexión a internet.';
      notifyListeners();
      return false;
    }

    if (_selectedService == null ||
        _selectedPet == null ||
        _selectedDate == null ||
        _selectedTimeSlot == null) {
      _errorMessage = 'Faltan datos obligatorios para confirmar la cita.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await appointmentsRepository.createAppointment(
      petId: _selectedPet!.id,
      serviceId: _selectedService!.id,
      dateString: _selectedDate!,
      timeSlot: _selectedTimeSlot!,
      clientNotes: _clientNotes.isNotEmpty ? _clientNotes : null,
    );

    _isSubmitting = false;

    if (res.isOk) {
      _failure = null;
      _successAppointmentId = res.dataOrNull;
      _step = BookingStep.success;
      notifyListeners();
      return true;
    } else {
      final failure = res.failureOrNull!;
      _failure = failure;
      if (l10n != null) {
        _errorMessage = failure.toLocalizedMessage(l10n);
      } else {
        _errorMessage = failure.code;
      }
      notifyListeners();
      return false;
    }
  }

  /// Cancela todas las suscripciones activas a Firestore para evitar fugas de memoria.
  @override
  void dispose() {
    _servicesSub?.cancel();
    _petsSub?.cancel();
    _operatingSub?.cancel();
    _pricingSub?.cancel();
    _locksSub?.cancel();
    _blocksSub?.cancel();
    super.dispose();
  }
}
