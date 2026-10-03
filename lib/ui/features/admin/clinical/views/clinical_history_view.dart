// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/clinical/views/clinical_history_view.dart
// Propósito: Vista de expediente e historial clínico de mascota con soporte de auditoría inmutable, versiones históricas y anulación justificada.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/data/models/clinical_record.dart';
import 'package:mipetshop/data/models/clinical_record_version.dart';
import 'package:mipetshop/data/repositories/clinical_repository.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/admin/clinical/view_models/clinical_consultation_view_model.dart';
import 'package:mipetshop/ui/features/admin/clinical/views/clinical_consultation_form_view.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';

/// Vista de expediente e historial clínico cronológico de una mascota para uso veterinario y administrativo.
///
/// Características y principios de diseño médico-legal:
/// - Listado cronológico de atenciones y consultas con badges de estado (Original, Editado, Anulado).
/// - Inspección de versiones históricas inmutables mediante hoja modal deslizable ([_openVersionsSheet]).
/// - Control estricto de rectificaciones: la edición solo está autorizada al veterinario autor o al Super Usuario.
/// - Mecanismo de anulación justificada: no destruye físicamente el documento sino que preserva la trazabilidad con motivo formal.
class ClinicalHistoryView extends StatelessWidget {
  /// Repositorio de acceso y auditoría de registros clínicos.
  final ClinicalRepository clinicalRepository;

  /// Identificador único de la mascota consultada.
  final String petId;

  /// Identificador único del tutor legal de la mascota.
  final String ownerId;

  /// Nombre de la mascota para el encabezado de la ficha.
  final String petName;

  /// Identificador único del miembro del personal autenticado.
  final String currentStaffUid;

  /// Nombre del miembro del personal para el registro de auditoría.
  final String currentStaffName;

  /// Rol del colaborador para la verificación de permisos de edición y anulación (`VET`, `ADMIN`, `SUPERADMIN`).
  final String currentStaffRole;

  /// Retrollamada opcional ejecutada al retroceder.
  final VoidCallback? onBack;

  /// Constructor de la vista de historial clínico.
  const ClinicalHistoryView({
    super.key,
    required this.clinicalRepository,
    required this.petId,
    required this.ownerId,
    required this.petName,
    required this.currentStaffUid,
    required this.currentStaffName,
    required this.currentStaffRole,
    this.onBack,
  });


  void _openCorrectionForm(BuildContext context, ClinicalRecord record) {
    final vm = ClinicalConsultationViewModel(
      clinicalRepository: clinicalRepository,
      petId: petId,
      ownerId: ownerId,
      patientSnapshot: record.patientSnapshot,
      currentStaffUid: currentStaffUid,
      currentStaffName: currentStaffName,
      currentStaffRole: currentStaffRole,
      existingRecord: record,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ClinicalConsultationFormView(
          viewModel: vm,
          onSaved: () => Navigator.of(ctx).pop(),
          onCancel: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _openVersionsSheet(BuildContext context, ClinicalRecord record) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => StreamBuilder<List<ClinicalRecordVersion>>(
          stream: clinicalRepository.streamRecordVersions(petId, record.id!),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final versions = snapshot.data ?? [];
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.clinicalVersionsSheetTitle ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                if (versions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(l10n?.clinicalNoPreviousVersions ?? ''),
                    ),
                  )
                else
                  ...versions.map((ver) {
                    final dateStr = ver.snapshot['lastEditedAt'] != null
                        ? ver.snapshot['lastEditedAt'].toString()
                        : l10n?.clinicalVersionDateUnknown ?? '';
                    final reasonStr = ver.snapshot['consultation']?['reason']?.toString() ?? l10n?.clinicalVersionReasonUnknown ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(l10n?.clinicalVersionBadge('${ver.versionNumber}') ?? ''),
                        ),
                        title: Text(l10n?.clinicalVersionEntry('${ver.versionNumber}', dateStr) ?? ''),
                        subtitle: Text(
                          l10n?.clinicalVersionEditedByReason(ver.editedByName, reasonStr) ?? '',
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAnnulDialog(BuildContext context, ClinicalRecord record) {
    final l10n = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.clinicalEntryAnnulmentTitle ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.clinicalAnnulEntryWarning ?? '',
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: reasonCtrl,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n?.clinicalAnnulReasonHistoryLabel ?? '',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = reasonCtrl.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop();
              await clinicalRepository.annulClinicalRecord(
                petId: petId,
                recordId: record.id!,
                reason: text,
              );
            },
            child: Text(l10n?.clinicalEntryAnnulAction ?? ''),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ResponsiveLayout(
      builder: (context, breakpoint) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.clinicalHistoryTitle(petName) ?? ''),
            leading: onBack != null
                ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)
                : null,
          ),
          body: StreamBuilder<List<ClinicalRecord>>(
            stream: clinicalRepository.streamClinicalRecords(petId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(l10n?.clinicalHistoryLoadError('${snapshot.error}') ?? ''),
                );
              }

              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return Center(
                  child: Text(l10n?.clinicalNoRecords ?? ''),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final rec = records[index];
                  final isAnnulled = rec.status == 'ANNULLED';
                  final canEdit = !isAnnulled &&
                      (rec.authorUid == currentStaffUid ||
                          currentStaffRole == 'SUPERADMIN');

                  return Card(
                    elevation: 0.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: isAnnulled
                          ? const BorderSide(color: Colors.red, width: 1.5)
                          : const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${rec.type} · ${rec.attentionDate} ${rec.attentionTime}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                              if (isAnnulled)
                                StatusBadge.danger(
                                  text: l10n?.clinicalRecordAnnulledBadge ?? '',
                                )
                              else if (rec.isEdited)
                                StatusBadge.warning(
                                  text: l10n?.clinicalRecordCorrectedBadge(rec.version) ?? '',
                                ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            l10n?.clinicalRecordAttendedBy(rec.authorName) ?? '',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.0),
                          ),
                          if (rec.consultation?.reason != null) ...[
                            const SizedBox(height: 8.0),
                            Text(
                              l10n?.clinicalRecordReason(rec.consultation!.reason) ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                          if (rec.plan?.diagnosis != null) ...[
                            const SizedBox(height: 4.0),
                            Text(l10n?.clinicalDiagnosisSummary(rec.plan!.diagnosis ?? '') ?? ''),
                          ],
                          if (isAnnulled && rec.annulmentReason != null) ...[
                            const SizedBox(height: 8.0),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                l10n?.clinicalRecordAnnulmentReason(rec.annulmentReason ?? '') ?? '',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const Divider(height: 24.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (rec.isEdited && rec.id != null)
                                TextButton.icon(
                                  key: Key('view_versions_btn_${rec.id}'),
                                  icon: const Icon(Icons.history, size: 18),
                                  label: Text(l10n?.clinicalViewVersionsAction ?? ''),
                                  onPressed: () => _openVersionsSheet(context, rec),
                                ),
                              if (canEdit)
                                TextButton.icon(
                                  key: Key('edit_record_btn_${rec.id}'),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: Text(l10n?.clinicalCorrectAction ?? ''),
                                  onPressed: () => _openCorrectionForm(context, rec),
                                ),
                              if (!isAnnulled && rec.id != null)
                                TextButton.icon(
                                  key: Key('annul_record_btn_${rec.id}'),
                                  icon: const Icon(Icons.block, color: Colors.red, size: 18),
                                  label: Text(
                                    l10n?.clinicalAnnulAction ?? '',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () => _showAnnulDialog(context, rec),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
