// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/clinical/views/clinical_consultation_form_view.dart
// Propósito: Formulario médico veterinario de consulta clínica con evaluación de signos vitales, 10 sistemas anatómicos y trazabilidad inmutable.
// =========================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mipetshop/core/feature_flags.dart';
import 'package:mipetshop/core/services/web_file_picker.dart';
import 'package:mipetshop/core/validators/clinical.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/models/clinical_record.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/admin/clinical/view_models/clinical_consultation_view_model.dart';
import 'package:mipetshop/l10n/app_localizations.dart';

/// Formulario clínico veterinario para el registro exhaustivo de una consulta médica.
///
/// Implementa los estándares formales de historia clínica veterinaria:
/// - Bloque de anamnesis: motivo de consulta, enfermedad actual y antecedentes patológicos.
/// - Registro de constantes fisiológicas: temperatura corporal (°C), frecuencia cardíaca (lpm),
///   frecuencia respiratoria (rpm), peso exacto en gramos/kg y puntuación de condición corporal (BCS 1-9).
/// - Examen físico sistemático sobre 10 sistemas anatómicos (`NOT_EXAMINED`, `NORMAL`, `ABNORMAL` con hallazgos).
/// - Diagnóstico presuntivo/definitivo e indicaciones terapéuticas para el tutor de la mascota.
/// - Registro de recetas médicas con dosificación estructurada y carga de adjuntos de laboratorio (PDF/imágenes).
class ClinicalConsultationFormView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de los estados clínicos y la persistencia del expediente.
  final ClinicalConsultationViewModel viewModel;

  /// Retrollamada opcional ejecutada al completar y persistir exitosamente la consulta.
  final VoidCallback? onSaved;

  /// Retrollamada opcional ejecutada al cancelar el diligenciamiento del formulario.
  final VoidCallback? onCancel;

  /// Constructor del formulario de consulta clínica veterinaria.
  const ClinicalConsultationFormView({
    super.key,
    required this.viewModel,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<ClinicalConsultationFormView> createState() =>
      _ClinicalConsultationFormViewState();
}


class _ClinicalConsultationFormViewState
    extends State<ClinicalConsultationFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _reasonController;
  late TextEditingController _currentIllnessController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _diagnosisController;
  late TextEditingController _ownerInstructionsController;
  late TextEditingController _temperatureController;
  late TextEditingController _heartRateController;
  late TextEditingController _respiratoryRateController;
  late TextEditingController _weightController;
  late TextEditingController _bcsController;

  final Map<String, TextEditingController> _findingsControllers = {};

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;
    _reasonController = TextEditingController(text: vm.reason);
    _currentIllnessController = TextEditingController(text: vm.currentIllness ?? '');
    _medicalHistoryController = TextEditingController(text: vm.medicalHistory ?? '');
    _diagnosisController = TextEditingController(text: vm.diagnosis ?? '');
    _ownerInstructionsController =
        TextEditingController(text: vm.ownerInstructions ?? '');

    _temperatureController = TextEditingController(
      text: vm.temperatureDeciC != null
          ? (vm.temperatureDeciC! / 10.0).toStringAsFixed(1)
          : '',
    );
    _heartRateController = TextEditingController(
      text: vm.heartRateBpm?.toString() ?? '',
    );
    _respiratoryRateController = TextEditingController(
      text: vm.respiratoryRateRpm?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: vm.weightGrams != null
          ? (vm.weightGrams! / 1000.0).toStringAsFixed(2)
          : '',
    );
    _bcsController = TextEditingController(
      text: vm.bodyConditionScore?.toString() ?? '',
    );

    for (final sys in ClinicalValidators.validSystems) {
      _findingsControllers[sys] =
          TextEditingController(text: vm.systemFindings[sys] ?? '');
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _currentIllnessController.dispose();
    _medicalHistoryController.dispose();
    _diagnosisController.dispose();
    _ownerInstructionsController.dispose();
    _temperatureController.dispose();
    _heartRateController.dispose();
    _respiratoryRateController.dispose();
    _weightController.dispose();
    _bcsController.dispose();

    for (final c in _findingsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showAnnulDialog() {
    final l10n = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.clinicalConsultationAnnulmentTitle ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.clinicalAnnulmentWarning ?? '',
              style: const TextStyle(fontSize: 13.0, color: Colors.black87),
            ),
            const SizedBox(height: 12.0),
            TextField(
              key: const Key('annul_reason_input'),
              controller: reasonCtrl,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n?.clinicalAnnulReasonLabel ?? '',
                border: const OutlineInputBorder(),
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
            key: const Key('confirm_annul_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = reasonCtrl.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop();
              final success = await widget.viewModel.annul(text);
              if (success && mounted) {
                widget.onSaved?.call();
              }
            },
            child: Text(l10n?.clinicalConfirmAnnulmentAction ?? ''),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final vm = widget.viewModel;
    vm.reason = _reasonController.text.trim();
    vm.currentIllness = _currentIllnessController.text.trim().isNotEmpty
        ? _currentIllnessController.text.trim()
        : null;
    vm.medicalHistory = _medicalHistoryController.text.trim().isNotEmpty
        ? _medicalHistoryController.text.trim()
        : null;

    final tempVal = double.tryParse(_temperatureController.text.trim());
    vm.temperatureDeciC = tempVal != null ? (tempVal * 10).round() : null;

    vm.heartRateBpm = int.tryParse(_heartRateController.text.trim());
    vm.respiratoryRateRpm = int.tryParse(_respiratoryRateController.text.trim());

    final weightKg = double.tryParse(_weightController.text.trim());
    vm.weightGrams = weightKg != null ? (weightKg * 1000).round() : null;

    vm.bodyConditionScore = int.tryParse(_bcsController.text.trim());

    vm.diagnosis = _diagnosisController.text.trim().isNotEmpty
        ? _diagnosisController.text.trim()
        : null;
    vm.ownerInstructions = _ownerInstructionsController.text.trim().isNotEmpty
        ? _ownerInstructionsController.text.trim()
        : null;

    for (final sys in ClinicalValidators.validSystems) {
      final findings = _findingsControllers[sys]?.text.trim() ?? '';
      vm.setSystemFindings(sys, findings);
    }

    final success = await vm.submitConsultation();
    if (success && mounted) {
      widget.onSaved?.call();
    }
  }

  void _addMockAttachment() {
    final l10n = AppLocalizations.of(context);
    final count = widget.viewModel.attachments.length + 1;
    widget.viewModel.uploadAttachment(
      fileName: 'estudio_radiologico_$count.pdf',
      mimeType: 'application/pdf',
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]), // Dummy PDF
      description: l10n?.clinicalAttachmentDefaultDesc(count) ?? '',
    );
  }

  void _addTreatmentLineDialog() {
    final medCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    String route = 'ORAL';
    final durCtrl = TextEditingController();
    String modality = 'PRESCRIBED';

    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n?.clinicalPrescribeTreatmentTitle ?? ''),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('treatment_med_input'),
                  controller: medCtrl,
                  decoration: InputDecoration(labelText: l10n?.clinicalMedicationLabel ?? ''),
                ),
                TextField(
                  key: const Key('treatment_dose_input'),
                  controller: doseCtrl,
                  decoration: InputDecoration(labelText: l10n?.clinicalDoseLabel ?? ''),
                ),
                DropdownButtonFormField<String>(
                  initialValue: route,
                  decoration: InputDecoration(labelText: l10n?.clinicalRouteLabel ?? ''),
                  items: ClinicalValidators.validRoutes.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => route = v ?? 'ORAL'),
                ),
                TextField(
                  key: const Key('treatment_duration_input'),
                  controller: durCtrl,
                  decoration: InputDecoration(labelText: l10n?.clinicalDurationLabel ?? ''),
                ),
                DropdownButtonFormField<String>(
                  initialValue: modality,
                  decoration: InputDecoration(labelText: l10n?.clinicalModalityLabel ?? ''),
                  items: ClinicalValidators.validModalities.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => modality = v ?? 'PRESCRIBED'),
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
              key: const Key('confirm_add_treatment_btn'),
              onPressed: () {
                if (medCtrl.text.trim().isEmpty ||
                    doseCtrl.text.trim().isEmpty ||
                    durCtrl.text.trim().isEmpty) {
                  return;
                }
                widget.viewModel.addTreatmentLine(
                  TreatmentLineItem(
                    medication: medCtrl.text.trim(),
                    dose: doseCtrl.text.trim(),
                    route: route,
                    duration: durCtrl.text.trim(),
                    startDate: '2026-09-02',
                    modality: modality,
                  ),
                );
                Navigator.of(ctx).pop();
              },
              child: Text(l10n?.clinicalAddPrescriptionLineAction ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = widget.viewModel;

    return ResponsiveLayout(
      builder: (context, breakpoint) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              vm.isEditMode ? l10n?.clinicalCorrectConsultationTitle ?? '' : 'Nueva Consulta Clínica',
              key: const Key('clinical_form_title'),
            ),
            actions: [
              if (vm.canAnnulRecord) ...[
                TappableArea(
                  key: const Key('annul_consultation_btn'),
                  tooltip: l10n?.clinicalAnnulRecordTooltip ?? '',
                  semanticLabel: l10n?.clinicalAnnulRecordSemantic ?? '',
                  minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  onTap: _showAnnulDialog,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.block, color: Colors.red),
                  ),
                ),
              ],
              if (widget.onCancel != null)
                TappableArea(
                  key: const Key('cancel_consultation_btn'),
                  tooltip: l10n?.clinicalDeferTooltip ?? '',
                  semanticLabel: l10n?.clinicalDeferSemantic ?? '',
                  minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  onTap: widget.onCancel!,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Center(
                      child: Text(l10n?.clinicalDeferAction ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
          body: AnimatedBuilder(
            animation: vm,
            builder: (context, _) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Center(
                    child: ConstrainedBox(
                      // En 768 px y pantallas medianas, constrained a 800 para evitar overflow
                      constraints: const BoxConstraints(maxWidth: 860.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (vm.errorMessage != null) ...[
                            Container(
                              key: const Key('consultation_error_banner'),
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.red.shade700),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade900),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      vm.failure?.toLocalizedMessage(l10n ?? AppLocalizations.of(context)!) ??
                                          vm.errorMessage!,
                                      style: TextStyle(color: Colors.red.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (vm.successMessage != null) ...[
                            Container(
                              key: const Key('consultation_success_banner'),
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.green.shade700),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.green.shade900),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      vm.successMessage!,
                                      style: TextStyle(color: Colors.green.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // BLOQUE 1: Datos del Paciente (Estrictamente Congelado y de Solo Lectura, CL-03)
                          _buildFrozenPatientCard(vm.patientSnapshot),

                          const SizedBox(height: 20.0),

                          // BLOQUE 2: Anamnesis / Motivo
                          _buildSectionHeader(l10n?.clinicalSectionReasonTitle ?? ''),
                          const SizedBox(height: 8.0),
                          TextFormField(
                            key: const Key('consultation_reason_input'),
                            controller: _reasonController,
                            maxLength: 500,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: l10n?.clinicalReasonLabel ?? '',
                              border: const OutlineInputBorder(),
                              helperText: l10n?.clinicalReasonHelper ?? '',
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          TextFormField(
                            key: const Key('consultation_illness_input'),
                            controller: _currentIllnessController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: l10n?.clinicalCurrentIllnessLabel ?? '',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          TextFormField(
                            key: const Key('consultation_history_input'),
                            controller: _medicalHistoryController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: l10n?.clinicalBackgroundLabel ?? '',
                              border: const OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 24.0),

                          // BLOQUE 3: Signos Vitales
                          _buildSectionHeader(l10n?.clinicalSectionVitalsTitle ?? ''),
                          const SizedBox(height: 8.0),
                          _buildVitalsInputs(breakpoint, l10n),

                          const SizedBox(height: 24.0),

                          // BLOQUE 4: Examen por Sistemas (Los 10 Sistemas Anatómicos)
                          _buildSectionHeader(l10n?.clinicalSectionExamTitle ?? ''),
                          const SizedBox(height: 4.0),
                          Text(
                            l10n?.clinicalSectionExamHelp ?? '',
                            style: const TextStyle(fontSize: 13.0, color: Colors.black54),
                          ),
                          const SizedBox(height: 12.0),
                          _buildSystemsList(vm, l10n),

                          const SizedBox(height: 24.0),

                          // BLOQUE 5: Plan y Diagnóstico
                          _buildSectionHeader(l10n?.clinicalSectionPlanTitle ?? ''),
                          const SizedBox(height: 8.0),
                          TextFormField(
                            key: const Key('consultation_diagnosis_input'),
                            controller: _diagnosisController,
                            decoration: InputDecoration(
                              labelText: l10n?.clinicalDiagnosisLabel ?? '',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          DropdownButtonFormField<String>(
                            initialValue: vm.diagnosisType,
                            decoration: InputDecoration(
                              labelText: l10n?.clinicalDiagnosisTypeLabel ?? '',
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'PRESUMPTIVE',
                                child: Text(l10n?.clinicalDiagnosisPresumptive ?? ''),
                              ),
                              DropdownMenuItem(
                                value: 'DEFINITIVE',
                                child: Text(l10n?.clinicalDiagnosisDefinitive ?? ''),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) vm.diagnosisType = v;
                            },
                          ),

                          const SizedBox(height: 16.0),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              Text(
                                l10n?.clinicalTreatmentLinesLabel ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                key: const Key('add_treatment_line_btn'),
                                onPressed: _addTreatmentLineDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(l10n?.clinicalPrescribeMedicationAction ?? ''),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          if (vm.treatmentLines.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                l10n?.clinicalNoPrescriptions ?? '',
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: vm.treatmentLines.length,
                              itemBuilder: (ctx, idx) {
                                final line = vm.treatmentLines[idx];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: ListTile(
                                    title: Text(l10n?.clinicalPrescriptionLine(line.medication, line.dose) ?? ''),
                                    subtitle: Text(
                                      l10n?.clinicalTreatmentLineDetails(line.route, line.duration, line.modality) ?? '',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => vm.removeTreatmentLine(idx),
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _ownerInstructionsController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: l10n?.clinicalOwnerInstructionsLabel ?? '',
                              border: const OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 24.0),

                          // BLOQUE 6: Adjuntos Clínicos (máximo 20)
                          _buildSectionHeader(
                            l10n?.clinicalSectionAttachmentsTitle(vm.attachments.length, ClinicalValidators.maxAttachments) ?? '',
                          ),
                          const SizedBox(height: 8.0),
                          Wrap(
                            spacing: 12.0,
                            runSpacing: 8.0,
                            children: [
                              if (kClinicalAttachmentsEnabled)
                                ElevatedButton.icon(
                                  key: const Key('add_attachment_btn'),
                                  onPressed: vm.attachments.length < ClinicalValidators.maxAttachments
                                      ? _addMockAttachment
                                      : null,
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(l10n?.clinicalUploadAttachmentAction ?? ''),
                                ),
                              if (kClinicalPetPhotoEnabled)
                                ElevatedButton.icon(
                                  key: const Key('upload_pet_photo_btn'),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final pickResult = await pickPlatformFile();
                                    if (!mounted) return;
                                    if (pickResult.isSuccess && pickResult.file != null) {
                                      final f = pickResult.file!;
                                      await vm.uploadPetPhoto(
                                        fileName: f.name,
                                        mimeType: f.mimeType,
                                        bytes: f.bytes,
                                      );
                                    } else if (pickResult.status == FilePickStatus.sizeExceeded) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(l10n?.imageSizeExceeded ?? '')),
                                      );
                                    } else if (pickResult.status == FilePickStatus.unsupportedFormat) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(l10n?.imageFormatUnsupported ?? '')),
                                      );
                                    } else if (pickResult.status == FilePickStatus.rejectedHeic) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(l10n?.imageFormatHeicRejected ?? '')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text(l10n?.clinicalUpdatePetPhotoAction ?? ''),
                                ),
                            ],
                          ),
                          if (!kClinicalAttachmentsEnabled || !kClinicalPetPhotoEnabled)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                l10n?.clinicalUploadsContainedNotice ?? '',
                                key: const Key('clinical_uploads_contained_notice'),
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          const SizedBox(height: 8.0),
                          if (vm.attachments.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: vm.attachments.length,
                              itemBuilder: (ctx, idx) {
                                final att = vm.attachments[idx];
                                return ListTile(
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(att.description),
                                  subtitle: Text(l10n?.clinicalAttachmentLine(att.storagePath, '${att.sizeBytes}') ?? ''),
                                );
                              },
                            ),

                          const SizedBox(height: 32.0),

                          // ACCIONES FINALES
                          if (!vm.canEditRecord) ...[
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                l10n?.clinicalNotEditableNotice ?? '',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              height: 52.0,
                              child: ElevatedButton(
                                key: const Key('save_consultation_btn'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                onPressed: vm.isLoading ? null : _handleSave,
                                child: vm.isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        vm.isEditMode
                                            ? l10n?.clinicalSaveCorrectionAction ?? ''
                                            : l10n?.clinicalSaveConsultationAction ?? '',
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFrozenPatientCard(PatientSnapshot snapshot) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.blueGrey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.blueGrey.shade800, size: 20.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    l10n?.clinicalSectionPatientTitle ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20.0),
            Text(
              l10n?.clinicalPatientDataPet(snapshot.pet.name, snapshot.pet.species, snapshot.pet.breed, snapshot.pet.sex, snapshot.pet.ageAtAttention) ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            Text(
              l10n?.clinicalPatientDataReproductive(snapshot.pet.reproductiveStatus, snapshot.pet.birthDate) ?? '',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              l10n?.clinicalPatientDataOwner(snapshot.owner.fullName, snapshot.owner.documentType, snapshot.owner.documentNumber) ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            Text(
              l10n?.clinicalPatientDataContact(snapshot.owner.phone, snapshot.owner.email, snapshot.owner.address) ?? '',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildVitalsInputs(AppBreakpoint breakpoint, AppLocalizations? l10n) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: [
        SizedBox(
          width: 150.0,
          child: TextFormField(
            key: const Key('vital_temp_input'),
            controller: _temperatureController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n?.clinicalTemperatureLabel ?? '',
              hintText: l10n?.clinicalTemperatureHint ?? '',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          width: 150.0,
          child: TextFormField(
            key: const Key('vital_hr_input'),
            controller: _heartRateController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n?.clinicalHeartRateLabel ?? '',
              hintText: l10n?.clinicalHeartRateHint ?? '',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          width: 150.0,
          child: TextFormField(
            key: const Key('vital_rr_input'),
            controller: _respiratoryRateController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n?.clinicalRespRateLabel ?? '',
              hintText: l10n?.clinicalRespRateHint ?? '',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          width: 150.0,
          child: TextFormField(
            key: const Key('vital_weight_input'),
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n?.clinicalWeightLabel ?? '',
              hintText: l10n?.clinicalWeightHint ?? '',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          width: 150.0,
          child: TextFormField(
            key: const Key('vital_bcs_input'),
            controller: _bcsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n?.clinicalBodyConditionLabel ?? '',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemsList(ClinicalConsultationViewModel vm, AppLocalizations? l10n) {
    final systemLabels = {
      'mucous': l10n?.clinicalSystemMucous ?? '',
      'skin': l10n?.clinicalSystemSkin ?? '',
      'eyes': 'Ojos',
      'ears': l10n?.clinicalSystemEars ?? '',
      'cardiovascular': l10n?.clinicalSystemCardiovascular ?? '',
      'respiratory': l10n?.clinicalSystemRespiratory ?? '',
      'gastrointestinal': l10n?.clinicalSystemGastrointestinal ?? '',
      'nervous': l10n?.clinicalSystemNervous ?? '',
      'musculoskeletal': l10n?.clinicalSystemMusculoskeletal ?? '',
      'genitourinary': l10n?.clinicalSystemGenitourinary ?? '',
    };

    return Column(
      children: ClinicalValidators.validSystems.map((sys) {
        final state = vm.systemStates[sys] ?? 'NOT_EXAMINED';
        final isAbnormal = state == 'ABNORMAL';
        final label = systemLabels[sys] ?? sys;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                    DropdownButton<String>(
                      key: Key('system_state_$sys'),
                      value: state,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'NOT_EXAMINED',
                          child: Text(l10n?.clinicalSystemNotExamined ?? ''),
                        ),
                        DropdownMenuItem(
                          value: 'NORMAL',
                          child: Text(l10n?.clinicalSystemNormal ?? ''),
                        ),
                        DropdownMenuItem(
                          value: 'ABNORMAL',
                          child: Text(l10n?.clinicalSystemAbnormal ?? ''),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          vm.setSystemState(sys, v);
                        }
                      },
                    ),
                  ],
                ),
                if (isAbnormal) ...[
                  const SizedBox(height: 8.0),
                  TextFormField(
                    key: Key('system_findings_$sys'),
                    controller: _findingsControllers[sys],
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: l10n?.clinicalFindingsLabel(label) ?? '',
                      border: const OutlineInputBorder(),
                      helperText: l10n?.clinicalFindingsHelper ?? '',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
