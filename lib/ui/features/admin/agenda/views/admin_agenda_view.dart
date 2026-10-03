// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/agenda/views/admin_agenda_view.dart
// Propósito: Interfaz administrativa avanzada para gestión de agenda, citas, franjas horarias y bloqueos preventivos de disponibilidad.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/models/clinical_record.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/clinical_repository.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/data/repositories/profile_repository.dart';
import 'package:mipetshop/domain/models/appointment.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/domain/models/user_profile.dart';
import 'package:mipetshop/ui/features/admin/agenda/view_models/admin_agenda_view_model.dart';
import 'package:mipetshop/ui/features/admin/clinical/view_models/clinical_consultation_view_model.dart';
import 'package:mipetshop/ui/features/admin/clinical/views/clinical_consultation_form_view.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';

/// Vista interactiva principal del personal administrativo y veterinario para la gestión integral de agenda.
///
/// Capacidades operativas implementadas:
/// - Selector de fecha de consulta con visualización de citas agrupadas por franjas horarias o estados.
/// - Gestión de estados de cita: Confirmación de citas pendientes, reagendamiento con validación de choques,
///   cancelación administrativa con motivo formal y finalización de servicio.
/// - Detección y transición automática a formulario clínico ([ClinicalConsultationFormView]) al completar citas médicas.
/// - Administración de bloqueos de disponibilidad: bloqueo de día completo o intervalos horarios específicos por emergencias o mantenimiento.
/// - Atajos de teclado y accesibilidad completa con navegación asistida.
class AdminAgendaView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de las citas del día y los bloqueos temporales.
  final AdminAgendaViewModel viewModel;

  /// Constructor de la vista administrativa de agenda.
  const AdminAgendaView({super.key, required this.viewModel});

  @override
  State<AdminAgendaView> createState() => _AdminAgendaViewState();
}


