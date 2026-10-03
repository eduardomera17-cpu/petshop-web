// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: pet.dart
// Propósito: Entidad inmutable de dominio que modela el perfil y características de las mascotas de los clientes.
// =========================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet.freezed.dart';

/// Entidad inmutable de dominio que representa a una Mascota.
///
/// Modela los atributos biológicos, médicos preliminares (alergias, peso),
/// de vigencia y trazabilidad de desactivación de los pacientes atendidos.
@freezed
class Pet with _$Pet {
  /// Constructor de fábrica inmutable para la entidad [Pet].
  const factory Pet({
    /// Identificador único de la mascota en el sistema.
    required String id,

    /// Identificador del propietario o tutor registrado.
    required String ownerId,

    /// Nombre de la mascota.
    required String name,

    /// Nombre en minúsculas sin acentos para facilitar búsquedas.
    required String searchName,

    /// Especie a la que pertenece el paciente (ej. CANINE, FELINE).
    required String species,

    /// Sexo biológico de la mascota (MALE / FEMALE).
    required String sex,

    /// Condición reproductiva (INTACT / NEUTERED).
    required String reproductiveStatus,

    /// Raza declarada de la mascota.
    String? breed,

    /// Fecha de nacimiento en formato ISO-8601 (YYYY-MM-DD).
    String? birthDate,

    /// Alergias conocidas o sensibilidades alimentarias.
    String? allergies,

    /// Ruta de la imagen de perfil en Cloud Storage.
    String? photoPath,

    /// Estado de actividad en el sistema ('ACTIVE' o 'INACTIVE').
    required String status,

    /// Último pesaje corporal en gramos.
    int? lastWeightGrams,

    /// Fecha en que se registró el último peso corporal.
    String? lastWeightDate,

    /// Fecha y hora en que se desactivó la mascota, si aplica.
    DateTime? deactivatedAt,

    /// Identificador del usuario que autorizó la desactivación.
    String? deactivatedBy,
  }) = _Pet;
}
