// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: appointment_dto.dart
// Propósito: DTO para la serialización y mapeo bidireccional entre Cloud Firestore y el modelo de dominio de citas.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mipetshop/domain/models/appointment.dart';

part 'appointment_dto.g.dart';

/// Objeto de Transferencia de Datos (DTO) para la entidad Cita en Cloud Firestore.
///
/// Modela los documentos almacenados en la colección `/appointments`, gestionando
/// la persistencia de datos financieros en centavos, estados de atención, llaves
/// de unicidad para evitar conflictos de concurrencia y registros de auditoría.
@JsonSerializable(explicitToJson: true)
class AppointmentDto {
  /// Identificador único del documento de la cita en Firestore.
  final String? id;

  /// Identificador del usuario cliente en Firebase Authentication / Firestore.
  final String clientId;

  /// Nombre completo o descriptivo del cliente.
  final String clientName;

  /// Identificador de la mascota asociada a la cita.
  final String petId;

  /// Nombre de la mascota para presentación rápida en la agenda.
  final String petName;

  /// Identificador del servicio contratado.
  final String serviceId;

  /// Nombre descriptivo del servicio (ej. Consulta Médica, Baño y Peluquería).
  final String serviceName;

  /// Indica si el servicio requiere atención y ficha clínica veterinaria.
  final bool isClinical;

  /// Fecha agendada en formato estandarizado ISO-8601 (YYYY-MM-DD).
  final String dateString;

  /// Franja horaria reservada (ej. "09:00 - 09:30").
  final String timeSlot;

  /// Clave compuesta de unicidad para el bloqueo de horarios (ej. "2026-09-22_09:00").
  final String slotKey;

  /// Clave para validar límites de citas por mascota por día (ej. "pet123_2026-09-22").
  final String petDayKey;

  /// Fecha en que se efectuó la transacción o reserva en formato texto.
  final String actionDateString;

  /// Estado actual del flujo de la cita (ej. "pending", "confirmed", "completed", "cancelled").
  final String status;

  /// Precio base del servicio expresado en centavos de dólar para precisión monetaria.
  final int basePriceCents;

  /// Tasa impositiva del Impuesto a los Consumos Especiales (ICE) en puntos base (basis points).
  final int iceBp;

  /// Tasa impositiva del Impuesto al Valor Agregado (IVA) en puntos base (basis points).
  final int ivaBp;

  /// Monto calculado del impuesto ICE en centavos.
  final int iceAmountCents;

  /// Monto calculado del impuesto IVA en centavos.
  final int ivaAmountCents;

  /// Precio total final facturable de la cita en centavos de dólar.
  final int finalPriceCents;

  /// Observaciones adicionales provistas por el cliente durante el agendamiento.
  final String? clientNotes;

  /// Bandera que señala si la cita médica completada aún tiene una ficha clínica pendiente de redacción.
  final bool hasPendingClinicalRecord;

  /// Indica si la cita ya fue consolidada en una proforma o factura formal.
  final bool isBilled;

  /// Identificador de la proforma a la que fue vinculada esta cita.
  final String? proformaId;

  /// Motivo registrado en caso de cancelación de la cita.
  final String? cancelledReason;

  /// Contador de reagendamientos realizados sobre esta cita (sujeto a políticas de límites).
  final int rescheduleCount;

  /// Historial detallado de cambios de fecha y hora aplicados a la cita.
  final List<Map<String, dynamic>> rescheduleHistory;

  /// Bandera que alerta sobre posibles colisiones con bloqueos operativos de agenda.
  final bool hasBlockConflict;

  /// Datos de auditoría perimetral y trazabilidad de cambios en la base de datos.
  final Map<String, dynamic>? audit;

