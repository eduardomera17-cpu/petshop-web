// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/core/breakpoints.dart
// Propósito: Definición de puntos de quiebre responsivos y widget de construcción adaptativa (ResponsiveLayout) basado en restricciones del contenedor.
// =========================================================================

import 'package:flutter/widgets.dart';

/// {@template app_breakpoint}
/// Clasificación canónica de anchos de pantalla adaptativos del sistema.
///
/// Definición conforme a los umbrales de diseño Material / Web Responsivo:
/// - [compact]: ancho menor a 600 puntos lógicos (móviles).
/// - [medium]: ancho entre 600 y 1023 puntos lógicos (tablets / laptops pequeñas).
/// - [expanded]: ancho igual o mayor a 1024 puntos lógicos (computadoras de escritorio).
/// {@endtemplate}
enum AppBreakpoint {
  /// Pantallas móviles o contenedores estrechos (< 600 dp).
  compact,

  /// Pantallas medianas o tablets (600 - 1023 dp).
  medium,

  /// Pantallas amplias de escritorio (>= 1024 dp).
  expanded;

  /// Límite superior del segmento compacto en puntos lógicos.
  static const double compactLimit = 600.0;

  /// Límite superior del segmento medio en puntos lógicos.
  static const double mediumLimit = 1024.0;

  /// Obtiene la categoría de breakpoint a partir del ancho provisto.
  static AppBreakpoint fromWidth(double width) {
    if (width < compactLimit) return AppBreakpoint.compact;
    if (width < mediumLimit) return AppBreakpoint.medium;
    return AppBreakpoint.expanded;
  }

  bool get isCompact => this == AppBreakpoint.compact;
  bool get isMedium => this == AppBreakpoint.medium;
  bool get isExpanded => this == AppBreakpoint.expanded;
}

/// {@template responsive_layout}
/// Constructor adaptativo de interfaz de usuario basado exclusivamente en restricciones de caja.
///
/// Evalúa dinámicamente el ancho máximo disponible mediante [LayoutBuilder] y provee
/// el [AppBreakpoint] correspondiente al builder para decidir la disposición de los componentes.
/// Prohíbe la consulta a dimensiones de ventana globales en subárboles (evitando roturas de layout).
/// {@endtemplate}
class ResponsiveLayout extends StatelessWidget {
  /// Función constructora que recibe el contexto de renderizado y el breakpoint vigente.
  final Widget Function(BuildContext context, AppBreakpoint breakpoint) builder;

  /// Constructor del layout responsivo.
  const ResponsiveLayout({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = AppBreakpoint.fromWidth(constraints.maxWidth);
        return builder(context, breakpoint);
      },
    );
  }
}
