// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: register_view_model.dart
// Propósito: ViewModel para el registro seguro de clientes en 6 pasos, coordinando reCAPTCHA, Firebase Auth, Cloud Functions y actualización de Custom Claims.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/validators/document.dart';
import 'package:mipetshop/core/validators/phone.dart';
import 'package:mipetshop/data/repositories/auth_repository.dart';
import 'package:mipetshop/data/services/firebase_auth_service.dart';
import 'package:mipetshop/data/services/functions_service.dart';

/// ViewModel para la pantalla de registro de clientes (AppFlow §2.1).
///
/// Gestiona la secuencia estricta de 6 pasos sin pantallas intermedias de verificación de correo:
/// 1. Validación previa de presencia del token reCAPTCHA.
/// 2. Llamada a la Cloud Function `verifyHuman` con token y correo (la contraseña jamás viaja aquí).
/// 3. Creación de cuenta en Firebase Auth (`createUserWithEmailAndPassword`). Las blocking functions
///    asignan el rol preliminar `PENDING_PROFILE`.
/// 4. Invocación de la Cloud Function `completeRegistration` para persistir los datos personales validados.
/// 5. Refresco forzado de Custom Claims en el cliente (`getIdToken(true)`).
/// 6. Conclusión exitosa con acceso directo al panel del cliente.
class RegisterViewModel extends ChangeNotifier {
  /// Servicio de Cloud Functions para verificación de persona y completitud de perfil.
  final FunctionsService functionsService;

  /// Servicio base de autenticación con Firebase.
  final FirebaseAuthService authService;

  /// Repositorio de autenticación para refresco reactivo de sesión y claims.
  final AuthRepository authRepository;

  /// Constructor con inyección de servicios y repositorios requeridos.
  RegisterViewModel({
    required this.functionsService,
    required this.authService,
    required this.authRepository,
  });

  FunctionsService get _functionsService => functionsService;
  FirebaseAuthService get _authService => authService;
  AuthRepository get _authRepository => authRepository;

  // Campos de formulario (conservados ante fallos)
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _fullName = '';
  String _phone = '';
  String _documentType = DocumentTypes.cedula;
  String _documentNumber = '';
  String _address = '';

  // Estado de verificación de persona (reCAPTCHA)
  String? _recaptchaToken;

  // Estados de interfaz
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerificationError = false;
  bool _registrationSuccess = false;

  /// Correo electrónico ingresado.
  String get email => _email;

  /// Contraseña de acceso.
  String get password => _password;

  /// Confirmación de la contraseña para cotejo de igualdad.
  String get confirmPassword => _confirmPassword;

  /// Nombre completo del titular.
  String get fullName => _fullName;

  /// Teléfono celular ecuatoriano.
  String get phone => _phone;

  /// Tipo de documento de identidad (Cédula, RUC, Pasaporte).
  String get documentType => _documentType;

  /// Número de documento de identificación.
  String get documentNumber => _documentNumber;

  /// Dirección domiciliaria.
  String get address => _address;

  /// Token emitido por el componente de reCAPTCHA.
  String? get recaptchaToken => _recaptchaToken;

  /// Indica si hay una transacción de registro en ejecución.
  bool get isLoading => _isLoading;

  /// Mensaje descriptivo de error ante fallos de validación o red.
  String? get errorMessage => _errorMessage;

  /// Indica si el error se originó en la validación contra bots.
  bool get isVerificationError => _isVerificationError;

  /// Bandera que confirma que el usuario se registró y autenticó con éxito.
  bool get registrationSuccess => _registrationSuccess;

  /// El botón de envío permanece deshabilitado hasta obtener el token de la casilla.
  ///
  /// Deliberadamente NO exige además que el formulario sea válido. La norma sólo
  /// condiciona el botón a la verificación de seguridad (A-10, CA-53); añadir el
  /// segundo candado producía un bloqueo circular: con el formulario inválido el
  /// botón quedaba inerte, de modo que `validate()` no llegaba a ejecutarse nunca
  /// y el usuario no podía saber qué campo estaba mal. Pulsar con datos
  /// incompletos ahora revela los errores de todos los campos a la vez; el envío
  /// real lo sigue impidiendo la guarda `isFormValid` de [register].
  bool get isSubmitEnabled {
    if (_isLoading) return false;
    if (_recaptchaToken == null || _recaptchaToken!.trim().isEmpty) return false;
    return true;
  }

  /// Evalúa la validez formal de todos los campos del formulario conforme a las reglas ecuatorianas.
  bool get isFormValid {
    if (_email.trim().isEmpty || !_email.contains('@')) return false;
    if (_password.isEmpty || _password.length < 6) return false;
    if (_password != _confirmPassword) return false;
    if (!isValidFullName(_fullName)) return false;
    if (!isValidPhone(_phone)) return false;
    if (!isValidDocumentType(_documentType)) return false;
    if (!isValidDocumentNumber(_documentType, _documentNumber)) return false;
    if (!isValidAddress(_address)) return false;
    return true;
  }

