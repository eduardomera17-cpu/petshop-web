// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/widgets/admin_back_button.dart
// Propósito: Botón de retorno accesible y homogéneo para las pantallas del panel administrativo en arquitecturas basadas en GoRouter.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';

/// {@template admin_back_button}
/// Control interactivo para el retorno explícito al tablero o ruta superior del Panel de Administración (TRD §1.3.3, §1.3.4, N-06).
///
/// Dado que las rutas administrativas se alcanzan mediante navegación declarativa con `context.go`
/// (la cual reemplaza la pila en lugar de apilar), el `AppBar` estándar no deduce un botón de retroceso automático.
/// Este widget restituye dicha salida con soporte táctil, semántico y de teclado vía [TappableArea].
/// {@endtemplate}
class AdminBackButton extends StatelessWidget {
  /// Destino del retorno. Por omisión, el panel principal.
  final String destination;

  /// Acción alternativa: si se proporciona, sustituye a la navegación por ruta
  /// (útil en vistas maestro-detalle que resuelven el retorno con estado local).
  final VoidCallback? onBack;

  const AdminBackButton({
    super.key,
    this.destination = '/admin',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return TappableArea(
      key: const Key('admin_back_button'),
      tooltip: 'Volver al panel',
      semanticLabel: 'Volver al Panel de Administración',
      onTap: onBack ?? () => context.go(destination),
      child: const Icon(Icons.arrow_back),
    );
  }
}
