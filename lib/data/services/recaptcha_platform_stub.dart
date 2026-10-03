// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: recaptcha_platform_stub.dart
// Propósito: Implementación de respaldo (stub) de reCAPTCHA para plataformas no web.
// =========================================================================

/// Fuera de la web no hay SDK de reCAPTCHA que cargar: no hace nada.
Future<void> loadRecaptchaScriptPlatform(String siteKey) async {}

/// reCAPTCHA Enterprise solo está disponible en Flutter Web: fuera de la web no hay evaluación posible.
Future<String> executeRecaptchaActionPlatform(String siteKey, String actionName) {
  throw UnsupportedError('reCAPTCHA Enterprise solo está disponible en Flutter Web.');
}

/// La casilla challenge no existe fuera de la web: no hace nada.
void renderRecaptchaCheckboxPlatform({
  required String siteKey,
  required String containerId,
  required void Function(String token) onVerified,
  required void Function() onExpired,
  required void Function() onError,
}) {}

/// La casilla challenge no existe fuera de la web: no hace nada.
void resetRecaptchaCheckboxPlatform([int? widgetId]) {}

/// Registrador stub de vistas HTML para compatibilidad de compilación no web.
void registerRecaptchaViewFactoryPlatform(String viewType, String containerId) {}
