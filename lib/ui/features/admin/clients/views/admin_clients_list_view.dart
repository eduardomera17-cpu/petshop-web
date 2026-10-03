// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/clients/views/admin_clients_list_view.dart
// Propósito: Vista de directorio administrativo de clientes activos y usuarios desactivados con búsqueda en tiempo real y reactivación.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/clients/view_models/admin_clients_view_model.dart';
import 'package:mipetshop/ui/features/admin/clients/views/admin_client_detail_view.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';

/// Vista de directorio administrativo para la gestión de clientes y tutores de mascotas.
///
/// Características y capacidades:
/// - Pestaña dual segmentada: Clientes Activos vs. Cuentas Desactivadas voluntariamente.
/// - Barra de búsqueda con filtrado predictivo por nombres completos, identificación tributaria o correo.
/// - Transición fluida a la ficha detallada del cliente ([AdminClientDetailView]) al seleccionar una fila.
/// - Operación de reactivación administrativa de cuentas desactivadas mediante confirmación modal.
class AdminClientsListView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de la lista de clientes y filtros de búsqueda.
  final AdminClientsViewModel viewModel;

  /// Identificador único del miembro del personal que opera la interfaz.
  final String staffUid;

  /// Constructor de la vista de listado de clientes.
  const AdminClientsListView({
    super.key,
    required this.viewModel,
    required this.staffUid,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.selectedClient != null) {
          return AdminClientDetailView(
            viewModel: viewModel,
            client: viewModel.selectedClient!,
            staffUid: staffUid,
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: const AdminBackButton(),
            title: Text(l10n?.adminClientsManagementTitle ?? ''),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (viewModel.failure != null || viewModel.errorMessage != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.red.shade100,
                              child: Text(
                                viewModel.failure?.toLocalizedMessage(l10n ?? AppLocalizations.of(context)!) ??
                                    viewModel.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          _buildTabsHeader(l10n),
                          const SizedBox(height: 12.0),
                          if (viewModel.selectedTab == 0) ...[
                            _buildSearchBar(l10n),
                            const SizedBox(height: 12.0),
                            Expanded(child: _buildActiveClientsList(l10n)),
                          ] else ...[
                            Expanded(child: _buildDeactivatedUsersList(context, l10n)),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabsHeader(AppLocalizations? l10n) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(
          value: 0,
          label: Text(l10n?.adminClientsActiveTab ?? ''),
          icon: const Icon(Icons.people),
        ),
        ButtonSegment(
          value: 1,
          label: Text(l10n?.adminClientsDeactivatedTab ?? ''),
          icon: const Icon(Icons.person_off),
        ),
      ],
      selected: {viewModel.selectedTab},
      onSelectionChanged: (newSelection) {
        viewModel.setSelectedTab(newSelection.first);
      },
    );
  }

  Widget _buildSearchBar(AppLocalizations? l10n) {
    return TextField(
      key: const Key('client_search_field'),
      decoration: InputDecoration(
        labelText: l10n?.adminClientsSearchLabel ?? '',
        hintText: l10n?.adminClientsSearchHint ?? '',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      ),
      onChanged: (val) => viewModel.setSearchQuery(val),
    );
  }

  Widget _buildActiveClientsList(AppLocalizations? l10n) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final clients = viewModel.activeClients;
    if (clients.isEmpty) {
      return Center(
        child: Text(
          l10n?.adminClientsEmptyActive ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 16.0),
        ),
      );
    }

    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return Card(
          key: Key('client_card_${client.uid}'),
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: InkWell(
            onTap: () => viewModel.selectClient(client),
            borderRadius: BorderRadius.circular(10.0),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          l10n?.adminClientDocAndPhone(client.documentType, client.documentNumber, client.phone) ?? '',
                          style: const TextStyle(color: Colors.black87, fontSize: 13.0),
                        ),
                        Text(
                          client.email,
                          style: const TextStyle(color: Colors.black54, fontSize: 12.0),
                        ),
                      ],
                    ),
                  ),
                  TappableArea(
                    key: Key('view_client_btn_${client.uid}'),
                    tooltip: l10n?.adminClientsTooltipView ?? '',
                    semanticLabel: l10n?.adminClientsSemanticsView ?? '',
                    minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                    onTap: () => viewModel.selectClient(client),
                    child: const Icon(Icons.chevron_right, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeactivatedUsersList(BuildContext context, AppLocalizations? l10n) {
    final list = viewModel.deactivatedUsers;

    if (list.isEmpty) {
      return Center(
        child: Text(
          l10n?.adminClientsEmptyDeactivated ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 16.0),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final user = list[index];
        return Card(
          key: Key('deactivated_user_card_${user.uid}'),
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person_off, color: Colors.grey),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        l10n?.adminClientEmailAndPhone(user.email, user.phone) ?? '',
                        style: const TextStyle(color: Colors.black87, fontSize: 13.0),
                      ),
                      Text(
                        l10n?.adminClientsStatusDeactivated ?? '',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12.0),
                      ),
                    ],
                  ),
                ),
                TappableArea(
                  key: Key('reactivate_btn_${user.uid}'),
                  tooltip: l10n?.adminClientsReactivateTitle ?? '',
                  semanticLabel: l10n?.adminClientsSemanticsReactivate ?? '',
                  minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n?.adminClientsReactivateTitle ?? ''),
                        content: Text(l10n?.adminClientsReactivateContent(user.fullName) ?? ''),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(l10n?.cancel ?? ''),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(l10n?.adminClientsReactivateConfirm ?? ''),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await viewModel.reactivateAccountOrPet(
                        entityType: 'USER',
                        entityId: user.uid,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.restore, color: Colors.green, size: 20.0),
                        const SizedBox(width: 4.0),
                        Text(
                          l10n?.adminClientsReactivateConfirm ?? '',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
    );
  }
}
