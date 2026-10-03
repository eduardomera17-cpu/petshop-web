// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/dashboard/views/admin_dashboard_screen.dart
// Propósito: Pantalla adaptadora y proveedora de inyección de dependencias para el panel de control administrativo y métricas operativas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/dashboard_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/dashboard/view_models/admin_dashboard_view_model.dart';
import 'package:mipetshop/ui/features/admin/dashboard/views/admin_dashboard_view.dart';

/// Pantalla adaptadora que inicializa el modelo [AdminDashboardViewModel] a partir
/// del [DashboardRepository] provisto en el árbol de contexto y delega la renderización a [AdminDashboardView].
class AdminDashboardScreen extends StatefulWidget {
  /// Constructor del contenedor de pantalla del dashboard administrativo.
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

/// Estado interactivo de [AdminDashboardScreen] a cargo del ciclo de vida del [AdminDashboardViewModel].
class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  /// Instancia activa del modelo de vista gestor de los indicadores y métricas del dashboard.
  AdminDashboardViewModel? _viewModel;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final repo = Provider.of<DashboardRepository?>(context, listen: false);
        if (repo != null) {
          _viewModel = AdminDashboardViewModel(dashboardRepository: repo);
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
        appBar: AppBar(title: Text(l10n?.navAdmin ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminDashboardView(viewModel: _viewModel!);
  }
}
