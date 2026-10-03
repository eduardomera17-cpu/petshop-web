// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/requests/views/admin_requests_screen.dart
// Propósito: Pantalla contenedora que inicializa y provee el ViewModel de gestión administrativa de solicitudes de productos del catálogo.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/product_requests_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/requests/view_models/admin_requests_view_model.dart';
import 'package:mipetshop/ui/features/admin/requests/views/admin_requests_view.dart';

/// {@template admin_requests_screen}
/// Pantalla de entrada para el módulo administrativo de solicitudes de productos.
///
/// Resuelve las dependencias necesarias mediante Provider ([ProductRequestsRepository]),
/// inicializa de forma segura el ciclo de vida de [AdminRequestsViewModel] y renderiza
/// la vista principal [AdminRequestsView].
/// {@endtemplate}
class AdminRequestsScreen extends StatefulWidget {
  /// Constructor inmutable para la pantalla contenedora de solicitudes administrativas.
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  AdminRequestsViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final requestsRepo = Provider.of<ProductRequestsRepository?>(context, listen: false);
        if (requestsRepo != null) {
          _viewModel = AdminRequestsViewModel(requestsRepository: requestsRepo);
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
    if (_viewModel == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.adminRequestsTitle ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminRequestsView(viewModel: _viewModel!);
  }
}
