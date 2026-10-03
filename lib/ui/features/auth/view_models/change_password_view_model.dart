// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: change_password_view_model.dart
// Propósito: ViewModel para el cambio de contraseña de usuario con reautenticación obligatoria directa en cliente mediante Firebase Auth.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';

/// ViewModel para la pantalla de cambio de contraseña (AppFlow §2.4).
///
/// Implementado 100% en cliente sin Cloud Functions para salvaguardar el secreto de credenciales:
/// 1. Exige la contraseña actual para verificar la identidad del usuario en sesión.
/// 2. Invoca `reauthenticateWithCredential(email, actual)` ante Firebase Auth.
/// 3. Actualiza el secreto mediante `updatePassword(nueva)`.
/// 4. Captura y traduce el error `requires-recent-login` a mensajes entendibles por el usuario.
class ChangePasswordViewModel extends ChangeNotifier {
  /// Servicio de autenticación con Firebase.
  final FirebaseAuthService authService;

  /// Constructor con inyección del servicio de autenticación.
  ChangePasswordViewModel({
    required this.authService,
  });

  FirebaseAuthService get _authService => authService;

  String _currentPassword = '';
  String _newPassword = '';
  String _confirmNewPassword = '';

  bool _isLoading = false;
  String? _errorMessage;
  bool _changeSuccess = false;

  /// Contraseña actual ingresada por el usuario para reautenticarse.
  String get currentPassword => _currentPassword;

  /// Nueva contraseña deseada.
  String get newPassword => _newPassword;

  /// Confirmación de la nueva contraseña.
  String get confirmNewPassword => _confirmNewPassword;

  /// Indica si la actualización de credenciales está en proceso.
  bool get isLoading => _isLoading;

  /// Mensaje de error para visualización en la interfaz.
  String? get errorMessage => _errorMessage;

  /// Bandera que confirma si la contraseña fue actualizada satisfactoriamente.
  bool get changeSuccess => _changeSuccess;

  /// Determina si el botón de guardar debe estar activo.
  ///
  /// Requiere que no haya carga activa, que la contraseña actual no esté vacía,
  /// que la nueva clave tenga al menos 6 caracteres y coincida con la confirmación.
  bool get isSubmitEnabled {
    if (_isLoading) return false;
    if (_currentPassword.isEmpty) return false;
    if (_newPassword.length < 6) return false;
    if (_newPassword != _confirmNewPassword) return false;
    return true;
  }

  /// Actualiza la contraseña actual y restablece errores.
  void setCurrentPassword(String value) {
    _currentPassword = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza la nueva contraseña y restablece errores.
  void setNewPassword(String value) {
    _newPassword = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza la confirmación de nueva contraseña y restablece errores.
  void setConfirmNewPassword(String value) {
    _confirmNewPassword = value;
    _clearError();
    notifyListeners();
  }

  /// Limpia los estados de error y éxito previos.
  void _clearError() {
    _errorMessage = null;
    _changeSuccess = false;
  }

  /// Ejecuta el proceso de cambio de contraseña tras reautenticar al usuario.
  ///
  /// En caso de éxito, borra los campos sensibles de memoria y notifica a los oyentes.
  Future<bool> changePassword() async {
    // Prohibido permitir cambio de clave sin solicitar la contraseña actual 
    if (_currentPassword.isEmpty) {
      _errorMessage = 'Debes ingresar tu contraseña actual para continuar.';
      notifyListeners();
      return false;
    }

    if (_newPassword.length < 6) {
      _errorMessage = 'La nueva contraseña debe tener al menos 6 caracteres.';
      notifyListeners();
      return false;
    }

    if (_newPassword != _confirmNewPassword) {
      _errorMessage = 'Las contraseñas no coinciden.';
      notifyListeners();
      return false;
    }

    final user = _authService.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      _errorMessage = 'No hay una sesión activa o correo disponible para reautenticar.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // 1. Re-autenticación obligatoria con contraseña actual 
      final reauthRes = await _authService.reauthenticateWithCredential(
        email: email,
        currentPassword: _currentPassword,
      );

      if (reauthRes.isErr) {
        _isLoading = false;
        final failure = reauthRes.failureOrNull!;
        if (failure.code == 'INVALID_CREDENTIALS') {
          _errorMessage = 'La contraseña actual ingresada es incorrecta.';
        } else if (failure.code == 'REAUTH_REQUIRED') {
          _errorMessage = 'Por seguridad, debes volver a iniciar sesión para realizar esta acción.';
        } else {
          _errorMessage = 'Error al verificar la contraseña actual.';
        }
        notifyListeners();
        return false;
      }

      // 2. Actualización de la nueva contraseña en Firebase Auth (AppFlow §2.4)
      final updateRes = await _authService.updatePassword(newPassword: _newPassword);

      _isLoading = false;

      if (updateRes.isErr) {
        final failure = updateRes.failureOrNull!;
        if (failure.code == 'REAUTH_REQUIRED') {
          _errorMessage = 'Por seguridad, debes volver a iniciar sesión para realizar esta acción.';
        } else {
          _errorMessage = 'Error al actualizar la contraseña.';
        }
        notifyListeners();
        return false;
      }

      _changeSuccess = true;
      _currentPassword = '';
      _newPassword = '';
      _confirmNewPassword = '';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Ha ocurrido un error inesperado. Por favor intenta de nuevo.';
      notifyListeners();
      return false;
    }
  }
}
