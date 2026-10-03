// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/pets/views/pets_list_view.dart
// Propósito: Vista principal de listado y gestión de mascotas pertenecientes al cliente con soporte responsivo y acceso a fichas individuales.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';
import 'package:mipetshop/ui/features/pets/view_models/pet_form_view_model.dart';
import 'package:mipetshop/ui/features/pets/view_models/pets_list_view_model.dart';
import 'package:mipetshop/ui/features/pets/views/pet_detail_view.dart';
import 'package:mipetshop/ui/features/pets/views/pet_form_view.dart';

/// Pantalla interactiva que presenta el catálogo o listado de mascotas registradas por el cliente.
///
/// Características principales:
/// - Escucha reactiva en tiempo real del listado de mascotas mediante [PetsListViewModel].
/// - Presentación en cuadrícula adaptable o lista vertical en función de los breakpoints de pantalla ([ResponsiveLayout]).
/// - Tarjetas interactivas con foto de perfil descargada en memoria, especie, raza y estado de vigencia (Activa / Inactiva).
/// - Acceso directo a la ficha detallada de la mascota y botón flotante para el alta de nuevos pacientes o ejemplares.
class PetsListView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de la lista de mascotas y la memoria caché de fotos.
  final PetsListViewModel viewModel;

  /// Identificador único del cliente autenticado.
  final String ownerId;

  /// Constructor de la vista de listado de mascotas.
  const PetsListView({
    super.key,
    required this.viewModel,
    required this.ownerId,
  });

  @override
  State<PetsListView> createState() => _PetsListViewState();
}


class _PetsListViewState extends State<PetsListView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.startListening(widget.ownerId);
  }

  void _openAddPet() {
    final formVm = PetFormViewModel(repository: widget.viewModel.repository);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetFormView(
          viewModel: formVm,
          ownerId: widget.ownerId,
        ),
      ),
    );
  }

  void _openPetDetail(Pet pet) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetDetailView(
          pet: pet,
          repository: widget.viewModel.repository,
          initialPhotoBytes: widget.viewModel.getPhoto(pet.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final addText = l10n?.addPetAction ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.petsListTitle ?? ''),
      ),
      floatingActionButton: TappableArea(
        semanticLabel: addText,
        tooltip: addText,
        minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        onTap: _openAddPet,
        child: FloatingActionButton.extended(
          onPressed: _openAddPet,
          icon: const Icon(Icons.add),
          label: Text(addText),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading && widget.viewModel.pets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.errorMessage != null && widget.viewModel.pets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  widget.viewModel.errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            );
          }

          final pets = widget.viewModel.pets;
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 64.0,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    l10n?.emptyPetsMessage ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  TappableArea(
                    semanticLabel: addText,
                    tooltip: addText,
                    minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                    onTap: _openAddPet,
                    child: ElevatedButton.icon(
                      onPressed: _openAddPet,
                      icon: const Icon(Icons.add),
                      label: Text(addText),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(180.0, 48.0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ResponsiveLayout(
            builder: (context, breakpoint) {
              final hPadding = breakpoint.isCompact ? 16.0 : 32.0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = breakpoint.isCompact
                      ? 1
                      : (breakpoint.isMedium ? 2 : 3);

                  if (crossAxisCount == 1) {
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPadding,
                        vertical: 16.0,
                      ),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildPetCard(pets[index], theme, l10n),
                        );
                      },
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPadding,
                      vertical: 24.0,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      return _buildPetCard(pets[index], theme, l10n);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPetCard(Pet pet, ThemeData theme, AppLocalizations? l10n) {
    final photoBytes = widget.viewModel.getPhoto(pet.id);
    final isActive = pet.status == 'ACTIVE';
    final statusText = isActive
        ? (l10n?.petStatusActive ?? '')
        : (l10n?.petStatusDeactivated ?? '');

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: TappableArea(
        semanticLabel: pet.name,
        tooltip: pet.name,
        minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        onTap: () => _openPetDetail(pet),
        child: InkWell(
          onTap: () => _openPetDetail(pet),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36.0,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
                  child: photoBytes == null
                      ? Icon(
                          Icons.pets,
                          size: 36.0,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pet.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${pet.species}${pet.breed != null ? ' · ${pet.breed}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      isActive
                          ? StatusBadge.success(text: statusText)
                          : StatusBadge.neutral(text: statusText),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
