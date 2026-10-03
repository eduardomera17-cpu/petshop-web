// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: forgot_password_view_model.dart
// Propósito: ViewModel para la solicitud de restablecimiento de contraseña mediante correo, implementando protección reCAPTCHA y confirmación genérica anti-enumeración.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';

/// ViewModel para la pantalla de recuperación de contraseña (AppFlow §2.3).
///
/// Implementa:
/// - Verificación de persona obligatoria mediante reCAPTCHA para mitigar ataques de denegación o spam.
/// - Envío del correo de recuperación mediante Firebase Authentication.
/// - Respuesta y confirmación genérica indistintamente de si el correo existe o no en el sistema,
///   impidiendo que atacantes descubran correos registrados en la base de datos (anti-enumeración).
class ForgotPasswordViewModel extends ChangeNotifier {
  /// Servicio de autenticación con Firebase.
  final FirebaseAuthService authService;

  /// Constructor con inyección del servicio de autenticación.
  ForgotPasswordViewModel({
    required this.authService,
  });

  FirebaseAuthService get _authService => authService;

  String _email = '';
  String? _recaptchaToken;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerificationError = false;
  bool _emailSentSuccess = false;

  /// Correo electrónico ingresado para recibir el enlace de recuperación.
  String get email => _email;

  /// Token emitido por el servicio reCAPTCHA.
  String? get recaptchaToken => _recaptchaToken;

  /// Indica si hay una solicitud de recuperación en curso.
  bool get isLoading => _isLoading;

  /// Mensaje de error para retroalimentación visual al usuario.
  String? get errorMessage => _errorMessage;

  /// Indica si el fallo actual corresponde a la verificación contra bots.
  bool get isVerificationError => _isVerificationError;

  /// Bandera que confirma si el flujo de envío de correo concluyó exitosamente.
  bool get emailSentSuccess => _emailSentSuccess;

  /// Determina si el botón de envío debe habilitarse.
  ///
  /// Requiere que no haya carga activa, que el token reCAPTCHA esté presente y que
  /// el correo tenga un formato elemental válido con arroba.
  bool get isSubmitEnabled {
    if (_isLoading) return false;
    if (_recaptchaToken == null || _recaptchaToken!.trim().isEmpty) return false;
    return _email.trim().isNotEmpty && _email.contains('@');
  }

  /// Actualiza el correo ingresado y restablece los mensajes de error.
  void setEmail(String value) {
    _email = value;
    _clearError();
    notifyListeners();
  }

  /// Registra el token generado por el widget de reCAPTCHA.
  void setRecaptchaToken(String? token) {
    _recaptchaToken = token;
    _clearError();
    notifyListeners();
  }

  /// Maneja el evento de expiración del desafío de seguridad.
  void onVerificationExpired() {
    _recaptchaToken = null;
    _isVerificationError = true;
    _errorMessage = 'La verificación de seguridad ha caducado. Intenta de nuevo.';
    notifyListeners();
  }

  /// Maneja fallos de conectividad con el servicio reCAPTCHA.
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

  /// Ejecuta la solicitud de envío de correo de restablecimiento.
  ///
  /// Valida la presencia del token reCAPTCHA y la estructura del correo.
  /// En caso de éxito o fallo no crítico de cuenta inexistente, presenta confirmación
  /// genérica para preservar la privacidad de los usuarios registrados.
  Future<bool> sendPasswordReset() async {
    // 1. Validar presencia del token de casilla 
    if (_recaptchaToken == null || _recaptchaToken!.trim().isEmpty) {
      _isVerificationError = true;
      _errorMessage = 'Es obligatorio completar la verificación de seguridad.';
      notifyListeners();
      return false;
    }

    if (_email.trim().isEmpty || !_email.contains('@')) {
      _isVerificationError = false;
      _errorMessage = 'Por favor ingresa un correo electrónico válido.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final res = await _authService.sendPasswordResetEmail(email: _email);
      _isLoading = false;

      if (res.isErr) {
        final failure = res.failureOrNull!;
        if (failure.code == 'VERIFICATION_FAILED' ||
            failure.code == 'VERIFICATION_REQUIRED' ||
            failure.code == 'VERIFICATION_UNAVAILABLE') {
          _isVerificationError = true;
          _recaptchaToken = null;
          _errorMessage = failure.code == 'VERIFICATION_UNAVAILABLE'
              ? 'El servicio de verificación de seguridad no está disponible momentáneamente.'
              : 'La verificación de seguridad no fue superada o ha caducado. Intenta de nuevo.';
        } else {
          // No revelar detalles de la cuenta para mitigar enumeración
          _isVerificationError = false;
          _errorMessage = 'No se pudo enviar el correo de recuperación. Intenta nuevamente.';
        }
        notifyListeners();
        return false;
      }

      // Confirmación genérica siempre
      _emailSentSuccess = true;
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
