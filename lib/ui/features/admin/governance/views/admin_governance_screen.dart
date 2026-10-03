// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/governance/views/admin_governance_screen.dart
// Propósito: Pantalla adaptadora e inyectora de dependencias para el módulo administrativo de gobernanza, roles y auditoría.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/governance_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/governance/view_models/governance_view_model.dart';
import 'package:mipetshop/ui/features/admin/governance/views/admin_governance_view.dart';

/// Pantalla adaptadora que resuelve reactivamente el [GovernanceRepository] del árbol de dependencias,
/// gestiona el ciclo de vida de [GovernanceViewModel] y renderiza [AdminGovernanceView].
class AdminGovernanceScreen extends StatefulWidget {
  /// Constructor del adaptador de pantalla de gobernanza.
  const AdminGovernanceScreen({super.key});

  @override
  State<AdminGovernanceScreen> createState() => _AdminGovernanceScreenState();
}

/// Estado interactivo de [AdminGovernanceScreen] a cargo de inicializar y desechar el [GovernanceViewModel].
class _AdminGovernanceScreenState extends State<AdminGovernanceScreen> {
  /// Instancia activa del modelo de vista gestor de gobernanza y auditoría.
  GovernanceViewModel? _viewModel;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        GovernanceRepository? govRepo;
        try {
          govRepo = Provider.of<GovernanceRepository>(context, listen: false);
        } catch (_) {
          govRepo = Provider.of<GovernanceRepository?>(context, listen: false);
        }
        if (govRepo != null) {
          _viewModel = GovernanceViewModel(repository: govRepo);
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
        appBar: AppBar(title: Text(l10n?.govTitle ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminGovernanceView(viewModel: _viewModel!);
  }
}
