// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/governance/views/account_management_view.dart
// Propósito: Vista de gobierno y administración de usuarios, asignación de roles y control de ciclo de vida de cuentas del sistema.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mipetshop/core/widgets/tappable_area.dart';
import 'package:mipetshop/domain/models/user_profile.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/core/breakpoints.dart';
import 'package:mipetshop/ui/core/widgets/status_badge.dart';
import 'package:mipetshop/ui/features/admin/governance/view_models/governance_view_model.dart';

/// Pestaña de administración de cuentas de usuario y control de accesos del petshop.
///
/// Implementa los requerimientos de gobernanza y control interno:
/// - Listado y filtrado de usuarios por roles de seguridad (`CLIENT`, `STAFF`, `VET`, `ADMIN`).
/// - Creación de colaboradores con generación segura de enlace de invitación o restablecimiento de contraseña.
/// - Cambio y reasignación de roles operativos con validación de privilegios de `SUPERADMIN`.
/// - Desactivación lógica, reactivación preventiva y baja permanente de cuentas de personal.
/// - Diálogos de confirmación crítica y retroalimentación mediante `SnackBar`.
class AccountManagementView extends StatelessWidget {
  /// Modelo de vista reactivo gestor de las operaciones de gobernanza y cuentas.
  final GovernanceViewModel viewModel;

  /// Constructor de la vista de gestión de cuentas.
  const AccountManagementView({
    super.key,
    required this.viewModel,
  });

