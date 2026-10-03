// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/auth/views/register_view.dart
// Propósito: Pantalla de registro para nuevos clientes con validación de cédula/RUC ecuatoriano,
//            formateo de teléfono (+593), verificación humana y creación segura vía Cloud Functions.
// =========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mipetshop/core/validators/document.dart';
import 'package:mipetshop/core/validators/phone.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/l10n/app_localizations.dart';
import 'package:mipetshop/ui/features/auth/view_models/register_view_model.dart';
import 'package:mipetshop/ui/features/auth/widgets/verificacion_persona_widget.dart';
import 'package:provider/provider.dart';

/// Pantalla de auto-registro para nuevos clientes del Petshop.
///
/// Recopila los datos de identidad civil y contacto del cliente:
/// correo electrónico, contraseña con doble factor de confirmación,
/// tipo y número de documento (con algoritmo módulo 10/11 para cédula y RUC de Ecuador),
/// teléfono celular con prefijo automático `+593`, dirección domiciliaria
/// y el token de verificación de persona antes de despachar el aprovisionamiento.
class RegisterView extends StatefulWidget {
  /// Instancia inyectable del ViewModel de registro (opcional para pruebas unitarias).
  final RegisterViewModel? viewModel;

  /// Construye la vista de registro de clientes.
  const RegisterView({super.key, this.viewModel});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final RegisterViewModel _viewModel;
  bool _isLocalViewModel = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _addressController = TextEditingController();

  /// Todo celular ecuatoriano empieza por +593, de modo que el campo lo escribe
  /// solo al recibir el foco y deja el cursor detras, listo para los 9 digitos.
  final _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _isLocalViewModel = true;
      _viewModel = RegisterViewModel(
        functionsService: FunctionsService(),
        authService: FirebaseAuthService(),
        authRepository: context.read<AuthRepository>(),
      );
    }

    _viewModel.addListener(_onViewModelChanged);
    _phoneFocusNode.addListener(_prefillPhonePrefix);
  }

  /// Escribe el prefijo +593 en cuanto el campo recibe el foco, si esta vacio.
  ///
  /// No se toca el contenido si el usuario ya escribio algo: el prefijo es una
  /// ayuda de entrada, no una imposicion que pueda pisar lo tecleado.
  void _prefillPhonePrefix() {
    if (!_phoneFocusNode.hasFocus) return;
    if (_phoneController.text.isNotEmpty) return;
    _phoneController.text = kEcuadorPhonePrefix;
    _phoneController.selection = TextSelection.collapsed(
      offset: _phoneController.text.length,
    );
    _viewModel.setPhone(_phoneController.text);
  }

  void _onViewModelChanged() {
    if (_viewModel.registrationSuccess && mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _documentNumberController.dispose();
    _addressController.dispose();
    _phoneFocusNode.removeListener(_prefillPhonePrefix);
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.navRegister ?? ''),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520.0),
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return Form(
                  key: _formKey,
                  // Cada campo se valida en cuanto el usuario lo toca, de modo que el
                  // borde rojo y el texto de error aparecen mientras escribe y no sólo
                  // al enviar (N-23: recorridos que se entienden sin explicación).
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n?.navRegister ?? '',
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

                      // Banner de error diferenciado 
                      if (_viewModel.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: _viewModel.isVerificationError
                                ? Colors.amber.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(
                              color: _viewModel.isVerificationError
                                  ? Colors.amber.shade300
                                  : Colors.red.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _viewModel.isVerificationError
                                    ? Icons.security
                                    : Icons.error_outline,
                                size: 18.0,
                                color: _viewModel.isVerificationError
                                    ? Colors.amber.shade800
                                    : Colors.red.shade800,
                              ),
                              const SizedBox(width: 8.0),
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

                      // 1. Nombre Completo 
                      TextFormField(
                        key: const Key('register_fullname_field'),
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: l10n?.fullNameLabel ?? '',
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setFullName(val),
                        validator: validateFullName,
                      ),
                      const SizedBox(height: 16.0),

                      // 2. Correo Electrónico
                      TextFormField(
                        key: const Key('register_email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n?.emailLabel ?? '',
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setEmail(val),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n?.validationEmailRequired ?? '';
                          }
                          if (!val.contains('@')) {
                            return l10n?.validationEmailInvalid ?? '';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // 3. Contraseña
                      TextFormField(
                        key: const Key('register_password_field'),
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n?.passwordLabel ?? '',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setPassword(val),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return l10n?.validationPasswordRequired ?? '';
                          }
                          if (val.length < 6) {
                            return l10n?.validationPasswordMinLength ?? '';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // 4. Confirmar Contraseña
                      TextFormField(
                        key: const Key('register_confirm_password_field'),
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n?.confirmPasswordLabel ?? '',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setConfirmPassword(val),
                        validator: (val) => val != _passwordController.text
                            ? (l10n?.validationPasswordsDoNotMatch ?? '')
                            : null,
                      ),
                      const SizedBox(height: 16.0),

                      // 5. Teléfono ecuatoriano 
                      TextFormField(
                        key: const Key('register_phone_field'),
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n?.phoneLabel ?? '',
                          hintText: '+593987654321',
                          prefixIcon: const Icon(Icons.phone),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setPhone(val),
                        validator: validatePhone,
                      ),
                      const SizedBox(height: 16.0),

                      // 6. Tipo de Documento y Número 
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: DropdownButtonFormField<String>(
                              key: const Key('register_document_type_field'),
                              initialValue: _viewModel.documentType,
                              decoration: InputDecoration(
                                labelText: l10n?.documentTypeLabel ?? '',
                                border: const OutlineInputBorder(),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: DocumentTypes.cedula,
                                  child: Text(l10n?.docTypeCedula ?? ''),
                                ),
                                DropdownMenuItem(
                                  value: DocumentTypes.ruc,
                                  child: Text(l10n?.docTypeRuc ?? ''),
                                ),
                                DropdownMenuItem(
                                  value: DocumentTypes.passport,
                                  child: Text(l10n?.docTypePassport ?? ''),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  _viewModel.setDocumentType(val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            flex: 6,
                            child: TextFormField(
                              key: const Key('register_document_number_field'),
                              controller: _documentNumberController,
                              decoration: InputDecoration(
                                labelText: l10n?.documentNumberLabel ?? '',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (val) => _viewModel.setDocumentNumber(val),
                              validator: (val) => validateDocumentNumber(
                                _viewModel.documentType,
                                val,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // 7. Dirección 
                      TextFormField(
                        key: const Key('register_address_field'),
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n?.addressLabel ?? '',
                          prefixIcon: const Icon(Icons.home),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) => _viewModel.setAddress(val),
                        validator: validateAddress,
                      ),
                      const SizedBox(height: 20.0),

                      // 8. Widget de Casilla VerificacionPersona 
                      VerificacionPersonaWidget(
                        key: const Key('register_verificacion_persona'),
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

                      // 9. Botón de Acción (deshabilitado hasta cumplir verificación y validación - )
                      ElevatedButton(
                        key: const Key('register_submit_button'),
                        onPressed: _viewModel.isSubmitEnabled
                            ? () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  await _viewModel.register();
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
                            : Text(l10n?.createAccountAction ?? ''),
                      ),
                      const SizedBox(height: 16.0),

                      // Enlace a inicio de sesión
                      TextButton(
                        key: const Key('register_to_login_link'),
                        onPressed: () => context.go('/login'),
                        child: Text(
                          l10n?.alreadyHaveAccount ?? '',
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