  // Mutadores de campos de formulario (conservando estado ante errores)

  /// Actualiza el correo electrónico y restablece errores previos.
  void setEmail(String value) {
    _email = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza la contraseña y restablece errores previos.
  void setPassword(String value) {
    _password = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza la confirmación de contraseña y restablece errores previos.
  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza el nombre completo y restablece errores previos.
  void setFullName(String value) {
    _fullName = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza el número telefónico celular y restablece errores previos.
  void setPhone(String value) {
    _phone = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza el tipo de documento de identidad y restablece errores previos.
  void setDocumentType(String value) {
    _documentType = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza el número de documento de identificación y restablece errores previos.
  void setDocumentNumber(String value) {
    _documentNumber = value;
    _clearError();
    notifyListeners();
  }

  /// Actualiza la dirección física domiciliaria y restablece errores previos.
  void setAddress(String value) {
    _address = value;
    _clearError();
    notifyListeners();
  }

  /// Establece el token obtenido del widget de verificación reCAPTCHA.
  void setRecaptchaToken(String? token) {
    _recaptchaToken = token;
    _clearError();
    notifyListeners();
  }

  /// Notifica que la verificación de seguridad expiró y deshabilita el botón de envío.
  void onVerificationExpired() {
    _recaptchaToken = null;
    _isVerificationError = true;
    _errorMessage = 'La verificación de seguridad ha caducado. Intenta de nuevo.';
    notifyListeners();
  }

  /// Notifica un fallo técnico en la carga del servicio reCAPTCHA.
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

  /// Ejecuta el flujo estricto de registro en seis pasos (AppFlow §2.1).
  ///
  /// 1. Comprueba presencia del token reCAPTCHA y validez del formulario.
  /// 2. Invoca la callable `verifyHuman({ token, email })` sin exponer la contraseña.
  /// 3. Crea la cuenta mediante `createUserWithEmailAndPassword`.
  /// 4. Invoca la callable `completeRegistration` para persistir los datos validados del usuario.
  /// 5. Fuerza la recarga de Custom Claims en el cliente con [AuthRepository.forceRefreshToken].
  /// 6. Concluye satisfactoriamente concediendo acceso al panel de cliente.
  Future<bool> register() async {
    // 1. Validar presencia del token de casilla 
    if (_recaptchaToken == null || _recaptchaToken!.trim().isEmpty) {
      _isVerificationError = true;
      _errorMessage = 'Es obligatorio completar la verificación de seguridad.';
      notifyListeners();
      return false;
    }

    if (!isFormValid) {
      _isVerificationError = false;
      _errorMessage = 'Por favor completa todos los campos correctamente.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // PASO 2: Callable verifyHuman({ token, email })
      // La contraseña NUNCA viaja aquí (AppFlow §2.1)
      final verifyRes = await _functionsService.verifyHuman(
        token: _recaptchaToken!,
        email: _email,
      );

      if (verifyRes.isErr) {
        final failure = verifyRes.failureOrNull!;
        _isVerificationError = true;
        _recaptchaToken = null; // Exige resolver de nuevo la casilla
        _errorMessage = _mapVerificationError(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // PASO 3: createUserWithEmailAndPassword
      // Blocking functions beforeUserCreated y beforeUserSignedIn asignan PENDING_PROFILE
      final authRes = await _authService.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      if (authRes.isErr) {
        final failure = authRes.failureOrNull!;
        _isVerificationError = false;
        _errorMessage = failure.code == 'EMAIL_ALREADY_IN_USE'
            ? 'El correo ya se encuentra registrado.'
            : 'Error al crear la cuenta. Intenta de nuevo.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // PASO 4: completeRegistration (callable paso 6 de AppFlow §2.1)
      final completeRes = await _functionsService.completeRegistration(
        fullName: _fullName,
        phone: _phone,
        documentType: _documentType,
        documentNumber: _documentNumber,
        address: _address,
      );

      if (completeRes.isErr) {
        final failure = completeRes.failureOrNull!;
        _isVerificationError = false;
        _errorMessage = failure.code == 'INVALID_ARGUMENT'
            ? 'Los datos del perfil no son válidos.'
            : 'Error al completar el perfil.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // PASO 5: Refresco forzado de claims en cliente: getIdToken(true)
      await _authRepository.forceRefreshToken();

      // PASO 6: Registro concluido con éxito directo al panel 
      _registrationSuccess = true;
      _isLoading = false;
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

  /// Traduce fallos de verificación de seguridad a mensajes amigables para el usuario.
  String _mapVerificationError(Failure failure) {
    return switch (failure.code) {
      'VERIFICATION_UNAVAILABLE' =>
        'El servicio de verificación de seguridad no está disponible momentáneamente.',
      'VERIFICATION_HIGH_RISK' =>
        'No se pudo validar la solicitud por motivos de seguridad.',
      'VERIFICATION_FAILED' =>
        'La verificación de seguridad no fue superada o ha caducado. Intenta de nuevo.',
      _ => 'La verificación de seguridad no pudo ser completada.',
    };
  }
}
