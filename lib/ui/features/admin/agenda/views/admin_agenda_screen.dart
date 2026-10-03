// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/agenda/views/admin_agenda_screen.dart
// Propósito: Pantalla adaptadora y proveedora de inyección de dependencias para el módulo administrativo de agenda y citas.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/agenda_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/admin/agenda/view_models/admin_agenda_view_model.dart';
import 'package:mipetshop/ui/features/admin/agenda/views/admin_agenda_view.dart';

/// Pantalla adaptadora del módulo de administración de agenda que resuelve reactivamente
/// el [AgendaRepository] del árbol de dependencias e instancia el [AdminAgendaViewModel].
///
/// Gestiona de manera segura el ciclo de vida del ViewModel subyacente y delega
/// la renderización de la interfaz a [AdminAgendaView].
class AdminAgendaScreen extends StatefulWidget {
  /// Constructor del contenedor de pantalla de agenda administrativa.
  const AdminAgendaScreen({super.key});

  @override
  State<AdminAgendaScreen> createState() => _AdminAgendaScreenState();
}

/// Estado interactivo de [AdminAgendaScreen] a cargo de instanciar y liberar el [AdminAgendaViewModel].
class _AdminAgendaScreenState extends State<AdminAgendaScreen> {
  /// Instancia activa del modelo de vista gestor de la agenda global.
  AdminAgendaViewModel? _viewModel;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final agendaRepo = Provider.of<AgendaRepository?>(context, listen: false);
        if (agendaRepo != null) {
          _viewModel = AdminAgendaViewModel(agendaRepository: agendaRepo);
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
        appBar: AppBar(title: Text(l10n?.navAdminAgenda ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return AdminAgendaView(viewModel: _viewModel!);
  }
}
