// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/views/admin_proformas_list_view.dart
// Propósito: Vista de administración, listado y ciclo de vida de proformas comerciales para el personal del petshop.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/domain/models/proforma.dart';
import 'package:mipetshop/domain/use_cases/preview_proforma_pricing.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/admin_proformas_view_model.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/billing_config_view_model.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/billing_parameters_view.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/pending_concepts_view.dart';
import 'package:mipetshop/ui/features/admin/proformas/view_models/pending_concepts_view_model.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/ui/features/admin/proformas/views/proforma_composition_view.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';

/// Vista de supervisión general y ciclo de vida de proformas para personal de administración.
///
/// Capacidades del módulo:
/// - Listado y filtrado de comprobantes por estados: Borrador (`DRAFT`), Entregada (`DELIVERED`),
///   Cobrada/Finalizada (`FINALIZED`) y Anulada (`VOIDED`).
/// - Creación de borradores con selección de cliente y conceptos pendientes no facturados.
/// - Transición interactiva a la pantalla de composición y cotización [ProformaCompositionView].
/// - Acceso a la configuración de parámetros impositivos [BillingParametersView].
class AdminProformasListView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de proformas administrativas.
  final AdminProformasViewModel viewModel;

  /// Modelo de vista para la configuración tributaria y fiscal del negocio.
  final BillingConfigViewModel billingConfigViewModel;

  /// Identificador único del colaborador administrativo.
  final String currentUid;

  /// Caso de uso de computación previa del desglose impositivo y comercial.
  final PreviewProformaPricingUseCase previewUseCase;

  /// Configuración pública vigente de alícuotas impositivas (IVA e ICE).
  final PublicPricingConfig pricingConfig;

  /// Repositorio de persistencia de proformas y conceptos pendientes.
  final ProformasRepository proformasRepository;

  /// Stream reactivo de clientes elegibles filtrados por término de búsqueda.
  final Stream<List<ProformaClientOption>> Function(String query) clientsStream;

  /// Constructor de la vista de administración de proformas.
  const AdminProformasListView({
    super.key,
    required this.viewModel,
    required this.billingConfigViewModel,
    required this.currentUid,
    required this.previewUseCase,
    required this.pricingConfig,
    required this.proformasRepository,
    required this.clientsStream,
  });


  /// Flujo completo de composición: elegir cliente, marcar sus conceptos y
  /// crear el borrador con ellos dentro.
  Future<void> _openNewProforma(BuildContext context) async {
    final cliente = await showDialog<ProformaClientOption>(
      context: context,
      builder: (_) => ProformaClientPickerDialog(clientsStream: clientsStream),
    );
    if (cliente == null || !context.mounted) return;

    final conceptsVm = PendingConceptsViewModel(
      repository: proformasRepository,
      clientId: cliente.uid,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => PendingConceptsView(
          viewModel: conceptsVm,
          clientName: cliente.fullName,
          confirmLabel: (l10n, count) => l10n.proformaCreateWithSelection(count),
          onConfirm: (items) async {
            final id = await viewModel.createDraft(
              clientId: cliente.uid,
              items: items,
            );
            return id != null && id.isNotEmpty;
          },
        ),
      ),
    );

    conceptsVm.dispose();
  }

  void _openComposition(BuildContext context, Proforma proforma) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProformaCompositionView(
          proforma: proforma,
          viewModel: viewModel,
          previewUseCase: previewUseCase,
          pricingConfig: pricingConfig,
          proformasRepository: proformasRepository,
        ),
      ),
    );
  }

  void _openBillingParams(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BillingParametersView(
          viewModel: billingConfigViewModel,
          currentUid: currentUid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: Text(l10n.adminProformasTitle),
        actions: [
          TappableArea(
            semanticLabel: l10n.proformaNewAction,
            onTap: () => _openNewProforma(context),
            child: TextButton.icon(
              key: const ValueKey('new_proforma_button'),
              onPressed: () => _openNewProforma(context),
              icon: const Icon(Icons.note_add_outlined),
              label: Text(l10n.proformaNewAction),
            ),
          ),
          TappableArea(
            semanticLabel: l10n.adminBillingParametersTitle,
            tooltip: l10n.adminBillingParametersTitle,
            onTap: () => _openBillingParams(context),
            child: IconButton(
              key: const ValueKey('go_to_billing_parameters_button'),
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.adminBillingParametersTitle,
              onPressed: () => _openBillingParams(context),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          final horizontalPadding = isWide ? 32.0 : 16.0;

          return Column(
            children: [
              // Filtros por estado
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
                            key: const ValueKey('filter_all_proformas'),
                            label: Text(l10n.filterAll),
                            selected: viewModel.selectedStatus == null,
                            onSelected: (_) => viewModel.filterStatus(null),
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            key: const ValueKey('filter_draft_proformas'),
                            label: Text(l10n.proformaStatusDraft),
                            selected: viewModel.selectedStatus == 'DRAFT',
                            onSelected: (_) => viewModel.filterStatus('DRAFT'),
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            key: const ValueKey('filter_delivered_proformas'),
                            label: Text(l10n.proformaStatusDelivered),
                            selected: viewModel.selectedStatus == 'DELIVERED',
                            onSelected: (_) => viewModel.filterStatus('DELIVERED'),
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            key: const ValueKey('filter_finalized_proformas'),
                            label: Text(l10n.proformaStatusFinalized),
                            selected: viewModel.selectedStatus == 'FINALIZED',
                            onSelected: (_) => viewModel.filterStatus('FINALIZED'),
                          ),
                          const SizedBox(width: 8.0),
                          ChoiceChip(
                            key: const ValueKey('filter_voided_proformas'),
                            label: Text(l10n.proformaStatusVoided),
                            selected: viewModel.selectedStatus == 'VOIDED',
                            onSelected: (_) => viewModel.filterStatus('VOIDED'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Lista de proformas
              Expanded(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (viewModel.errorMessage != null) {
                      return Center(
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      );
                    }

                    if (viewModel.proformas.isEmpty) {
                      return Center(
                        child: Text(l10n.noProformasFoundAdmin),
                      );
                    }

                    return ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16.0,
                      ),
                      itemCount: viewModel.proformas.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        final proforma = viewModel.proformas[index];
                        return _AdminProformaCard(
                          proforma: proforma,
                          onTap: () => _openComposition(context, proforma),
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

/// Tarjeta interactiva de presentación resumida de una proforma comercial para administradores.
class _AdminProformaCard extends StatelessWidget {
  /// Entidad de la proforma cuyos datos de cabecera y montos son mostrados.
  final Proforma proforma;

  /// Retrollamada ejecutada al presionar la tarjeta para abrir su edición o composición.
  final VoidCallback onTap;

  /// Constructor de la tarjeta administrativa de proforma.
  const _AdminProformaCard({
    required this.proforma,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final statusBadge = switch (proforma.status) {
      'DRAFT' => StatusBadge.warning(text: l10n.proformaStatusDraft),
      'DELIVERED' => StatusBadge.info(text: l10n.proformaStatusDelivered),
      'FINALIZED' => StatusBadge.success(text: l10n.proformaStatusFinalized),
      'VOIDED' => StatusBadge.danger(text: l10n.proformaStatusVoided),
      _ => StatusBadge.neutral(text: proforma.status),
    };

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        key: ValueKey('proforma_card_${proforma.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.adminProformaCardId(proforma.id),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  statusBadge,
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                l10n.adminProformaClient(proforma.clientName),
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4.0),
              Text(
                l10n.adminProformaCardSummary(
                  proforma.items.length,
                  l10n.proformaTotalLabel,
                  formatCents(proforma.totalCents),
                ),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