class _AdminAgendaViewState extends State<AdminAgendaView> {
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _showCreateBlockDialog() {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.viewModel.selectedDate),
    );
    final timeController = TextEditingController();
    final reasonController = TextEditingController();

    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.adminBlockAvailabilityTitle ?? ''),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('block_date_field'),
                controller: dateController,
                decoration: InputDecoration(
                  labelText: l10n?.agendaBlockDateLabel ?? '',
                  hintText: l10n?.agendaBlockDateHint ?? '',
                ),
              ),
              const SizedBox(height: 12.0),
              TextField(
                key: const Key('block_time_field'),
                controller: timeController,
                decoration: InputDecoration(
                  labelText: l10n?.agendaBlockSlotLabel ?? '',
                  hintText: l10n?.agendaBlockSlotHint ?? '',
                ),
              ),
              const SizedBox(height: 12.0),
              TextField(
                key: const Key('block_reason_field'),
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: l10n?.agendaBlockReasonLabel ?? '',
                  hintText: l10n?.agendaBlockReasonHint ?? '',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? ''),
          ),
          ElevatedButton(
            key: const Key('confirm_block_submit_button'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final dateStr = dateController.text.trim();
              final timeStr = timeController.text.trim().isEmpty ? null : timeController.text.trim();
              final reasonStr = reasonController.text.trim().isEmpty ? null : reasonController.text.trim();

              await widget.viewModel.createAvailabilityBlock(
                dateString: dateStr,
                timeSlot: timeStr,
                reason: reasonStr,
              );
            },
            child: Text(l10n?.adminBlockAction ?? ''),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(String appointmentId) {
    final l10n = AppLocalizations.of(context);
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(widget.viewModel.selectedDate.add(const Duration(days: 1))),
    );
    final timeController = TextEditingController(text: '10:00');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.adminRescheduleAppointmentTitle ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('reschedule_date_field'),
              controller: dateController,
              decoration: InputDecoration(
                labelText: l10n?.agendaRescheduleDateLabel ?? '',
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              key: const Key('reschedule_time_field'),
              controller: timeController,
              decoration: InputDecoration(
                labelText: l10n?.agendaRescheduleSlotLabel ?? '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? ''),
          ),
          ElevatedButton(
            key: const Key('confirm_reschedule_button'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.viewModel.rescheduleAppointment(
                appointmentId: appointmentId,
                toDateString: dateController.text.trim(),
                toTimeSlot: timeController.text.trim(),
              );
            },
            child: Text(l10n?.adminRescheduleAction ?? ''),
          ),
        ],
      ),
    );
  }

  Future<void> _openClinicalFormForAppointment(Appointment appt) async {
    final clinicalRepo = Provider.of<ClinicalRepository?>(context, listen: false);
    if (clinicalRepo == null) return;
    final authRepo = Provider.of<AuthRepository?>(context, listen: false);
    final petsRepo = Provider.of<PetsRepository?>(context, listen: false);
    final profileRepo = Provider.of<ProfileRepository?>(context, listen: false);

    final staffUid = authRepo?.currentUser?.uid;
    if (staffUid == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.sessionInvalid ?? '')),
      );
      return;
    }

    Pet? pet;
    if (petsRepo != null) {
      final petRes = await petsRepo.getPetById(appt.petId);
      if (petRes is Ok<Pet>) {
        pet = petRes.value;
      }
    }

    UserProfile? owner;
    if (profileRepo != null) {
      final ownerRes = await profileRepo.getUserProfile(appt.clientId);
      if (ownerRes is Ok<UserProfile>) {
        owner = ownerRes.value;
      }
    }

    if (!mounted) return;

    final petBirthDate = pet?.birthDate;
    String ageAtAttention = '__NOT_REGISTERED__';
    if (petBirthDate != null && petBirthDate.trim().isNotEmpty) {
      final today = BusinessClock.todayBusinessDate();
      final partsB = petBirthDate.trim().split('-');
      final partsT = today.split('-');
      if (partsB.length == 3 && partsT.length == 3) {
        final bY = int.tryParse(partsB[0]) ?? 0;
        final bM = int.tryParse(partsB[1]) ?? 0;
        final bD = int.tryParse(partsB[2]) ?? 0;
        final tY = int.tryParse(partsT[0]) ?? 0;
        final tM = int.tryParse(partsT[1]) ?? 0;
        final tD = int.tryParse(partsT[2]) ?? 0;
        var years = tY - bY;
        var months = tM - bM;
        if (tD < bD) months--;
        if (months < 0) {
          years--;
          months += 12;
        }
        if (years >= 0) {
          if (years == 0) {
            ageAtAttention = '$months ${months == 1 ? 'mes' : 'meses'}';
          } else {
            ageAtAttention = '$years ${years == 1 ? 'año' : 'años'}';
          }
        }
      }
    }

    final patientSnapshot = PatientSnapshot(
      pet: PatientPetSnapshot(
        name: pet?.name ?? appt.petName,
        species: (pet != null && pet.species.isNotEmpty) ? pet.species : '__NOT_REGISTERED__',
        breed: (pet?.breed != null && pet!.breed!.isNotEmpty) ? pet.breed! : '__NOT_REGISTERED__',
        sex: (pet != null && pet.sex.isNotEmpty) ? pet.sex : '__NOT_REGISTERED__',
        reproductiveStatus: (pet != null && pet.reproductiveStatus.isNotEmpty) ? pet.reproductiveStatus : '__NOT_REGISTERED__',
        birthDate: (petBirthDate != null && petBirthDate.isNotEmpty) ? petBirthDate : '__NOT_REGISTERED__',
        ageAtAttention: ageAtAttention,
      ),
      owner: PatientOwnerSnapshot(
        fullName: (owner != null && owner.fullName.isNotEmpty) ? owner.fullName : appt.clientName,
        documentType: (owner != null && owner.documentType.isNotEmpty) ? owner.documentType : '__NOT_REGISTERED__',
        documentNumber: (owner != null && owner.documentNumber.isNotEmpty) ? owner.documentNumber : '__NOT_REGISTERED__',
        phone: (owner != null && owner.phone.isNotEmpty) ? owner.phone : '__NOT_REGISTERED__',
        address: (owner != null && owner.address.isNotEmpty) ? owner.address : '__NOT_REGISTERED__',
        email: (owner != null && owner.email.isNotEmpty) ? owner.email : '__NOT_REGISTERED__',
      ),
    );

    final vm = ClinicalConsultationViewModel(
      clinicalRepository: clinicalRepo,
      petId: appt.petId,
      ownerId: appt.clientId,
      patientSnapshot: patientSnapshot,
      sourceAppointmentId: appt.id,
      currentStaffUid: staffUid,
      currentStaffName: authRepo?.currentUser?.displayName ?? '',
      currentStaffRole: authRepo?.role ?? 'ADMIN',
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        child: SizedBox(
          width: 800,
          height: 700,
          child: ClinicalConsultationFormView(
            viewModel: vm,
            onSaved: () => Navigator.of(dialogCtx).pop(),
            onCancel: () => Navigator.of(dialogCtx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final conflicts = widget.viewModel.pendingConflicts;

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true): () {
              widget.viewModel.confirmSelectedAppointment();
            },
            const SingleActivator(LogicalKeyboardKey.keyK, control: true, shift: true): () {
              widget.viewModel.completeSelectedAppointment();
            },
          },
          child: Focus(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                leading: const AdminBackButton(),
                title: Text(l10n?.adminAgendaTitle ?? ''),
                actions: [
                  TappableArea(
                    key: const Key('create_block_appbar_button'),
                    tooltip: l10n?.adminBlockAvailabilityTitle ?? '',
                    semanticLabel: l10n?.adminBlockAvailabilitySemantics ?? '',
                    minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                    onTap: _showCreateBlockDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.block, color: Colors.redAccent),
                          const SizedBox(width: 4.0),
                          Text(l10n?.adminBlockAction ?? ''),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (conflicts.isNotEmpty) _buildConflictsBanner(conflicts, l10n),
                                _buildToolbar(constraints.maxWidth),
                                const SizedBox(height: 16.0),
                                _buildAppointmentsList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConflictsBanner(List<BlockConflictItem> conflicts, AppLocalizations? l10n) {
    return Container(
      key: const Key('block_conflicts_banner'),
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 28.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  l10n?.adminBlockConflictsDetected(conflicts.length) ?? '',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              IconButton(
                key: const Key('dismiss_conflicts_button'),
                icon: const Icon(Icons.close),
                onPressed: () => widget.viewModel.clearConflicts(),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            l10n?.adminBlockConflictsHelp ?? '',
            style: const TextStyle(fontSize: 13.0, color: Colors.black87),
          ),
          const SizedBox(height: 12.0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: conflicts.length,
            separatorBuilder: (context, index) => const Divider(height: 12.0),
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              return Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${conflict.clientName} · ${conflict.petName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n?.adminConflictServiceDateTime(conflict.serviceName, conflict.dateString, conflict.timeSlot) ?? '',
                            style: const TextStyle(fontSize: 12.0, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    TappableArea(
                      key: Key('cancel_conflict_${conflict.appointmentId}'),
                      tooltip: l10n?.agendaCancelAppointmentTooltip ?? '',
                      semanticLabel: l10n?.agendaCancelConflictSemantic ?? '',
                      minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () => widget.viewModel.cancelAppointment(conflict.appointmentId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          l10n?.cancel ?? '',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    TappableArea(
                      key: Key('reschedule_conflict_${conflict.appointmentId}'),
                      tooltip: l10n?.agendaRescheduleAppointmentTooltip ?? '',
                      semanticLabel: l10n?.agendaRescheduleConflictSemantic ?? '',
                      minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () => _showRescheduleDialog(conflict.appointmentId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          l10n?.adminRescheduleAction ?? '',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(double availableWidth) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('agenda_controls_card'),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Selector de Vista Semanal / Mensual
            SegmentedButton<AgendaViewMode>(
              segments: [
                ButtonSegment(value: AgendaViewMode.week, label: Text(l10n?.adminViewModeWeek ?? '')),
                ButtonSegment(value: AgendaViewMode.month, label: Text(l10n?.adminViewModeMonth ?? '')),
              ],
              selected: {widget.viewModel.viewMode},
              onSelectionChanged: (set) => widget.viewModel.setViewMode(set.first),
            ),

            // Selector de Fecha
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TappableArea(
                  tooltip: l10n?.agendaPreviousDayTooltip ?? '',
                  semanticLabel: l10n?.agendaPreviousDaySemantic ?? '',
                  minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  onTap: () {
                    widget.viewModel.setSelectedDate(
                      widget.viewModel.selectedDate.subtract(const Duration(days: 1)),
                    );
                  },
                  child: const Icon(Icons.chevron_left),
                ),
                Text(
                  widget.viewModel.formattedSelectedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                TappableArea(
                  tooltip: l10n?.agendaNextDayTooltip ?? '',
                  semanticLabel: l10n?.agendaNextDaySemantic ?? '',
                  minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  onTap: () {
                    widget.viewModel.setSelectedDate(
                      widget.viewModel.selectedDate.add(const Duration(days: 1)),
                    );
                  },
                  child: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            // Filtro de Estado
            DropdownButton<String>(
              value: widget.viewModel.filterStatus ?? 'ALL',
              hint: Text(l10n?.adminStatusFilterLabel ?? ''),
              items: [
                DropdownMenuItem(value: 'ALL', child: Text(l10n?.adminStatusFilterAll ?? '')),
                DropdownMenuItem(value: 'PENDING', child: Text(l10n?.adminStatusFilterPending ?? '')),
                DropdownMenuItem(value: 'CONFIRMED', child: Text(l10n?.adminStatusFilterConfirmed ?? '')),
                DropdownMenuItem(value: 'COMPLETED', child: Text(l10n?.adminStatusFilterCompleted ?? '')),
                DropdownMenuItem(value: 'CANCELLED', child: Text(l10n?.adminStatusFilterCancelled ?? '')),
              ],
              onChanged: (val) => widget.viewModel.setFilterStatus(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final l10n = AppLocalizations.of(context);
    final appointments = widget.viewModel.filteredAppointments;

    if (widget.viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            l10n?.adminAgendaEmpty ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 16.0),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final isSelected = widget.viewModel.selectedAppointment?.id == appt.id;

        return _buildAppointmentCard(appt, isSelected);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appt, bool isSelected) {
    final l10n = AppLocalizations.of(context);
    final statusBadge = switch (appt.status) {
      'PENDING' => StatusBadge.warning(text: l10n?.appointmentStatusPending ?? appt.status),
      'CONFIRMED' => StatusBadge.success(text: l10n?.appointmentStatusConfirmed ?? appt.status),
      'COMPLETED' => StatusBadge.info(text: l10n?.appointmentStatusCompleted ?? appt.status),
      'CANCELLED' => StatusBadge.danger(text: l10n?.appointmentStatusCancelled ?? appt.status),
      _ => StatusBadge.neutral(text: appt.status),
    };

    return Card(
      key: Key('appointment_card_${appt.id}'),
      elevation: 0.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF0284C7)
              : (appt.hasBlockConflict ? Colors.amber.shade700 : const Color(0xFFE2E8F0)),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () => widget.viewModel.selectAppointment(appt),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      appt.timeSlot,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.adminAppointmentClientPet(appt.clientName, appt.petName) ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                        Text(
                          appt.serviceName,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  statusBadge,
                ],
              ),

              // Badges e indicadores visuales
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  if (appt.hasBlockConflict)
                    Container(
                      key: Key('conflict_indicator_${appt.id}'),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 14.0, color: Colors.amber.shade900),
                          const SizedBox(width: 4.0),
                          Text(
                            l10n?.adminAppointmentBlockConflict ?? '',
                            style: TextStyle(fontSize: 11.0, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  if (appt.hasPendingClinicalRecord)
                    Container(
                      key: Key('clinical_pending_indicator_${appt.id}'),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.purple.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.medical_services, size: 14.0, color: Colors.purple.shade700),
                          const SizedBox(width: 4.0),
                          Text(
                            l10n?.adminAppointmentClinicalPending ?? '',
                            style: TextStyle(fontSize: 11.0, color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Notas agregadas por el cliente (AG-07)
              if (appt.clientNotes != null && appt.clientNotes!.trim().isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Container(
                  key: Key('client_notes_${appt.id}'),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16.0, color: Colors.blueGrey),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          l10n?.adminAppointmentClientNotes(appt.clientNotes ?? '') ?? '',
                          style: const TextStyle(fontSize: 13.0, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botones de acción operativos (confirmar, completar, cancelar, reagendar)
              const SizedBox(height: 12.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.end,
                children: [
                  if (appt.status == 'PENDING') ...[
                    TappableArea(
                      key: Key('confirm_btn_${appt.id}'),
                      tooltip: l10n?.agendaConfirmAppointmentTooltip ?? '',
                      semanticLabel: l10n?.agendaConfirmAppointmentSemantics ?? '',
                      minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () => widget.viewModel.confirmAppointment(appt.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.blue, size: 18.0),
                            const SizedBox(width: 4.0),
                            Text(
                              l10n?.adminConfirmAction ?? '',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (appt.status == 'CONFIRMED') ...[
                    TappableArea(
                      key: Key('complete_btn_${appt.id}'),
                      tooltip: l10n?.agendaCompleteAppointmentTooltip ?? '',
                      semanticLabel: l10n?.agendaCompleteAppointmentSemantics ?? '',
                      minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () async {
                        if (widget.viewModel.isActionInProgress) return;
                        final ok = await widget.viewModel.completeAppointment(appt.id);
                        if (ok && appt.isClinical && mounted) {
                          await _openClinicalFormForAppointment(appt);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done_all, color: Colors.green, size: 18.0),
                            const SizedBox(width: 4.0),
                            Text(
                              l10n?.adminCompleteAction ?? '',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TappableArea(
                      key: Key('reschedule_btn_${appt.id}'),
                      tooltip: l10n?.agendaRescheduleAppointmentTooltip ?? '',
                      semanticLabel: l10n?.agendaRescheduleAppointmentSemantics ?? '',
                      minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () => _showRescheduleDialog(appt.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_calendar, color: Colors.orange, size: 18.0),
                            const SizedBox(width: 4.0),
                            Text(
                              l10n?.adminRescheduleAction ?? '',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (appt.status == 'PENDING' || appt.status == 'CONFIRMED') ...[
                    TappableArea(
                      key: Key('cancel_btn_${appt.id}'),
                      tooltip: l10n?.agendaCancelAppointmentTooltip ?? '',
                      semanticLabel: l10n?.agendaCancelAppointmentSemantics ?? '',
                      minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                      onTap: () => widget.viewModel.cancelAppointment(appt.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cancel_outlined, color: Colors.red, size: 18.0),
                            const SizedBox(width: 4.0),
                            Text(
                              l10n?.cancel ?? '',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
