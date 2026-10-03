// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: agenda_repository.dart
// Propósito: Repositorio administrativo para la gestión de turnos de agenda, bloqueos y control de clientes.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/appointment_dto.dart';
import 'package:mipetshop/data/models/pet_dto.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/domain/models/user_profile.dart';

/// Representa un bloqueo de disponibilidad temporal o definitivo en la agenda.
class AvailabilityBlock {
  /// Identificador único del bloqueo (ej. 'YYYY-MM-DD_HH:MM' o 'YYYY-MM-DD').
  final String id;

  /// Fecha del bloqueo en formato YYYY-MM-DD.
  final String dateString;

  /// Franja horaria bloqueada (null si abarca el día completo).
  final String? timeSlot;

  /// Motivo o justificación del bloqueo (ej. feriado, mantenimiento, descanso médico).
  final String? reason;

  /// Marca temporal de creación en el servidor.
  final DateTime? createdAt;

  /// Identificador del usuario que configuró el bloqueo.
  final String? createdBy;

  /// Constructor inmutable del bloqueo de disponibilidad.
  const AvailabilityBlock({
    required this.id,
    required this.dateString,
    this.timeSlot,
    this.reason,
    this.createdAt,
    this.createdBy,
  });

  /// Construye un [AvailabilityBlock] desde un [DocumentSnapshot] de Firestore.
  factory AvailabilityBlock.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? created;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    }
    return AvailabilityBlock(
      id: doc.id,
      dateString: (data['dateString'] as String?) ?? (doc.id.contains('_') ? doc.id.split('_').first : doc.id),
      timeSlot: (data['timeSlot'] as String?) ?? (doc.id.contains('_') ? doc.id.split('_').last : null),
      reason: data['reason'] as String?,
      createdAt: created,
      createdBy: data['createdBy'] as String?,
    );
  }
}

/// Modela una cita activa que entra en conflicto con un bloqueo operativo programado.
class BlockConflictItem {
  /// Identificador de la cita afectada.
  final String appointmentId;

  /// Identificador del cliente.
  final String clientId;

  /// Nombre del cliente para contacto urgente.
  final String clientName;

  /// Identificador de la mascota.
  final String petId;

  /// Nombre de la mascota.
  final String petName;

  /// Identificador del servicio contratado.
  final String serviceId;

  /// Nombre del servicio.
  final String serviceName;

  /// Fecha programada de la cita.
  final String dateString;

  /// Franja horaria de la cita.
  final String timeSlot;

  /// Estado de la cita ('PENDING', 'CONFIRMED').
  final String status;

  /// Constructor inmutable del ítem de conflicto.
  const BlockConflictItem({
    required this.appointmentId,
    required this.clientId,
    required this.clientName,
    required this.petId,
    required this.petName,
    required this.serviceId,
    required this.serviceName,
    required this.dateString,
    required this.timeSlot,
    required this.status,
  });

