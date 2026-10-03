// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/widgets/connectivity_banner.dart
// Propósito: Componente perimetral de monitoreo de conectividad de red, banner visual
//            y ámbito heredado (InheritedWidget) para inhibir mutaciones offline.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'connectivity_platform_stub.dart'
    if (dart.library.html) 'connectivity_platform_web.dart';

/// Controlador observable del estado de conectividad a la red (TRD §1.3.6, N-13).
///
/// Implementa [ChangeNotifier] para gestionar y notificar variaciones en el estado
/// de enlace del cliente, permitiendo a la interfaz de usuario reaccionar en tiempo real
/// ante pérdidas o restauraciones de acceso a Internet.
class ConnectivityController extends ChangeNotifier {
  /// Estado interno de conectividad a la red.
  bool _isOnline;

  /// Inicializa el controlador con un estado opcional o consultando la plataforma.
  ///
  /// En entornos Flutter Web ([kIsWeb]), suscribe automáticamente escuchadores
  /// de eventos del navegador ('online' y 'offline') para mantener sincronizado el estado.
  ConnectivityController({bool? initialOnline})
      : _isOnline = initialOnline ?? getPlatformOnline() {
    if (initialOnline == null && kIsWeb) {
      initPlatformConnectivityListeners((online) {
        setOnline(online);
      });
    }
  }

  /// Indica si el dispositivo cuenta actualmente con enlace a la red.
  bool get isOnline => _isOnline;

  /// Actualiza el estado de red y notifica a los escuchadores si hay un cambio de estado.
  ///
  /// @param online `true` si la conexión está disponible; `false` si se ha interrumpido.
  void setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }
}

/// Ámbito heredado para consultar el estado de red en el subárbol (TRD §1.3.6, N-13).
///
/// Expone a los widgets descendientes la propiedad [isOnline] y el [controller]
/// para condicionar comportamientos y desactivar acciones de mutación críticas.
class ConnectivityScope extends InheritedWidget {
  /// Bandera que indica si el canal de comunicación con la red está activo.
  final bool isOnline;

  /// Instancia del controlador de conectividad que rige este ámbito.
  final ConnectivityController controller;

  /// Crea una instancia del ámbito heredado [ConnectivityScope].
  const ConnectivityScope({
    super.key,
    required this.isOnline,
    required this.controller,
    required super.child,
  });

  /// Obtiene la instancia más cercana de [ConnectivityScope] en el árbol, o `null` si no existe.
  static ConnectivityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConnectivityScope>();
  }

  /// Obtiene la instancia más cercana de [ConnectivityScope] en el árbol.
  ///
  /// Lanza una aserción si el widget no se encuentra presente en el contexto actual.
  static ConnectivityScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No se encontró ConnectivityScope en el árbol');
    return scope!;
  }

  @override
  bool updateShouldNotify(ConnectivityScope oldWidget) {
    return isOnline != oldWidget.isOnline;
  }
}

/// Banner global de conectividad perimetral.
///
/// Muestra un aviso en caso de pérdida de red e inhibe la interacción en
/// acciones de mutación, evitando la escritura optimista en frontend.
class ConnectivityBanner extends StatefulWidget {
  /// Subárbol de widgets protegido y monitorizado por este banner.
  final Widget child;

  /// Controlador externo opcional para inyección o pruebas unitarias.
  final ConnectivityController? controller;

  /// Crea una instancia del banner perimetral [ConnectivityBanner].
  const ConnectivityBanner({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  /// Instancia activa del controlador de conectividad.
  late final ConnectivityController _controller;

  /// Bandera que determina si este State gestiona el ciclo de vida del controlador.
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = ConnectivityController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isOnline = _controller.isOnline;
        final l10n = AppLocalizations.of(context);
        final offlineMessage = l10n?.offlineBannerMessage ??
            'Sin conexión a Internet. Acciones deshabilitadas.';

        return ConnectivityScope(
          isOnline: isOnline,
          controller: _controller,
          child: Stack(
            children: [
              widget.child,
              if (!isOnline)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 6.0,
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 20.0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                offlineMessage,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
