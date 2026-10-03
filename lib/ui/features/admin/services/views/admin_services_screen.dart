// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/services/views/admin_services_screen.dart
// Propósito: Pantalla contenedora que resuelve dependencias e inicializa la gestión administrativa de servicios veterinarios y de estética.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/services/view_models/services_view_model.dart';
import 'package:mipetshop/ui/features/admin/services/views/services_list_view.dart';

/// {@template admin_services_screen}
/// Pantalla de entrada para el módulo administrativo de catálogo de servicios.
///
/// Obtiene mediante Provider los repositorios [CatalogRepository] y [AuthRepository],
/// gestiona el ciclo de vida del [ServicesViewModel], identifica el UID del usuario autenticado
/// y presenta la vista de lista [ServicesListView].
/// {@endtemplate}
class AdminServicesScreen extends StatefulWidget {
  /// Constructor inmutable de la pantalla contenedora de servicios administrativos.
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  ServicesViewModel? _viewModel;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final catalogRepo = Provider.of<CatalogRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        if (catalogRepo != null) {
          _viewModel = ServicesViewModel(repository: catalogRepo);
          _uid = authRepo?.currentUser?.uid;
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
    final currentUid = _uid ?? authRepo?.currentUser?.uid;

    if (_viewModel == null || currentUid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.adminServicesTitle ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return ServicesListView(
      viewModel: _viewModel!,
      currentUid: currentUid,
    );
  }
}
