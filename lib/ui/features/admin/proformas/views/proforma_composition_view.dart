// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/views/proforma_composition_view.dart
// Propósito: Interfaz administrativa para la visualización detallada, composición de conceptos, previsualización tributaria (ICE e IVA), entrega y anulación de proformas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/domain/models/proforma.dart';
import 'package:mipetshop/domain/use_cases/preview_proforma_pricing.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/admin_proformas_view_model.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/pending_concepts_view_model.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/pending_concepts_view.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/void_proforma_dialog.dart';

/// {@template proforma_composition_view}
/// Pantalla de gestión integral, detalle tributario y acciones operativas de una proforma.
///
/// Presenta los datos generales del cliente, el desglose pormenorizado de los ítems
/// con sus bases imponibles e impuestos correspondientes (IVA e ICE calculados mediante
/// el caso de uso [PreviewProformaPricingUseCase]), y expone las acciones de ciclo de vida:
/// anexar conceptos adicionales, emitir/entregar (DELIVERED), finalizar (FINALIZED) o anular (VOIDED).
/// {@endtemplate}
class ProformaCompositionView extends StatefulWidget {
  /// Entidad de la proforma actualmente visualizada.
  final Proforma proforma;

  /// ViewModel administrativo para la ejecución de acciones sobre proformas.
  final AdminProformasViewModel viewModel;

  /// Caso de uso de cálculo tributario normativo para previsualizar subtotales e impuestos.
  final PreviewProformaPricingUseCase previewUseCase;

  /// Configuración tarifaria e impositiva vigente del sistema.
  final PublicPricingConfig pricingConfig;

  /// Repositorio de acceso a datos de proformas y conceptos pendientes del cliente.
  ///
  /// Si este parámetro es nulo, la acción de anexar nuevos conceptos se desactiva.
  final ProformasRepository? proformasRepository;

  /// Constructor inmutable de la vista de composición de proforma.
  const ProformaCompositionView({
    super.key,
    required this.proforma,
    required this.viewModel,
    required this.previewUseCase,
    required this.pricingConfig,
    this.proformasRepository,
  });

  @override
  State<ProformaCompositionView> createState() => _ProformaCompositionViewState();
}

class _ProformaCompositionViewState extends State<ProformaCompositionView> {

  /// Incorpora conceptos pendientes a un borrador ya existente.
  Future<void> _addConcepts() async {
    final repo = widget.proformasRepository;
    if (repo == null) return;

    final conceptsVm = PendingConceptsViewModel(
      repository: repo,
      clientId: widget.proforma.clientId,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => PendingConceptsView(
          viewModel: conceptsVm,
          clientName: widget.proforma.clientName,
          confirmLabel: (l10n, count) => l10n.proformaAddSelectionAction(count),
          onConfirm: (items) => widget.viewModel.addItems(
            proformaId: widget.proforma.id,
            items: items,
          ),
        ),
      ),
    );

