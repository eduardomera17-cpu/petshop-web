// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/clients/views/admin_client_detail_view.dart
// Propósito: Ficha administrativa de cliente y gestión clínica/demográfica de sus mascotas asociadas garantizando la invariante de identidad inmutable.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/clinical_repository.dart';
import 'package:mipetshop/domain/models/pet.dart';
import 'package:mipetshop/domain/models/user_profile.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/clients/view_models/admin_clients_view_model.dart';
import 'package:mipetshop/ui/features/admin/clinical/views/clinical_history_view.dart';

/// Ficha administrativa de consulta de cliente y gestión de sus mascotas registradas.
///
/// Invariante de seguridad: Ningún dato de identidad personal del cliente (nombre, cédula, correo)
/// es modificable por el personal para salvaguardar la veracidad de los registros.
///
/// Funcionalidades para el personal:
/// - Visualización de información de contacto y estado de la cuenta.
/// - Consulta de mascotas vinculadas con acceso a su expediente clínico completo ([ClinicalHistoryView]).
/// - Diálogo de corrección administrativa de atributos zootécnicos de las mascotas (sexo y condición reproductiva).
class AdminClientDetailView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de las operaciones sobre clientes y mascotas.
  final AdminClientsViewModel viewModel;

  /// Perfil del cliente seleccionado.
  final UserProfile client;

  /// Identificador único del miembro del personal que visualiza la ficha.
  final String staffUid;

  /// Constructor de la vista de detalle de cliente.
  const AdminClientDetailView({
    super.key,
    required this.viewModel,
    required this.client,
    required this.staffUid,
  });


  /// Abre el registro clínico de la mascota (`CL-03`, `CL-08`, `CL-12`, `CA-AD-52`).
  ///
  /// `CA-AD-52` dice dónde se consulta una versión anterior: **desde la propia
  /// entrada**. Las entradas viven en esta pantalla, colgando de la mascota, y
  /// hasta `AUD-344` no había forma de llegar a ellas: la vista existía y no la
  /// alcanzaba nadie. La ficha de cliente es su sitio porque es donde `CL-02`
  /// pone la lista de mascotas, y sirve igual a una cuenta desactivada (`CL-06`).
  ///
  /// Sin repositorio o sin sesión **no se abre**. No es celo: `CL-12` limita la
  /// corrección al autor y al Super Usuario, y esa pantalla decide qué ofrece a
  /// partir del rol. Abrirla sin saber quién mira degradaría a un Super Usuario
  /// en silencio, que es peor que no abrirla.
  void _openClinicalHistory(BuildContext context, Pet pet) {
    final l10n = AppLocalizations.of(context);
    final clinicalRepo = Provider.of<ClinicalRepository?>(context, listen: false);
    final authRepo = Provider.of<AuthRepository?>(context, listen: false);

    if (clinicalRepo == null || authRepo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.errorGeneric ?? '')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ClinicalHistoryView(
          clinicalRepository: clinicalRepo,
          petId: pet.id,
          ownerId: client.uid,
          petName: pet.name,
          currentStaffUid: staffUid,
          currentStaffName: authRepo.currentUser?.displayName ?? '',
          currentStaffRole: authRepo.role ?? '',
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _showPetCorrectionDialog(BuildContext context, Pet pet) {
    final l10n = AppLocalizations.of(context);
    String selectedSex = pet.sex;
    String selectedReproductive = pet.reproductiveStatus;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(l10n?.adminPetCorrectionTitle(pet.name) ?? ''),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.adminPetCorrectionNote ?? '',
                style: const TextStyle(fontSize: 12.0, color: Colors.blueGrey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                key: const Key('correction_sex_dropdown'),
                initialValue: selectedSex,
                decoration: InputDecoration(labelText: l10n?.adminPetCorrectionSexLabel ?? ''),
                items: [
                  DropdownMenuItem(value: 'MALE', child: Text(l10n?.adminPetCorrectionSexMale ?? '')),
                  DropdownMenuItem(value: 'FEMALE', child: Text(l10n?.adminPetCorrectionSexFemale ?? '')),
                ],
                onChanged: (val) {
                  if (val != null) setStateDialog(() => selectedSex = val);
                },
              ),
              const SizedBox(height: 12.0),
              DropdownButtonFormField<String>(
                key: const Key('correction_reproductive_dropdown'),
                initialValue: selectedReproductive,
                decoration: InputDecoration(labelText: l10n?.adminPetCorrectionReproductiveLabel ?? ''),
                items: [
                  DropdownMenuItem(value: 'INTACT', child: Text(l10n?.adminPetCorrectionReproductiveIntact ?? '')),
                  DropdownMenuItem(value: 'NEUTERED', child: Text(l10n?.adminPetCorrectionReproductiveNeutered ?? '')),
                  DropdownMenuItem(value: 'UNKNOWN', child: Text(l10n?.adminPetCorrectionReproductiveUnknown ?? '')),
                ],
                onChanged: (val) {
                  if (val != null) setStateDialog(() => selectedReproductive = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n?.cancel ?? ''),
            ),
            ElevatedButton(
              key: const Key('save_pet_correction_button'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await viewModel.updatePetStaffCorrection(
                  petId: pet.id,
                  staffUid: staffUid,
                  sex: selectedSex,
                  reproductiveStatus: selectedReproductive,
                );
              },
              child: Text(l10n?.adminPetCorrectionSave ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.adminClientDetailTitle(client.fullName) ?? ''),
        leading: TappableArea(
          key: const Key('back_to_clients_list_button'),
          tooltip: l10n?.adminClientTooltipBack ?? '',
          semanticLabel: l10n?.adminClientSemanticsBack ?? '',
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: () => viewModel.clearSelectedClient(),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyIdentityCard(l10n),
                      const SizedBox(height: 20.0),
                      _buildPetsSection(context, l10n),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Ficha de Cliente estrictamente de SÓLO LECTURA (CA-AD-27).
  ///
  /// Se garantiza de forma taxativa que NO existen controles TextField,
  /// TextFormField ni botones de edición de identidad (CF-08 reservado para Etapa 5).
  Widget _buildReadOnlyIdentityCard(AppLocalizations? l10n) {
    return Card(
      key: const Key('read_only_client_profile_card'),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.blueGrey, size: 24.0),
                const SizedBox(width: 8.0),
                // El título cede sitio a la insignia de estado (AUD-346). Con
                // `DEACTIVATED` la fila se desbordaba 57 px a 800 px, y `CL-06`
                // obliga a consultar entera la ficha de una cuenta desactivada.
                Flexible(
                  child: Text(
                    l10n?.adminClientIdentityTitle ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: client.status == 'ACTIVE' ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    client.status,
                    style: TextStyle(
                      color: client.status == 'ACTIVE' ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0),
            _buildReadOnlyField(l10n?.adminClientFieldFullName ?? '', client.fullName),
            _buildReadOnlyField(l10n?.adminClientFieldDocument ?? '', '${client.documentType}: ${client.documentNumber}'),
            _buildReadOnlyField(l10n?.adminClientFieldEmail ?? '', client.email),
            _buildReadOnlyField(l10n?.adminClientFieldPhone ?? '', client.phone),
            _buildReadOnlyField(l10n?.adminClientFieldAddress ?? '', client.address.isNotEmpty ? client.address : (l10n?.adminClientAddressNotRegistered ?? '')),
            _buildReadOnlyField(l10n?.adminClientFieldRole ?? '', client.role),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190.0,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsSection(BuildContext context, AppLocalizations? l10n) {
    final pets = viewModel.selectedClientPets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pets, color: Colors.blueGrey, size: 24.0),
            const SizedBox(width: 8.0),
            Text(
              l10n?.adminClientPetsRegisteredTitle(pets.length) ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        if (pets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n?.adminClientNoPets ?? '',
              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final breedText = pet.breed ?? (l10n?.adminPetBreedNotSpecified ?? '');
              return Card(
                key: Key('pet_card_${pet.id}'),
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Icon(
                          pet.species.toUpperCase() == 'CAT' ? Icons.pets : Icons.cruelty_free,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              l10n?.adminPetSpeciesLabel(pet.species, breedText) ?? '',
                              style: const TextStyle(color: Colors.black54, fontSize: 13.0),
                            ),
                            Text(
                              l10n?.adminPetSexReproductiveLabel(pet.sex, pet.reproductiveStatus) ?? '',
                              style: const TextStyle(color: Colors.blueGrey, fontSize: 13.0),
                            ),
                          ],
                        ),
                      ),
                      // Registro clínico de la mascota (AUD-344, CL-03, CL-08, CL-12)
                      TappableArea(
                        key: Key('clinical_record_btn_${pet.id}'),
                        tooltip: l10n?.adminPetClinicalRecordAction ?? '',
                        semanticLabel: l10n?.adminPetClinicalRecordSemantics(pet.name) ?? '',
                        minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                        onTap: () => _openClinicalHistory(context, pet),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            children: [
                              const Icon(Icons.medical_information_outlined, size: 18.0, color: Colors.teal),
                              const SizedBox(width: 4.0),
                              Text(
                                l10n?.adminPetClinicalRecordAction ?? '',
                                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botón para corrección por el personal
                      TappableArea(
                        key: Key('correct_pet_btn_${pet.id}'),
                        tooltip: l10n?.adminPetCorrectionTooltip ?? '',
                        semanticLabel: l10n?.adminPetCorrectionSemantics ?? '',
                        minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                        onTap: () => _showPetCorrectionDialog(context, pet),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 18.0, color: Colors.blue),
                              const SizedBox(width: 4.0),
                              Text(
                                l10n?.adminPetCorrectionAction ?? '',
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
