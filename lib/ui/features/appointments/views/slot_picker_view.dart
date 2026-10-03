// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/appointments/views/slot_picker_view.dart
// Propósito: Selector dinámico de franjas horarias operativas disponibles con exclusión de colisiones y bloqueo de horarios pasados.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/appointments/view_models/booking_view_model.dart';

/// Componente de selección de franjas horarias disponibles para la fecha seleccionada.
///
/// Obtiene y proyecta los intervalos de atención libres mediante `viewModel.getSlotsForDate()`,
/// filtrando automáticamente horas que hayan expirado respecto al reloj operativo
/// o aquellas reservadas por otros clientes mediante centinelas de bloqueo en Firestore.
class SlotPickerView extends StatelessWidget {
  /// Modelo de vista que gestiona el estado temporal y la selección horaria.
  final BookingViewModel viewModel;

  /// Constructor del selector de franjas horarias.
  const SlotPickerView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final selectedDate = viewModel.selectedDate;
    if (selectedDate == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n?.selectDateLabel ?? '',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final availableSlots = viewModel.getSlotsForDate(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            l10n?.availableSlotsTitle ?? '',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (availableSlots.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      l10n?.noSlotsAvailableNotice ?? '',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: availableSlots.map((slot) {
                final isSelected = viewModel.selectedTimeSlot == slot;

                return TappableArea(
                  onTap: () => viewModel.selectTimeSlot(slot),
                  child: ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (_) => viewModel.selectTimeSlot(slot),
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
