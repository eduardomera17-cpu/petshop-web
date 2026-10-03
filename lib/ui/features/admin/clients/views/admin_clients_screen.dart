// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/clients/views/admin_clients_screen.dart
// Propósito: Pantalla adaptadora y proveedora de dependencias para el directorio administrativo de clientes y tutores.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/clients/view_models/admin_clients_view_model.dart';
import 'package:mipetshop/ui/features/admin/clients/views/admin_clients_list_view.dart';

/// Pantalla adaptadora del directorio de clientes para el personal administrativo y veterinario.
///
/// Resuelve las dependencias requeridas ([AgendaRepository] y [AuthRepository]) desde el árbol
/// de proveedores, inicializa el [AdminClientsViewModel] y delega la interfaz a [AdminClientsListView].
class AdminClientsScreen extends StatefulWidget {
  /// Constructor de la pantalla adaptadora del directorio de clientes.
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

/// Estado interactivo de [AdminClientsScreen] a cargo de la inicialización y disposición del ViewModel.
class _AdminClientsScreenState extends State<AdminClientsScreen> {
  /// Modelo de vista reactivo gestor de la búsqueda y listado de clientes.
  AdminClientsViewModel? _viewModel;

  /// Identificador único del miembro del personal autenticado.
  String? _staffUid;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final agendaRepo = Provider.of<AgendaRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        if (agendaRepo != null) {
          _viewModel = AdminClientsViewModel(agendaRepository: agendaRepo);
          _staffUid = authRepo?.currentUser?.uid;
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authRepo = Provider.of<AuthRepository?>(context, listen: false);
    final currentStaffUid = _staffUid ?? authRepo?.currentUser?.uid;

    if (_viewModel == null || currentStaffUid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.adminNavClients ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminClientsListView(
      viewModel: _viewModel!,
      staffUid: currentStaffUid,
    );
  }
}
