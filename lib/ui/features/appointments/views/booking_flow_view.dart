// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/appointments/views/booking_flow_view.dart
// Propósito: Asistente guiado por etapas (wizard) para el agendamiento integral de citas veterinarias y estéticas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/appointments/view_models/booking_view_model.dart';
import 'package:mipetshop/ui/features/appointments/views/booking_confirm_view.dart';
import 'package:mipetshop/ui/features/appointments/views/calendar_view.dart';
import 'package:mipetshop/ui/features/appointments/views/service_picker_view.dart';
import 'package:mipetshop/ui/features/appointments/views/slot_picker_view.dart';

/// Orquestador y controlador de interfaz del asistente secuencial de reserva de citas.
///
/// Implementa un patrón de flujo por etapas (wizard) que guía al usuario cliente a través de:
/// 1. Catálogo de servicios veterinarios o de peluquería disponibles.
/// 2. Selección de la mascota registrada receptora del servicio.
/// 3. Selección de fecha operativa en calendario y franja horaria disponible.
/// 4. Revisión del desglose financiero, impuestos aplicables e ingreso de notas.
/// 5. Confirmación definitiva y presentación del código de ticket asignado.
///
/// Directriz arquitectural:
/// - El flujo de reserva no admite reprogramaciones por parte del cliente (ADR-002).
class BookingFlowView extends StatefulWidget {
  /// Modelo de vista que custodia el estado transaccional del flujo de agendamiento.
  final BookingViewModel viewModel;

  /// Constructor del orquestador de reserva de citas.
  const BookingFlowView({super.key, required this.viewModel});

  @override
  State<BookingFlowView> createState() => _BookingFlowViewState();
}

/// Estado mutable y constructor visual del asistente de agendamiento [BookingFlowView].
class _BookingFlowViewState extends State<BookingFlowView> {
  @override
  void initState() {
    super.initState();
    // Inicialización de catálogos y parámetros requeridos en el ViewModel
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.bookingTitle ?? ''),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;

