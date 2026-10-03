// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/validators/phone.dart
// Propósito: Validador canónico de números telefónicos móviles de Ecuador (+593 seguido de 9 dígitos numéricos).
// =========================================================================

/// Expresión regular canónica de validación de teléfono celular ecuatoriano (E.164).
///
/// Exige el prefijo internacional obligatorio '+593' seguido de exactamente 9 dígitos numéricos.
/// Replica con exactitud matemática la regla del backend en Firebase Functions.
final RegExp ecuadorPhoneRegex = RegExp(r'^\+593[0-9]{9}$');

/// Prefijo internacional telefónico oficial de la República del Ecuador (+593).
const String kEcuadorPhonePrefix = '+593';

/// Valida el formato ecuatoriano de teléfono (N-17, CA-37).
///
/// Debe comenzar con +593 y tener exactamente 9 dígitos numéricos (ej. +593987654321).
bool isValidPhone(String? phone) {
  if (phone == null) return false;
  final trimmed = phone.trim();
  return ecuadorPhoneRegex.hasMatch(trimmed);
}

/// Validador de formulario para campos de texto en Flutter.
///
/// Retorna mensaje de error descriptivo o null si el valor es válido.
String? validatePhone(String? phone) {
  if (phone == null || phone.trim().isEmpty) {
    return 'El teléfono de contacto es obligatorio.';
  }
  if (!isValidPhone(phone)) {
    return 'El teléfono de contacto debe tener formato ecuatoriano (+593 seguido de 9 dígitos).';
  }
  return null;
}
