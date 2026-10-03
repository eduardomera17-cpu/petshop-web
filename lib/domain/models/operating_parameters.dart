// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: operating_parameters.dart
// Propósito: Entidad de dominio para la configuración de horarios de atención, agenda y umbrales de stock.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dominio inmutable para la configuración operativa del negocio.
///
/// Modela el documento `/business_config/operating_parameters` en Cloud Firestore,
/// definiendo la jornada laboral, duración de turnos de citas, días operativos y
/// alertas de inventario crítico bajo la zona horaria institucional `America/Guayaquil`.
class OperatingParameters {
  /// Zona horaria oficial del establecimiento ('America/Guayaquil').
  final String timezone;

  /// Hora de apertura de la jornada laboral en formato HH:MM (ej. "08:00").
  final String openingTime;

  /// Hora de cierre de la jornada laboral en formato HH:MM (ej. "18:00").
  final String closingTime;

  /// Duración predeterminada de cada turno o franja de atención en minutos.
  final int slotDurationMinutes;

  /// Lista de días laborales hábiles de la semana (1 = Lunes a 7 = Domingo).
  final List<int> workingWeekdays;

  /// Umbral mínimo de existencias para considerar que un producto tiene stock bajo.
  final int lowStockThreshold;

  /// Metadatos de auditoría transaccional de la configuración.
  final Map<String, dynamic>? audit;

  /// Constructor inmutable con valores por omisión de funcionamiento del negocio.
  const OperatingParameters({
    this.timezone = 'America/Guayaquil',
    this.openingTime = '08:00',
    this.closingTime = '18:00',
    this.slotDurationMinutes = 30,
    this.workingWeekdays = const [1, 2, 3, 4, 5, 6],
    this.lowStockThreshold = 5,
    this.audit,
  });

  /// Construye una instancia a partir de un [DocumentSnapshot] de Firestore.
  factory OperatingParameters.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return OperatingParameters.fromMap(data);
  }

  /// Construye una instancia a partir de un mapa clave-valor.
  factory OperatingParameters.fromMap(Map<String, dynamic> map) {
    List<int> parseWeekdays(dynamic raw) {
      if (raw is List) {
        return raw.whereType<num>().map((e) => e.toInt()).toList()..sort();
      }
      return const [1, 2, 3, 4, 5, 6];
    }

    return OperatingParameters(
      timezone: (map['timezone'] as String?) ?? 'America/Guayaquil',
      openingTime: (map['openingTime'] as String?) ?? '08:00',
      closingTime: (map['closingTime'] as String?) ?? '18:00',
      slotDurationMinutes: (map['slotDurationMinutes'] as num?)?.toInt() ?? 30,
      workingWeekdays: parseWeekdays(map['workingWeekdays']),
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 5,
      audit: map['audit'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['audit'] as Map)
          : null,
    );
  }

  /// Convierte la configuración operativa a un mapa para persistir en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'timezone': timezone,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'slotDurationMinutes': slotDurationMinutes,
      'workingWeekdays': workingWeekdays,
      'lowStockThreshold': lowStockThreshold,
      if (audit != null) 'audit': audit,
    };
  }

  /// Crea una copia de la instancia actual modificando únicamente los campos provistos.
  OperatingParameters copyWith({
    String? openingTime,
    String? closingTime,
    int? slotDurationMinutes,
    List<int>? workingWeekdays,
    int? lowStockThreshold,
    Map<String, dynamic>? audit,
  }) {
    return OperatingParameters(
      timezone: timezone,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      workingWeekdays: workingWeekdays ?? this.workingWeekdays,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      audit: audit ?? this.audit,
    );
  }
}
