// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: read_state.dart
// Propósito: DTO para el rastreo y sincronización de mensajes leídos por usuario en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'read_state.g.dart';

/// Convertidor para marcas de tiempo [Timestamp] opcionales en [DateTime].
class _NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const _NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? object) =>
      object != null ? Timestamp.fromDate(object) : null;
}

/// Objeto de Transferencia de Datos (DTO) para el control de lecturas de mensajes.
///
/// Modela los documentos almacenados en la subcolección `/chats/{chatId}/read_states`
/// para gestionar las marcas de lectura y contadores de mensajes no leídos por usuario.
@JsonSerializable(explicitToJson: true)
@_NullableTimestampConverter()
class ReadStateDto {
  /// UID del usuario al que pertenece este estado de lectura.
  final String? uid;

  /// Fecha y hora de la última interacción o lectura de mensajes registrada.
  final DateTime? lastReadAt;

  /// Cantidad de mensajes pendientes de lectura para este usuario.
  final int unreadCount;

  /// Constructor inmutable para inicializar el estado de lectura.
  const ReadStateDto({
    this.uid,
    this.lastReadAt,
    this.unreadCount = 0,
  });

  /// Construye un [ReadStateDto] desde un mapa en formato JSON.
  factory ReadStateDto.fromJson(Map<String, dynamic> json) =>
      _$ReadStateDtoFromJson(json);

  /// Serializa la instancia a formato JSON.
  Map<String, dynamic> toJson() => _$ReadStateDtoToJson(this);

  /// Construye un [ReadStateDto] a partir de un [DocumentSnapshot] de Firestore.
  ///
  /// Lanza un [StateError] si los datos del snapshot son nulos.
  factory ReadStateDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de estado de lectura no puede ser nula.');
    }
    return ReadStateDto.fromJson({
      ...data,
      'uid': snapshot.id,
    });
  }

  /// Convierte el DTO en un mapa para persistir en Firestore excluyendo el 'uid'.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('uid');
    return map;
  }
}
