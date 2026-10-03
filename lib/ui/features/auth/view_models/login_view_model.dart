// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: login_view_model.dart
// Propósito: ViewModel para la pantalla de inicio de sesión con validación de credenciales, control de reCAPTCHA y manejo diferenciado de fallos.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';

/// ViewModel para la pantalla de inicio de sesión (AppFlow §2.2).
///
/// Gestiona el estado reactivo del formulario de autenticación:
/// - Bloqueo de envío hasta que el usuario resuelva satisfactoriamente el desafío de seguridad (reCAPTCHA).
/// - Diferenciación estricta de fallos: expiración o caída del captcha frente a credenciales inválidas.
/// - Mensaje genérico de credenciales incorrectas para prevenir enumeración de cuentas.
/// - Preservación de campos ingresados ante fallos no críticos.
class LoginViewModel extends ChangeNotifier {
  /// Servicio de autenticación con Firebase.
  final FirebaseAuthService authService;

  /// Constructor con inyección del servicio de autenticación.
  LoginViewModel({
    required this.authService,
  });

  FirebaseAuthService get _authService => authService;

  String _email = '';
  String _password = '';
  String? _recaptchaToken;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerificationError = false;
  bool _loginSuccess = false;

  /// Correo electrónico ingresado en el formulario.
  String get email => _email;

  /// Contraseña ingresada en el formulario.
  String get password => _password;

  /// Token emitido por el servicio de verificación reCAPTCHA.
  String? get recaptchaToken => _recaptchaToken;

  /// Indica si hay una operación de autenticación en curso.
  bool get isLoading => _isLoading;

  /// Mensaje de error formateado para ser presentado en la interfaz gráfica.
  String? get errorMessage => _errorMessage;

  /// Indica si el error actual corresponde a la verificación de persona (reCAPTCHA).
  bool get isVerificationError => _isVerificationError;

  /// Bandera que señala si el proceso de login concluyó exitosamente.
  bool get loginSuccess => _loginSuccess;

  /// Determina si el botón de inicio de sesión debe estar habilitado.
  ///
  /// Requiere que no haya carga en curso, que el token reCAPTCHA esté presente y válido,
  /// y que tanto el correo como la contraseña contengan caracteres.
  bool get isSubmitEnabled {
    if (_isLoading) return false;
    if (_recaptchaToken == null || _recaptchaToken!.trim().isEmpty) return false;
    return _email.trim().isNotEmpty && _password.isNotEmpty;
  }

  /// Actualiza el correo electrónico y limpia mensajes de error previos.
  void setEmail(String value) {
    _email = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza la contraseña y limpia mensajes de error previos.
  void setPassword(String value) {
    _password = value;
    _clearError();
    notifyListeners();
  }

  /// Establece el token de verificación emitido por el widget de reCAPTCHA.
  void setRecaptchaToken(String? token) {
    _recaptchaToken = token;
    _clearError();
    notifyListeners();
  }

  /// Notifica que el token de verificación ha expirado y requiere nueva resolución.
  void onVerificationExpired() {
    _recaptchaToken = null;
    _isVerificationError = true;
    _errorMessage = 'La verificación de seguridad ha caducado. Intenta de nuevo.';
    notifyListeners();
  }

  /// Notifica un fallo de red o indisponibilidad del servicio reCAPTCHA.
  void onVerificationError() {
    _recaptchaToken = null;
    _isVerificationError = true;
    _errorMessage = 'El servicio de verificación de seguridad no está disponible momentáneamente.';
    notifyListeners();
  }

  /// Limpia los estados de error activos del formulario.
  void _clearError() {
    _errorMessage = null;
    _isVerificationError = false;
  }

  /// Ejecuta el proceso de inicio de sesión con Firebase Authentication.
  ///
  /// Valida preliminarmente la existencia del token reCAPTCHA y las credenciales.
  /// Si ocurre un fallo, mapea el código a un mensaje institucional amigable:
  /// - Fallos de verificación: restablece el token para forzar nueva comprobación humana.
  /// - Cuentas inactivas: notifica restricción administrativa.
  /// - Error de credenciales: muestra mensaje genérico para evitar enumeración de usuarios.
  Future<bool> login() async {
    // 1. Verificación previa obligatoria 
    if (_recaptchaToken == null || _recaptchaToken!.trim().isEmpty) {
      _isVerificationError = true;
      _errorMessage = 'Es obligatorio completar la verificación de seguridad.';
      notifyListeners();
      return false;
    }

    if (_email.trim().isEmpty || _password.isEmpty) {
      _isVerificationError = false;
      _errorMessage = 'Por favor ingresa tu correo y contraseña.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // El token de casilla no viaja a ninguna callable (AppFlow §2.2)
      final res = await _authService.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      _isLoading = false;

      if (res.isErr) {
        final failure = res.failureOrNull!;
        // Distinguir error de verificación de error de credenciales 
        if (failure.code == 'VERIFICATION_FAILED' ||
            failure.code == 'VERIFICATION_REQUIRED' ||
            failure.code == 'VERIFICATION_UNAVAILABLE') {
          _isVerificationError = true;
          _recaptchaToken = null; // Reiniciar casilla
          _errorMessage = failure.code == 'VERIFICATION_UNAVAILABLE'
              ? 'El servicio de verificación de seguridad no está disponible momentáneamente.'
              : 'La verificación de seguridad no fue superada o ha caducado. Intenta de nuevo.';
        } else if (failure.code == 'ACCOUNT_NOT_ACTIVE') {
          _isVerificationError = false;
          _errorMessage = 'Tu cuenta se encuentra inactiva o deshabilitada. Contacta al soporte.';
        } else {
          // : Mensaje genérico para credenciales incorrectas
          _isVerificationError = false;
          _errorMessage = 'Correo o contraseña incorrectos.';
        }
        notifyListeners();
        return false;
      }

      _loginSuccess = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _isVerificationError = false;
      _errorMessage = 'Ha ocurrido un error inesperado. Por favor intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }
}