          if (vm.isLoading) {
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

          if (vm.step == BookingStep.success) {
            return _buildSuccessView(context, vm, l10n);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  _buildStepHeader(context, vm, l10n),
                  Expanded(
                    child: _buildCurrentStepContent(context, vm, l10n),
                  ),
                  _buildBottomBar(context, vm, l10n),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Construye la barra horizontal de progreso que enumera las etapas y permite regresar a pasos previamente completados.
  Widget _buildStepHeader(
    BuildContext context,
    BookingViewModel vm,
    AppLocalizations? l10n,
  ) {
    final steps = [
      (BookingStep.serviceSelection, l10n?.stepServiceTitle ?? ''),
      (BookingStep.petSelection, l10n?.stepPetTitle ?? ''),
      (BookingStep.dateTimeSelection, l10n?.stepDateTimeTitle ?? ''),
      (BookingStep.confirmation, l10n?.stepConfirmTitle ?? ''),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: steps.map((item) {
            final stepEnum = item.$1;
            final stepTitle = item.$2;

            final isActive = vm.step == stepEnum;
            final isPassed = vm.step.index > stepEnum.index;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: InkWell(
                onTap: isPassed ? () => vm.goToStep(stepEnum) : null,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12.0,
                      backgroundColor: isActive
                          ? Theme.of(context).primaryColor
                          : (isPassed ? Colors.green.shade700 : Colors.grey.shade400),
                      child: isPassed
                          ? const Icon(Icons.check, size: 14.0, color: Colors.white)
                          : Text(
                              (stepEnum.index + 1).toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 11.0),
                            ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      stepTitle,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Theme.of(context).primaryColor : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Retorna la vista correspondiente a la etapa actual gobernada por el ViewModel.
  Widget _buildCurrentStepContent(
    BuildContext context,
    BookingViewModel vm,
    AppLocalizations? l10n,
  ) {
    return switch (vm.step) {
      BookingStep.serviceSelection => ServicePickerView(viewModel: vm),
      BookingStep.petSelection => _buildPetSelector(context, vm, l10n),
      BookingStep.dateTimeSelection => _buildDateTimeSelector(context, vm, l10n),
      BookingStep.confirmation => BookingConfirmView(viewModel: vm),
      BookingStep.success => const SizedBox.shrink(),
    };
  }

  /// Construye el selector de pacientes (mascotas registradas del cliente).
  Widget _buildPetSelector(
    BuildContext context,
    BookingViewModel vm,
    AppLocalizations? l10n,
  ) {
    if (vm.pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets, size: 64.0, color: Colors.grey.shade400),
              const SizedBox(height: 16.0),
              Text(
                l10n?.noActivePetsMessage ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: vm.pets.length,
      itemBuilder: (context, index) {
        final pet = vm.pets[index];
        final isSelected = vm.selectedPet?.id == pet.id;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: const Icon(Icons.pets, color: Colors.blueGrey),
            ),
            title: Text(
              pet.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            subtitle: Text(
              '${pet.species}${pet.breed != null ? ' · ${pet.breed}' : ''}',
            ),
            trailing: TappableArea(
              onTap: () => vm.selectPet(pet),
              child: ElevatedButton(
                onPressed: () => vm.selectPet(pet),
                style: isSelected
                    ? ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
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
            onTap: () => vm.selectPet(pet),
          ),
        );
      },
    );
  }

  /// Construye la vista integrada de selección temporal: calendario mensual y franjas horarias operativas.
  Widget _buildDateTimeSelector(
    BuildContext context,
    BookingViewModel vm,
    AppLocalizations? l10n,
  ) {
    return ListView(
      children: [
        CalendarView(viewModel: vm),
        const Divider(height: 24.0),
        SlotPickerView(viewModel: vm),
      ],
    );
  }

  /// Construye la barra de control inferior con acciones contextuales de retroceso y avance en el flujo.
  Widget _buildBottomBar(
    BuildContext context,
    BookingViewModel vm,
    AppLocalizations? l10n,
  ) {
    final canGoBack = vm.step != BookingStep.serviceSelection;
    final canGoNext = switch (vm.step) {
      BookingStep.serviceSelection => vm.selectedService != null,
      BookingStep.petSelection => vm.selectedPet != null,
      BookingStep.dateTimeSelection =>
        vm.selectedDate != null && vm.selectedTimeSlot != null,
      BookingStep.confirmation => false,
      BookingStep.success => false,
    };

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canGoBack)
            TappableArea(
              onTap: () {
                final prevIndex = vm.step.index - 1;
                if (prevIndex >= 0) {
                  vm.goToStep(BookingStep.values[prevIndex]);
                }
              },
              child: OutlinedButton(
                onPressed: () {
                  final prevIndex = vm.step.index - 1;
                  if (prevIndex >= 0) {
                    vm.goToStep(BookingStep.values[prevIndex]);
                  }
                },
                child: Text(l10n?.previousStepAction ?? ''),
              ),
            ),
          const Spacer(),
          if (canGoNext)
            TappableArea(
              onTap: () {
                if (vm.step == BookingStep.dateTimeSelection) {
                  vm.proceedToConfirm();
                } else {
                  final nextIndex = vm.step.index + 1;
                  if (nextIndex < BookingStep.values.length) {
                    vm.goToStep(BookingStep.values[nextIndex]);
                  }
                }
              },
              child: ElevatedButton(
                onPressed: () {
                  if (vm.step == BookingStep.dateTimeSelection) {
                    vm.proceedToConfirm();
                  } else {
                    final nextIndex = vm.step.index + 1;
                    if (nextIndex < BookingStep.values.length) {
                      vm.goToStep(BookingStep.values[nextIndex]);
                    }
                  }
                },
                child: Text(l10n?.nextStepAction ?? ''),
              ),
            ),
        ],
      ),
    );
  }

  /// Construye la pantalla de confirmación exitosa tras la persistencia de la cita en Firestore.
  Widget _buildSuccessView(
    BuildContext context,
    BookingViewModel vm,
    AppLocalizations? l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80.0, color: Colors.green),
            const SizedBox(height: 16.0),
            Text(
              l10n?.bookingSuccessMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            if (vm.successAppointmentId != null) ...[
              Text(
                '${l10n?.appointmentCodeLabel ?? ''}: ${vm.successAppointmentId}',
                style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24.0),
            ],
            TappableArea(
              onTap: vm.reset,
              child: ElevatedButton.icon(
                onPressed: vm.reset,
                icon: const Icon(Icons.add),
                label: Text(l10n?.bookingTitle ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
