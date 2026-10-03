// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/core/shortcuts/admin_shortcuts.dart
// Propósito: Sistema de atajos globales de teclado, intenciones y catálogo modal de accesibilidad para la agilización de operaciones en el panel administrativo.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intención de teclado para desplegar la ventana modal de ayuda contextual de atajos ('?').
class ShowShortcutsHelpIntent extends Intent {
  const ShowShortcutsHelpIntent();
}

/// Intención de teclado para confirmar la cita médica seleccionada ('Alt + C').
class ConfirmAppointmentIntent extends Intent {
  const ConfirmAppointmentIntent();
}

/// Intención de teclado para completar y finalizar la cita médica seleccionada ('Alt + K').
class CompleteAppointmentIntent extends Intent {
  const CompleteAppointmentIntent();
}

/// Intención de teclado para avanzar la solicitud de producto a estado lista para retiro ('Alt + A').
class AdvanceProductRequestIntent extends Intent {
  const AdvanceProductRequestIntent();
}

/// Intención de teclado para enfocar el buscador o filtro de listados ('Ctrl + F').
class SearchActionIntent extends Intent {
  const SearchActionIntent();
}

/// Intención de teclado para navegar a la siguiente conversación en la bandeja de chat ('Alt + N').
class NextConversationIntent extends Intent {
  const NextConversationIntent();
}

/// {@template admin_shortcuts}
/// Envoltura de accesibilidad que intercepta combinaciones de teclas del teclado físico
/// y las mapea hacia acciones operativas administrativas concretas.
/// {@endtemplate}
class AdminShortcuts extends StatelessWidget {
  /// Subárbol de widgets interactivo envuelto por el detector de atajos.
  final Widget child;

  /// Acción a ejecutar al confirmar cita médica.
  final VoidCallback? onConfirmAppointment;

  /// Acción a ejecutar al marcar como completada una cita.
  final VoidCallback? onCompleteAppointment;

  /// Acción a ejecutar al avanzar el despacho de una orden de productos.
  final VoidCallback? onAdvanceProductRequest;

  /// Acción a ejecutar para abrir o enfocar la búsqueda.
  final VoidCallback? onSearch;

  /// Acción a ejecutar para transicionar a la siguiente conversación.
  final VoidCallback? onNextConversation;

  const AdminShortcuts({
    super.key,
    required this.child,
    this.onConfirmAppointment,
    this.onCompleteAppointment,
    this.onAdvanceProductRequest,
    this.onSearch,
    this.onNextConversation,
  });

  /// Muestra la hoja modal de ayuda con la lista descubrible de atajos (CA-AD-48).
  static void showHelpModal(BuildContext context) {
    const helpTitle = 'Atajos de teclado del panel';
    const closeButtonLabel = 'Cerrar';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.blueGrey),
            SizedBox(width: 8.0),
            Text(helpTitle),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: ListView(
            shrinkWrap: true,
            children: const [
              _ShortcutHelpTile(
                keys: '?',
                description: 'Abrir esta hoja de ayuda contextual',
              ),
              _ShortcutHelpTile(
                keys: 'Alt + C',
                description: 'Confirmar cita seleccionada',
              ),
              _ShortcutHelpTile(
                keys: 'Alt + K',
                description: 'Completar cita seleccionada',
              ),
              _ShortcutHelpTile(
                keys: 'Alt + A',
                description: 'Avanzar solicitud de producto',
              ),
              _ShortcutHelpTile(
                keys: 'Ctrl + F / /',
                description: 'Buscar o filtrar en listado',
              ),
              _ShortcutHelpTile(
                keys: 'Alt + N',
                description: 'Abrir la siguiente conversación de chat',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(closeButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Tecla '?' (Shift + / o tecla directa con interrogación)
        const CharacterActivator('?'): const ShowShortcutsHelpIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyC):
            const ConfirmAppointmentIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyK):
            const CompleteAppointmentIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyA):
            const AdvanceProductRequestIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const SearchActionIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyN):
            const NextConversationIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ShowShortcutsHelpIntent: CallbackAction<ShowShortcutsHelpIntent>(
            onInvoke: (_) {
              showHelpModal(context);
              return null;
            },
          ),
          ConfirmAppointmentIntent: CallbackAction<ConfirmAppointmentIntent>(
            onInvoke: (_) {
              onConfirmAppointment?.call();
              return null;
            },
          ),
          CompleteAppointmentIntent: CallbackAction<CompleteAppointmentIntent>(
            onInvoke: (_) {
              onCompleteAppointment?.call();
              return null;
            },
          ),
          AdvanceProductRequestIntent: CallbackAction<AdvanceProductRequestIntent>(
            onInvoke: (_) {
              onAdvanceProductRequest?.call();
              return null;
            },
          ),
          SearchActionIntent: CallbackAction<SearchActionIntent>(
            onInvoke: (_) {
              onSearch?.call();
              return null;
            },
          ),
          NextConversationIntent: CallbackAction<NextConversationIntent>(
            onInvoke: (_) {
              onNextConversation?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

/// Fila informativa para el listado de combinaciones de teclas en el diálogo de ayuda.
class _ShortcutHelpTile extends StatelessWidget {
  /// Representación textual de la combinación de teclas (e.g. 'Alt + C').
  final String keys;

  /// Explicación funcional de la acción disparada por el atajo.
  final String description;

  const _ShortcutHelpTile({
    required this.keys,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14.0),
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
