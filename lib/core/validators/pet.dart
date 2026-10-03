// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/validators/pet.dart
// Propósito: Validadores y restricciones de dominio para registro de mascotas (nombres, especies, sexo, estado reproductivo y fechas no futuras).
// =========================================================================

import 'package:mipetshop/core/business_clock.dart';

/// Constantes y cotas de validación de mascotas idénticas a las reglas de seguridad de Firestore (PRD §0, TRD §2.3).
abstract final class PetValidationConstraints {
  /// Longitud mínima del nombre de la mascota.
  static const int minNameLength = 1;

  /// Longitud máxima del nombre de la mascota.
  static const int maxNameLength = 60;

  /// Longitud mínima de la especie.
  static const int minSpeciesLength = 1;

  /// Longitud máxima de la especie.
  static const int maxSpeciesLength = 40;

  /// Longitud mínima del campo de búsqueda normalizado.
  static const int minSearchNameLength = 1;

  /// Longitud máxima del campo de búsqueda normalizado.
  static const int maxSearchNameLength = 60;

  /// Longitud máxima del campo de raza.
  static const int maxBreedLength = 60;

  /// Longitud máxima del campo descriptivo de alergias y condiciones preexistentes.
  static const int maxAllergiesLength = 500;

  /// Sexos biológicos autorizados para las mascotas.
  static const List<String> allowedSexes = ['MALE', 'FEMALE'];

  /// Estados reproductivos autorizados.
  static const List<String> allowedReproductiveStatuses = [
    'INTACT',
    'NEUTERED',
    'UNKNOWN',
  ];

  /// Patrón canónico para la fecha de nacimiento en formato YYYY-MM-DD.
  static final RegExp birthDateRegex = RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$');
}

/// Valida el nombre de la mascota (1 a 60 caracteres).
bool isValidPetName(String? name) {
  if (name == null) return false;
  final trimmed = name.trim();
  return trimmed.length >= PetValidationConstraints.minNameLength &&
      trimmed.length <= PetValidationConstraints.maxNameLength;
}

/// Mensaje de validación para el nombre de la mascota.
String? validatePetName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return 'El nombre de la mascota es obligatorio y debe tener entre 1 y 60 caracteres.';
  }
  if (!isValidPetName(name)) {
    return 'El nombre de la mascota debe tener entre 1 y 60 caracteres.';
  }
  return null;
}

/// Valida la especie de la mascota (1 a 40 caracteres).
bool isValidPetSpecies(String? species) {
  if (species == null) return false;
  final trimmed = species.trim();
  return trimmed.length >= PetValidationConstraints.minSpeciesLength &&
      trimmed.length <= PetValidationConstraints.maxSpeciesLength;
}

/// Mensaje de validación para la especie de la mascota.
String? validatePetSpecies(String? species) {
  if (species == null || species.trim().isEmpty) {
    return 'La especie de la mascota es obligatoria y debe tener entre 1 y 40 caracteres.';
  }
  if (!isValidPetSpecies(species)) {
    return 'La especie de la mascota debe tener entre 1 y 40 caracteres.';
  }
  return null;
}

/// Valida el nombre de búsqueda normalizado de la mascota (1 a 60 caracteres).
bool isValidPetSearchName(String? searchName) {
  if (searchName == null) return false;
  final trimmed = searchName.trim();
  return trimmed.length >= PetValidationConstraints.minSearchNameLength &&
      trimmed.length <= PetValidationConstraints.maxSearchNameLength;
}

/// Valida la raza de la mascota (opcional, máximo 60 caracteres).
bool isValidPetBreed(String? breed) {
  if (breed == null) return true;
  return breed.trim().length <= PetValidationConstraints.maxBreedLength;
}

/// Mensaje de validación para la raza de la mascota.
String? validatePetBreed(String? breed) {
  if (!isValidPetBreed(breed)) {
    return 'La raza no puede exceder los 60 caracteres.';
  }
  return null;
}

/// Valida las alergias reportadas por el cliente (opcional, máximo 500 caracteres).
bool isValidPetAllergies(String? allergies) {
  if (allergies == null) return true;
  return allergies.trim().length <= PetValidationConstraints.maxAllergiesLength;
}

/// Mensaje de validación para el campo de alergias.
String? validatePetAllergies(String? allergies) {
  if (!isValidPetAllergies(allergies)) {
    return 'El campo de alergias no puede exceder los 500 caracteres.';
  }
  return null;
}

/// Valida el sexo biológico de la mascota (MALE | FEMALE).
bool isValidPetSex(String? sex) {
  if (sex == null) return false;
  return PetValidationConstraints.allowedSexes.contains(sex.trim());
}

/// Mensaje de validación para el sexo biológico.
String? validatePetSex(String? sex) {
  if (!isValidPetSex(sex)) {
    return 'El sexo debe ser MALE o FEMALE.';
  }
  return null;
}

/// Valida el estado reproductivo (INTACT | NEUTERED | UNKNOWN).
bool isValidPetReproductiveStatus(String? status) {
  if (status == null) return false;
  return PetValidationConstraints.allowedReproductiveStatuses.contains(status.trim());
}

/// Mensaje de validación para el estado reproductivo.
String? validatePetReproductiveStatus(String? status) {
  if (!isValidPetReproductiveStatus(status)) {
    return 'El estado reproductivo debe ser INTACT, NEUTERED o UNKNOWN.';
  }
  return null;
}

/// Valida la fecha de nacimiento de la mascota (opcional, formato YYYY-MM-DD, no futura).
bool isValidPetBirthDate(String? birthDate, {String? todayBusinessDate}) {
  if (birthDate == null || birthDate.trim().isEmpty) return true;
  final date = birthDate.trim();
  if (!PetValidationConstraints.birthDateRegex.hasMatch(date)) return false;

  final parts = date.split('-');
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return false;
  if (month < 1 || month > 12) return false;
  if (day < 1 || day > 31) return false;

  // Validación de fecha no futura según BusinessClock o fecha base provista
  final today = todayBusinessDate ?? BusinessClock.todayBusinessDate();
  return date.compareTo(today) <= 0;
}

/// Mensaje de validación para la fecha de nacimiento.
String? validatePetBirthDate(String? birthDate, {String? todayBusinessDate}) {
  if (birthDate == null || birthDate.trim().isEmpty) return null;
  if (!isValidPetBirthDate(birthDate, todayBusinessDate: todayBusinessDate)) {
    return 'La fecha de nacimiento debe tener formato YYYY-MM-DD y no puede ser futura.';
  }
  return null;
}
