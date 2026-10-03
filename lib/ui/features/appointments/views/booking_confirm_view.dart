// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/appointments/views/booking_confirm_view.dart
// Propósito: Pantalla final de confirmación y revisión de reserva de cita con desglose impositivo y control de conectividad en tiempo real.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/core/widgets/connectivity_banner.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/appointments/view_models/booking_view_model.dart';

/// Pantalla final de consolidación, revisión y confirmación del flujo de reserva de citas.
///
/// Presenta el resumen exhaustivo de los parámetros seleccionados por el usuario cliente:
/// - Servicio veterinario o estético escogido.
/// - Mascota receptora y especie.
/// - Fecha calendario y franja horaria designada.
/// - Desglose impositivo referencial con cálculo de base imponible, ICE e IVA proyectados.
/// - Campo de observaciones o requerimientos especiales (máximo 250 caracteres).
///
/// Salvaguardas operativas y de integridad:
/// - Bloqueo estricto del botón de confirmación en ausencia de conectividad (modo offline).
/// - Prohibición absoluta de opciones de reprogramación en esta instancia según directriz de arquitectura.
class BookingConfirmView extends StatefulWidget {
  /// Modelo de vista que gestiona el estado integral del flujo de reserva y la creación final de la cita.
  final BookingViewModel viewModel;

  /// Constructor de la vista de confirmación de reserva.
  const BookingConfirmView({super.key, required this.viewModel});

  @override
  State<BookingConfirmView> createState() => _BookingConfirmViewState();
}

/// Estado mutable de [BookingConfirmView].
///
/// Administra el controlador de texto para las notas del cliente y sincroniza
/// los cambios con el [BookingViewModel].
class _BookingConfirmViewState extends State<BookingConfirmView> {
  /// Controlador de edición para el campo de observaciones y notas del cliente.
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Inicialización del controlador con el texto actual de observaciones registrado en el ViewModel
    _notesController = TextEditingController(text: widget.viewModel.clientNotes);
  }

  @override
  void dispose() {
    // Liberación del controlador de texto
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = widget.viewModel;

    // Evaluación de conectividad a la red para prevenir intentos de reserva en frío o desconexión
    final isOnline = ConnectivityScope.maybeOf(context)?.isOnline ?? true;
    final pricing = vm.pricingPreview;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          l10n?.confirmBookingTitle ?? '',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),

        // Banner informativo de desconexión de red (modo offline)
        if (!isOnline) ...[
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.red),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    l10n?.offlineWarning ?? '',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
        ],

        // Banner de presentación de errores devueltos por el backend
        if (vm.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
        ],
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                  Icons.medical_services_outlined,
                  l10n?.serviceSummaryLabel ?? '',
                  vm.selectedService?.name ?? '-',
                ),
                const Divider(height: 20.0),
                _buildSummaryRow(
                  Icons.pets,
                  l10n?.petSummaryLabel ?? '',
                  '${vm.selectedPet?.name ?? '-'} (${vm.selectedPet?.species ?? ''})',
                ),
                const Divider(height: 20.0),
                _buildSummaryRow(
                  Icons.calendar_month,
                  l10n?.dateTimeSummaryLabel ?? '',
                  '${vm.selectedDate ?? '-'}  ·  ${vm.selectedTimeSlot ?? '-'}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        if (pricing != null) ...[
          Card(
            color: Colors.blueGrey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.bookingBasePriceSummary(formatCents(pricing.basePriceCents)) ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    l10n?.bookingEstimatedTaxesSummary(
                          formatCents(pricing.iceAmountCents + pricing.ivaAmountCents),
                        ) ??
                        '',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    l10n?.bookingTotalEstimatedSummary(formatCents(pricing.finalPriceCents)) ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    l10n?.bookingPriceEstimatedNotice ?? '',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
        ],
        // Campo de texto para notas u observaciones del cliente (máx. 250 caracteres)
        TextFormField(
          key: const Key('booking_notes_field'),
          controller: _notesController,
          decoration: InputDecoration(
            labelText: l10n?.clientNotesLabel ?? '',
            border: const OutlineInputBorder(),
            counterText: l10n?.notesCharCount(_notesController.text.length),
          ),
          maxLength: 250,
          maxLines: 3,
          onChanged: (val) {
            vm.setClientNotes(val);
            setState(() {});
          },
        ),
        const SizedBox(height: 16.0),
        Text(
          l10n?.confirmBookingNotice ?? '',
          style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),

        // Botón principal de confirmación con protección táctil accesible y bloqueo en modo offline
        TappableArea(
          onTap: (!isOnline || vm.isSubmitting)
              ? () {}
              : () => vm.confirmBooking(isOnline: isOnline, l10n: l10n),
          child: SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              onPressed: (!isOnline || vm.isSubmitting)
                  ? null
                  : () => vm.confirmBooking(isOnline: isOnline, l10n: l10n),
              child: vm.isSubmitting
                  ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(l10n?.confirmBookingAction ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye una fila visual estandarizada para mostrar pares atributo-valor con ícono temático.
  Widget _buildSummaryRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 22.0),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12.0, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
