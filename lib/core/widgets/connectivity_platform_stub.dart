// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/widgets/connectivity_platform_stub.dart
// Propósito: Implementación fallback/stub para plataformas no web y pruebas unitarias en VM Dart.
// =========================================================================

/// Determina si la plataforma actual posee enlace activo a la red.
///
/// En el stub para entornos no web o tests unitarios en VM, retorna siempre `true`
/// para no bloquear la ejecución ni requerir dependencias DOM ausentes.
bool getPlatformOnline() => true;

/// Inicializa los escuchadores de eventos de red a nivel de plataforma.
///
/// En esta implementación stub (no web / VM), la operación no realiza acciones
/// dado que no existe acceso al árbol de eventos de un navegador.
///
/// @param callback Función receptora que notificaría transiciones en el estado del enlace.
void initPlatformConnectivityListeners(void Function(bool isOnline) callback) {}
