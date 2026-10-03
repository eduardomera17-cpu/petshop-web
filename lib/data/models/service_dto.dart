// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: service_dto.dart
// Propósito: DTO para el catálogo de servicios veterinarios y de estética en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mipetshop/domain/models/service.dart';

part 'service_dto.g.dart';

/// Objeto de Transferencia de Datos (DTO) para la entidad Servicio.
///
/// Modela los documentos almacenados en la colección `/services` de Cloud Firestore,
/// gestionando tarifas base en centavos, duraciones operativas para agendamiento,
/// clasificación de atención clínica y visibilidad para reservas.
@JsonSerializable(explicitToJson: true)
class ServiceDto {
  /// Identificador único del servicio en Firestore.
  final String? id;

  /// Nombre comercial del servicio (ej. Consulta Médica Veterinaria, Baño Antipulgas).
  final String name;

  /// Nombre normalizado en minúsculas y sin acentos para filtrado predictivo.
  final String searchName;

  /// Descripción de las prestaciones incluidas en el servicio.
  final String description;

  /// Precio base sin tributos expresado en centavos de dólar.
  final int basePriceCents;

  /// Puntos base aplicables de ICE (0 si no aplica).
  final int iceBp;

  /// Determina si el servicio requiere confección obligatoria de historia clínica.
  final bool isClinical;

  /// Duración estimada del servicio en minutos para el cálculo de franjas de agenda.
  final int estimatedDurationMinutes;

  /// Indica si el servicio está habilitado y visible para el público.
  final bool isActive;

  /// Metadatos de auditoría para trazabilidad de creación y cambios.
  final Map<String, dynamic>? audit;

  /// Constructor inmutable de inicialización del DTO de Servicio.
  const ServiceDto({
    this.id,
    required this.name,
    required this.searchName,
    required this.description,
    required this.basePriceCents,
    this.iceBp = 0,
    required this.isClinical,
    required this.estimatedDurationMinutes,
    required this.isActive,
    this.audit,
  });

  /// Construye una instancia a partir de un mapa JSON deserializado.
  factory ServiceDto.fromJson(Map<String, dynamic> json) => _$ServiceDtoFromJson(json);

  /// Serializa la entidad a formato JSON.
  Map<String, dynamic> toJson() => _$ServiceDtoToJson(this);

  /// Construye un [ServiceDto] desde un [DocumentSnapshot] de Firestore.
  ///
  /// Lanza un [StateError] si la data del snapshot es nula.
  factory ServiceDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de servicio no puede ser nula.');
    }
    return ServiceDto.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convierte el DTO a un mapa estructurado para persistir en Firestore, omitiendo el 'id'.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  /// Mapea este DTO a la entidad de dominio puro [Service].
  Service toDomain() {
    return Service(
      id: id ?? '',
      name: name,
      searchName: searchName,
      description: description,
      basePriceCents: basePriceCents,
      iceBp: iceBp,
      isClinical: isClinical,
      estimatedDurationMinutes: estimatedDurationMinutes,
      isActive: isActive,
    );
  }

  /// Construye una instancia de [ServiceDto] a partir de la entidad [Service].
  factory ServiceDto.fromDomain(Service service, {Map<String, dynamic>? audit}) {
    return ServiceDto(
      id: service.id.isEmpty ? null : service.id,
      name: service.name,
      searchName: service.searchName,
      description: service.description,
      basePriceCents: service.basePriceCents,
      iceBp: service.iceBp,
      isClinical: service.isClinical,
      estimatedDurationMinutes: service.estimatedDurationMinutes,
      isActive: service.isActive,
      audit: audit,
    );
  }
}
