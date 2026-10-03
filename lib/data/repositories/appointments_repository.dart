// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: appointments_repository.dart
// Propósito: Repositorio para la consulta de disponibilidad en tiempo real, agendamiento y gestión de citas del cliente.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/appointment_dto.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/domain/models/appointment.dart';

/// Configuración operativa pública leída desde `/business_config/public_operating`.
class PublicOperatingConfig {
  /// Zona horaria del negocio.
  final String timezone;

  /// Hora de apertura matutina (HH:MM).
  final String openingTime;

  /// Hora de cierre vespertino (HH:MM).
  final String closingTime;

  /// Duración en minutos de las franjas de cita.
  final int slotDurationMinutes;

  /// Días laborales hábiles (1 = lunes a 7 = domingo).
  final List<int> workingWeekdays;

  /// Constructor inmutable de configuración operativa pública.
  const PublicOperatingConfig({
    required this.timezone,
    required this.openingTime,
    required this.closingTime,
    required this.slotDurationMinutes,
    required this.workingWeekdays,
  });

  /// Construye la configuración a partir del mapa de datos del documento.
  factory PublicOperatingConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const PublicOperatingConfig(
        timezone: 'America/Guayaquil',
        openingTime: '08:00',
        closingTime: '18:00',
        slotDurationMinutes: 30,
        workingWeekdays: [1, 2, 3, 4, 5, 6],
      );
    }

    final rawWeekdays = data['workingWeekdays'];
    List<int> parsedWeekdays;
    if (rawWeekdays is List) {
      parsedWeekdays = rawWeekdays.map((e) => (e as num).toInt()).toList();
    } else {
      parsedWeekdays = const [1, 2, 3, 4, 5, 6];
    }

    return PublicOperatingConfig(
      timezone: (data['timezone'] as String?) ?? 'America/Guayaquil',
      openingTime: (data['openingTime'] as String?) ?? '08:00',
      closingTime: (data['closingTime'] as String?) ?? '18:00',
      slotDurationMinutes: (data['slotDurationMinutes'] as num?)?.toInt() ?? 30,
      workingWeekdays: parsedWeekdays,
    );
  }
}

