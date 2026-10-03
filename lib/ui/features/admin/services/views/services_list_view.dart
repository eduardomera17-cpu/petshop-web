// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/services/views/services_list_view.dart
// Propósito: Interfaz administrativa principal para la consulta, filtrado visual, alternancia de disponibilidad y navegación al formulario de servicios veterinarios y de estética.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/services/view_models/service_form_view_model.dart';
import 'package:mipetshop/ui/features/admin/services/view_models/services_view_model.dart';
import 'package:mipetshop/ui/features/admin/services/views/service_form_view.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';

/// {@template services_list_view}
/// Vista interactiva en cuadrícula adaptativa para la gestión del catálogo de servicios.
///
/// Presenta los servicios con distintivos de tipología (clínico o general) y estado activo/inactivo,
/// desglose de precios al consumidor con impuestos y opciones de edición rápida y habilitación/deshabilitación.
/// {@endtemplate}
class ServicesListView extends StatefulWidget {
  /// ViewModel con el flujo reactivo y operaciones del catálogo de servicios.
  final ServicesViewModel viewModel;

  /// Identificador único del usuario administrativo autenticado en sesión.
  final String currentUid;

  /// Constructor inmutable para la vista de lista de servicios.
  const ServicesListView({
    super.key,
    required this.viewModel,
    required this.currentUid,
  });

  @override
  State<ServicesListView> createState() => _ServicesListViewState();
}

class _ServicesListViewState extends State<ServicesListView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.startListening();
  }

  void _openAddService() {
    final formVm = ServiceFormViewModel(
      repository: widget.viewModel.repository,
      ivaBp: widget.viewModel.pricingConfig.ivaBp,
      iceIncludedInIvaBase: widget.viewModel.pricingConfig.iceIncludedInIvaBase,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceFormView(
          viewModel: formVm,
          currentUid: widget.currentUid,
        ),
      ),
    );
  }

  void _openEditService(Service service) {
    final formVm = ServiceFormViewModel(
      repository: widget.viewModel.repository,
      initialService: service,
      ivaBp: widget.viewModel.pricingConfig.ivaBp,
      iceIncludedInIvaBase: widget.viewModel.pricingConfig.iceIncludedInIvaBase,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceFormView(
          viewModel: formVm,
          currentUid: widget.currentUid,
        ),
      ),
    );
  }

  Future<void> _toggleService(Service service) async {
    final l10n = AppLocalizations.of(context);
    final confirmMessage = service.isActive
        ? (l10n?.serviceConfirmDeactivate ?? '')
        : (l10n?.serviceConfirmActivate ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(service.name),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? ''),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              service.isActive
                  ? (l10n?.serviceDeactivateAction ?? '')
                  : (l10n?.serviceActivateAction ?? ''),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.viewModel.toggleActive(
        serviceId: service.id,
        uid: widget.currentUid,
        isActive: !service.isActive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: Text(l10n?.adminServicesTitle ?? ''),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TappableArea(
              onTap: _openAddService,
              child: IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n?.addServiceAction ?? '',
                onPressed: _openAddService,
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16.0),
                  Text(l10n?.loadingServices ?? ''),
                ],
              ),
            );
          }

          // El catálogo vacío y el catálogo que no se pudo leer no son el mismo
          // estado. Mostrarlos igual escondía fallos reales de lectura tras el
          // mensaje «no hay servicios registrados».
          if (widget.viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.0,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      l10n?.servicesLoadErrorMessage ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      widget.viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.0, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24.0),
                    TappableArea(
                      onTap: widget.viewModel.startListening,
                      child: ElevatedButton.icon(
                        onPressed: widget.viewModel.startListening,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n?.retry ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (widget.viewModel.services.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64.0, color: Colors.grey.shade400),
                    const SizedBox(height: 16.0),
                    Text(
                      l10n?.emptyServicesMessage ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24.0),
                    TappableArea(
                      onTap: _openAddService,
                      child: ElevatedButton.icon(
                        onPressed: _openAddService,
                        icon: const Icon(Icons.add),
                        label: Text(l10n?.addServiceAction ?? ''),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

              final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  mainAxisExtent: 220.0,
                ),
                itemCount: widget.viewModel.services.length,
                itemBuilder: (context, index) {
                  final service = widget.viewModel.services[index];
                  final pricing = widget.viewModel.calculatePricing(service);

                  return _ServiceCard(
                    service: service,
                    pricing: pricing,
                    onEdit: () => _openEditService(service),
                    onToggleActive: () => _toggleService(service),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: TappableArea(
        onTap: _openAddService,
        child: FloatingActionButton.extended(
          onPressed: _openAddService,
          icon: const Icon(Icons.add),
          label: Text(l10n?.addServiceAction ?? ''),
        ),
      ),
    );
  }
}

/// Tarjeta visual representativa de un servicio dentro del catálogo administrativo.
class _ServiceCard extends StatelessWidget {
  /// Entidad del servicio del catálogo.
  final Service service;

  /// Resultado del cálculo tributario aplicado a la tarifa del servicio.
  final LinePricingResult pricing;

  /// Callback invocado al presionar el botón de edición del servicio.
  final VoidCallback onEdit;

  /// Callback invocado al alternar el estado activo/inactivo del servicio.
  final VoidCallback onToggleActive;

  const _ServiceCard({
    required this.service,
    required this.pricing,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final statusText = service.isActive
        ? (l10n?.serviceStatusActive ?? '')
        : (l10n?.serviceStatusInactive ?? '');

    final statusBadge = service.isActive
        ? StatusBadge.success(text: statusText)
        : StatusBadge.neutral(text: statusText);

    final typeBadgeText = service.isClinical
        ? (l10n?.serviceClinicalBadge ?? '')
        : (l10n?.serviceGeneralBadge ?? '');

    final typeBadge = service.isClinical
        ? StatusBadge.info(text: typeBadgeText)
        : StatusBadge.neutral(text: typeBadgeText);

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: service.isActive ? null : TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                typeBadge,
                const SizedBox(width: 6.0),
                statusBadge,
              ],
            ),
            const SizedBox(height: 6.0),
            Expanded(
              child: Text(
                service.description.isNotEmpty ? service.description : '-',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6.0),
            Row(
              children: [
                Icon(Icons.schedule, size: 14.0, color: Colors.grey.shade600),
                const SizedBox(width: 4.0),
                Text(
                  l10n?.serviceDurationSummary(service.estimatedDurationMinutes) ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Text(
              l10n?.servicePriceSummary(
                    formatCents(pricing.basePriceCents),
                    formatCents(pricing.finalPriceCents),
                  ) ??
                  '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
            const Divider(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TappableArea(
                  onTap: onEdit,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20.0),
                    tooltip: l10n?.editServiceAction ?? '',
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 4.0),
                TappableArea(
                  onTap: onToggleActive,
                  child: IconButton(
                    icon: Icon(
                      service.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20.0,
                      color: service.isActive ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                    tooltip: service.isActive
                        ? (l10n?.serviceDeactivateAction ?? '')
                        : (l10n?.serviceActivateAction ?? ''),
                    onPressed: onToggleActive,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
