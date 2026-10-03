// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/profile/views/account_deactivation_dialog.dart
// Propósito: Diálogo modal de confirmación para la desactivación voluntaria de cuenta de cliente con previsualización categorizada y reautenticación segura.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/profile/view_models/account_deactivation_view_model.dart';

/// Diálogo modal de alta criticidad para la desactivación voluntaria de la cuenta del cliente.
///
/// Implementa los mecanismos de seguridad y transparencia definidos en las especificaciones:
/// - Previsualización clasificada en dos grupos:
///   1. Elementos cancelados inmediatamente (citas futuras y pedidos pendientes).
///   2. Elementos archivados y protegidos por normativas contables/tributarias (facturación histórica y citas completadas).
/// - Exigencia de reautenticación obligatoria mediante ingreso de la contraseña vigente.
/// - Cierre definitivo de sesión y revocación de tokens de acceso al confirmar el procedimiento.
class AccountDeactivationDialog extends StatefulWidget {
  /// Modelo de vista reactivo gestor de la carga de la vista previa y la invocación transaccional.
  final AccountDeactivationViewModel viewModel;

  /// Retrollamada ejecutada tras la desactivación exitosa para limpiar el estado de la sesión o navegar al login.
  final VoidCallback onDeactivated;

  /// Constructor del diálogo modal de desactivación de cuenta.
  const AccountDeactivationDialog({
    super.key,
    required this.viewModel,
    required this.onDeactivated,
  });

  /// Método utilitario estático para desplegar el diálogo modal con configuración no cancelable al tocar fuera.
  static Future<bool?> show(
    BuildContext context, {
    required AccountDeactivationViewModel viewModel,
    required VoidCallback onDeactivated,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AccountDeactivationDialog(
        viewModel: viewModel,
        onDeactivated: onDeactivated,
      ),
    );
  }

  @override
  State<AccountDeactivationDialog> createState() =>
      _AccountDeactivationDialogState();
}


class _AccountDeactivationDialogState extends State<AccountDeactivationDialog> {
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadPreview();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final cancelBtnText = l10n?.cancel ?? '';
        final confirmBtnText = widget.viewModel.isSubmitting
            ? (l10n?.deactivatingAccount ?? '')
            : (l10n?.confirmDeactivationAction ?? '');