  /// Constructor inmutable que inicializa todas las propiedades del DTO de la cita.
  const AppointmentDto({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.petId,
    required this.petName,
    required this.serviceId,
    required this.serviceName,
    required this.isClinical,
    required this.dateString,
    required this.timeSlot,
    required this.slotKey,
    required this.petDayKey,
    required this.actionDateString,
    required this.status,
    required this.basePriceCents,
    this.iceBp = 0,
    required this.ivaBp,
    required this.iceAmountCents,
    required this.ivaAmountCents,
    required this.finalPriceCents,
    this.clientNotes,
    this.hasPendingClinicalRecord = false,
    this.isBilled = false,
    this.proformaId,
    this.cancelledReason,
    this.rescheduleCount = 0,
    this.rescheduleHistory = const [],
    this.hasBlockConflict = false,
    this.audit,
  });

  /// Construye un [AppointmentDto] a partir de un mapa JSON deserializado.
  factory AppointmentDto.fromJson(Map<String, dynamic> json) => _$AppointmentDtoFromJson(json);

  /// Convierte la instancia actual en un mapa serializable a formato JSON.
  Map<String, dynamic> toJson() => _$AppointmentDtoToJson(this);

  /// Construye una instancia de [AppointmentDto] desde un [DocumentSnapshot] de Firestore.
  ///
  /// Mapea los campos persistidos en la colección `/appointments` e inyecta el ID del documento.
  /// Lanza un [StateError] si los datos del documento son nulos.
  factory AppointmentDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de cita no puede ser nula.');
    }
    return AppointmentDto.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convierte el DTO en un mapa para persistencia en Cloud Firestore.
  ///
  /// Excluye el campo 'id' para evitar duplicidad, permitiendo que Firestore gestione
  /// la clave primaria como identificador del documento.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  /// Convierte este DTO al modelo de entidad de dominio puro [Appointment].
  Appointment toDomain() {
    return Appointment(
      id: id ?? '',
      clientId: clientId,
      clientName: clientName,
      petId: petId,
      petName: petName,
      serviceId: serviceId,
      serviceName: serviceName,
      isClinical: isClinical,
      dateString: dateString,
      timeSlot: timeSlot,
      slotKey: slotKey,
      petDayKey: petDayKey,
      actionDateString: actionDateString,
      status: status,
      basePriceCents: basePriceCents,
      iceBp: iceBp,
      ivaBp: ivaBp,
      iceAmountCents: iceAmountCents,
      ivaAmountCents: ivaAmountCents,
      finalPriceCents: finalPriceCents,
      clientNotes: clientNotes,
      hasPendingClinicalRecord: hasPendingClinicalRecord,
      isBilled: isBilled,
      proformaId: proformaId,
      cancelledReason: cancelledReason,
      rescheduleCount: rescheduleCount,
      rescheduleHistory: rescheduleHistory,
      hasBlockConflict: hasBlockConflict,
    );
  }

  /// Crea una instancia de [AppointmentDto] a partir de la entidad de dominio [Appointment],
  /// agregando opcionalmente metadatos de auditoría transaccional.
  factory AppointmentDto.fromDomain(Appointment appt, {Map<String, dynamic>? audit}) {
    return AppointmentDto(
      id: appt.id.isEmpty ? null : appt.id,
      clientId: appt.clientId,
      clientName: appt.clientName,
      petId: appt.petId,
      petName: appt.petName,
      serviceId: appt.serviceId,
      serviceName: appt.serviceName,
      isClinical: appt.isClinical,
      dateString: appt.dateString,
      timeSlot: appt.timeSlot,
      slotKey: appt.slotKey,
      petDayKey: appt.petDayKey,
      actionDateString: appt.actionDateString,
      status: appt.status,
      basePriceCents: appt.basePriceCents,
      iceBp: appt.iceBp,
      ivaBp: appt.ivaBp,
      iceAmountCents: appt.iceAmountCents,
      ivaAmountCents: appt.ivaAmountCents,
      finalPriceCents: appt.finalPriceCents,
      clientNotes: appt.clientNotes,
      hasPendingClinicalRecord: appt.hasPendingClinicalRecord,
      isBilled: appt.isBilled,
      proformaId: appt.proformaId,
      cancelledReason: appt.cancelledReason,
      rescheduleCount: appt.rescheduleCount,
      rescheduleHistory: appt.rescheduleHistory,
      hasBlockConflict: appt.hasBlockConflict,
      audit: audit,
    );
  }
}
