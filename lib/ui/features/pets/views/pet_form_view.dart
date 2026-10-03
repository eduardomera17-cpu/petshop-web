// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/pets/views/pet_form_view.dart
// Propósito: Formulario interactivo para registro y actualización de datos de mascotas con soporte de edad aproximada y carga segura de fotografía.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/services/web_file_picker.dart';
import 'package:mipetshop/core/validators/pet.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/pets/view_models/pet_form_view_model.dart';

/// Formulario interactivo para el alta inicial o edición de datos de una mascota.
///
/// Características y capacidades:
/// - Admite selección de especie tipificada (`DOG`, `CAT`, `OTHER`).
/// - Manejo de edad flexible: fecha exacta mediante selector de calendario o cálculo inverso por edad aproximada (años/meses).
/// - Selección y previsualización de fotografía local previa a la carga con validación de tipo MIME y peso máximo.
/// - Carga segura a Cloud Storage mediante streams binarios y nombres aleatorios sin URLs públicas desprotegidas.
/// - Validación canónica de campos obligatorios, razas, estado reproductivo y restricciones alérgicas.
class PetFormView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de los estados y mutaciones del formulario.
  final PetFormViewModel viewModel;

  /// Identificador único del usuario dueño de la mascota.
  final String ownerId;

  /// Constructor del formulario de mascota.
  const PetFormView({
    super.key,
    required this.viewModel,
    required this.ownerId,
  });

  @override
  State<PetFormView> createState() => _PetFormViewState();
}


