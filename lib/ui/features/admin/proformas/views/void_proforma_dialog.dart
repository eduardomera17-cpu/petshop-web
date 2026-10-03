// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/views/void_proforma_dialog.dart
// Propósito: Diálogo modal interactivo para la captura del motivo justificado y confirmación de anulación de proformas administrativas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/admin_proformas_view_model.dart';

/// {@template void_proforma_dialog}
/// Diálogo modal interactivo para la anulación justificada de una proforma.
///
/// Exige el ingreso obligatorio de un motivo de anulación válido (entre 5 y 300 caracteres)
/// cumpliendo con las políticas de auditoría tributaria y trazabilidad institucional.
/// Al confirmar, delega la operación al [AdminProformasViewModel].
/// {@endtemplate}
class VoidProformaDialog extends StatefulWidget {
  /// Identificador único de la proforma que se desea anular.
  final String proformaId;

  /// ViewModel administrativo encargado de procesar la petición de anulación en backend.
  final AdminProformasViewModel viewModel;

  /// Constructor del diálogo modal de anulación.
  const VoidProformaDialog({
    super.key,
    required this.proformaId,
    required this.viewModel,
  });

  /// Método estático utilitario para desplegar el diálogo modal en pantalla.
  ///
  /// Bloquea el cierre accidental mediante tap exterior ([barrierDismissible] en `false`).
  static Future<void> show(
    BuildContext context, {
    required String proformaId,
    required AdminProformasViewModel viewModel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VoidProformaDialog(
        proformaId: proformaId,
        viewModel: viewModel,
      ),
    );
  }

  @override
  State<VoidProformaDialog> createState() => _VoidProformaDialogState();
}

class _VoidProformaDialogState extends State<VoidProformaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final reason = _reasonCtrl.text.trim();
    final success = await widget.viewModel.voidDocument(
      proformaId: widget.proformaId,
      reason: reason,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.proformaVoidedSuccess),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.voidProformaDialogTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.voidReasonPrompt,
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                key: const ValueKey('void_proforma_reason_input'),
                controller: _reasonCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: l10n.voidReasonLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return l10n.voidReasonMinLengthError;
                  }
                  if (val.trim().length > 300) {
                    return l10n.voidReasonMaxLengthError;
                  }
                  return null;
                },
              ),
              ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  if (widget.viewModel.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.viewModel.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13.0),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TappableArea(
          semanticLabel: l10n.cancel,
          onTap: () => Navigator.of(context).pop(),
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ),
        ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final confirmText = widget.viewModel.isProcessing
                ? l10n.voidingProforma
                : l10n.voidProformaAction;
            return TappableArea(
              semanticLabel: confirmText,
              onTap: widget.viewModel.isProcessing ? null : _submit,
              child: SizedBox(
                height: 48.0,
                child: ElevatedButton(
                  key: const ValueKey('confirm_void_proforma_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.viewModel.isProcessing ? null : _submit,
                  child: widget.viewModel.isProcessing
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.voidingProforma),
                          ],
                        )
                      : Text(l10n.voidProformaAction),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
