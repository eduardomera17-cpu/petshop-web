// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/profile/views/staff_profile_screen.dart
// Propósito: Pantalla adaptadora y proveedora de perfil para personal operativo y administrativo con desactivación de cuenta restringida.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/repositories/profile_repository.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/profile/view_models/profile_view_model.dart';
import 'package:mipetshop/ui/features/profile/views/profile_view.dart';

/// Pantalla de perfil administrativo para colaboradores con roles `STAFF`, `VET`, `ADMIN` y `SUPERADMIN`.
///
/// Encapsula la inicialización contextual del [ProfileViewModel] a partir de los repositorios inyectados,
/// cargando la información personal del colaborador autenticado.
/// Reutiliza el componente [ProfileView] deshabilitando explícitamente la acción de desactivación
/// de cuenta (`showDeactivation: false`), debido a que las cuentas operativas del sistema
/// se gestionan únicamente desde el módulo de Gobernanza.
class StaffProfileScreen extends StatefulWidget {
  /// Constructor de la pantalla de perfil del personal.
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

/// Estado interactivo de [StaffProfileScreen] a cargo del ciclo de vida del [ProfileViewModel] del colaborador.
class _StaffProfileScreenState extends State<StaffProfileScreen> {
  /// Modelo de vista reactivo gestor del perfil administrativo.
  ProfileViewModel? _viewModel;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final repo = Provider.of<ProfileRepository?>(context, listen: false);
      final firestore = Provider.of<FirebaseFirestore?>(context, listen: false);
      final authRepo = Provider.of<AuthRepository?>(context, listen: false);

      if (repo != null) {
        _viewModel = ProfileViewModel(repository: repo);
      } else if (firestore != null) {
        _viewModel = ProfileViewModel(
          repository: ProfileRepository(firestore: firestore),
        );
      }

      final uid = authRepo?.currentUser?.uid;
      if (uid != null && _viewModel != null) {
        _viewModel!.loadProfile(uid);
      }
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
    final title = l10n?.staffProfileTitle ?? (l10n?.navProfile ?? '');

    if (_viewModel == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ProfileView(
      viewModel: _viewModel!,
      showDeactivation: false,
      title: title,
    );
  }
}
