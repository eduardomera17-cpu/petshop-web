// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: appointment.dart
// Propósito: Entidad inmutable de dominio que modela el ciclo de vida y reglas de negocio de una cita.
// =========================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment.freezed.dart';

/// Entidad inmutable del dominio que representa una Cita en el Petshop.
///
/// Encapsula las reglas de negocio para el agendamiento, control de bloqueos horarios,
/// cálculos tributarios en centavos, vinculación de expedientes clínicos y facturación.
@freezed
class Appointment with _$Appointment {
  /// Fábrica constructora de la cita con validaciones y valores por defecto.
  const factory Appointment({
    /// Identificador único de la cita.
    required String id,

    /// Identificador del cliente propietario de la mascota.
    required String clientId,

    /// Nombre completo del cliente para visualización rápida en UI.
    required String clientName,

    /// Identificador de la mascota a atender.
    required String petId,

    /// Nombre de la mascota registrada en la cita.
    required String petName,

    /// Identificador del servicio a prestar.
    required String serviceId,

    /// Nombre comercial del servicio contratado.
    required String serviceName,

    /// Determina si la cita requiere redacción de ficha médica veterinaria.
    required bool isClinical,

    /// Fecha de la cita en formato estandarizado (YYYY-MM-DD).
    required String dateString,

    /// Franja horaria acordada (ej. "10:00 - 10:30").
    required String timeSlot,

    /// Clave compuesta única para control de concurrencia y solapamiento.
    required String slotKey,

    /// Clave de restricción para evitar citas duplicadas por mascota el mismo día.
    required String petDayKey,

    /// Fecha y hora en formato texto del momento del agendamiento.
    required String actionDateString,

    /// Estado del ciclo de vida de la cita ('pending', 'confirmed', 'completed', 'cancelled').
    required String status,

    /// Precio base del servicio en centavos de dólar.
    required int basePriceCents,

    /// Puntos base del Impuesto a los Consumos Especiales (ICE).
    @Default(0) int iceBp,

    /// Puntos base del Impuesto al Valor Agregado (IVA).
    required int ivaBp,

    /// Monto del impuesto ICE liquidado en centavos.
    required int iceAmountCents,

    /// Monto del impuesto IVA liquidado en centavos.
    required int ivaAmountCents,

    /// Importe total final liquidado en centavos de dólar.
    required int finalPriceCents,

    /// Notas o indicaciones especiales aportadas por el tutor de la mascota.
    String? clientNotes,

    /// Indica si tras completarse la cita médica aún está pendiente redactar la ficha clínica.
    @Default(false) bool hasPendingClinicalRecord,

    /// Indica si el servicio prestado ya fue cobrado e incluido en una proforma.
    @Default(false) bool isBilled,

    /// Identificador de la proforma que facturó esta atención.
    String? proformaId,

    /// Justificación registrada en caso de cancelación de la cita.
    String? cancelledReason,

    /// Número acumulado de reagendamientos efectuados.
    @Default(0) int rescheduleCount,

    /// Historial de modificaciones y fechas previas de la cita.
    @Default([]) List<Map<String, dynamic>> rescheduleHistory,

    /// Señal que advierte de incompatibilidad con un bloqueo manual de agenda.
    @Default(false) bool hasBlockConflict,
  }) = _Appointment;
}
