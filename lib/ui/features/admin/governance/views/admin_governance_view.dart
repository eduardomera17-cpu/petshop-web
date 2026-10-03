// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/governance/views/admin_governance_view.dart
// Propósito: Vista principal del módulo de gobernanza con pestañas para gestión de cuentas de personal, parámetros operativos y log de auditoría.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/core/widgets/admin_back_button.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/governance/view_models/governance_view_model.dart';
import 'package:mipetshop/ui/features/admin/governance/views/account_management_view.dart';
import 'package:mipetshop/ui/features/admin/governance/views/audit_log_view.dart';
import 'package:mipetshop/ui/features/admin/governance/views/operating_parameters_view.dart';

/// Vista contenedora del módulo administrativo de Gobernanza y Configuración.
///
/// Integra a través de un [TabBar] interactivo de tres pestañas:
/// 1. Gestión de Cuentas de Personal ([AccountManagementView]): Alta, modificación de roles y desactivación.
/// 2. Parámetros Operativos ([OperatingParametersView]): Horarios de atención, aforos, duración de citas y recargos.
/// 3. Registro de Auditoría ([AuditLogView]): Trazabilidad inmutable de eventos sensibles del sistema.
class AdminGovernanceView extends StatefulWidget {
  /// Modelo de vista reactivo gestor de la gobernanza, cuentas, parámetros y registros de auditoría.
  final GovernanceViewModel viewModel;

  /// Constructor de la vista de gobernanza administrativa.
  const AdminGovernanceView({
    super.key,
    required this.viewModel,
  });

  @override
  State<AdminGovernanceView> createState() => _AdminGovernanceViewState();
}


class _AdminGovernanceViewState extends State<AdminGovernanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.viewModel.setTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AdminBackButton(),
        title: Text(l10n?.govTitle ?? ''),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              key: const Key('tab_accounts'),
              icon: const Icon(Icons.people_outline),
              text: l10n?.govTabAccounts ?? '',
            ),
            Tab(
              key: const Key('tab_operating_parameters'),
              icon: const Icon(Icons.tune),
              text: l10n?.govTabOperatingParameters ?? '',
            ),
            Tab(
              key: const Key('tab_audit_log'),
              icon: const Icon(Icons.history),
              text: l10n?.govTabAuditLog ?? '',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            AccountManagementView(viewModel: widget.viewModel),
            OperatingParametersView(viewModel: widget.viewModel),
            AuditLogView(viewModel: widget.viewModel),
          ],
        ),
      ),
    );
  }
}
