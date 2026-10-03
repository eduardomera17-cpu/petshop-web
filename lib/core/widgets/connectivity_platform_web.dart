// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/widgets/connectivity_platform_web.dart
// Propósito: Detección y monitorización de conectividad en Flutter Web mediante API estándar del DOM.
// =========================================================================

import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Consulta el estado actual de enlace a Internet en el navegador mediante `navigator.onLine`.
///
/// Captura posibles excepciones en caso de ejecución en workers u otros contextos
/// restringidos, retornando `true` por omisión para evitar falsos bloqueos.
bool getPlatformOnline() {
  try {
    return web.window.navigator.onLine;
  } catch (_) {
    return true;
  }
}

/// Suscribe escuchadores para los eventos nativos `online` y `offline` en el objeto global `window`.
///
/// Permite reaccionar a desconexiones de red repentinas o restablecimiento del enlace,
/// invocando la función [callback] provista con el nuevo estado booleano.
///
/// @param callback Función que recibe el nuevo estado de conexión (`true` si online, `false` si offline).
void initPlatformConnectivityListeners(void Function(bool isOnline) callback) {
  try {
    web.window.addEventListener(
      'online',
      (web.Event _) {
        callback(true);
      }.toJS,
    );

    web.window.addEventListener(
      'offline',
      (web.Event _) {
        callback(false);
      }.toJS,
    );
  } catch (_) {
    // Protección ante ejecución en entornos web sin acceso a window
  }
}
