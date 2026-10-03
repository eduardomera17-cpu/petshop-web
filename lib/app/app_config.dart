// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/app/app_config.dart
// Propósito: Configuración de entorno inyectada en tiempo de compilación (sin valores propios en el código).
// =========================================================================

/// Configuración específica de cada despliegue, leída en **tiempo de compilación**.
///
/// Ningún identificador de un proyecto concreto vive en el código fuente. Se inyectan con
/// `--dart-define` o, más cómodo, con un archivo JSON:
///
/// ```bash
/// cp config/app_config.example.json config/app_config.json   # y rellenarlo
/// flutter run -d chrome --dart-define-from-file=config/app_config.json
/// ```
///
/// Estos valores acaban dentro del JavaScript compilado, por lo que **no son secretos** (son
/// las claves públicas del cliente web de Firebase y las claves de sitio de reCAPTCHA). La
/// protección real está en las restricciones de la clave de API (por referente HTTP), en
/// App Check y en las reglas de seguridad. Nunca coloques aquí contraseñas, claves privadas
/// ni cuentas de servicio.
class AppConfig {
  const AppConfig._();

  /// Clave de API del cliente web de Firebase.
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');

  /// Identificador de la aplicación web de Firebase.
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');

  /// Identificador del remitente de mensajería (número de proyecto).
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');

  /// Identificador del proyecto de Firebase.
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  /// Dominio de autenticación de Firebase (normalmente `<proyecto>.firebaseapp.com`).
  static const String firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  /// Bucket de Cloud Storage (normalmente `<proyecto>.firebasestorage.app`).
  static const String firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  /// Identificador de medición de Google Analytics. Es opcional.
  static const String firebaseMeasurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  /// Clave de sitio de reCAPTCHA Enterprise de tipo puntuación (invisible), usada también por App Check.
  static const String recaptchaScoreSiteKey = String.fromEnvironment('RECAPTCHA_SCORE_SITE_KEY');

  /// Clave de sitio de reCAPTCHA Enterprise de tipo casilla (visible).
  static const String recaptchaCheckboxSiteKey =
      String.fromEnvironment('RECAPTCHA_CHECKBOX_SITE_KEY');

  /// Nombres de las claves obligatorias que no se han definido en la compilación.
  ///
  /// Una lista vacía significa que la configuración está completa.
  static List<String> get missingKeys {
    const required = <String, String>{
      'FIREBASE_API_KEY': firebaseApiKey,
      'FIREBASE_APP_ID': firebaseAppId,
      'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
      'FIREBASE_PROJECT_ID': firebaseProjectId,
      'FIREBASE_AUTH_DOMAIN': firebaseAuthDomain,
      'FIREBASE_STORAGE_BUCKET': firebaseStorageBucket,
      'RECAPTCHA_SCORE_SITE_KEY': recaptchaScoreSiteKey,
      'RECAPTCHA_CHECKBOX_SITE_KEY': recaptchaCheckboxSiteKey,
    };
    return <String>[
      for (final entry in required.entries)
        if (entry.value.isEmpty) entry.key,
    ];
  }
}