        return AlertDialog(
          title: Text(l10n?.accountDeactivationTitle ?? ''),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 500),
            child: widget.viewModel.isLoadingPreview
                ? const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.accountDeactivationNotice ?? '',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Grupo 1: Elementos a cancelar
                        Text(
                          l10n?.deactivationGroupToCancelTitle ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.viewModel.toCancel.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              l10n?.deactivationGroupToCancelEmpty ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else
                          ...widget.viewModel.toCancel.map((item) {
                            final concept = (item['concept'] as String?) ?? '';
                            final type = item['type'] as String?;

                            if (type == 'APPOINTMENT') {
                              final dateStr = (item['dateString'] as String?) ?? '';
                              final slot = item['timeSlot'] as String?;
                              final subtitleText = slot != null && slot.isNotEmpty
                                  ? '$dateStr · $slot'
                                  : dateStr;
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.cancel,
                                    color: Colors.red, size: 20),
                                title: Text(concept),
                                subtitle: Text(
                                  subtitleText,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }

                            // PRODUCT_REQUEST: enumera sus lines (TRD §3.4.G, AUD-244)
                            final lines = (item['lines'] as List?) ?? [];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.cancel,
                                  color: Colors.red, size: 20),
                              title: Text(concept),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...lines.map((l) {
                                    final lineMap = l is Map ? l : const <dynamic, dynamic>{};
                                    final rawName = lineMap['productName'] as String?;
                                    final pName = rawName?.trim();
                                    final displayName = (pName != null && pName.isNotEmpty)
                                        ? pName
                                        : (l10n?.deactivationUnknownProduct ?? '');
                                    final qty = (lineMap['quantity'] as num?)?.toInt() ?? 1;
                                    return Text(
                                      '$displayName · ${l10n?.quantityLabel(qty) ?? ''}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 16),

                        // Grupo 2: Elementos retenidos
                        Text(
                          l10n?.deactivationGroupToRetainTitle ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        if (widget.viewModel.toRetain.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              l10n?.deactivationGroupToRetainEmpty ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else
                          ...widget.viewModel.toRetain.map((item) {
                            final concept = (item['concept'] as String?) ?? '';
                            final type = item['type'] as String?;
                            final reasonText = _translateReason(l10n, item['reason'] as String?);

                            if (type == 'APPOINTMENT') {
                              final dateStr = (item['dateString'] as String?) ?? '';
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.lock,
                                    color: Colors.blue, size: 20),
                                title: Text(concept),
                                subtitle: Text(
                                  dateStr.isNotEmpty
                                      ? '$dateStr · $reasonText'
                                      : reasonText,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }

                            // PRODUCT_REQUEST: enumera sus lines y muestra reason traducido (CA-64)
                            final lines = (item['lines'] as List?) ?? [];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.lock,
                                  color: Colors.blue, size: 20),
                              title: Text(concept),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...lines.map((l) {
                                    final lineMap = l is Map ? l : const <dynamic, dynamic>{};
                                    final rawName = lineMap['productName'] as String?;
                                    final pName = rawName?.trim();
                                    final displayName = (pName != null && pName.isNotEmpty)
                                        ? pName
                                        : (l10n?.deactivationUnknownProduct ?? '');
                                    final qty = (lineMap['quantity'] as num?)?.toInt() ?? 1;
                                    return Text(
                                      '$displayName · ${l10n?.quantityLabel(qty) ?? ''}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    );
                                  }),
                                  if (reasonText.isNotEmpty)
                                    Text(
                                      reasonText,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 20),

                        // Campo de reautenticación por contraseña
                        Text(
                          l10n?.deactivationPasswordPrompt ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const ValueKey('deactivation_password_field'),
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n?.passwordLabel ?? '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: TappableArea(
                              semanticLabel: _obscurePassword
                                  ? (l10n?.showPassword ?? '')
                                  : (l10n?.hidePassword ?? ''),
                              tooltip: _obscurePassword
                                  ? (l10n?.showPassword ?? '')
                                  : (l10n?.hidePassword ?? ''),
                              child: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        if (widget.viewModel.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _mapDeactivationError(
                                context, widget.viewModel.errorMessage!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          actions: [
            TappableArea(
              semanticLabel: cancelBtnText,
              onTap: widget.viewModel.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: TextButton(
                onPressed: widget.viewModel.isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(cancelBtnText),
              ),
            ),
            TappableArea(
              semanticLabel: confirmBtnText,
              onTap: widget.viewModel.isSubmitting
                  ? null
                  : () => _handleSubmit(),
              child: ElevatedButton(
                key: const ValueKey('confirm_deactivation_submit_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: widget.viewModel.isSubmitting
                    ? null
                    : () => _handleSubmit(),
                child: Text(confirmBtnText),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleSubmit() async {
    final password = _passwordCtrl.text;
    if (password.trim().isEmpty) return;

    final success = await widget.viewModel.confirmDeactivation(password);
    if (success && mounted) {
      Navigator.of(context).pop(true);
      widget.onDeactivated();
    }
  }

  String _translateReason(AppLocalizations? l10n, String? reason) {
    if (reason == 'COMPLETED') {
      return l10n?.deactivationReasonCompleted ?? '';
    }
    if (reason == 'BILLED') {
      return l10n?.deactivationReasonBilled ?? '';
    }
    return '';
  }

  String _mapDeactivationError(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context);
    switch (code) {
      case 'INVALID_PASSWORD':
      case 'WRONG_PASSWORD':
        return l10n?.errorCurrentPasswordIncorrect ?? '';
      default:
        return l10n?.errorGeneric ?? '';
    }
  }
}
