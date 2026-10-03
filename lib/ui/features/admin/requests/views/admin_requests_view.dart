// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/requests/views/admin_requests_view.dart
// Propósito: Interfaz administrativa para el seguimiento, filtrado por estado y despacho de solicitudes de productos del catálogo.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/domain/models/product_request.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/requests/view_models/admin_requests_view_model.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';

/// {@template admin_requests_view}
/// Vista de la cola de despacho de solicitudes de productos para personal administrativo.
///
/// Permite inspeccionar las solicitudes generadas por los clientes, filtrarlas según su estado
/// (pendientes de despacho, listas para retiro, canceladas o finalizadas), y avanzar
/// su flujo operacional a estado listo para retiro ([advanceToReady]).
/// {@endtemplate}
class AdminRequestsView extends StatelessWidget {
  /// ViewModel con el estado y operaciones de la cola administrativa de solicitudes.
  final AdminRequestsViewModel viewModel;

  /// Constructor inmutable de la vista administrativa de solicitudes.
  const AdminRequestsView({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: Text(l10n.adminRequestsTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final horizontalPadding = isWide ? 32.0 : 16.0;

          return Column(
            children: [
              // Barra de filtros por estado
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16.0,
                  horizontalPadding,
                  8.0,
                ),
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            key: const ValueKey('filter_all_requests'),
                            label: Text(l10n.filterAll),
                            selected: viewModel.selectedStatus == null,
                            onSelected: (_) => viewModel.filterStatus(null),
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            key: const ValueKey('filter_pending_dispatch'),
                            label: Text(l10n.requestStatusPendingDispatch),
                            selected: viewModel.selectedStatus == 'PENDING_DISPATCH',
                            onSelected: (_) => viewModel.filterStatus('PENDING_DISPATCH'),
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            key: const ValueKey('filter_ready_for_pickup'),
                            label: Text(l10n.requestStatusReadyForPickup),
                            selected: viewModel.selectedStatus == 'READY_FOR_PICKUP',
                            onSelected: (_) => viewModel.filterStatus('READY_FOR_PICKUP'),
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            key: const ValueKey('filter_cancelled'),
                            label: Text(l10n.requestStatusCancelled),
                            selected: viewModel.selectedStatus == 'CANCELLED',
                            onSelected: (_) => viewModel.filterStatus('CANCELLED'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Lista de solicitudes
              Expanded(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (viewModel.failure != null) {
                      return Center(
                        child: Text(
                          viewModel.failure!.toLocalizedMessage(l10n),
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      );
                    }

                    if (viewModel.requests.isEmpty) {
                      return Center(
                        child: Text(l10n.noRequestsFoundAdmin),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16.0,
                      ),
                      itemCount: viewModel.requests.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final request = viewModel.requests[index];
                        return _RequestAdminCard(
                          request: request,
                          viewModel: viewModel,
                          isAdvancing: viewModel.isAdvancing,
                          onAdvance: () async {
                            final success = await viewModel.advanceToReady(request.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.requestAdvancedSuccess),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tarjeta administrativa que sintetiza los datos de una solicitud de catálogo.
class _RequestAdminCard extends StatelessWidget {
  /// Entidad de la solicitud de producto a desplegar.
  final ProductRequest request;

  /// ViewModel administrativo para operaciones de cálculo y despacho.
  final AdminRequestsViewModel viewModel;

  /// Indica si la solicitud se encuentra actualmente procesando la transición de estado.
  final bool isAdvancing;

  /// Callback invocado para avanzar la solicitud a estado listo para retiro.
  final VoidCallback onAdvance;

  const _RequestAdminCard({
    required this.request,
    required this.viewModel,
    required this.isAdvancing,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final statusBadge = switch (request.status) {
      'PENDING_DISPATCH' => StatusBadge.warning(text: l10n.requestStatusPendingDispatch),
      'READY_FOR_PICKUP' => StatusBadge.info(text: l10n.requestStatusReadyForPickup),
      'CANCELLED' => StatusBadge.danger(text: l10n.requestStatusCancelled),
      'FINALIZED' => StatusBadge.success(text: l10n.requestStatusFinalized),
      _ => StatusBadge.neutral(text: request.status),
    };

    final canAdvance = request.status == 'PENDING_DISPATCH';
    final lines = viewModel.linesOf(request);
    final totalCents = viewModel.totalBeforeTaxesCents(request);

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: TappableArea(
        key: ValueKey('request_card_${request.id}'),
        semanticLabel: l10n.adminRequestDetailTitle,
        borderRadius: BorderRadius.circular(10.0),
        onTap: () => _openDetail(context, lines, totalCents),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.requestClientLabel(request.clientName),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    statusBadge,
                  ],
                ),
            const SizedBox(height: 8.0),
            // Una fila por línea (IN-04, CA-AD-61): la tarjeta mostraba sólo los
            // campos planos, es decir, la primera línea.
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  l10n.adminRequestLine(line.productName, line.quantity),
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              l10n.adminRequestDate(request.actionDateString),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
            ),
            const SizedBox(height: 4.0),
            Text(
              l10n.adminRequestTotalBeforeTaxes(formatCents(totalCents)),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (canAdvance) ...[
              const Divider(height: 24.0),
              Align(
                alignment: Alignment.centerRight,
                child: TappableArea(
                  semanticLabel: l10n.advanceToReadyAction,
                  onTap: isAdvancing ? null : onAdvance,
                  child: ElevatedButton.icon(
                    key: ValueKey('advance_request_button_${request.id}'),
                    onPressed: isAdvancing ? null : onAdvance,
                    icon: isAdvancing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(l10n.advanceToReadyAction),
                  ),
                ),
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// El detalle, en una hoja inferior. Por línea: cantidad, precio acordado y
  /// subtotal (CA-AD-14). Ninguna acción por línea (CA-AD-62).
  void _openDetail(
    BuildContext context,
    List<ProductRequestLine> lines,
    int totalCents,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _RequestDetailSheet(
        key: ValueKey('request_detail_${request.id}'),
        request: request,
        lines: lines,
        totalCents: totalCents,
      ),
    );
  }
}

/// Hoja modal inferior para el desglose pormenorizado de las líneas de una solicitud.
class _RequestDetailSheet extends StatelessWidget {
  /// Solicitud de producto cuyos ítems se detallan.
  final ProductRequest request;

  /// Lista de líneas de producto acordadas en la solicitud.
  final List<ProductRequestLine> lines;

  /// Monto acumulado antes de tributos en centavos de dólar.
  final int totalCents;

  const _RequestDetailSheet({
    super.key,
    required this.request,
    required this.lines,
    required this.totalCents,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminRequestDetailTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                l10n.adminRequestDate(request.actionDateString),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
              ),
              const Divider(height: 24.0),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        l10n.adminRequestDetailLine(
                          line.quantity,
                          formatCents(line.agreedUnitPriceCents),
                          formatCents(line.quantity * line.agreedUnitPriceCents),
                        ),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 8.0),
              const SizedBox(height: 8.0),
              Text(
                l10n.adminRequestTotalBeforeTaxes(formatCents(totalCents)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                l10n.adminRequestTaxNote,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
