// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/catalog/views/my_requests_view.dart
// Propósito: Vista de consulta y gestión de solicitudes de compra de productos del cliente, con cálculo impositivo y cancelación reactiva.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/product_request.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';
import 'package:mipetshop/ui/features/catalog/view_models/my_requests_view_model.dart';
import 'package:mipetshop/ui/features/catalog/views/cancel_request_dialog.dart';

/// Interfaz gráfica para la consulta del estado y cancelación de pedidos de productos del cliente.
///
/// Permite al usuario revisar el ciclo de vida de sus órdenes (`PENDING`, `APPROVED`, `READY_FOR_PICKUP`,
/// `FULFILLED`, `REJECTED`, `CANCELLED`), visualizar el desglose de productos solicitados con sus precios
/// congelados e impuestos calculados, y cancelar solicitudes activas antes de su despacho en tienda.
class MyRequestsView extends StatefulWidget {
  /// Modelo de vista que suministra la lista reactiva de solicitudes de compra del cliente.
  final MyRequestsViewModel viewModel;

  /// Constructor de la vista de pedidos del cliente.
  const MyRequestsView({
    super.key,
    required this.viewModel,
  });

  @override
  State<MyRequestsView> createState() => _MyRequestsViewState();
}

/// Estado mutable de [MyRequestsView].
///
/// Gestiona la inicialización de los flujos de pedidos y las acciones de cancelación modal.
class _MyRequestsViewState extends State<MyRequestsView> {
  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel y consulta de solicitudes activas e históricas
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.myRequestsTitle ?? ''),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.errorMessage != null &&
              widget.viewModel.requests.isEmpty) {
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

          if (widget.viewModel.requests.isEmpty) {
            return Center(
              child: Text(
                l10n?.emptyRequestsMessage ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              final listView = ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: widget.viewModel.requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final request = widget.viewModel.requests[index];
                  final pricing =
                      widget.viewModel.calculatePricingForRequest(request);
                  final canCancel = widget.viewModel.canCancel(request);

                  return _RequestCard(
                    request: request,
                    pricing: pricing,
                    canCancel: canCancel,
                    isCancelling: widget.viewModel.isCancelling,
                    onCancel: () => _handleCancel(context, request),
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

  /// Abre el diálogo de confirmación y despacha la cancelación asíncrona de la solicitud.
  void _handleCancel(BuildContext context, ProductRequest request) {
    CancelRequestDialog.show(
      context,
      lines: _RequestCard.getEffectiveLines(request),
      onConfirm: () async {
        final success = await widget.viewModel.cancelRequest(request.id);
        if (success && context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.cancelRequestSuccess ?? ''),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}

/// Tarjeta visual representativa de una solicitud de compra de productos.
class _RequestCard extends StatelessWidget {
  /// Entidad de la solicitud de compra.
  final ProductRequest request;

  /// Resultado financiero proyectado para la solicitud.
  final LinePricingResult pricing;

  /// Indica si la solicitud aún se encuentra en un estado cancelable por el cliente.
  final bool canCancel;

  /// Bandera de estado que indica si una acción de cancelación se encuentra en curso.
  final bool isCancelling;

  /// Acción a ejecutar para iniciar el flujo modal de cancelación.
  final VoidCallback onCancel;

  /// Constructor de la tarjeta de solicitud de producto.
  const _RequestCard({
    required this.request,
    required this.pricing,
    required this.canCancel,
    required this.isCancelling,
    required this.onCancel,
  });

  /// Las líneas de producto de la solicitud: sólo `items`. La forma plana se retiró (WP-6.11-B) y ya no se
  /// deriva ninguna línea de la raíz.
  static List<ProductRequestLine> getEffectiveLines(ProductRequest request) => request.items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusBadge = _buildStatusBadge(context, request.status);
    final cancelBtnText = l10n?.cancelRequestAction ?? '';
    final lines = getEffectiveLines(request);

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                    l10n?.requestItemsHeader ?? '',
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
              '${l10n?.appointmentDateLabel ?? ''}: ${request.actionDateString}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        line.productName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
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
            const Divider(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.requestTotalLabel ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      l10n?.priceBaseFormatted(
                            formatCents(pricing.basePriceCents),
                          ) ??
                          '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      l10n?.priceWithTaxesFormatted(
                            formatCents(pricing.finalPriceCents),
                          ) ??
                          '',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                if (canCancel)
                  TappableArea(
                    semanticLabel: cancelBtnText,
                    onTap: isCancelling ? null : onCancel,
                    child: OutlinedButton(
                      key: ValueKey('cancel_request_button_${request.id}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onPressed: isCancelling ? null : onCancel,
                      child: Text(cancelBtnText),
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
    return switch (status) {
      'PENDING_DISPATCH' =>
        StatusBadge.warning(text: l10n?.requestStatusPendingDispatch ?? ''),
      'READY_FOR_PICKUP' =>
        StatusBadge.info(text: l10n?.requestStatusReadyForPickup ?? ''),
      'FINALIZED' =>
        StatusBadge.success(text: l10n?.requestStatusFinalized ?? ''),
      'CANCELLED' =>
        StatusBadge.danger(text: l10n?.requestStatusCancelled ?? ''),
      _ => StatusBadge.neutral(text: status),
    };
  }
}
