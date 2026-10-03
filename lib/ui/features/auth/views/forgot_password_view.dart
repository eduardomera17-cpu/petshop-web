// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/auth/views/forgot_password_view.dart
// Propósito: Vista de solicitud de restablecimiento de contraseña con protección reCAPTCHA/Turnstile y flujo de confirmación genérica anti-enumeración.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/auth/view_models/forgot_password_view_model.dart';
import 'package:mipetshop/ui/features/auth/widgets/verificacion_persona_widget.dart';

/// Interfaz gráfica de usuario para la recuperación y restablecimiento de credenciales de acceso.
///
/// Implementa un formulario responsivo y seguro que solicita la dirección de correo
/// institucional/personal del usuario, valida su sintaxis y requiere la resolución de un desafío
/// de verificación humana (reCAPTCHA / Cloudflare Turnstile) mediante [VerificacionPersonaWidget]
/// antes de autorizar el envío de las instrucciones.
///
/// Conforme a las directrices de ciberseguridad y privacidad (OWASP ASVS), tras la emisión
/// de la solicitud presenta un mensaje de confirmación neutro e indistinto, evitando revelar
/// si el correo proporcionado se encuentra registrado en el sistema.
class ForgotPasswordView extends StatefulWidget {
  /// Instancia opcional del modelo de vista [ForgotPasswordViewModel] para inyección en pruebas unitarias/de widgets.
  final ForgotPasswordViewModel? viewModel;

  /// Constructor de la pantalla de recuperación de contraseña.
  const ForgotPasswordView({super.key, this.viewModel});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

/// Estado mutable de [ForgotPasswordView].
///
/// Gestiona el ciclo de vida del [ForgotPasswordViewModel], el controlador de texto
/// para el correo electrónico y la clave global de validación del formulario.
class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  /// Referencia al modelo de vista que gestiona el estado y la lógica de negocio.
  late final ForgotPasswordViewModel _viewModel;

  /// Bandera indicadora de propiedad local del ViewModel para su liberación controlada en [dispose].
  bool _isLocalViewModel = false;

  /// Identificador global único del formulario para desencadenar validaciones estructurales.
  final _formKey = GlobalKey<FormState>();

  /// Controlador de edición para el campo de entrada del correo electrónico.
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel inyectado externamente o instanciación local por defecto
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _isLocalViewModel = true;
      _viewModel = ForgotPasswordViewModel(
        authService: FirebaseAuthService(),
      );
    }
  }

  @override
  void dispose() {
    // Si el ViewModel se instanció localmente, se liberan sus recursos y listeners asociados
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.navForgotPassword ?? ''),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440.0),
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                // Caso exitoso: Confirmación genérica indistinta para mitigar enumeración de cuentas
                if (_viewModel.emailSentSuccess) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 64.0,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        l10n?.forgotPasswordInstructionsSentTitle ?? '',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        l10n?.forgotPasswordConfirmation ?? '',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        key: const Key('forgot_password_back_to_login_button'),
                        onPressed: () => context.go('/login'),
                        child: Text(l10n?.backToLogin ?? ''),
                      ),
                    ],
                  );
                }

                // Formulario interactivo de solicitud de restablecimiento
                return Form(
                  key: _formKey,
                  // Validación proactiva en tiempo real al interactuar el usuario
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_reset, size: 64.0, color: Colors.blueAccent),
                      const SizedBox(height: 16.0),
                      Text(
                        l10n?.resetPasswordTitle ?? '',
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

                      // Banner de retroalimentación visual para errores de verificación o de servicio
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

                      // 1. Campo de entrada para el Correo Electrónico
                      TextFormField(
                        key: const Key('forgot_password_email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n?.emailLabel ?? '',
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setEmail(val),
                        validator: (val) => val == null || !val.contains('@')
                            ? (l10n?.validationEmailInvalid ?? '')
                            : null,
                      ),
                      const SizedBox(height: 20.0),

                      // 2. Widget de verificación humana (reCAPTCHA / Turnstile)
                      VerificacionPersonaWidget(
                        key: const Key('forgot_password_verificacion_persona'),
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

                      // 3. Botón de confirmación para emisión de instrucciones
                      ElevatedButton(
                        key: const Key('forgot_password_submit_button'),
                        onPressed: _viewModel.isSubmitEnabled
                            ? () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  await _viewModel.sendPasswordReset();
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
                                l10n?.sendResetInstructionsAction ?? '',
                              ),
                      ),
                      const SizedBox(height: 16.0),

                      // Enlace de retorno seguro a la pantalla de inicio de sesión
                      TextButton(
                        key: const Key('forgot_password_to_login_link'),
                        onPressed: () => context.go('/login'),
                        child: Text(
                          l10n?.backToLogin ?? '',
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
