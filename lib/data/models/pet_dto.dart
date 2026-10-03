// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: pet_dto.dart
// Propósito: DTO para el mapeo y persistencia de mascotas de clientes en Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mipetshop/domain/models/pet.dart';

part 'pet_dto.g.dart';

/// Objeto de Transferencia de Datos (DTO) para la entidad Mascota.
///
/// Modela los documentos almacenados en la colección `/pets` de Cloud Firestore,
/// gestionando información biológica, datos biométricos históricos, estados
/// de vigencia y auditoría de desactivación.
@JsonSerializable(explicitToJson: true)
class PetDto {
  /// Identificador único del documento de la mascota en Firestore.
  final String? id;

  /// UID del cliente propietario en Firebase Authentication / Firestore.
  final String ownerId;

  /// Nombre de la mascota.
  final String name;

  /// Nombre normalizado en minúsculas y sin acentos para indexación y búsqueda rápida.
  final String searchName;

  /// Especie a la que pertenece la mascota (ej. CANINE, FELINE).
  final String species;

  /// Sexo biológico del animal (MALE / FEMALE).
  final String sex;

  /// Condición reproductiva (INTACT / NEUTERED).
  final String reproductiveStatus;

  /// Raza de la mascota, si se conoce.
  final String? breed;

  /// Fecha de nacimiento en formato ISO-8601 (YYYY-MM-DD).
  final String? birthDate;

  /// Registro de alergias conocidas o condiciones médicas sensibles.
  final String? allergies;

  /// Ruta de la fotografía de perfil almacenada en Cloud Storage.
  final String? photoPath;

  /// Estado operativo de la mascota ('ACTIVE' o 'INACTIVE').
  final String status;

  /// Último peso corporal registrado expresado en gramos.
  final int? lastWeightGrams;

  /// Fecha en que se efectuó el último pesaje.
  final String? lastWeightDate;

  /// Fecha y hora en que se desactivó la mascota del sistema.
  @JsonKey(fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)
  final DateTime? deactivatedAt;

  /// UID del usuario administrativo que ejecutó la desactivación.
  final String? deactivatedBy;

  /// Metadatos de auditoría y trazabilidad transaccional.
  final Map<String, dynamic>? audit;

  /// Constructor inmutable de inicialización del DTO de Mascota.
  const PetDto({
    this.id,
    required this.ownerId,
    required this.name,
    required this.searchName,
    required this.species,
    required this.sex,
    required this.reproductiveStatus,
    this.breed,
    this.birthDate,
    this.allergies,
    this.photoPath,
    required this.status,
    this.lastWeightGrams,
    this.lastWeightDate,
    this.deactivatedAt,
    this.deactivatedBy,
    this.audit,
  });

  /// Construye un [PetDto] a partir de un mapa JSON deserializado.
  factory PetDto.fromJson(Map<String, dynamic> json) => _$PetDtoFromJson(json);

  /// Convierte la instancia en un mapa serializable a formato JSON.
  Map<String, dynamic> toJson() => _$PetDtoToJson(this);

  /// Construye un [PetDto] a partir de un [DocumentSnapshot] recuperado de la colección `/pets`.
  ///
  /// Lanza un [StateError] si el snapshot contiene datos nulos.
  factory PetDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot data de mascota no puede ser nula.');
    }
    return PetDto.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  /// Convierte el DTO a un mapa compatible para escritura en Firestore excluyendo el 'id'.
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id');
    return map;
  }

  /// Mapea este DTO a la entidad de dominio puro [Pet].
  Pet toDomain() {
    return Pet(
      id: id ?? '',
      ownerId: ownerId,
      name: name,
      searchName: searchName,
      species: species,
      sex: sex,
      reproductiveStatus: reproductiveStatus,
      breed: breed,
      birthDate: birthDate,
      allergies: allergies,
      photoPath: photoPath,
      status: status,
      lastWeightGrams: lastWeightGrams,
      lastWeightDate: lastWeightDate,
      deactivatedAt: deactivatedAt,
      deactivatedBy: deactivatedBy,
    );
  }

  /// Construye una instancia de [PetDto] a partir de la entidad de dominio [Pet].
  factory PetDto.fromDomain(Pet pet, {Map<String, dynamic>? audit}) {
    return PetDto(
      id: pet.id.isEmpty ? null : pet.id,
      ownerId: pet.ownerId,
      name: pet.name,
      searchName: pet.searchName,
      species: pet.species,
      sex: pet.sex,
      reproductiveStatus: pet.reproductiveStatus,
      breed: pet.breed,
      birthDate: pet.birthDate,
      allergies: pet.allergies,
      photoPath: pet.photoPath,
      status: pet.status,
      lastWeightGrams: pet.lastWeightGrams,
      lastWeightDate: pet.lastWeightDate,
      deactivatedAt: pet.deactivatedAt,
      deactivatedBy: pet.deactivatedBy,
      audit: audit,
    );
  }

  /// Convierte un valor dinámico o [Timestamp] a [DateTime].
  static DateTime? _dateTimeFromTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convierte un [DateTime] a [Timestamp] de Firestore.
  static dynamic _dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}