class _PetFormViewState extends State<PetFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _allergiesController;

  late final TextEditingController _yearsController;
  late final TextEditingController _monthsController;

  bool _useApproximateAge = false;
  PickedFileData? _pendingPhotoFile;

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;

    _nameController = TextEditingController(text: vm.name);
    _breedController = TextEditingController(text: vm.breed ?? '');
    _birthDateController = TextEditingController(text: vm.birthDate ?? '');
    _allergiesController = TextEditingController(text: vm.allergies ?? '');

    _yearsController = TextEditingController();
    _monthsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _allergiesController.dispose();
    _yearsController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final vm = widget.viewModel;
    vm.setName(_nameController.text);
    vm.setBreed(_breedController.text);
    vm.setBirthDate(_birthDateController.text);
    vm.setAllergies(_allergiesController.text);

    final success = await vm.savePet(ownerId: widget.ownerId);

    if (success && mounted) {
      if (!vm.isEditing && _pendingPhotoFile != null && vm.createdPetId != null) {
        await vm.uploadPhoto(
          uid: widget.ownerId,
          petId: vm.createdPetId!,
          fileName: _pendingPhotoFile!.name,
          bytes: _pendingPhotoFile!.bytes,
          mimeType: _pendingPhotoFile!.mimeType,
        );
      }

      if (!mounted) return;

      final msg = vm.isEditing
          ? (l10n?.petUpdateSuccess ?? '')
          : (l10n?.petCreateSuccess ?? '');

      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    }
  }

  void _applyApproximateAge() {
    final years = int.tryParse(_yearsController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    widget.viewModel.setAgeApproximate(years: years, months: months);
    if (widget.viewModel.birthDate != null) {
      _birthDateController.text = widget.viewModel.birthDate!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEditing = widget.viewModel.isEditing;

    final title = isEditing
        ? (l10n?.petEditAction ?? '')
        : (l10n?.addPetAction ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return ResponsiveLayout(
            builder: (context, breakpoint) {
              final hPadding = breakpoint.isCompact ? 16.0 : 32.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: hPadding,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAvatarSection(theme, l10n),
                          const SizedBox(height: 24.0),
                          if (widget.viewModel.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                widget.viewModel.errorMessage!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                          _buildNameField(l10n),
                          const SizedBox(height: 16.0),
                          _buildSpeciesAndBreedFields(l10n),
                          const SizedBox(height: 16.0),
                          _buildSexAndStatusFields(l10n),
                          const SizedBox(height: 16.0),
                          _buildBirthDateSection(l10n),
                          const SizedBox(height: 16.0),
                          _buildAllergiesField(l10n),
                          const SizedBox(height: 32.0),
                          _buildButtons(l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection(ThemeData theme, AppLocalizations? l10n) {
    final photoBytes = widget.viewModel.photoBytes;
    final photoText = l10n?.petPhotoAction ?? '';

    return Column(
      children: [
        CircleAvatar(
          radius: 48.0,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
          child: photoBytes == null
              ? Icon(
                  Icons.pets,
                  size: 48.0,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(height: 12.0),
        TappableArea(
          semanticLabel: photoText,
          tooltip: photoText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: () => _pickPhoto(l10n),
          child: OutlinedButton.icon(
            onPressed: () => _pickPhoto(l10n),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(photoText),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140.0, 48.0),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto(AppLocalizations? l10n) async {
    final pickResult = await pickPlatformFile();
    if (!mounted) return;

    switch (pickResult.status) {
      case FilePickStatus.cancelled:
        return;
      case FilePickStatus.unsupportedFormat:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.imageFormatUnsupported ?? '')),
        );
        return;
      case FilePickStatus.rejectedHeic:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.imageFormatHeicRejected ?? '')),
        );
        return;
      case FilePickStatus.sizeExceeded:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.imageSizeExceeded ?? '')),
        );
        return;
      case FilePickStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pickResult.errorMessage ?? (l10n?.errorGeneric ?? '')),
          ),
        );
        return;
      case FilePickStatus.success:
        final file = pickResult.file!;
        _pendingPhotoFile = file;
        widget.viewModel.setPhotoBytes(file.bytes);
        if (widget.viewModel.isEditing && widget.viewModel.petId != null) {
          await widget.viewModel.uploadPhoto(
            uid: widget.ownerId,
            petId: widget.viewModel.petId!,
            fileName: file.name,
            bytes: file.bytes,
            mimeType: file.mimeType,
          );
        }
        return;
    }
  }

  Widget _buildNameField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('pet_name_field'),
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n?.petNameLabel ?? '',
        prefixIcon: const Icon(Icons.badge_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        if (!isValidPetName(val)) {
          return validatePetName(val);
        }
        return null;
      },
    );
  }

  Widget _buildSpeciesAndBreedFields(AppLocalizations? l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: const Key('pet_species_field'),
            initialValue: widget.viewModel.species,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n?.petSpeciesLabel ?? '',
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'DOG',
                child: Text(l10n?.petSpeciesDog ?? ''),
              ),
              DropdownMenuItem(
                value: 'CAT',
                child: Text(l10n?.petSpeciesCat ?? ''),
              ),
              DropdownMenuItem(
                value: 'BIRD',
                child: Text(l10n?.petSpeciesBird ?? ''),
              ),
              DropdownMenuItem(
                value: 'OTHER',
                child: Text(l10n?.petSpeciesOther ?? ''),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                widget.viewModel.setSpecies(val);
              }
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 3,
          child: TextFormField(
            key: const Key('pet_breed_field'),
            controller: _breedController,
            decoration: InputDecoration(
              labelText: l10n?.petBreedLabel ?? '',
              border: const OutlineInputBorder(),
            ),
            validator: (val) {
              if (!isValidPetBreed(val)) {
                return validatePetBreed(val);
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSexAndStatusFields(AppLocalizations? l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: const Key('pet_sex_field'),
            initialValue: widget.viewModel.sex,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n?.petSexLabel ?? '',
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'MALE',
                child: Text(l10n?.petSexMale ?? ''),
              ),
              DropdownMenuItem(
                value: 'FEMALE',
                child: Text(l10n?.petSexFemale ?? ''),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                widget.viewModel.setSex(val);
              }
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: const Key('pet_reproductive_status_field'),
            initialValue: widget.viewModel.reproductiveStatus,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n?.petReproductiveStatusLabel ?? '',
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'INTACT',
                child: Text(l10n?.petReproductiveIntact ?? ''),
              ),
              DropdownMenuItem(
                value: 'NEUTERED',
                child: Text(l10n?.petReproductiveNeutered ?? ''),
              ),
              DropdownMenuItem(
                value: 'UNKNOWN',
                child: Text(l10n?.petReproductiveUnknown ?? ''),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                widget.viewModel.setReproductiveStatus(val);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateSection(AppLocalizations? l10n) {
    final ageNotice = l10n?.petAgeCalculationNotice ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n?.petBirthDateLabel ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _useApproximateAge = !_useApproximateAge;
                    });
                  },
                  icon: Icon(_useApproximateAge ? Icons.calendar_month : Icons.calculate_outlined),
                  label: Text(
                    _useApproximateAge
                        ? (l10n?.petBirthDateLabel ?? '')
                        : (l10n?.petAgeLabel ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (!_useApproximateAge) ...[
              TextFormField(
                key: const Key('pet_birthdate_field'),
                controller: _birthDateController,
                decoration: InputDecoration(
                  labelText: l10n?.petBirthDateLabel ?? '',
                  hintText: l10n?.dateFormatHint ?? '',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  return validatePetBirthDate(val);
                },
              ),
            ] else ...[
              Text(
                ageNotice,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12.0),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('pet_age_years_field'),
                      controller: _yearsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n?.petAgeYears ?? '',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _applyApproximateAge(),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextFormField(
                      key: const Key('pet_age_months_field'),
                      controller: _monthsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n?.petAgeMonths ?? '',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _applyApproximateAge(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesField(AppLocalizations? l10n) {
    return TextFormField(
      key: const Key('pet_allergies_field'),
      controller: _allergiesController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: l10n?.petAllergiesLabel ?? '',
        prefixIcon: const Icon(Icons.medical_information_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: (val) {
        return validatePetAllergies(val);
      },
    );
  }

  Widget _buildButtons(AppLocalizations? l10n) {
    final isSaving = widget.viewModel.isSaving;
    final saveText = l10n?.saveChangesAction ?? '';
    final cancelText = l10n?.cancel ?? '';

    return Row(
      children: [
        Expanded(
          child: TappableArea(
            semanticLabel: cancelText,
            tooltip: cancelText,
            minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
            onTap: isSaving ? null : () => Navigator.of(context).pop(),
            child: OutlinedButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48.0),
              ),
              child: Text(cancelText),
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: TappableArea(
            semanticLabel: saveText,
            tooltip: saveText,
            minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
            onTap: isSaving ? null : _submit,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48.0),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : Text(saveText),
            ),
          ),
        ),
      ],
    );
  }
}
