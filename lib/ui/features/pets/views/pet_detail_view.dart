// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/pets/views/pet_detail_view.dart
// Propósito: Vista de inspección detallada de mascota para el cliente, garantizando la política de cero exposición clínica en el portal cliente.
// =========================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/pets_repository.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';
import 'package:mipetshop/ui/features/pets/view_models/pet_form_view_model.dart';
import 'package:mipetshop/ui/features/pets/views/pet_deactivate_dialog.dart';
import 'package:mipetshop/ui/features/pets/views/pet_form_view.dart';

/// Vista de inspección detallada (ficha general) de la mascota para el usuario cliente.
///
/// Despliega los atributos demográficos y administrativos de la mascota:
/// - Fotografía oficial almacenada en Cloud Storage con visualización binaria optimizada.
/// - Especie, raza, sexo, estado reproductivo y cálculo dinámico de edad según fecha de nacimiento.
/// - Alergias declaradas por el dueño para la atención de servicios estéticos y de baño.
/// - Acceso a las acciones de edición de datos y solicitud de baja lógica preventiva.
/// - Cumple estrictamente con la política de seguridad y privacidad al omitir historiales clínicos veterinarios.
class PetDetailView extends StatefulWidget {
  /// Entidad de la mascota cuyos datos son presentados en la ficha.
  final Pet pet;

  /// Repositorio de persistencia y consumo de servicios para mascotas y fotografías.
  final PetsRepository repository;

  /// Bytes binarios iniciales de la fotografía precargados en memoria para evitar parpadeos visuales.
  final Uint8List? initialPhotoBytes;

  /// Constructor de la vista de ficha detallada de mascota.
  const PetDetailView({
    super.key,
    required this.pet,
    required this.repository,
    this.initialPhotoBytes,
  });

  @override
  State<PetDetailView> createState() => _PetDetailViewState();
}


