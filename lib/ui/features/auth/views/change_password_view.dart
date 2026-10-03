// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/auth/views/change_password_view.dart
// Propósito: Vista de cambio seguro de contraseña con requerimiento mandatario de re-autenticación de credenciales vigentes.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/auth/view_models/change_password_view_model.dart';

/// Pantalla para la modificación y rotación de contraseñas de cuentas de usuario.
///
/// Implementa los estándares de seguridad que exigen la re-autenticación previa
/// mediante el ingreso mandatario de la clave actual del usuario antes de autorizar
/// el reemplazo por una nueva credencial en Firebase Authentication, protegiendo
/// la sesión activa contra accesos no supervisados o secuestro de identidad.
class ChangePasswordView extends StatefulWidget {
  /// Instancia opcional del modelo de vista [ChangePasswordViewModel] para facilitar inyección en pruebas.
  final ChangePasswordViewModel? viewModel;

  /// Constructor de la vista de cambio de contraseña.
  const ChangePasswordView({super.key, this.viewModel});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

/// Estado mutable de [ChangePasswordView].
///
/// Administra el ciclo de vida del [ChangePasswordViewModel], la clave de validación del formulario
/// y los controladores individuales de texto para contraseña actual, nueva y confirmación.
class _ChangePasswordViewState extends State<ChangePasswordView> {
  /// Referencia al modelo de vista gestor de la lógica de re-autenticación y cambio.
  late final ChangePasswordViewModel _viewModel;

  /// Bandera que controla si el ViewModel fue instanciado internamente y debe ser liberado en [dispose].
  bool _isLocalViewModel = false;

  /// Clave global para la evaluación y validación de las reglas del formulario.
  final _formKey = GlobalKey<FormState>();

  /// Controlador de edición para la entrada de la contraseña vigente.
  final _currentPasswordController = TextEditingController();

  /// Controlador de edición para la entrada de la nueva credencial.
  final _newPasswordController = TextEditingController();

  /// Controlador de edición para el campo de confirmación de la nueva credencial.
  final _confirmNewPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Vinculación de la instancia del ViewModel provista o construcción interna por defecto
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _isLocalViewModel = true;
      _viewModel = ChangePasswordViewModel(
        authService: FirebaseAuthService(),
      );
    }
  }

  @override
  void dispose() {
    // Liberación del ViewModel si fue instanciado localmente por este widget
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.changePasswordAction ?? ''),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440.0),
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return Form(
                  key: _formKey,
                  // Validación proactiva en tiempo real al tipear en los campos
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.password, size: 64.0, color: Colors.blueAccent),
                      const SizedBox(height: 16.0),
                      Text(
                        l10n?.changePasswordAction ?? '',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        l10n?.appTitle ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),

                      // Banner informativo de confirmación de actualización exitosa
                      if (_viewModel.changeSuccess) ...[
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.green.shade800),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green.shade900),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  l10n?.changePasswordSuccess ?? '',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // Banner de alerta para errores de re-autenticación o comunicación
                      if (_viewModel.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.red.shade800),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade900),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  _viewModel.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // 1. Campo de entrada para Contraseña Actual (obligatoria para re-autenticación)
                      TextFormField(
                        key: const Key('change_password_current_field'),
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n?.currentPasswordLabel ?? '',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setCurrentPassword(val),
                        validator: (val) => val == null || val.isEmpty
                            ? (l10n?.validationCurrentPasswordRequired ?? '')
                            : null,
                      ),
                      const SizedBox(height: 16.0),

                      // 2. Campo de entrada para la Nueva Contraseña (mínimo 6 caracteres)
                      TextFormField(
                        key: const Key('change_password_new_field'),
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n?.newPasswordLabel ?? '',
                          prefixIcon: const Icon(Icons.lock_reset),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setNewPassword(val),
                        validator: (val) => val == null || val.length < 6
                            ? (l10n?.validationPasswordMinLength ?? '')
                            : null,
                      ),
                      const SizedBox(height: 16.0),

                      // 3. Campo de entrada para Confirmar Nueva Contraseña
                      TextFormField(
                        key: const Key('change_password_confirm_field'),
                        controller: _confirmNewPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n?.confirmNewPasswordLabel ?? '',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setConfirmNewPassword(val),
                        validator: (val) => val != _newPasswordController.text
                            ? (l10n?.validationPasswordsDoNotMatch ?? '')
                            : null,
                      ),
                      const SizedBox(height: 24.0),

                      // 4. Botón de ejecución del cambio (inactivo si faltan datos requeridos)
                      ElevatedButton(
                        key: const Key('change_password_submit_button'),
                        onPressed: _viewModel.isSubmitEnabled
                            ? () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  final ok = await _viewModel.changePassword();
                                  if (ok) {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmNewPasswordController.clear();
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _viewModel.isLoading
                            ? const SizedBox(
                                height: 20.0,
                                width: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n?.changePasswordAction ?? '',
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