  static String _docLabel(String type, String num) => '$type: $num';


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        // Disparar diálogo de enlace generado si existe
        if (viewModel.lastGeneratedLink != null) {
          final link = viewModel.lastGeneratedLink!;
          final isCreation = viewModel.linkDialogTitle == 'CUENTA_CREADA';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (viewModel.lastGeneratedLink != null) {
              viewModel.clearGeneratedLink();
              _showGeneratedLinkDialog(context, link, isCreation, l10n);
            }
          });
        }

        if (viewModel.actionSuccessMessage != null) {
          final msg = viewModel.actionSuccessMessage!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
            );
            viewModel.clearActionFeedback();
          });
        }

        if (viewModel.actionErrorMessage != null) {
          final msg = viewModel.actionFailure?.toLocalizedMessage(l10n ?? AppLocalizations.of(context)!) ??
              viewModel.actionErrorMessage!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
            );
            viewModel.clearActionFeedback();
          });
        }

        return ResponsiveLayout(
          builder: (context, breakpoint) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(breakpoint.isCompact ? 12.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra de herramientas: búsqueda, filtro de rol y botón de creación
                  _buildToolbar(context, viewModel, l10n, breakpoint),
                  const SizedBox(height: 16.0),

                  if (viewModel.isLoadingUsers)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (viewModel.usersError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              viewModel.usersFailure?.toLocalizedMessage(l10n ?? AppLocalizations.of(context)!) ??
                                  viewModel.usersError!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                            const SizedBox(height: 8.0),
                            ElevatedButton(
                              onPressed: viewModel.loadUsers,
                              child: Text(l10n?.govButtonRefresh ?? ''),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (viewModel.filteredUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          l10n?.govNoAccountsFound ?? '',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                    )
                  else
                    // La tabla de cinco columnas sólo cabe en expanded. En
                    // medium el desplazamiento horizontal recortaba la columna
                    // de Acciones fuera de pantalla sin ninguna señal visible,
                    // y el personal no podía alcanzar los botones. Las tarjetas
                    // sí muestran las acciones completas a cualquier ancho.
                    breakpoint.isExpanded
                        ? _buildUserTable(context, viewModel, l10n)
                        : _buildUserCards(context, viewModel, l10n),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    GovernanceViewModel viewModel,
    AppLocalizations? l10n,
    AppBreakpoint breakpoint,
  ) {
    final searchField = TextFormField(
      key: const Key('account_search_input'),
      decoration: InputDecoration(
        hintText: l10n?.govSearchPlaceholder ?? '',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      ),
      initialValue: viewModel.searchQuery,
      onChanged: viewModel.setSearchQuery,
    );

    final roleFilterDropdown = DropdownButtonFormField<String>(
      key: const Key('account_role_filter'),
      initialValue: viewModel.roleFilter,
      decoration: InputDecoration(
        labelText: l10n?.govColumnRole ?? '',
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      ),
      items: [
        DropdownMenuItem(value: 'ALL', child: Text(l10n?.govRoleFilterAll ?? '')),
        DropdownMenuItem(value: 'SUPERADMIN', child: Text(l10n?.govRoleSuperAdmin ?? '')),
        DropdownMenuItem(value: 'ADMIN', child: Text(l10n?.govRoleAdmin ?? '')),
        DropdownMenuItem(value: 'CLIENT', child: Text(l10n?.govRoleClient ?? '')),
      ],
      onChanged: (val) {
        if (val != null) viewModel.setRoleFilter(val);
      },
    );

    final createButton = SizedBox(
      height: 48.0,
      child: ElevatedButton.icon(
        key: const Key('create_account_button'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(160.0, 48.0),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: viewModel.isActionLoading
            ? null
            : () => _showCreateAccountDialog(context, viewModel, l10n),
        icon: const Icon(Icons.person_add),
        label: Text(l10n?.govCreateAccountButton ?? ''),
      ),
    );

    if (breakpoint.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12.0),
          roleFilterDropdown,
          const SizedBox(height: 12.0),
          createButton,
        ],
      );
    }

    if (breakpoint.isMedium) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(child: roleFilterDropdown),
              const SizedBox(width: 12.0),
              createButton,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: searchField),
        const SizedBox(width: 12.0),
        Expanded(flex: 2, child: roleFilterDropdown),
        const SizedBox(width: 12.0),
        createButton,
      ],
    );
  }

  Widget _buildUserCards(
    BuildContext context,
    GovernanceViewModel viewModel,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: viewModel.filteredUsers.map((user) {
        final isSuperAdmin = user.role == 'SUPERADMIN';
        return Card(
          key: Key('user_card_${user.uid}'),
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                    ),
                    _buildStatusChip(context, user.status, l10n),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(user.email, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                const SizedBox(height: 4.0),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    _buildRoleChip(context, user.role, l10n),
                    if (user.documentNumber.isNotEmpty)
                      Text(_docLabel(user.documentType, user.documentNumber)),
                  ],
                ),
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(user.phone),
                ],
                const Divider(height: 20.0),
                // INVARIANTE CA-AD-19, CA-AD-36, CF-11:
                // Si es SUPERADMIN, NO renderizar botones de acción.
                if (isSuperAdmin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Chip(
                      key: Key('superadmin_immutable_chip_${user.uid}'),
                      avatar: const Icon(Icons.shield, size: 16.0),
                      label: Text(l10n?.govSuperAdminImmutableBadge ?? ''),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  _buildActionButtons(context, viewModel, user, l10n, isCompact: true),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserTable(
    BuildContext context,
    GovernanceViewModel viewModel,
    AppLocalizations? l10n,
  ) {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          // Sin acotar las celdas de texto, el correo y el nombre estiraban la
          // tabla mas alla del ancho util y empujaban la columna de Acciones
          // fuera de pantalla: los botones existian pero nadie podia pulsarlos.
          columnSpacing: 24.0,
          columns: [
            DataColumn(label: Text(l10n?.govColumnName ?? '')),
            DataColumn(label: Text(l10n?.govColumnEmail ?? '')),
            DataColumn(label: Text(l10n?.govColumnRole ?? '')),
            DataColumn(label: Text(l10n?.govColumnStatus ?? '')),
            DataColumn(label: Text(l10n?.govColumnActions ?? '')),
          ],
          rows: viewModel.filteredUsers.map((user) {
            final isSuperAdmin = user.role == 'SUPERADMIN';
            return DataRow(
              key: ValueKey('user_row_${user.uid}'),
              cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (user.documentNumber.isNotEmpty)
                          Text(
                            '${user.documentType}: ${user.documentNumber}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.0, color: Theme.of(context).colorScheme.outline),
                          ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220.0),
                    child: Text(user.email, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(_buildRoleChip(context, user.role, l10n)),
                DataCell(_buildStatusChip(context, user.status, l10n)),
                DataCell(
                  // INVARIANTE CA-AD-19, CA-AD-36, CF-11:
                  // Para SUPERADMIN NUNCA se ofrecen botones de acción.
                  isSuperAdmin
                      ? Chip(
                          key: Key('superadmin_immutable_chip_${user.uid}'),
                          avatar: const Icon(Icons.shield, size: 16.0),
                          label: Text(l10n?.govSuperAdminImmutableBadge ?? ''),
                          visualDensity: VisualDensity.compact,
                        )
                      : _buildActionButtons(context, viewModel, user, l10n, isCompact: false),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, String role, AppLocalizations? l10n) {
    String label;
    Color color;

    switch (role) {
      case 'SUPERADMIN':
        label = l10n?.govRoleSuperAdmin ?? '';
        color = Colors.deepPurple;
        break;
      case 'ADMIN':
        label = l10n?.govRoleAdmin ?? '';
        color = Colors.indigo;
        break;
      default:
        label = l10n?.govRoleClient ?? '';
        color = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status, AppLocalizations? l10n) {
    switch (status) {
      case 'ACTIVE':
        return StatusBadge.success(text: l10n?.govStatusActive ?? '');
      case 'DEACTIVATED':
        return StatusBadge.warning(text: l10n?.govStatusDeactivated ?? '');
      case 'DELETED':
        return StatusBadge.danger(text: l10n?.govStatusDeleted ?? '');
      default:
        return StatusBadge.neutral(text: status);
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    GovernanceViewModel viewModel,
    UserProfile user,
    AppLocalizations? l10n, {
    required bool isCompact,
  }) {
    final canDeactivate = user.status == 'ACTIVE';
    // El panel sabía desactivar y no sabía deshacerlo: una cuenta desactivada
    // quedaba sin retorno pese a existir la callable en el backend.
    final canReactivate = user.status == 'DEACTIVATED';
    final canDeleteStaff = user.role == 'ADMIN' && user.status != 'DELETED';

    final editBtn = TappableArea(
      key: Key('edit_identity_${user.uid}'),
      tooltip: l10n?.govActionEditIdentity ?? '',
      semanticLabel: l10n?.govActionEditIdentity ?? '',
      onTap: () => _showEditIdentityDialog(context, viewModel, user, l10n),
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.edit, size: 20.0),
      ),
    );

    final resetBtn = TappableArea(
      key: Key('reset_password_${user.uid}'),
      tooltip: l10n?.govActionResetPassword ?? '',
      semanticLabel: l10n?.govActionResetPassword ?? '',
      onTap: () => viewModel.resetUserPassword(user.uid),
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.lock_reset, size: 20.0),
      ),
    );

    final deactivateBtn = canDeactivate
        ? TappableArea(
            key: Key('deactivate_account_${user.uid}'),
            tooltip: l10n?.govActionDeactivate ?? '',
            semanticLabel: l10n?.govActionDeactivate ?? '',
            onTap: () => _showDeactivateConfirmDialog(context, viewModel, user, l10n),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.block, size: 20.0, color: Colors.orange),
            ),
          )
        : const SizedBox.shrink();

    final reactivateBtn = canReactivate
        ? TappableArea(
            key: Key('reactivate_account_${user.uid}'),
            tooltip: l10n?.govActionReactivate ?? '',
            semanticLabel: l10n?.govActionReactivate ?? '',
            onTap: () => _showReactivateConfirmDialog(context, viewModel, user, l10n),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.check_circle_outline, size: 20.0, color: Colors.green),
            ),
          )
        : const SizedBox.shrink();

    final deleteStaffBtn = canDeleteStaff
        ? TappableArea(
            key: Key('delete_staff_${user.uid}'),
            tooltip: l10n?.govActionDeleteStaff ?? '',
            semanticLabel: l10n?.govActionDeleteStaff ?? '',
            onTap: () => _showDeleteStaffConfirmDialog(context, viewModel, user, l10n),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.person_remove, size: 20.0, color: Colors.red),
            ),
          )
        : const SizedBox.shrink();

    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      alignment: isCompact ? WrapAlignment.end : WrapAlignment.start,
      children: [
        editBtn,
        resetBtn,
        if (canDeactivate) deactivateBtn,
        if (canReactivate) reactivateBtn,
        if (canDeleteStaff) deleteStaffBtn,
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DIÁLOGOS
  // ────────────────────────────────────────────────────────────────────────────

  void _showCreateAccountDialog(
    BuildContext context,
    GovernanceViewModel viewModel,
    AppLocalizations? l10n,
  ) {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final docNumCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String selectedRole = 'CLIENT';
    String selectedDocType = 'CEDULA';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n?.govCreateAccountDialogTitle ?? ''),
              content: SizedBox(
                width: 480.0,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const Key('create_account_email'),
                          controller: emailCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldEmail ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.govValidationRequired ?? '';
                            }
                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(val.trim())) {
                              return l10n?.govValidationInvalidEmail ?? '';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12.0),
                        TextFormField(
                          key: const Key('create_account_name'),
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldFullName ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.govValidationRequired ?? '';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<String>(
                          key: const Key('create_account_role'),
                          initialValue: selectedRole,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldRole ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'CLIENT',
                              child: Text(l10n?.govRoleClient ?? ''),
                            ),
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Text(l10n?.govRoleAdmin ?? ''),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => selectedRole = val);
                          },
                        ),
                        const SizedBox(height: 12.0),
                        TextFormField(
                          key: const Key('create_account_phone'),
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldPhone ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.govValidationRequired ?? '';
                            }
                            if (!RegExp(r'^\+593\d{9}$').hasMatch(val.trim())) {
                              return l10n?.govValidationInvalidPhone ?? '';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                key: const Key('create_account_doctype'),
                                isExpanded: true,
                                initialValue: selectedDocType,
                                decoration: InputDecoration(
                                  labelText: l10n?.govFieldDocumentType ?? '',
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'CEDULA', child: Text(l10n?.docTypeCedula ?? '')),
                                  DropdownMenuItem(value: 'RUC', child: Text(l10n?.docTypeRuc ?? '')),
                                  DropdownMenuItem(value: 'PASAPORTE', child: Text(l10n?.docTypePassport ?? '')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedDocType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                key: const Key('create_account_docnum'),
                                controller: docNumCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n?.govFieldDocumentNumber ?? '',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return l10n?.govValidationRequired ?? '';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        TextFormField(
                          key: const Key('create_account_address'),
                          controller: addressCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldAddress ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.govValidationRequired ?? '';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('create_account_cancel_button'),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(l10n?.govButtonCancel ?? ''),
                ),
                ElevatedButton(
                  key: const Key('create_account_submit_button'),
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.of(dialogCtx).pop();
                    await viewModel.createUserAccount(
                      email: emailCtrl.text,
                      fullName: nameCtrl.text,
                      role: selectedRole,
                      phone: phoneCtrl.text,
                      documentType: selectedDocType,
                      documentNumber: docNumCtrl.text,
                      address: addressCtrl.text,
                    );
                  },
                  child: Text(l10n?.govButtonCreate ?? ''),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditIdentityDialog(
    BuildContext context,
    GovernanceViewModel viewModel,
    UserProfile user,
    AppLocalizations? l10n,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone);
    final docNumCtrl = TextEditingController(text: user.documentNumber);
    final addressCtrl = TextEditingController(text: user.address);
    String selectedDocType = user.documentType.isNotEmpty ? user.documentType : 'CEDULA';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n?.govEditIdentityDialogTitle ?? ''),
              content: SizedBox(
                width: 480.0,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // INVARIANTE CF-08: El correo es PERMANENTEMENTE DE SÓLO LECTURA.
                        TextFormField(
                          key: const Key('edit_identity_email_readonly'),
                          initialValue: user.email,
                          readOnly: true,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldEmail ?? '',
                            border: const OutlineInputBorder(),
                            helperText: l10n?.govEmailReadOnlyNotice ?? '',
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          key: const Key('edit_identity_name'),
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldFullName ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.govValidationRequired ?? '';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12.0),
                        TextFormField(
                          key: const Key('edit_identity_phone'),
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldPhone ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.govValidationRequired ?? '';
                            }
                            if (!RegExp(r'^\+593\d{9}$').hasMatch(val.trim())) {
                              return l10n?.govValidationInvalidPhone ?? '';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                key: const Key('edit_identity_doctype'),
                                isExpanded: true,
                                initialValue: selectedDocType,
                                decoration: InputDecoration(
                                  labelText: l10n?.govFieldDocumentType ?? '',
                                  border: const OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'CEDULA', child: Text(l10n?.docTypeCedula ?? '')),
                                  DropdownMenuItem(value: 'RUC', child: Text(l10n?.docTypeRuc ?? '')),
                                  DropdownMenuItem(value: 'PASAPORTE', child: Text(l10n?.docTypePassport ?? '')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedDocType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                key: const Key('edit_identity_docnum'),
                                controller: docNumCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n?.govFieldDocumentNumber ?? '',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return l10n?.govValidationRequired ?? '';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        TextFormField(
                          key: const Key('edit_identity_address'),
                          controller: addressCtrl,
                          decoration: InputDecoration(
                            labelText: l10n?.govFieldAddress ?? '',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.govValidationRequired ?? '';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('edit_identity_cancel_button'),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(l10n?.govButtonCancel ?? ''),
                ),
                ElevatedButton(
                  key: const Key('edit_identity_submit_button'),
                  onPressed: () async {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.of(dialogCtx).pop();
                    await viewModel.updateUserIdentity(
                      targetUid: user.uid,
                      fullName: nameCtrl.text,
                      phone: phoneCtrl.text,
                      documentType: selectedDocType,
                      documentNumber: docNumCtrl.text,
                      address: addressCtrl.text,
                    );
                  },
                  child: Text(l10n?.govButtonSave ?? ''),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGeneratedLinkDialog(
    BuildContext context,
    String link,
    bool isCreation,
    AppLocalizations? l10n,
  ) {
    final title = isCreation
        ? (l10n?.govLinkDialogTitleCreated ?? '')
        : (l10n?.govLinkDialogTitleReset ?? '');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 460.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n?.govLinkDialogNotice ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: SelectableText(
                    link,
                    key: const Key('generated_link_text'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    key: const Key('copy_link_button'),
                    icon: const Icon(Icons.copy, size: 18.0),
                    label: Text(l10n?.govButtonCopyLink ?? ''),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.govLinkCopiedSnackbar ?? ''),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              key: const Key('close_link_dialog_button'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n?.govButtonClose ?? ''),
            ),
          ],
        );
      },
    );
  }

  void _showDeactivateConfirmDialog(
    BuildContext context,
    GovernanceViewModel viewModel,
    UserProfile user,
    AppLocalizations? l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(l10n?.govConfirmDeactivateTitle ?? ''),
          content: Text(
            l10n?.govConfirmDeactivateMessage(user.fullName) ?? '',
          ),
          actions: [
            TextButton(
              key: const Key('confirm_deactivate_dialog_cancel'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n?.govButtonCancel ?? ''),
            ),
            ElevatedButton(
              key: const Key('confirm_deactivate_dialog_button'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await viewModel.deactivateUserAccount(user.uid);
              },
              child: Text(
                l10n?.govButtonConfirmDeactivate ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReactivateConfirmDialog(
    BuildContext context,
    GovernanceViewModel viewModel,
    UserProfile user,
    AppLocalizations? l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(l10n?.govConfirmReactivateTitle ?? ''),
          content: Text(
            l10n?.govConfirmReactivateMessage(user.fullName) ?? '',
          ),
          actions: [
            TextButton(
              key: const Key('confirm_reactivate_dialog_cancel'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n?.govButtonCancel ?? ''),
            ),
            ElevatedButton(
              key: const Key('confirm_reactivate_dialog_button'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await viewModel.reactivateUserAccount(user.uid);
              },
              child: Text(
                l10n?.govButtonConfirmReactivate ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteStaffConfirmDialog(
    BuildContext context,
    GovernanceViewModel viewModel,
    UserProfile user,
    AppLocalizations? l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(l10n?.govConfirmDeleteStaffTitle ?? ''),
          content: Text(
            l10n?.govConfirmDeleteStaffMessage(user.fullName) ?? '',
          ),
          actions: [
            TextButton(
              key: const Key('confirm_delete_staff_dialog_cancel'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l10n?.govButtonCancel ?? ''),
            ),
            ElevatedButton(
              key: const Key('confirm_delete_staff_dialog_button'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await viewModel.deleteStaffAccount(user.uid);
              },
              child: Text(
                l10n?.govButtonConfirmDelete ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
