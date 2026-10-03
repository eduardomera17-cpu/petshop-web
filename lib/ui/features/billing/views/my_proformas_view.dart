// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/billing/views/my_proformas_view.dart
// Propósito: Vista de consulta histórica de proformas emitidas al cliente, estados de liquidación, motivos de anulación y descarga de comprobantes PDF.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/proforma.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/billing/view_models/my_proformas_view_model.dart';

/// Interfaz gráfica para la consulta y descarga de proformas emitidas al cliente.
///
/// Permite al usuario revisar sus documentos cotizados y prefacturados,
/// conociendo su estado administrativo (`DRAFT`, `DELIVERED`, `FINALIZED` o `VOIDED`),
/// la justificación de anulación si aplicare y la posibilidad de descargar el documento
/// PDF oficial almacenado en Cloud Storage directamente en la memoria del dispositivo.
class MyProformasView extends StatefulWidget {
  /// Modelo de vista que suministra la colección reactiva de proformas del cliente.
  final MyProformasViewModel viewModel;

  /// Callback opcional de navegación hacia la vista del carrito unificado.
  final VoidCallback? onOpenCart;

  /// Callback opcional de navegación hacia el resumen de pagos pendientes.
  final VoidCallback? onOpenPaymentSummary;

  /// Constructor de la vista de proformas del cliente.
  const MyProformasView({
    super.key,
    required this.viewModel,
    this.onOpenCart,
    this.onOpenPaymentSummary,
  });

  @override
  State<MyProformasView> createState() => _MyProformasViewState();
}

/// Estado mutable de [MyProformasView].
///
/// Gestiona la inicialización de proformas y las descargas de comprobantes PDF.
class _MyProformasViewState extends State<MyProformasView> {
  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel y consulta de proformas emitidas al cliente
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.myProformasTitle ?? ''),
        actions: [
          if (widget.onOpenPaymentSummary != null)
            TappableArea(
              semanticLabel: l10n?.paymentSummaryOpenAction ?? '',
              onTap: widget.onOpenPaymentSummary,
              child: TextButton.icon(
                key: const ValueKey('open_payment_summary_button'),
                onPressed: widget.onOpenPaymentSummary,
                icon: const Icon(Icons.request_quote_outlined),
                label: Text(l10n?.paymentSummaryOpenAction ?? ''),
              ),
            ),
          if (widget.onOpenCart != null)
            TappableArea(
              semanticLabel: l10n?.cartOpenAction ?? '',
              onTap: widget.onOpenCart,
              child: TextButton.icon(
                key: const ValueKey('open_cart_button'),
                onPressed: widget.onOpenCart,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text(l10n?.cartOpenAction ?? ''),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.errorMessage != null &&
              widget.viewModel.proformas.isEmpty) {
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

          if (widget.viewModel.proformas.isEmpty) {
            return Center(
              child: Text(
                l10n?.emptyProformasMessage ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              final listView = ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: widget.viewModel.proformas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final proforma = widget.viewModel.proformas[index];
                  final isDownloading = widget.viewModel.isDownloading &&
                      widget.viewModel.downloadedProformaId == proforma.id;

                  return _ProformaCard(
                    proforma: proforma,
                    isDownloading: isDownloading,
                    onDownloadPdf: () => _handleDownload(context, proforma),
                  );
                },
              );

              if (isWide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: listView,
                  ),
                );
              }
              return listView;
            },
          );
        },
      ),
    );
  }

  /// Desencadena la descarga asíncrona del comprobante PDF de la proforma y notifica el resultado mediante SnackBar.
  void _handleDownload(BuildContext context, Proforma proforma) async {
    final success = await widget.viewModel.downloadPdf(proforma);
    if (success && context.mounted) {
      final l10n = AppLocalizations.of(context);
      final size = widget.viewModel.downloadedPdfBytes?.lengthInBytes ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.pdfDownloadSuccessWithSize(
                  l10n.pdfDownloadSuccess,
                  (size / 1024).toStringAsFixed(1),
                ) ??
                '',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// Tarjeta visual representativa de una proforma individual emitida.
class _ProformaCard extends StatelessWidget {
  /// Entidad de la proforma representada.
  final Proforma proforma;

  /// Indica si el archivo PDF de esta proforma se encuentra actualmente en proceso de descarga.
  final bool isDownloading;

  /// Callback para solicitar la descarga del documento PDF.
  final VoidCallback onDownloadPdf;

  /// Constructor de la tarjeta de proforma.
  const _ProformaCard({
    required this.proforma,
    required this.isDownloading,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusBadge = _buildStatusBadge(context, proforma.status);
    final hasPdf =
        proforma.pdfStoragePath != null && proforma.pdfStoragePath!.isNotEmpty;
    final downloadBtnText = l10n?.downloadPdfAction ?? '';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n?.proformaNumberLabel(proforma.id) ?? proforma.id,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                statusBadge,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n?.proformaDateLabel ?? ''}: ${proforma.issuedAt.toIso8601String().split('T').first}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${l10n?.proformaItemsTitle ?? ''}: ${proforma.items.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (proforma.status == 'VOIDED' &&
                proforma.voidReason != null &&
                proforma.voidReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  l10n?.proformaVoidReasonLabel(proforma.voidReason!) ?? '',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const Divider(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n?.proformaTotalLabel ?? ''}: ${l10n?.moneyAmount(formatCents(proforma.totalCents)) ?? ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (hasPdf)
                  TappableArea(
                    semanticLabel: downloadBtnText,
                    onTap: isDownloading ? null : onDownloadPdf,
                    child: OutlinedButton.icon(
                      key: ValueKey('download_pdf_button_${proforma.id}'),
                      onPressed: isDownloading ? null : onDownloadPdf,
                      icon: isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: Text(downloadBtnText),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context);
    String label;
    Color color;

    switch (status) {
      case 'DRAFT':
        label = l10n?.proformaStatusDraft ?? '';
        color = Colors.grey;
        break;
      case 'DELIVERED':
        label = l10n?.proformaStatusDelivered ?? '';
        color = Colors.blue;
        break;
      case 'FINALIZED':
        label = l10n?.proformaStatusFinalized ?? '';
        color = Colors.green;
        break;
      case 'VOIDED':
        label = l10n?.proformaStatusVoided ?? '';
        color = Colors.red;
        break;
      default:
        label = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
