// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/auth/views/login_view.dart
// Propósito: Pantalla de inicio de sesión con autenticación por correo y contraseña,
//            integración de verificación humana reCAPTCHA Enterprise y manejo de errores.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/auth/view_models/login_view_model.dart';
import 'package:mipetshop/ui/features/auth/widgets/verificacion_persona_widget.dart';

/// Pantalla de inicio de sesión para todos los roles del sistema (cliente, personal y superadmin).
///
/// Proporciona el formulario de credenciales (correo y contraseña), integra el widget
/// de verificación de persona para mitigación de ataques automatizados de fuerza bruta,
/// gestiona el feedback visual ante credenciales inválidas o cuentas desactivadas
/// y redirige según el rol operativo del usuario.
class LoginView extends StatefulWidget {
  /// Instancia inyectable del ViewModel de inicio de sesión (opcional para pruebas).
  final LoginViewModel? viewModel;

  /// Construye la vista de autenticación de usuarios.
  const LoginView({super.key, this.viewModel});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel _viewModel;
  bool _isLocalViewModel = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _isLocalViewModel = true;
      _viewModel = LoginViewModel(
        authService: FirebaseAuthService(),
      );
    }
  }

  @override
  void dispose() {
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.navLogin ?? ''),
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
                  // Cada campo se valida en cuanto el usuario lo toca: el borde rojo y el
                  // texto de error aparecen mientras escribe, no solo al enviar.
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.pets, size: 64.0, color: Colors.blueAccent),
                      const SizedBox(height: 16.0),
                      Text(
                        l10n?.loginWelcomeTitle ?? '',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        l10n?.loginSubtitle ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),

                      // Banner de error con mensajería diferenciada (, , )
                      if (_viewModel.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: _viewModel.isVerificationError
                                ? Colors.amber.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: _viewModel.isVerificationError
                                  ? Colors.amber.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _viewModel.isVerificationError
                                    ? Icons.shield_outlined
                                    : Icons.error_outline,
                                color: _viewModel.isVerificationError
                                    ? Colors.amber.shade900
                                    : Colors.red.shade900,
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  _viewModel.errorMessage!,
                                  style: TextStyle(
                                    color: _viewModel.isVerificationError
                                        ? Colors.amber.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // 1. Correo Electrónico
                      TextFormField(
                        key: const Key('login_email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n?.emailLabel ?? '',
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setEmail(val),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? (l10n?.validationEmailRequired ?? '')
                            : null,
                      ),
                      const SizedBox(height: 16.0),

                      // 2. Contraseña
                      TextFormField(
                        key: const Key('login_password_field'),
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n?.passwordLabel ?? '',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setPassword(val),
                        validator: (val) => val == null || val.isEmpty
                            ? (l10n?.validationPasswordRequired ?? '')
                            : null,
                      ),
                      const SizedBox(height: 20.0),

                      // 3. Widget de Casilla VerificacionPersona 
                      VerificacionPersonaWidget(
                        key: const Key('login_verificacion_persona'),
                        isEnabled: !_viewModel.isLoading,
                        onTokenChanged: (token) {
                          _viewModel.setRecaptchaToken(token);
                        },
                        onExpired: () {
                          _viewModel.onVerificationExpired();
                        },
                        onError: () {
                          _viewModel.onVerificationError();
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // 4. Botón de Acción (deshabilitado mientras no se resuelva la casilla - )
                      ElevatedButton(
                        key: const Key('login_submit_button'),
                        onPressed: _viewModel.isSubmitEnabled
                            ? () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  await _viewModel.login();
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
                            : Text(l10n?.loginAction ?? ''),
                      ),
                      const SizedBox(height: 16.0),

                      // Enlace a recuperación de contraseña
                      TextButton(
                        key: const Key('login_to_forgot_password_link'),
                        onPressed: () => context.go('/forgot-password'),
                        child: Text(
                          l10n?.forgotPasswordLink ?? '',
                        ),
                      ),

                      // Enlace a registro
                      TextButton(
                        key: const Key('login_to_register_link'),
                        onPressed: () => context.go('/register'),
                        child: Text(
                          l10n?.dontHaveAccount ?? '',
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
