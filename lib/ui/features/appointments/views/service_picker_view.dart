// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/appointments/views/service_picker_view.dart
// Propósito: Cuadrícula responsiva para la exploración y selección de servicios veterinarios y estéticos con proyección impositiva en tiempo real.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/appointments/view_models/booking_view_model.dart';

/// Componente de selección del servicio veterinario o estético deseado para la cita.
///
/// Despliega el catálogo de servicios activos adaptándose a las dimensiones de pantalla
/// (1 columna en móviles, 2 en tabletas y 3 en entornos de escritorio).
/// Para cada ítem calcula y visualiza de forma transparente el importe base, su duración
/// estimada y el precio final proyectado con los puntos base de ICE e IVA vigentes.
class ServicePickerView extends StatelessWidget {
  /// Modelo de vista que provee los servicios disponibles y la configuración impositiva.
  final BookingViewModel viewModel;

  /// Constructor del selector de servicios.
  const ServicePickerView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Estado vacío cuando no existen servicios habilitados en el sistema
    if (viewModel.services.isEmpty) {
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
            ],
          ),
        ),
      );
    }

    // Cuadrícula adaptable responsiva según el ancho del viewport
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            mainAxisExtent: 200.0,
          ),
          itemCount: viewModel.services.length,
          itemBuilder: (context, index) {
            final service = viewModel.services[index];
            // Proyección financiera inmediata con impuestos desglosados
            final pricing = calculateLinePricing(
              basePriceCents: service.basePriceCents,
              iceBp: service.iceBp,
              ivaBp: viewModel.pricingConfig.ivaBp,
              iceIncludedInIvaBase: viewModel.pricingConfig.iceIncludedInIvaBase,
            );

            final isSelected = viewModel.selectedService?.id == service.id;

            return _ServicePickerCard(
              service: service,
              pricing: pricing,
              isSelected: isSelected,
              onSelect: () => viewModel.selectService(service),
            );
          },
        );
      },
    );
  }
}

/// Tarjeta visual individual representativa de un servicio en el catálogo.
class _ServicePickerCard extends StatelessWidget {
  /// Datos del servicio ofrecido.
  final Service service;

  /// Resultado del cálculo tributario para este servicio.
  final LinePricingResult pricing;

  /// Indica si este servicio es el actualmente seleccionado.
  final bool isSelected;

  /// Acción ejecutada al seleccionar este servicio.
  final VoidCallback onSelect;

  /// Constructor de la tarjeta de servicio.
  const _ServicePickerCard({
    required this.service,
    required this.pricing,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final typeBadgeColor = service.isClinical ? Colors.blue.shade700 : Colors.teal.shade700;
    final typeBadgeText = service.isClinical
        ? (l10n?.serviceClinicalBadge ?? '')
        : (l10n?.serviceGeneralBadge ?? '');

    return Card(
      elevation: isSelected ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onSelect,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: typeBadgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: typeBadgeColor),
                    ),
                    child: Text(
                      typeBadgeText,
                      style: TextStyle(
                        color: typeBadgeColor,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: TappableArea(
                  onTap: onSelect,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: isSelected
                        ? ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                          )
                        : null,
                    child: Text(
                      isSelected
                          ? (l10n?.selectedBadge ?? '')
                          : (l10n?.selectAction ?? ''),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
