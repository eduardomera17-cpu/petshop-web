// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/feature_flags.dart
// Propósito: Interruptores de funciones inacabadas, desactivadas por defecto.
// =========================================================================

/// Adjuntar archivos desde la consulta clínica.
///
/// Desactivado por defecto: función inacabada. Se activa al compilar con
/// `--dart-define=PETSHOP_CLINICAL_ATTACHMENTS=true`.
const bool kClinicalAttachmentsEnabled = bool.fromEnvironment('PETSHOP_CLINICAL_ATTACHMENTS');

/// Actualizar la foto de la mascota desde la consulta clínica.
///
/// Desactivado por defecto: función inacabada. Se activa al compilar con
/// `--dart-define=PETSHOP_CLINICAL_PET_PHOTO=true`.
const bool kClinicalPetPhotoEnabled = bool.fromEnvironment('PETSHOP_CLINICAL_PET_PHOTO');