    conceptsVm.dispose();
  }

  Future<void> _deliver() async {
    final success = await widget.viewModel.deliver(widget.proforma);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.proformaDeliveredSuccess),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _finalize() async {
    final success = await widget.viewModel.finalize(widget.proforma.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.proformaFinalizedSuccess),
          backgroundColor: Colors.teal,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _openVoidDialog() {
    VoidProformaDialog.show(
      context,
      proformaId: widget.proforma.id,
      viewModel: widget.viewModel,
    ).then((_) {
      if (mounted && widget.viewModel.errorMessage == null) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final p = widget.proforma;
    final isDraft = p.status == 'DRAFT';
    final isDelivered = p.status == 'DELIVERED';
    final isFinalized = p.status == 'FINALIZED';
    final isVoided = p.status == 'VOIDED';

    // Cálculo en cascada usando el caso de uso normativo
    final pricingInputs = p.items.map((i) {
      return DocumentPricingItemInput(
        unitBasePriceCents: i.basePriceCents,
        quantity: i.quantity,
        ivaBp: i.ivaBp,
        iceBp: i.iceBp,
      );
    }).toList();

    final adjustmentInputs = <DocumentAdjustmentInput>[];
    if (p.discountsCents > 0) {
      adjustmentInputs.add(DocumentAdjustmentInput(
        type: 'DISCOUNT',
        amountCents: p.discountsCents,
      ));
    }
    if (p.surchargesCents > 0) {
      adjustmentInputs.add(DocumentAdjustmentInput(
        type: 'SURCHARGE',
        amountCents: p.surchargesCents,
      ));
    }

    final pricingResult = widget.previewUseCase.execute(
      items: pricingInputs,
      adjustments: adjustmentInputs,
      pricingConfig: widget.pricingConfig,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.proformaDetailWithId(p.id)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final horizontalPadding = isWide ? 40.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado de estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.adminProformaClient(p.clientName),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    _buildStatusBadge(p.status, l10n),
                  ],
                ),
                if (isVoided && p.voidReason != null) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      '${l10n.voidReasonLabel}: ${p.voidReason}',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20.0),

                // Lista de ítems
                Text(
                  l10n.proformaItemsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                if (p.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      l10n.proformaNoItemsAdded,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  Card(
                    elevation: 1.0,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: p.items.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = p.items[idx];
                        return ListTile(
                          title: Text(item.title),
                          subtitle: Text(
                            l10n.proformaItemQuantityAndIce(
                              item.quantity,
                              formatCents(item.basePriceCents),
                              item.iceBp,
                            ),
                          ),
                          trailing: Text(
                            l10n.moneyAmount(formatCents(item.totalCents)),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20.0),

                // Desglose Tributario (ICE e IVA separados)
                Card(
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.proformaDetailTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 20.0),
                        _SummaryRow(
                          label: l10n.proformaSubtotalLabel,
                          value: l10n.moneyAmount(formatCents(pricingResult.subtotalCents)),
                        ),
                        if (pricingResult.totalDiscountCents > 0)
                          _SummaryRow(
                            label: l10n.proformaDiscountLabel,
                            value: l10n.moneyAmountNegative(formatCents(pricingResult.totalDiscountCents)),
                            color: Colors.green.shade800,
                          ),
                        if (pricingResult.totalSurchargeCents > 0)
                          _SummaryRow(
                            label: l10n.proformaSurchargeLabel,
                            value: l10n.moneyAmountPositive(formatCents(pricingResult.totalSurchargeCents)),
                            color: Colors.orange.shade800,
                          ),
                        _SummaryRow(
                          label: l10n.proformaTaxableBaseLabel,
                          value: l10n.moneyAmount(formatCents(pricingResult.taxableBaseCents)),
                        ),
                        _SummaryRow(
                          label: l10n.proformaIceLabel,
                          value: l10n.moneyAmount(formatCents(pricingResult.totalIceCents)),
                        ),
                        _SummaryRow(
                          label: l10n.proformaIvaLabel,
                          value: l10n.moneyAmount(formatCents(pricingResult.totalIvaCents)),
                        ),
                        const Divider(height: 24.0, thickness: 1.5),
                        _SummaryRow(
                          label: l10n.proformaTotalLabel,
                          value: l10n.moneyAmount(formatCents(pricingResult.totalCents)),
                          isBold: true,
                          fontSize: 18.0,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Mensajes de error
                ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) {
                    final err = widget.viewModel.errorMessage;
                    if (err != null) {
                      String msg = err;
                      if (err == 'PROFORMA_EMPTY') {
                        msg = l10n.proformaEmptyError;
                      } else if (err == 'DELIVERY_IN_PROGRESS') {
                        msg = l10n.deliveryInProgressError;
                      } else if (err == 'TOO_MANY_ITEMS') {
                        msg = l10n.tooManyItemsError;
                      }
                      return Container(
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          msg,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Botonera de acciones según estado
                if (isDraft) ...[
                  if (widget.proformasRepository != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TappableArea(
                        semanticLabel: l10n.proformaAddConceptsAction,
                        onTap: widget.viewModel.isProcessing ? null : _addConcepts,
                        child: SizedBox(
                          height: 48.0,
                          child: OutlinedButton.icon(
                            key: const ValueKey('add_concepts_button'),
                            onPressed:
                                widget.viewModel.isProcessing ? null : _addConcepts,
                            icon: const Icon(Icons.playlist_add),
                            label: Text(l10n.proformaAddConceptsAction),
                          ),
                        ),
                      ),
                    ),
                  TappableArea(
                    semanticLabel: l10n.deliverProformaAction,
                    onTap: p.items.isEmpty || widget.viewModel.isProcessing
                        ? null
                        : _deliver,
                    child: SizedBox(
                      height: 48.0,
                      child: ElevatedButton.icon(
                        key: const ValueKey('deliver_proforma_button'),
                        // Deshabilitado si no contiene ítems
                        onPressed: p.items.isEmpty || widget.viewModel.isProcessing
                            ? null
                            : _deliver,
                        icon: const Icon(Icons.send),
                        label: Text(l10n.deliverProformaAction),
                      ),
                    ),
                  ),
                ] else if (isDelivered) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TappableArea(
                          semanticLabel: l10n.finalizeProformaAction,
                          onTap: widget.viewModel.isProcessing ? null : _finalize,
                          child: SizedBox(
                            height: 48.0,
                            child: ElevatedButton.icon(
                              key: const ValueKey('finalize_proforma_button'),
                              onPressed: widget.viewModel.isProcessing ? null : _finalize,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(l10n.finalizeProformaAction),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: TappableArea(
                          semanticLabel: l10n.voidProformaAction,
                          onTap: widget.viewModel.isProcessing ? null : _openVoidDialog,
                          child: SizedBox(
                            height: 48.0,
                            child: OutlinedButton.icon(
                              key: const ValueKey('void_proforma_button'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade400),
                              ),
                              onPressed: widget.viewModel.isProcessing ? null : _openVoidDialog,
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(l10n.voidProformaAction),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (isFinalized) ...[
                  TappableArea(
                    semanticLabel: l10n.voidProformaAction,
                    onTap: widget.viewModel.isProcessing ? null : _openVoidDialog,
                    child: SizedBox(
                      height: 48.0,
                      child: OutlinedButton.icon(
                        key: const ValueKey('void_proforma_button'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade400),
                        ),
                        onPressed: widget.viewModel.isProcessing ? null : _openVoidDialog,
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(l10n.voidProformaAction),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'DRAFT':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = l10n.proformaStatusDraft;
        break;
      case 'DELIVERED':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        text = l10n.proformaStatusDelivered;
        break;
      case 'FINALIZED':
        bg = Colors.teal.shade100;
        fg = Colors.teal.shade900;
        text = l10n.proformaStatusFinalized;
        break;
      case 'VOIDED':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        text = l10n.proformaStatusVoided;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13.0),
      ),
    );
  }
}

/// Fila reutilizable para la presentación de conceptos en el resumen tributario de la proforma.
class _SummaryRow extends StatelessWidget {
  /// Etiqueta descriptiva del rubro o impuesto.
  final String label;

  /// Valor monetario formateado correspondiente al rubro.
  final String value;

  /// Indica si el texto debe renderizarse con peso de fuente en negrita.
  final bool isBold;

  /// Tamaño de la fuente tipográfica en píxeles lógicos.
  final double fontSize;

  /// Color personalizado opcional para destacar el rubro (e.g., descuentos o recargos).
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize = 14.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