  /// Mapea la información desde una respuesta JSON de Cloud Functions.
  factory BlockConflictItem.fromMap(Map<String, dynamic> map) {
    return BlockConflictItem(
      appointmentId: (map['appointmentId'] as String?) ?? '',
      clientId: (map['clientId'] as String?) ?? '',
      clientName: (map['clientName'] as String?) ?? 'Cliente',
      petId: (map['petId'] as String?) ?? '',
      petName: (map['petName'] as String?) ?? 'Mascota',
      serviceId: (map['serviceId'] as String?) ?? '',
      serviceName: (map['serviceName'] as String?) ?? 'Servicio',
      dateString: (map['dateString'] as String?) ?? '',
      timeSlot: (map['timeSlot'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'PENDING',
    );
  }
}

/// Repositorio de acceso a datos para la administración de la agenda y citas globales.
///
/// Implementa consultas en tiempo real y transacciones de confirmación, completado,
/// reagendamiento, cancelación y gestión de clientes.
class AgendaRepository {
  /// Instancia de Cloud Firestore para consultas y streams.
  final FirebaseFirestore firestore;

  /// Servicio cliente de Cloud Functions para mutaciones atómicas.
  final FunctionsService _functionsService;

  /// Constructor del repositorio de agenda.
  AgendaRepository({
    required this.firestore,
    FunctionsService? functionsService,
  })  : _functionsService = functionsService ?? FunctionsService();

  FirebaseFirestore get _firestore => firestore;

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _blocksCol =>
      _firestore.collection('availability_blocks');

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _petsCol =>
      _firestore.collection('pets');

  /// Escucha en tiempo real el flujo de citas filtradas por estado, servicio y/o fecha.
  ///
  /// Consulta la colección `/appointments` en Cloud Firestore.
  /// @param status Estado de la cita ('PENDING', 'CONFIRMED', etc.).
  /// @param serviceId ID del servicio a filtrar.
  /// @param dateString Fecha en formato YYYY-MM-DD.
  /// @return Stream con la lista reactiva de [Appointment].
  Stream<List<Appointment>> streamAppointments({
    String? status,
    String? serviceId,
    String? dateString,
  }) {
    Query<Map<String, dynamic>> query = _appointmentsCol;

    if (dateString != null && dateString.isNotEmpty) {
      query = query.where('dateString', isEqualTo: dateString);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    if (serviceId != null && serviceId.isNotEmpty) {
      query = query.where('serviceId', isEqualTo: serviceId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((d) => AppointmentDto.fromFirestore(d).toDomain()).toList();
    });
  }

  /// Escucha en tiempo real los bloqueos de disponibilidad activos en `/availability_blocks`.
  Stream<List<AvailabilityBlock>> streamAvailabilityBlocks() {
    return _blocksCol.snapshots().map((snapshot) {
      return snapshot.docs.map((d) => AvailabilityBlock.fromFirestore(d)).toList();
    });
  }

  /// Confirma una cita pendiente mediante la Cloud Function autorizada [confirmAppointment].
  ///
  /// @param appointmentId Identificador de la cita a confirmar.
  Future<Result<void>> confirmAppointment(String appointmentId) async {
    final res = await _functionsService.confirmAppointment(appointmentId: appointmentId);
    return res.when(
      ok: (_) => const Ok(null),
      err: (failure) => Err(failure),
    );
  }

  /// Marca una cita como completada mediante la Cloud Function [completeAppointment].
  ///
  /// @param appointmentId Identificador de la cita atendida.
  /// @return [Result] con booleano indicando si requiere redacción de ficha médica.
  Future<Result<bool>> completeAppointment(String appointmentId) async {
    final res = await _functionsService.completeAppointment(appointmentId: appointmentId);
    return res.when(
      ok: (data) => Ok((data['requiresClinicalForm'] as bool?) ?? false),
      err: (failure) => Err(failure),
    );
  }

  /// Cancela una cita por disposición del personal administrativo mediante [cancelAppointmentByStaff].
  ///
  /// @param appointmentId Identificador de la cita a cancelar.
  Future<Result<void>> cancelAppointmentByStaff(String appointmentId) async {
    final res = await _functionsService.cancelAppointmentByStaff(appointmentId: appointmentId);
    return res.when(
      ok: (_) => const Ok(null),
      err: (failure) => Err(failure),
    );
  }

  /// Reagenda una cita a nueva fecha y franja mediante la Cloud Function [rescheduleAppointment].
  ///
  /// @param appointmentId Identificador de la cita a mover.
  /// @param toDateString Nueva fecha seleccionada.
  /// @param toTimeSlot Nueva franja horaria acordada.
  Future<Result<void>> rescheduleAppointment({
    required String appointmentId,
    required String toDateString,
    required String toTimeSlot,
  }) async {
    final res = await _functionsService.rescheduleAppointment(
      appointmentId: appointmentId,
      toDateString: toDateString,
      toTimeSlot: toTimeSlot,
    );
    return res.when(
      ok: (_) => const Ok(null),
      err: (failure) => Err(failure),
    );
  }

  /// Establece o elimina un bloqueo operativo de agenda y retorna citas en conflicto si las hubiere.
  ///
  /// @param dateString Fecha a bloquear.
  /// @param timeSlot Franja específica (opcional).
  /// @param reason Causa del bloqueo.
  /// @param action 'BLOCK' o 'UNBLOCK'.
  /// @return [Result] con lista de [BlockConflictItem] detectados.
  Future<Result<List<BlockConflictItem>>> setAvailabilityBlock({
    required String dateString,
    String? timeSlot,
    String? reason,
    String action = 'BLOCK',
  }) async {
    final res = await _functionsService.setAvailabilityBlock(
      dateString: dateString,
      timeSlot: timeSlot,
      reason: reason,
      action: action,
    );

    return res.when(
      ok: (data) {
        final rawConflicts = data['conflicts'];
        final conflicts = <BlockConflictItem>[];
        if (rawConflicts is List) {
          for (final item in rawConflicts) {
            if (item is Map) {
              conflicts.add(BlockConflictItem.fromMap(Map<String, dynamic>.from(item)));
            }
          }
        }
        return Ok(conflicts);
      },
      err: (failure) => Err(failure),
    );
  }

  /// Escucha en tiempo real el listado de clientes registrados en la colección `/users`.
  ///
  /// @param prefixQuery Filtro predictivo de búsqueda por nombre o término.
  Stream<List<UserProfile>> streamClients({String? prefixQuery}) {
    Query<Map<String, dynamic>> query = _usersCol.where('role', isEqualTo: 'CLIENT');

    return query.snapshots().map((snapshot) {
      var profiles = snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
      if (prefixQuery != null && prefixQuery.trim().isNotEmpty) {
        final normalized = prefixQuery.trim().toLowerCase();
        profiles = profiles.where((p) => p.searchName.contains(normalized) || p.fullName.toLowerCase().contains(normalized)).toList();
      }
      return profiles;
    });
  }

  /// Escucha en tiempo real las cuentas que han sido desactivadas en la plataforma.
  Stream<List<UserProfile>> streamDeactivatedUsers() {
    return _usersCol
        .where('status', isEqualTo: 'DEACTIVATED')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final dateA = (a.audit?['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = (b.audit?['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  /// Consulta el perfil detallado de un cliente en `/users/{uid}`.
  ///
  /// @param uid Identificador del usuario cliente.
  Future<Result<UserProfile>> getClientProfile(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists) {
        return const Err(
          DomainFailure(code: 'NOT_FOUND', debugMessage: 'Cliente no encontrado'),
        );
      }
      return Ok(UserProfile.fromFirestore(doc));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real las mascotas pertenecientes a un cliente en `/pets`.
  ///
  /// @param clientId UID del dueño.
  Stream<List<Pet>> streamClientPets(String clientId) {
    return _petsCol
        .where('ownerId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PetDto.fromFirestore(doc).toDomain()).toList();
    });
  }

  /// Actualiza correcciones administrativas de sexo y estado reproductivo en `/pets/{petId}`.
  ///
  /// @param petId Identificador de la mascota.
  /// @param staffUid UID del colaborador que realiza la corrección.
  /// @param sex Sexo biológico corregido.
  /// @param reproductiveStatus Condición reproductiva corregida.
  Future<Result<void>> updatePetStaffCorrection({
    required String petId,
    required String staffUid,
    required String sex,
    required String reproductiveStatus,
  }) async {
    try {
      final petRef = _petsCol.doc(petId);
      await petRef.update({
        'sex': sex.trim(),
        'reproductiveStatus': reproductiveStatus.trim(),
        'audit.updatedBy': staffUid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      });
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Reactiva una cuenta de usuario o mascota mediante la Cloud Function [reactivateAccountOrPet].
  ///
  /// @param entityType Tipo de entidad ('USER' o 'PET').
  /// @param entityId Identificador de la entidad a reactivar.
  Future<Result<void>> reactivateAccountOrPet({
    required String entityType,
    required String entityId,
  }) async {
    final res = await _functionsService.reactivateAccountOrPet(
      entityType: entityType,
      entityId: entityId,
    );
    return res.when(
      ok: (_) => const Ok(null),
      err: (failure) => Err(failure),
    );
  }
}