class _PetDetailViewState extends State<PetDetailView> {
  late Pet _currentPet;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
    _photoBytes = widget.initialPhotoBytes;
    if (_photoBytes == null && _currentPet.photoPath != null) {
      _loadPhoto();
    }
  }

  Future<void> _loadPhoto() async {
    if (_currentPet.photoPath == null) return;
    final res = await widget.repository.getPhotoBytes(_currentPet.photoPath);
    if (res.isOk && res.dataOrNull != null && mounted) {
      setState(() {
        _photoBytes = res.dataOrNull;
      });
    }
  }

  Future<void> _openEdit() async {
    final formVm = PetFormViewModel(
      repository: widget.repository,
      initialPet: _currentPet,
    );

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PetFormView(
          viewModel: formVm,
          ownerId: _currentPet.ownerId,
        ),
      ),
    );

    if (updated == true && mounted) {
      final res = await widget.repository.getPetById(_currentPet.id);
      if (res.isOk && res.dataOrNull != null) {
        setState(() {
          _currentPet = res.dataOrNull!;
        });
      }
    }
  }

  Future<void> _openDeactivate() async {
    final deactivated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PetDeactivateDialog(
        pet: _currentPet,
        repository: widget.repository,
      ),
    );

    if (deactivated == true && mounted) {
      final res = await widget.repository.getPetById(_currentPet.id);
      if (res.isOk && res.dataOrNull != null) {
        setState(() {
          _currentPet = res.dataOrNull!;
        });
      }
    }
  }

  String _formatAge(String? birthDateStr, AppLocalizations? l10n) {
    if (birthDateStr == null || birthDateStr.trim().isEmpty) return '-';
    final parts = birthDateStr.split('-');
    if (parts.length != 3) return birthDateStr;

    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return birthDateStr;

    final birth = DateTime(y, m, d);
    final now = BusinessClock.now();
    if (birth.isAfter(now)) return '-';

    var years = now.year - birth.year;
    var months = now.month - birth.month;
    if (now.day < birth.day) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0 && months > 0) {
      return '$years ${l10n?.petAgeYears ?? ''}, $months ${l10n?.petAgeMonths ?? ''}';
    } else if (years > 0) {
      return '$years ${l10n?.petAgeYears ?? ''}';
    } else if (months > 0) {
      return '$months ${l10n?.petAgeMonths ?? ''}';
    } else {
      return '< 1 ${l10n?.petAgeMonths ?? ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isActive = _currentPet.status == 'ACTIVE';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.petDetailTitle ?? ''),
        actions: [
          if (isActive)
            TappableArea(
              semanticLabel: l10n?.petEditAction ?? '',
              tooltip: l10n?.petEditAction ?? '',
              minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              onTap: _openEdit,
              child: IconButton(
                onPressed: _openEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
        ],
      ),
      body: ResponsiveLayout(
        builder: (context, breakpoint) {
          final hPadding = breakpoint.isCompact ? 16.0 : 32.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: hPadding,
              vertical: 24.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(theme, l10n, isActive),
                    const SizedBox(height: 24.0),
                    _buildInfoCard(theme, l10n),
                    const SizedBox(height: 32.0),
                    if (isActive) ...[
                      TappableArea(
                        semanticLabel: l10n?.petDeactivateAction ?? '',
                        tooltip: l10n?.petDeactivateAction ?? '',
                        minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                        onTap: _openDeactivate,
                        child: OutlinedButton.icon(
                          onPressed: _openDeactivate,
                          icon: const Icon(Icons.person_off_outlined, color: Colors.red),
                          label: Text(
                            l10n?.petDeactivateAction ?? '',
                            style: const TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 48.0),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, AppLocalizations? l10n, bool isActive) {
    final statusText = isActive
        ? (l10n?.petStatusActive ?? '')
        : (l10n?.petStatusDeactivated ?? '');

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 56.0,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: _photoBytes != null ? MemoryImage(_photoBytes!) : null,
              child: _photoBytes == null
                  ? Icon(
                      Icons.pets,
                      size: 56.0,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(height: 16.0),
            Text(
              _currentPet.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              '${_currentPet.species}${_currentPet.breed != null ? ' · ${_currentPet.breed}' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12.0),
            isActive
                ? StatusBadge.success(text: statusText)
                : StatusBadge.neutral(text: statusText),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, AppLocalizations? l10n) {
    final ageText = _formatAge(_currentPet.birthDate, l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.profileDetailsTitle ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24.0),
            _buildDetailRow(
              Icons.male,
              l10n?.petSexLabel ?? '',
              _currentPet.sex == 'MALE'
                  ? (l10n?.petSexMale ?? '')
                  : (l10n?.petSexFemale ?? ''),
            ),
            if (_currentPet.breed != null && _currentPet.breed!.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildDetailRow(
                Icons.pets,
                l10n?.petBreedLabel ?? '',
                _currentPet.breed!,
              ),
            ],
            const SizedBox(height: 16.0),
            _buildDetailRow(
              Icons.healing,
              l10n?.petReproductiveStatusLabel ?? '',
              _currentPet.reproductiveStatus == 'INTACT'
                  ? (l10n?.petReproductiveIntact ?? '')
                  : (_currentPet.reproductiveStatus == 'NEUTERED'
                      ? (l10n?.petReproductiveNeutered ?? '')
                      : (l10n?.petReproductiveUnknown ?? '')),
            ),
            const SizedBox(height: 16.0),
            _buildDetailRow(
              Icons.cake_outlined,
              l10n?.petBirthDateLabel ?? '',
              _currentPet.birthDate ?? '-',
            ),
            const SizedBox(height: 16.0),
            _buildDetailRow(
              Icons.access_time_outlined,
              l10n?.petAgeLabel ?? '',
              ageText,
            ),
            if (_currentPet.allergies != null && _currentPet.allergies!.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildDetailRow(
                Icons.medical_services_outlined,
                l10n?.petAllergiesLabel ?? '',
                _currentPet.allergies!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.0, color: Colors.grey.shade600),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }
}
