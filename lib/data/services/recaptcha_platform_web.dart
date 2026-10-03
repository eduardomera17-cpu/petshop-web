// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: recaptcha_platform_web.dart
// Propósito: Interoperabilidad JavaScript en Flutter Web para el renderizado y consumo de reCAPTCHA Enterprise.
// =========================================================================

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

@JS('grecaptcha.enterprise.ready')
external void _grecaptchaReady(JSFunction callback);

@JS('grecaptcha.enterprise.execute')
external JSPromise<JSString> _grecaptchaExecute(
  JSString siteKey,
  JSAny options,
);

@JS('grecaptcha.enterprise.render')
external JSAny _grecaptchaRender(
  JSAny container,
  JSAny parameters,
);

@JS('grecaptcha.enterprise.reset')
external void _grecaptchaReset(JSAny? optWidgetId);

/// Mapeo en memoria de los contenedores HTML creados por la fábrica de vistas.
///
/// Permite el acceso autoritativo al elemento DOM eludiendo las restricciones
/// del Shadow DOM inyectado por el canvas/html renderer de Flutter Web.
final Map<String, web.HTMLDivElement> _recaptchaContainers =
    <String, web.HTMLDivElement>{};

/// Registro de tipos de vista únicos para evitar registros duplicados en [ui_web.platformViewRegistry].
final Set<String> _registeredViewTypes = <String>{};

/// Frecuencia de sondeo para detectar la inserción del contenedor en el DOM.
const Duration _pollInterval = Duration(milliseconds: 50);

/// Número máximo de intentos de sondeo antes de declarar timeout de renderizado.
const int _maxPollAttempts = 300; // 15 s

/// Carga única del SDK de reCAPTCHA Enterprise (se reutiliza el mismo [Future] en llamadas repetidas).
Future<void>? _scriptLoad;

/// Plazo máximo de espera de la carga del SDK.
const Duration _scriptLoadTimeout = Duration(seconds: 10);

/// Inserta en el documento el SDK de reCAPTCHA Enterprise con la clave de sitio indicada.
///
/// La clave llega desde la configuración de compilación (`RECAPTCHA_SCORE_SITE_KEY`), de modo que
/// no hay que editar `web/index.html`. Es idempotente: solo se inserta una etiqueta `script`.
Future<void> loadRecaptchaScriptPlatform(String siteKey) {
  return _scriptLoad ??= _injectRecaptchaScript(siteKey);
}

Future<void> _injectRecaptchaScript(String siteKey) {
  final completer = Completer<void>();
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..src = 'https://www.google.com/recaptcha/enterprise.js?render=${Uri.encodeQueryComponent(siteKey)}'
    ..async = true;
  script.onload = ((web.Event _) {
    if (!completer.isCompleted) completer.complete();
  }).toJS;
  script.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('No se pudo cargar el SDK de reCAPTCHA Enterprise.'));
    }
  }).toJS;
  web.document.head!.append(script);
  return completer.future.timeout(_scriptLoadTimeout);
}

/// Ejecuta la validación de puntuación invisible invocando `grecaptcha.enterprise.execute`.
///
/// @param siteKey Clave de sitio asignada en Google Cloud reCAPTCHA Enterprise.
/// @param actionName Nombre de la acción contextual (ej. 'login', 'createAppointment').
/// @return Promesa con el token generado resuelto en formato Dart.
Future<String> executeRecaptchaActionPlatform(String siteKey, String actionName) async {
  final completer = Completer<String>();

  try {
    _grecaptchaReady((() {
      () async {
        try {
          final options = {'action': actionName}.jsify();
          final promise = _grecaptchaExecute(siteKey.toJS, options!);
          final token = await promise.toDart;
          completer.complete(token.toDart);
        } catch (e) {
          completer.completeError(e);
        }
      }();
    }).toJS);
  } catch (e) {
    completer.completeError(e);
  }

  return completer.future;
}

/// Renderiza la casilla visual interactiva dentro del contenedor HTML reservado en el DOM.
///
/// @param siteKey Clave de casilla challenge.
/// @param containerId ID del elemento contenedor donde se inyectará el iframe del captcha.
/// @param onVerified Notificación con el token de verificación exitosa.
/// @param onExpired Notificación de expiración del token tras 2 minutos.
/// @param onError Notificación de fallos de red o de carga del script.
void renderRecaptchaCheckboxPlatform({
  required String siteKey,
  required String containerId,
  required void Function(String token) onVerified,
  required void Function() onExpired,
  required void Function() onError,
}) {
  try {
    _grecaptchaReady((() {
      int attempts = 0;
      Timer.periodic(_pollInterval, (timer) {
        attempts++;
        final web.Element? element =
            _recaptchaContainers[containerId] ?? web.document.getElementById(containerId);

        if (element != null) {
          timer.cancel();
          try {
            final params = {
              'sitekey': siteKey,
              'callback': ((JSString token) {
                onVerified(token.toDart);
              }).toJS,
              'expired-callback': (() {
                onExpired();
              }).toJS,
              'error-callback': (() {
                web.console.warn('[reCAPTCHA] error-callback disparado por Google reCAPTCHA Enterprise.'.toJS);
                onError();
              }).toJS,
            }.jsify();

            _grecaptchaRender(element as JSAny, params!);
          } catch (err) {
            web.console.error('[reCAPTCHA] Error al invocar grecaptcha.enterprise.render: $err'.toJS);
            onError();
          }
        } else if (attempts >= _maxPollAttempts) {
          timer.cancel();
          final ms = _maxPollAttempts * _pollInterval.inMilliseconds;
          web.console.error(
            '[reCAPTCHA] La vista de plataforma "$containerId" no se materializó tras $ms ms. '
            'Fábricas registradas: $_registeredViewTypes. '
            'Contenedores entregados: ${_recaptchaContainers.keys.toList()}.'.toJS,
          );
          onError();
        }
      });
    }).toJS);
  } catch (e) {
    web.console.error('[reCAPTCHA] Error en grecaptcha.enterprise.ready: $e'.toJS);
    onError();
  }
}

/// Restablece el estado de la casilla de verificación invocando `grecaptcha.enterprise.reset`.
void resetRecaptchaCheckboxPlatform([int? widgetId]) {
  try {
    _grecaptchaReset(widgetId?.toJS);
  } catch (_) {}
}

/// Registra el contenedor HTML en el registro de vistas de plataforma de Flutter Web.
void registerRecaptchaViewFactoryPlatform(String viewType, String containerId) {
  if (_registeredViewTypes.contains(viewType)) return;
  _registeredViewTypes.add(viewType);

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = containerId;
      div.style.width = '100%';
      div.style.height = '100%';
      div.style.minHeight = '78px';
      _recaptchaContainers[containerId] = div;
      return div;
    },
  );
}
