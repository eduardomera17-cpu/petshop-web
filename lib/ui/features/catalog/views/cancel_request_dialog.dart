// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/catalog/views/cancel_request_dialog.dart
// Propósito: Diálogo modal de confirmación y advertencia para la cancelación de solicitudes de compra de productos.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/product_request.dart';
import 'package:mipetshop/l10n/app_localizations.dart';

/// Diálogo modal de confirmación interactivo para la anulación o desistimiento de un pedido de productos.
///
/// Presenta la relación de artículos y cantidades que integran la solicitud sujeta a cancelación,
/// requiriendo una acción deliberada del usuario antes de invocar la anulación en el backend.
class CancelRequestDialog extends StatelessWidget {
  /// Lista de productos que forman parte de la solicitud sujeta a anulación.
  final List<ProductRequestLine> lines;

  /// Callback ejecutado cuando el cliente confirma explícitamente el desistimiento.
  final VoidCallback onConfirm;

  /// Constructor del diálogo modal de cancelación de solicitud.
  const CancelRequestDialog({
    super.key,
    required this.lines,
    required this.onConfirm,
  });

  /// Método estático utilitario para desplegar el diálogo modal en pantalla.
  static Future<bool?> show(
    BuildContext context, {
    required List<ProductRequestLine> lines,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CancelRequestDialog(
        lines: lines,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleText = l10n?.cancelRequestTitle ?? '';
    final confirmText = l10n?.cancelRequestConfirm ?? '';
    final itemsHeader = l10n?.cancelRequestItemsHeader ?? '';
    final noticeText = l10n?.cancelRequestNotice ?? '';
    final cancelBtnText = l10n?.cancel ?? '';
    final confirmBtnText = l10n?.confirmCancelAction ?? '';

    return AlertDialog(
      title: Text(titleText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(confirmText),
          const SizedBox(height: 12),
          if (lines.isNotEmpty) ...[
            Text(
              itemsHeader,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        line.productName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      l10n?.quantityLabel(line.quantity) ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            noticeText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TappableArea(
          semanticLabel: cancelBtnText,
          onTap: () => Navigator.of(context).pop(false),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelBtnText),
          ),
        ),
        TappableArea(
          semanticLabel: confirmBtnText,
          onTap: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          child: ElevatedButton(
            key: const ValueKey('confirm_cancel_request_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            child: Text(confirmBtnText),
          ),
        ),
      ],
    );
  }
}
