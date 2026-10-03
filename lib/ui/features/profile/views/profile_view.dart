// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/profile/views/profile_view.dart
// Propósito: Pantalla de consulta de perfil de usuario con visualización de avatar en memoria, navegación a edición, cambio de credenciales y desactivación de cuenta.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/features/profile/view_models/account_deactivation_view_model.dart';
import 'package:mipetshop/ui/features/profile/view_models/profile_view_model.dart';
import 'package:mipetshop/ui/features/profile/views/account_deactivation_dialog.dart';
import 'package:mipetshop/ui/features/profile/views/profile_edit_view.dart';
import 'package:provider/provider.dart';

/// Vista de solo lectura para la inspección general del perfil de usuario y control de cuenta.
///
/// Funcionalidades integradas:
/// - Muestra los datos personales e identificadores oficiales registrados en la plataforma.
/// - Avatar de usuario descargado en memoria mediante bytes autenticados desde Cloud Storage sin enlaces públicos expuestos.
/// - Enlaces de navegación rápida hacia la pantalla de edición de datos personales ([ProfileEditView])
///   y hacia el formulario de actualización de clave de acceso.
/// - Control de baja voluntaria accesible exclusivamente para usuarios con rol de cliente (`CLIENT`),
///   apoyado en el diálogo modal [AccountDeactivationDialog].
class ProfileView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de los datos de perfil y la descarga del avatar.
  final ProfileViewModel viewModel;

  /// Retrollamada opcional personalizada al presionar el botón de editar.
  final VoidCallback? onEditPressed;

  /// Determina si se despliega el botón de desactivación de cuenta (por defecto `true`).
  final bool showDeactivation;

  /// Título personalizado para la barra de navegación superior.
  final String? title;

  /// Constructor de la vista de perfil de usuario.
  const ProfileView({
    super.key,
    required this.viewModel,
    this.onEditPressed,
    this.showDeactivation = true,
    this.title,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? (l10n?.navProfile ?? '')),
        actions: [
          TappableArea(
            semanticLabel: l10n?.navSignOut ?? '',
            tooltip: l10n?.navSignOut ?? '',
            onTap: () async {
              try {
                final authRepo = Provider.of<AuthRepository?>(context, listen: false);
                await authRepo?.signOut();
              } catch (_) {}
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = viewModel.profile;
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.noProfileData ?? '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            );
          }

          return ResponsiveLayout(
            builder: (context, breakpoint) {
              final horizontalPadding = breakpoint.isCompact ? 16.0 : 32.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, theme, l10n),
                        const SizedBox(height: 24.0),
                        _buildDetailsCard(context, theme, l10n),
                        const SizedBox(height: 24.0),
                        _buildActionButtons(context, l10n),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    final profile = viewModel.profile;
    final photoBytes = viewModel.photoBytes;

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 54.0,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage:
                  photoBytes != null ? MemoryImage(photoBytes) : null,
              child: photoBytes == null
                  ? Icon(
                      Icons.person,
                      size: 64.0,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(height: 16.0),
            Text(
              profile?.fullName ?? '',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            Text(
              profile?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (profile != null && profile.role != 'CLIENT') ...[
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  profile.role,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    final profile = viewModel.profile;

    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.profileDetailsTitle ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24.0),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: l10n?.phoneLabel ?? '',
              value: profile?.phone ?? '',
              theme: theme,
            ),
            const SizedBox(height: 16.0),
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: l10n?.documentTypeLabel ?? '',
              value: '${profile?.documentType}: ${profile?.documentNumber}',
              theme: theme,
            ),
            const SizedBox(height: 16.0),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: l10n?.addressLabel ?? '',
              value: profile?.address ?? '',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22.0, color: theme.colorScheme.primary),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations? l10n) {
    final editText = l10n?.editProfileAction ?? '';
    final changePasswordText = l10n?.changePasswordAction ?? '';
    final deactivateText = l10n?.accountDeactivationTitle ?? '';

    return Column(
      children: [
        TappableArea(
          semanticLabel: editText,
          tooltip: editText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: () {
            if (onEditPressed != null) {
              onEditPressed!();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ProfileEditView(viewModel: viewModel),
                ),
              );
            }
          },
          child: ElevatedButton.icon(
            onPressed: () {
              if (onEditPressed != null) {
                onEditPressed!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ProfileEditView(viewModel: viewModel),
                  ),
                );
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: Text(editText),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48.0),
            ),
          ),
        ),
        const SizedBox(height: 12.0),
        TappableArea(
          key: const ValueKey('change_password_profile_button'),
          semanticLabel: changePasswordText,
          tooltip: changePasswordText,
          minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
          onTap: () => context.go('/change-password'),
          child: OutlinedButton.icon(
            onPressed: () => context.go('/change-password'),
            icon: const Icon(Icons.lock_reset_outlined),
            label: Text(changePasswordText),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48.0),
            ),
          ),
        ),
        if (showDeactivation && viewModel.profile?.role == 'CLIENT') ...[
          const SizedBox(height: 12.0),
          TappableArea(
            semanticLabel: deactivateText,
            tooltip: deactivateText,
            minConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
            onTap: () => _openDeactivation(context),
            child: OutlinedButton.icon(
              key: const ValueKey('open_account_deactivation_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                minimumSize: const Size(double.infinity, 48.0),
              ),
              onPressed: () => _openDeactivation(context),
              icon: const Icon(Icons.person_off_outlined),
              label: Text(deactivateText),
            ),
          ),
        ],
      ],
    );
  }

  void _openDeactivation(BuildContext context) {
    final functions = Provider.of<FunctionsService?>(context, listen: false) ?? FunctionsService();
    final deactVm = AccountDeactivationViewModel(functionsService: functions);
    AccountDeactivationDialog.show(
      context,
      viewModel: deactVm,
      onDeactivated: () {
        final authRepo = Provider.of<AuthRepository?>(context, listen: false);
        authRepo?.signOut();
      },
    );
  }
}
