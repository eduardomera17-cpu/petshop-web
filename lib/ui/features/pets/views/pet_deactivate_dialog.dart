// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/pets/views/pet_deactivate_dialog.dart
// Propósito: Diálogo modal de previsualización de impacto y confirmación de baja lógica de mascota con cancelación en cascada de citas activas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/l10n/app_localizations.dart';

/// Diálogo modal de previsualización y confirmación de baja lógica de una mascota.
///
/// Consulta previamente las citas activas vinculadas mediante Cloud Functions seguro
/// para advertir al usuario y ejecutar la desactivación atómica en cascada.
/// Cumple con la normativa de privacidad al no exponer ningún dato clínico en pantalla.
class PetDeactivateDialog extends StatefulWidget {
  /// Entidad de la mascota sujeta al proceso de desactivación.
  final Pet pet;

  /// Repositorio de acceso a datos para consultar el impacto y ejecutar la baja.
  final PetsRepository repository;

  /// Constructor del diálogo de baja lógica de mascota.
  const PetDeactivateDialog({
    super.key,
    required this.pet,
    required this.repository,
  });

  @override
  State<PetDeactivateDialog> createState() => _PetDeactivateDialogState();
}


class _PetDeactivateDialogState extends State<PetDeactivateDialog> {
  bool _isLoadingPreview = true;
  bool _isDeactivating = false;
  String? _errorMessage;
  Failure? _failure;
  int _activeAppointmentsCount = 0;
  List<Map<String, dynamic>> _affectedAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    final res = await widget.repository.previewDeactivation(widget.pet.id);
    if (!mounted) return;

    if (res.isOk) {
      final data = res.dataOrNull ?? {};
      final count = (data['activeAppointmentsCount'] as num?)?.toInt() ?? 0;
      final rawList = data['activeAppointments'];
      final list = (rawList is List)
          ? rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _isLoadingPreview = false;
        _activeAppointmentsCount = count;
        _affectedAppointments = list;
      });
    } else {
      setState(() {
        _isLoadingPreview = false;
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
      });
    }
  }

  Future<void> _confirmDeactivation() async {
    setState(() {
      _isDeactivating = true;
      _errorMessage = null;
      _failure = null;
    });

    final res = await widget.repository.deactivatePet(widget.pet.id);
    if (!mounted) return;

    if (res.isOk) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.petDeactivateSuccess ?? ''),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isDeactivating = false;
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cancelText = l10n?.cancel ?? '';
    final confirmText = l10n?.petDeactivateAction ?? '';

    return AlertDialog(
      title: Text(l10n?.petDeactivateTitle ?? ''),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.pet.name} (${widget.pet.species})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(l10n?.petDeactivateConfirm ?? ''),
              const SizedBox(height: 12.0),
              Text(
                l10n?.petDeactivateNotice ?? '',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 16.0),
              if (_isLoadingPreview) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                Center(
                  child: Text(
                    l10n?.petLoadingPreview ?? '',
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    _failure?.toLocalizedMessage(l10n ?? AppLocalizations.of(context)!) ?? _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ] else ...[
                if (_activeAppointmentsCount > 0) ...[
                  Text(
                    '${l10n?.petDeactivateAffectedAppointments ?? ''} $_activeAppointmentsCount',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8.0),
                  ..._affectedAppointments.map((appt) {
                    final date = appt['dateString']?.toString() ?? '';
                    final slot = appt['timeSlot']?.toString() ?? '';
                    final service = appt['serviceName']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.event_busy, color: Colors.red),
                        title: Text(
                          l10n?.appointmentItemSummary(service, date) ?? '',
                        ),
                        subtitle: Text(slot),
                      ),
                    );
                  }),
                ] else ...[
                  Text(
                    l10n?.petDeactivateNoAppointments ?? '',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TappableArea(
          semanticLabel: cancelText,
          tooltip: cancelText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: _isDeactivating ? null : () => Navigator.of(context).pop(false),
          child: TextButton(
            onPressed: _isDeactivating ? null : () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
        ),
        TappableArea(
          semanticLabel: confirmText,
          tooltip: confirmText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: (_isLoadingPreview || _isDeactivating) ? null : _confirmDeactivation,
          child: ElevatedButton(
            onPressed: (_isLoadingPreview || _isDeactivating) ? null : _confirmDeactivation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(120.0, 48.0),
            ),
            child: _isDeactivating
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(confirmText),
          ),
        ),
      ],
    );
  }
}
