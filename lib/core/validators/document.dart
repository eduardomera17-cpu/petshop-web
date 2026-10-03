// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/validators/document.dart
// Propósito: Validaciones de identidad personal (cédula de 10 dígitos, RUC de 13 dígitos y pasaporte) y datos de contacto según normativa ecuatoriana.
// =========================================================================

/// Tipos de documento de identidad autorizados en el sistema.
abstract final class DocumentTypes {
  /// Cédula de ciudadanía o identidad ecuatoriana (10 dígitos).
  static const String cedula = 'CEDULA';

  /// Pasaporte internacional (5 a 20 caracteres alfanuméricos).
  static const String passport = 'PASSPORT';

  /// Registro Único de Contribuyentes para personas naturales o jurídicas (13 dígitos).
  static const String ruc = 'RUC';

  /// Lista exhaustiva de identificadores de tipo de documento válidos.
  static const List<String> values = [cedula, passport, ruc];
}

/// Expresión regular estricta para validación de cédulas ecuatorianas (10 dígitos numéricos).
final RegExp cedulaRegex = RegExp(r'^[0-9]{10}$');

/// Expresión regular estricta para validación de RUC ecuatoriano (13 dígitos numéricos).
final RegExp rucRegex = RegExp(r'^[0-9]{13}$');

/// Expresión regular estricta para pasaportes (5 a 20 caracteres alfanuméricos).
final RegExp passportRegex = RegExp(r'^[A-Za-z0-9]{5,20}$');

/// Valida el nombre completo (1 a 100 caracteres) (CA-17, A-01).
bool isValidFullName(String? fullName) {
  if (fullName == null) return false;
  final trimmed = fullName.trim();
  return trimmed.isNotEmpty && trimmed.length <= 100;
}

/// Valida el validador de formulario para nombre completo.
String? validateFullName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) {
    return 'El nombre completo es obligatorio y debe tener entre 1 y 100 caracteres.';
  }
  if (!isValidFullName(fullName)) {
    return 'El nombre completo debe tener entre 1 y 100 caracteres.';
  }
  return null;
}

/// Valida el tipo de documento permitido (N-18).
bool isValidDocumentType(String? documentType) {
  if (documentType == null) return false;
  return DocumentTypes.values.contains(documentType.trim());
}

/// Valida el número de documento según su tipo específico (N-18, CA-38).
///
/// - CEDULA: exactamente 10 dígitos numéricos
/// - RUC: exactamente 13 dígitos numéricos
/// - PASSPORT: entre 5 y 20 caracteres alfanuméricos
bool isValidDocumentNumber(String? documentType, String? documentNumber) {
  if (documentType == null || documentNumber == null) return false;
  final type = documentType.trim();
  final number = documentNumber.trim();

  return switch (type) {
    DocumentTypes.cedula => cedulaRegex.hasMatch(number),
    DocumentTypes.ruc => rucRegex.hasMatch(number),
    DocumentTypes.passport => passportRegex.hasMatch(number),
    _ => false,
  };
}

/// Validador de formulario para número de documento según su tipo.
String? validateDocumentNumber(String? documentType, String? documentNumber) {
  if (documentType == null || !isValidDocumentType(documentType)) {
    return 'El tipo de documento debe ser CEDULA, PASSPORT o RUC.';
  }
  if (documentNumber == null || documentNumber.trim().isEmpty) {
    return 'El número de documento es obligatorio.';
  }
  final type = documentType.trim();
  if (!isValidDocumentNumber(type, documentNumber)) {
    return switch (type) {
      DocumentTypes.cedula => 'La cédula debe contener exactamente 10 dígitos numéricos.',
      DocumentTypes.ruc => 'El RUC debe contener exactamente 13 dígitos numéricos.',
      DocumentTypes.passport => 'El pasaporte debe contener entre 5 y 20 caracteres alfanuméricos.',
      _ => 'El número de documento no es válido para el tipo seleccionado.',
    };
  }
  return null;
}

/// Valida la dirección (1 a 200 caracteres) (N-18, CA-38).
bool isValidAddress(String? address) {
  if (address == null) return false;
  final trimmed = address.trim();
  return trimmed.isNotEmpty && trimmed.length <= 200;
}

/// Validador de formulario para dirección.
String? validateAddress(String? address) {
  if (address == null || address.trim().isEmpty) {
    return 'La dirección es obligatoria y debe tener entre 1 y 200 caracteres.';
  }
  if (!isValidAddress(address)) {
    return 'La dirección no puede exceder los 200 caracteres.';
  }
  return null;
}
