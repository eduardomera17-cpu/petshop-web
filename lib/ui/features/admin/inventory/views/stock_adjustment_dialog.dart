// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/inventory/views/stock_adjustment_dialog.dart
// Propósito: Diálogo modal para realizar ajustes de inventario con delta relativo, motivo formal y cómputo de stock resultante.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/product.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/inventory/view_models/admin_inventory_view_model.dart';

/// Diálogo modal interactivo para la aplicación de ajustes manuales de stock físico.
///
/// Características y reglas de integridad:
/// - Permite ingresar variaciones relativas positivas (ingreso de mercancía) o negativas (mermas, daño o caducidad).
/// - Calcula y previsualiza en tiempo real el stock resultante impidiendo saldos negativos.
/// - Exige motivo o justificación formal del movimiento para mantener la trazabilidad contable.
class StockAdjustmentDialog extends StatefulWidget {
  /// Entidad del producto sujeto al ajuste de existencias.
  final Product product;

  /// Modelo de vista reactivo gestor de la persistencia del movimiento de inventario.
  final AdminInventoryViewModel viewModel;

  /// Constructor del diálogo de ajuste de stock.
  const StockAdjustmentDialog({
    super.key,
    required this.product,
    required this.viewModel,
  });

  /// Despliega el diálogo modal de ajuste de stock de forma no cancelable al tocar el fondo.
  static Future<void> show(
    BuildContext context, {
    required Product product,
    required AdminInventoryViewModel viewModel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StockAdjustmentDialog(
        product: product,
        viewModel: viewModel,
      ),
    );
  }

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}


class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deltaCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  int _delta = 0;

  @override
  void initState() {
    super.initState();
    _deltaCtrl.addListener(() {
      final parsed = int.tryParse(_deltaCtrl.text.trim()) ?? 0;
      setState(() {
        _delta = parsed;
      });
    });
  }

  @override
  void dispose() {
    _deltaCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.viewModel.adjustStock(
      productId: widget.product.id,
      delta: _delta,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.stockAdjustSuccess),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resultingStock = widget.product.stock + _delta;

    return AlertDialog(
      title: Text(l10n.inventoryAdjustmentTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${l10n.currentStockLabel}: ${widget.product.stock}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16.0),

              // Campo de Delta (+/-)
              TextFormField(
                key: const ValueKey('stock_delta_input'),
                controller: _deltaCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: false,
                ),
                decoration: InputDecoration(
                  labelText: l10n.stockDeltaLabel,
                  helperText: l10n.stockDeltaHelp,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.stockDeltaLabel;
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed == 0) {
                    return l10n.stockDeltaLabel;
                  }
                  if (widget.product.stock + parsed < 0) {
                    return l10n.stockDeltaHelp;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Vista previa del stock resultante
              Container(
                key: const ValueKey('resulting_stock_preview'),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: resultingStock >= 0 ? Colors.teal.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: resultingStock >= 0 ? Colors.teal.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.resultingStockLabel(resultingStock),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: resultingStock >= 0 ? Colors.teal.shade900 : Colors.red.shade900,
                      ),
                    ),
                    Icon(
                      resultingStock >= 0 ? Icons.check_circle_outline : Icons.error_outline,
                      color: resultingStock >= 0 ? Colors.teal : Colors.red,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Motivo del ajuste
              TextFormField(
                key: const ValueKey('adjustment_reason_input'),
                controller: _reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.stockAdjustmentReasonPrompt,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return l10n.stockAdjustmentReasonPrompt;
                  }
                  return null;
                },
              ),

              // Error si hubiese
              ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  if (widget.viewModel.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
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
            final confirmText = widget.viewModel.isAdjusting
                ? l10n.adjustingStock
                : l10n.adjustStockAction;
            return TappableArea(
              semanticLabel: confirmText,
              onTap: widget.viewModel.isAdjusting ? null : _submit,
              child: SizedBox(
                height: 48.0,
                child: ElevatedButton(
                  key: const ValueKey('confirm_stock_adjust_button'),
                  onPressed: widget.viewModel.isAdjusting ? null : _submit,
                  child: widget.viewModel.isAdjusting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.adjustingStock),
                          ],
                        )
                      : Text(l10n.adjustStockAction),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
