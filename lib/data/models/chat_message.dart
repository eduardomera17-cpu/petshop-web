// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: chat_message.dart
// Propósito: DTO para mensajes individuales en la subcolección de chats en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

/// Convertidor personalizado para manejar valores de tipo [Timestamp] de Firestore
/// y transformarlos adecuadamente en instancias de [DateTime].
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

/// Objeto de Transferencia de Datos (DTO) para un mensaje de chat individual.
///
/// Modela los documentos almacenados en la subcolección `/chats/{chatId}/messages`,
/// gestionando texto, imágenes adjuntas, roles del emisor y confirmaciones de lectura.
@JsonSerializable(explicitToJson: true)
@_NullableTimestampConverter()
class ChatMessageDto {
  /// Identificador único del mensaje en la subcolección de Firestore.
  final String? id;

  /// UID de Firebase Authentication correspondiente al remitente del mensaje.
  final String senderUid;

  /// Nombre legible del remitente para la burbuja de conversación.
  final String senderName;

  /// Rol operativo del emisor ('CLIENT', 'ADMIN' o 'SUPERADMIN').
  final String senderRole;

  /// Contenido textual del mensaje enviado.
  final String? text;

  /// Ruta en Cloud Storage de la imagen adjunta, si el mensaje contiene contenido multimedia.
  final String? imagePath;

  /// Indica si el mensaje ha sido visualizado o leído por un miembro del personal.
  final bool readByStaff;

  /// Fecha y hora de emisión del mensaje en el servidor de base de datos.
  final DateTime? createdAt;

  /// Constructor inmutable para inicializar las propiedades del mensaje.
  const ChatMessageDto({
    this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    this.text,
    this.imagePath,
    this.readByStaff = false,
    this.createdAt,
  });

  /// Construye un [ChatMessageDto] a partir de un mapa JSON deserializado.
  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);

  /// Serializa la instancia actual a formato JSON.
  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);

  /// Construye una instancia de [ChatMessageDto] desde un [DocumentSnapshot] de Firestore.
  ///
  /// Lanza un [StateError] si la data recuperada es nula.
  factory ChatMessageDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de mensaje de chat no puede ser nula.');
    }
    return ChatMessageDto.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convierte el DTO en un mapa estructurado para persistir en Firestore, omitiendo el campo 'id'.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }
}
