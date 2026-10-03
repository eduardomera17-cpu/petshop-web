// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/chat/views/admin_staff_inbox_screen.dart
// Propósito: Contenedor y punto de enlace de inyección de dependencias para la bandeja de entrada de mensajería del personal administrativo.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/chat_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/chat/view_models/staff_inbox_view_model.dart';
import 'package:mipetshop/ui/features/chat/views/staff_inbox_screen.dart';

/// Pantalla adaptadora de nivel administrativo que inicializa y provee el
/// modelo de vista [StaffInboxViewModel] a partir del contexto de inyección de dependencias.
///
/// Resuelve de forma reactiva los repositorios [ChatRepository] y [AuthRepository],
/// extrayendo las credenciales y rol del colaborador activo (`ADMIN`, `STAFF` o `VET`)
/// para instanciar la pantalla de mensajería unificada [StaffInboxScreen].
class AdminStaffInboxScreen extends StatefulWidget {
  /// Constructor del contenedor de bandeja de entrada para el personal administrativo.
  const AdminStaffInboxScreen({super.key});

  @override
  State<AdminStaffInboxScreen> createState() => _AdminStaffInboxScreenState();
}

/// Estado mutable de [AdminStaffInboxScreen] a cargo del ciclo de vida del [StaffInboxViewModel].
class _AdminStaffInboxScreenState extends State<AdminStaffInboxScreen> {
  /// Instancia del modelo de vista gestor de los canales de chat para el personal.
  StaffInboxViewModel? _viewModel;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      try {
        final chatRepo = Provider.of<ChatRepository?>(context, listen: false);
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        final staffUid = authRepo?.currentUser?.uid;
        if (chatRepo != null && authRepo != null && staffUid != null) {
          _viewModel = StaffInboxViewModel(
            chatRepository: chatRepo,
            currentStaffUid: staffUid,
            currentStaffName: authRepo.currentUser?.displayName ?? '',
            currentStaffRole: authRepo.role ?? 'ADMIN',
          );
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
        appBar: AppBar(title: Text(l10n?.adminNavChat ?? '')),
        body: const Center(child: Icon(Icons.pets, size: 64.0)),
      );
    }
    return StaffInboxScreen(viewModel: _viewModel!);
  }
}
