// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: chat.dart
// Propósito: DTO para la colección de salas y conversaciones de chat en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat.g.dart';

/// Convertidor personalizado para manejar valores de fecha/hora de Firestore [Timestamp]
/// y facilitar la serialización bidireccional con [DateTime].
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

/// Objeto de Transferencia de Datos (DTO) que representa un canal o hilo de conversación.
///
/// Modela los documentos almacenados en la colección `/chats` para la comunicación
/// bidireccional entre el cliente y el personal del petshop o mensajería interna.
@JsonSerializable(explicitToJson: true)
@_NullableTimestampConverter()
class ChatDto {
  /// Identificador único del chat en Cloud Firestore.
  final String? id;

  /// Tipo de canal ('CLIENT_STAFF' para atención al cliente o 'STAFF_INTERNAL' para coordinación).
  final String type;

  /// Identificador único del cliente asociado a la conversación.
  final String? clientId;

  /// Nombre legible del cliente para visualización en bandejas de entrada.
  final String? clientName;

  /// Nombre normalizado en minúsculas para búsquedas e indexación eficiente.
  final String? clientSearchName;

  /// Indica si la conversación ha sido archivada por el personal administrativo.
  final bool isArchived;

  /// Determina si la conversación se encuentra bloqueada para envío de nuevos mensajes.
  final bool isBlocked;

  /// Cantidad de mensajes no leídos pendientes de atención por parte del personal.
  final int staffUnreadCount;

  /// Texto del último mensaje enviado para previsualización en la lista de chats.
  final String? lastMessageText;

  /// Fecha y hora del último mensaje registrado.
  final DateTime? lastMessageTimestamp;

  /// Nombre del remitente del último mensaje.
  final String? lastMessageSenderName;

  /// UID del remitente del último mensaje registrado en la conversación.
  final String? lastMessageSenderUid;

  /// Total acumulado de mensajes intercambiados en el chat.
  final int messageCount;

  /// Fecha de apertura o creación del hilo de chat.
  final DateTime? createdAt;

  /// Fecha de última actividad o actualización del chat.
  final DateTime? updatedAt;

  /// Constructor inmutable para inicializar las propiedades del canal de chat.
  const ChatDto({
    this.id,
    required this.type,
    this.clientId,
    this.clientName,
    this.clientSearchName,
    this.isArchived = false,
    this.isBlocked = false,
    this.staffUnreadCount = 0,
    this.lastMessageText,
    this.lastMessageTimestamp,
    this.lastMessageSenderName,
    this.lastMessageSenderUid,
    this.messageCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializa un mapa JSON en una instancia de [ChatDto].
  factory ChatDto.fromJson(Map<String, dynamic> json) => _$ChatDtoFromJson(json);

  /// Serializa la instancia a un mapa en formato JSON.
  Map<String, dynamic> toJson() => _$ChatDtoToJson(this);

  /// Mapea un [DocumentSnapshot] proveniente de Firestore al DTO [ChatDto].
  ///
  /// Lanza un [StateError] si el contenido del documento resulta nulo.
  factory ChatDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de chat no puede ser nula.');
    }
    return ChatDto.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convierte el DTO a un mapa compatible para escritura en Firestore, excluyendo el 'id'.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }
}
