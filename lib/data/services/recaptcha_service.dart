// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: recaptcha_service.dart
// Propósito: Servicio de integración con reCAPTCHA Enterprise para validación humana y prevención de bots.
// =========================================================================

import 'dart:async';
import 'package:mipetshop/app/app_config.dart';
import 'recaptcha_platform_stub.dart'
    if (dart.library.html) 'recaptcha_platform_web.dart';

/// Servicio de gestión de tokens y widget de reCAPTCHA Enterprise.
///
/// Soporta dos claves de sitio, inyectadas en la compilación (ver [AppConfig]):
/// 1. [scoreSiteKey]: Clave invisible para Firebase App Check y scoring de mutaciones.
/// 2. [checkboxSiteKey]: Clave visible de casilla interactiva para registro, login y recuperación de cuentas.
class RecaptchaService {
  /// Clave de sitio de puntuación invisible.
  static const String scoreSiteKey = AppConfig.recaptchaScoreSiteKey;

  /// Clave de sitio de casilla visible.
  static const String checkboxSiteKey = AppConfig.recaptchaCheckboxSiteKey;

  /// Constructor del servicio reCAPTCHA.
  RecaptchaService();

  /// Carga el SDK de reCAPTCHA Enterprise con [scoreSiteKey] (una sola vez).
  ///
  /// No hace nada si la clave no está configurada: el arranque ya avisa de la configuración incompleta.
  static Future<void> loadScript() {
    if (scoreSiteKey.isEmpty) return Future<void>.value();
    return loadRecaptchaScriptPlatform(scoreSiteKey);
  }

  /// Ejecuta la evaluación invisible de acción y retorna el token emitido con tiempo de vida (TTL) de 2 minutos.
  ///
  /// @param actionName Nombre de la acción de negocio protegida (ej. 'login', 'booking').
  /// @return Token generado por reCAPTCHA Enterprise.
  Future<String> executeAction(String actionName) async {
    return executeRecaptchaActionPlatform(scoreSiteKey, actionName);
  }

  /// Renderiza la casilla interactiva de verificación en el contenedor del DOM indicado.
  ///
  /// @param containerId Identificador del elemento HTML contenedor.
  /// @param onVerified Callback ejecutado al resolver exitosamente el desafío captcha con el token.
  /// @param onExpired Callback invocado cuando el token vence (2 min), deshabilitando el envío.
  /// @param onError Callback invocado cuando ocurre un fallo de red o validación.
  void renderCheckbox({
    required String containerId,
    required void Function(String token) onVerified,
    required void Function() onExpired,
    required void Function() onError,
  }) {
    renderRecaptchaCheckboxPlatform(
      siteKey: checkboxSiteKey,
      containerId: containerId,
      onVerified: onVerified,
      onExpired: onExpired,
      onError: onError,
    );
  }

  /// Reinicia el widget de casilla ante expiración o fallo de reintento.
  ///
  /// @param widgetId Identificador del widget instanciado por grecaptcha.
  void resetCheckbox([int? widgetId]) {
    resetRecaptchaCheckboxPlatform(widgetId);
  }

  /// Registra la fábrica de vista de plataforma para renderizar el contenedor HTML en Flutter Web.
  ///
  /// @param viewType Identificador del tipo de vista para [HtmlElementView].
  /// @param containerId Identificador del elemento contenedor en el DOM.
  static void registerViewFactory(String viewType, String containerId) {
    registerRecaptchaViewFactoryPlatform(viewType, containerId);
  }
}
