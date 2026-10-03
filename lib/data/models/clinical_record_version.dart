// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: clinical_record_version.dart
// Propósito: DTO para el versionamiento histórico y auditoría inmutable de historias clínicas en Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clinical_record_version.g.dart';

/// Convertidor para serialización y deserialización de marcas temporales [Timestamp] a [DateTime].
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

/// DTO que representa una versión histórica de un registro clínico electrónico.
///
/// Modela los documentos almacenados en la subcolección
/// `/pets/{petId}/clinical_records/{recordId}/versions` para garantizar trazabilidad
/// forense inmutable de todas las modificaciones realizadas a la historia médica.
@JsonSerializable(explicitToJson: true)
class ClinicalRecordVersion {
  /// Número correlativo y secuencial de la versión registrada (ej. 1, 2, 3...).
  final int versionNumber;

  /// UID del facultativo o usuario que ejecutó la edición.
  final String editedBy;

  /// Nombre completo del usuario responsable de la modificación.
  final String editedByName;

  /// Fecha y hora exacta en la que se efectuó la edición.
  @_NullableTimestampConverter()
  final DateTime? editedAt;

  /// Copia íntegra de los datos del registro clínico antes o durante la versión.
  final Map<String, dynamic> snapshot;

  /// Constructor inmutable de la versión de historia clínica.
  const ClinicalRecordVersion({
    required this.versionNumber,
    required this.editedBy,
    required this.editedByName,
    this.editedAt,
    required this.snapshot,
  });

  /// Construye una instancia a partir de un mapa JSON deserializado.
  factory ClinicalRecordVersion.fromJson(Map<String, dynamic> json) =>
      _$ClinicalRecordVersionFromJson(json);

  /// Serializa la versión histórica a formato JSON.
  Map<String, dynamic> toJson() => _$ClinicalRecordVersionToJson(this);

  /// Construye un [ClinicalRecordVersion] desde un [DocumentSnapshot] de Firestore.
  ///
  /// Lanza un [StateError] si la data del documento no existe.
  factory ClinicalRecordVersion.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> docSnapshot, [
    SnapshotOptions? options,
  ]) {
    final data = docSnapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de versión clínica no puede ser nula.');
    }
    return ClinicalRecordVersion.fromJson(data);
  }

  /// Convierte la instancia en un mapa apto para almacenar en Firestore.
  Map<String, dynamic> toFirestore() {
    return toJson();
  }
}
