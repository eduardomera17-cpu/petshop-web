// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/billing/views/payment_summary_view.dart
// Propósito: Vista de resumen consolidado de conceptos pendientes de pago con desglose tributario línea por línea y aviso normativo mandatorio.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/billing/view_models/payment_summary_view_model.dart';

/// Interfaz gráfica del resumen consolidado de pagos pendientes de liquidación.
///
/// Presenta al usuario cliente un estado de cuenta transparente previo al cobro en caja:
/// - Desglose detallado ítem por ítem indicando cantidades, bases imponibles y tarifas de ICE e IVA.
/// - Panel consolidado de totales con subtotal bruto, descuentos aplicados, recargos operativos,
///   liquidación total de ICE, liquidación de IVA según la tasa vigente y el gran total estimado.
/// - Aviso normativo informativo que instruye que el pago definitivo y la emisión de factura/proforma
///   se formaliza en los puntos físicos de venta o mediante los canales habilitados del petshop.
class PaymentSummaryView extends StatefulWidget {
  /// Modelo de vista que computa el resumen reactivo de conceptos por cobrar.
  final PaymentSummaryViewModel viewModel;

  /// Constructor del resumen de pago.
  const PaymentSummaryView({
    super.key,
    required this.viewModel,
  });

  @override
  State<PaymentSummaryView> createState() => _PaymentSummaryViewState();
}

/// Estado mutable de [PaymentSummaryView].
///
/// Gestiona la carga y actualización reactiva de los conceptos pendientes de liquidación.
class _PaymentSummaryViewState extends State<PaymentSummaryView> {
  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel y consulta de conceptos por liquidar
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.paymentSummaryTitle ?? ''),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.errorMessage != null &&
              widget.viewModel.summaryResult == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(widget.viewModel.errorMessage!),
                  const SizedBox(height: 16),
                  TappableArea(
                    semanticLabel: l10n?.retry ?? '',
                    onTap: () => widget.viewModel.init(),
                    child: ElevatedButton(
                      onPressed: () => widget.viewModel.init(),
                      child: Text(l10n?.retry ?? ''),
                    ),
                  ),
                ],
              ),
            );
          }

          final summary = widget.viewModel.summaryResult;

          if (widget.viewModel.items.isEmpty || summary == null) {
            return Center(
              child: Text(
                key: const ValueKey('payment_summary_empty'),
                l10n?.paymentSummaryEmpty ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              final content = SingleChildScrollView(
                key: const ValueKey('payment_summary_scroll'),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aviso Mandatorio Informativo (FA-04, CA-57)
                    Container(
                      key: const ValueKey('payment_summary_mandatory_notice'),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n?.paymentSummaryNotice ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lista de ítems (CA-48)
                    Text(
                      l10n?.proformaItemsTitle ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      key: const ValueKey('payment_summary_items_list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.viewModel.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = widget.viewModel.items[index];
                        final hasIce = item.iceBp > 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  l10n?.moneyAmount(formatCents(item.totalCents)) ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n?.paymentSummaryItemQuantity(item.quantity) ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  l10n?.paymentSummaryItemBase(formatCents(item.basePriceCents)) ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (hasIce)
                              Text(
                                l10n?.paymentSummaryItemIce(
                                      (item.iceBp / 100).toStringAsFixed(0),
                                      formatCents(item.iceAmountCents),
                                    ) ??
                                    '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              l10n?.paymentSummaryItemIva(
                                    (item.ivaBp / 100).toStringAsFixed(0),
                                    formatCents(item.ivaAmountCents),
                                  ) ??
                                  '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 24, thickness: 1.5),

                    // Desglose de totales
                    _SummaryRow(
                      key: const ValueKey('payment_summary_subtotal_row'),
                      label: l10n?.proformaSubtotalLabel ?? '',
                      value: l10n?.moneyAmount(formatCents(summary.subtotalCents)) ?? '',
                    ),
                    if (summary.totalDiscountCents > 0) ...[
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: l10n?.proformaDiscountLabel ?? '',
                        value: l10n?.moneyAmountNegative(formatCents(summary.totalDiscountCents)) ?? '',
                        color: Colors.green.shade800,
                      ),
                    ],
                    if (summary.totalSurchargeCents > 0) ...[
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: l10n?.proformaSurchargeLabel ?? '',
                        value: l10n?.moneyAmountPositive(formatCents(summary.totalSurchargeCents)) ?? '',
                        color: Colors.orange.shade800,
                      ),
                    ],
                    if (summary.totalIceCents > 0) ...[
                      const SizedBox(height: 6),
                      _SummaryRow(
                        key: const ValueKey('payment_summary_ice_row'),
                        label: l10n?.proformaIceLabel ?? '',
                        value: l10n?.moneyAmount(formatCents(summary.totalIceCents)) ?? '',
                      ),
                    ],
                    const SizedBox(height: 6),
                    _SummaryRow(
                      key: const ValueKey('payment_summary_iva_row'),
                      label: widget.viewModel.pricingConfig != null
                          ? (l10n?.paymentSummaryIvaRateLabel(
                                (widget.viewModel.pricingConfig!.ivaBp / 100).toStringAsFixed(0),
                              ) ??
                              (l10n?.proformaIvaLabel ?? ''))
                          : (l10n?.proformaIvaLabel ?? ''),
                      value: l10n?.moneyAmount(formatCents(summary.totalIvaCents)) ?? '',
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      key: const ValueKey('payment_summary_total_row'),
                      label: l10n?.paymentSummaryEstimatedTotalLabel ?? l10n?.proformaTotalLabel ?? '',
                      value: l10n?.moneyAmount(formatCents(summary.totalCents)) ?? '',
                      isBold: true,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: content,
                  ),
                );
              }
              return content;
            },
          );
        },
      ),
    );
  }
}

/// Componente de fila estilizada para visualizar conceptos de desglose y totales.
class _SummaryRow extends StatelessWidget {
  /// Etiqueta descriptiva del concepto.
  final String label;

  /// Valor formateado con símbolo monetario.
  final String value;

  /// Indica si el texto debe representarse en negrita.
  final bool isBold;

  /// Tamaño de fuente personalizado opcional.
  final double? fontSize;

  /// Color cromático del texto opcional.
  final Color? color;

  /// Constructor de la fila de resumen.
  const _SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: fontSize,
      color: color,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: style),
        ),
        const SizedBox(width: 8),
        Text(value, style: style),
      ],
    );
  }
}