/// Repositorio de agendamiento y disponibilidad en tiempo real para clientes.
///
/// Gestiona la lectura de centinelas de exclusividad (`/slot_locks`), bloqueos
/// administrativos (`/availability_blocks`), configuración operativa y la
/// creación atómica de citas mediante Cloud Functions (sin escritura optimista).
class AppointmentsRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Servicio cliente para invocar Cloud Functions autorizadas.
  final FunctionsService _functionsService;

  /// Constructor del repositorio de citas.
  AppointmentsRepository({
    required this.firestore,
    FunctionsService? functionsService,
  })  : _functionsService = functionsService ?? FunctionsService();

  FirebaseFirestore get _firestore => firestore;

  DocumentReference<Map<String, dynamic>> get _operatingDoc =>
      _firestore.collection('business_config').doc('public_operating');

  DocumentReference<Map<String, dynamic>> get _pricingDoc =>
      _firestore.collection('business_config').doc('public_pricing');

  CollectionReference<Map<String, dynamic>> get _slotLocksCol =>
      _firestore.collection('slot_locks');

  CollectionReference<Map<String, dynamic>> get _blocksCol =>
      _firestore.collection('availability_blocks');

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _firestore.collection('appointments');

  /// Consulta la configuración operativa de horarios y días laborales.
  Future<Result<PublicOperatingConfig>> getOperatingConfig() async {
    try {
      final doc = await _operatingDoc.get();
      return Ok(PublicOperatingConfig.fromMap(doc.data()));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real la configuración operativa del negocio.
  Stream<PublicOperatingConfig> streamOperatingConfig() {
    return _operatingDoc.snapshots().map((snapshot) {
      return PublicOperatingConfig.fromMap(snapshot.data());
    });
  }

  /// Consulta la configuración impositiva vigente (IVA, ICE).
  Future<Result<PublicPricingConfig>> getPricingConfig() async {
    try {
      final doc = await _pricingDoc.get();
      return Ok(PublicPricingConfig.fromMap(doc.data()));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real la configuración impositiva.
  Stream<PublicPricingConfig> streamPricingConfig() {
    return _pricingDoc.snapshots().map((snapshot) {
      return PublicPricingConfig.fromMap(snapshot.data());
    });
  }

  /// Escucha en tiempo real el conjunto de claves de franjas ocupadas en `/slot_locks`.
  Stream<Set<String>> streamSlotLocks() {
    return _slotLocksCol.snapshots().map((snapshot) {
      return snapshot.docs.map((d) => d.id).toSet();
    });
  }

  /// Escucha en tiempo real los bloqueos administrativos en `/availability_blocks`.
  Stream<Set<String>> streamAvailabilityBlocks() {
    return _blocksCol.snapshots().map((snapshot) {
      return snapshot.docs.map((d) => d.id).toSet();
    });
  }

  /// Escucha las citas pertenecientes al cliente autenticado en `/appointments`.
  ///
  /// @param clientId UID del usuario cliente.
  Stream<List<Appointment>> streamClientAppointments(String clientId) {
    return _appointmentsCol
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((d) {
        return AppointmentDto.fromFirestore(d).toDomain();
      }).toList();
    });
  }

  /// Escucha en tiempo real las citas completadas o confirmadas aún no facturadas.
  ///
  /// @param clientId UID del cliente.
  Stream<List<Appointment>> streamCartAppointments(String clientId) {
    return _appointmentsCol
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: ['PENDING', 'CONFIRMED', 'COMPLETED'])
        .where('isBilled', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((d) {
        return AppointmentDto.fromFirestore(d).toDomain();
      }).toList();
    });
  }

  /// Invoca la creación atómica de una cita mediante la Cloud Function [createAppointment].
  ///
  /// Cumple con la regla de cero escrituras optimistas en cliente para evitar solapamientos.
  /// @param petId ID de la mascota.
  /// @param serviceId ID del servicio.
  /// @param dateString Fecha en formato YYYY-MM-DD.
  /// @param timeSlot Franja seleccionada.
  /// @param clientNotes Observaciones del cliente.
  /// @param requestId ID de solicitud idempotente opcional.
  /// @return [Result] con el ID de la cita creada en caso de éxito.
  Future<Result<String>> createAppointment({
    required String petId,
    required String serviceId,
    required String dateString,
    required String timeSlot,
    String? clientNotes,
    String? requestId,
  }) async {
    final res = await _functionsService.createAppointment(
      petId: petId,
      serviceId: serviceId,
      dateString: dateString,
      timeSlot: timeSlot,
      clientNotes: clientNotes,
      requestId: requestId,
    );

    if (res.isOk) {
      final data = res.dataOrNull!;
      final appointmentId = (data['appointmentId'] as String?) ?? '';
      return Ok(appointmentId);
    } else {
      return Err(res.failureOrNull!);
    }
  }

  /// Consulta paginada por cursor de las citas históricas del cliente autenticado.
  ///
  /// Emplea el índice compuesto `clientId` ASC + `dateString` DESC + `timeSlot` DESC.
  /// @param clientId UID del cliente.
  /// @param limit Límite de documentos a recuperar.
  /// @param startAfter Documento de corte para paginación.
  /// @return [Result] con [PaginatedAppointments].
  Future<Result<PaginatedAppointments>> getClientAppointments({
    required String clientId,
    int limit = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _appointmentsCol
          .where('clientId', isEqualTo: clientId)
          .orderBy('dateString', descending: true)
          .orderBy('timeSlot', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final appointments = snapshot.docs.map((d) {
        return AppointmentDto.fromFirestore(d).toDomain();
      }).toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == limit;

      return Ok(
        PaginatedAppointments(
          appointments: appointments,
          lastDocument: lastDoc,
          hasMore: hasMore,
        ),
      );
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la cancelación transaccional de una cita propia mediante [cancelAppointmentByClient].
  ///
  /// @param appointmentId ID de la cita a cancelar.
  Future<Result<void>> cancelAppointmentByClient(String appointmentId) async {
    final res = await _functionsService.cancelAppointmentByClient(
      appointmentId: appointmentId,
    );

    if (res.isOk) {
      return const Ok(null);
    } else {
      return Err(res.failureOrNull!);
    }
  }
}

/// Contenedor de resultados paginados de citas con cursor para Firestore.
class PaginatedAppointments {
  /// Citas recuperadas en la página actual.
  final List<Appointment> appointments;

  /// Último snapshot obtenido, utilizado como cursor `startAfterDocument`.
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;

  /// Indica si existen más páginas pendientes por consultar.
  final bool hasMore;

  /// Constructor inmutable del resultado paginado.
  const PaginatedAppointments({
    required this.appointments,
    this.lastDocument,
    required this.hasMore,
  });
}
