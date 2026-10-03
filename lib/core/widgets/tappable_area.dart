// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/widgets/tappable_area.dart
// Propósito: Envoltorio accesible para áreas interactivas con cumplimiento de directrices
//            WCAG 2.1 AA (tamaño mínimo 48x48 px, semántica y soporte para lectores de pantalla).
// =========================================================================

import 'package:flutter/material.dart';

/// Envoltorio accesible para elementos accionables (TRD §1.3.4, N-06).
///
/// Garantiza un área táctil mínima de 48×48 px lógicos, contraste AA y
/// soporte para lectores de pantalla mediante etiquetas [Semantics].
class TappableArea extends StatelessWidget {
  /// Widget hijo que se encapsula dentro del área táctil accesible.
  final Widget child;

  /// Callback ejecutado cuando el usuario hace clic o presiona el elemento.
  final VoidCallback? onTap;

  /// Callback opcional ejecutado ante una pulsación sostenida o prolongada.
  final VoidCallback? onLongPress;

  /// Etiqueta semántica descriptiva para lectores de pantalla y tecnologías de asistencia.
  final String? semanticLabel;

  /// Texto informativo emergente (tooltip) visualizado en hover o foco prolongado.
  final String? tooltip;

  /// Determina si el área interactiva está habilitada para recibir eventos de interacción.
  final bool enabled;

  /// Radio de curvatura en los bordes para el efecto ripple / tinta táctil.
  final BorderRadius? borderRadius;

  /// Espaciado interno entre los límites táctiles y el contenido hijo.
  final EdgeInsetsGeometry? padding;

  /// Nodo de foco para gestionar la navegación e interacción mediante teclado.
  final FocusNode? focusNode;

  /// Restricciones dimensionales mínimas requeridas (por defecto 48.0 x 48.0 píxeles lógicos).
  final BoxConstraints minConstraints;

  /// Crea un envoltorio táctil interactivo accesible [TappableArea].
  const TappableArea({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.tooltip,
    this.enabled = true,
    this.borderRadius,
    this.padding,
    this.focusNode,
    this.minConstraints = const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: minConstraints,
      child: Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );

    if (onTap != null || onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          focusNode: focusNode,
          child: content,
        ),
      );
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      content = Tooltip(
        message: tooltip!,
        child: content,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled && onTap != null,
      tooltip: tooltip,
      child: content,
    );
  }
}
