// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: firebase_auth_service.dart
// Propósito: Servicio de infraestructura para la gestión de autenticación y sesiones con Firebase Authentication.
// =========================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';

/// Servicio de infraestructura para interactuar con Firebase Authentication.
///
/// Provee métodos robustos para el registro, inicio de sesión, recuperación de contraseña,
/// reautenticación y cierre de sesión, encapsulando errores de Firebase en objetos tipados [Result].
class FirebaseAuthService {
  /// Instancia configurable de [FirebaseAuth] (permite inyección para pruebas unitarias).
  final FirebaseAuth? auth;

  /// Constructor del servicio de autenticación.
  FirebaseAuthService({this.auth});

  /// Cliente interno de Firebase Auth.
  FirebaseAuth get _client => auth ?? FirebaseAuth.instance;

  /// Acceso público a la instancia del cliente de Firebase Auth.
  FirebaseAuth get authClient => _client;

  /// Obtiene el usuario autenticado actual o null si no existe sesión activa.
  User? get currentUser {
    try {
      return _client.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Recupera el token de identidad JWT del usuario en sesión.
  ///
  /// @param forceRefresh Fuerza la renovación del token si es verdadero.
  /// @return Token JWT en formato String o null si no hay sesión.
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    return await currentUser?.getIdToken(forceRefresh);
  }

  /// Registra un nuevo usuario con credenciales de correo electrónico y contraseña en Firebase Auth.
  ///
  /// @param email Dirección de correo electrónico del usuario.
  /// @param password Contraseña de acceso.
  /// @return [Result] con [UserCredential] en caso de éxito o [Failure] en caso de error.
  Future<Result<UserCredential>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _client.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return Ok(credential);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Inicia sesión con correo y contraseña.
  ///
  /// Transforma códigos de error de Firebase en respuestas genéricas para prevenir enumeración de usuarios.
  /// @param email Correo electrónico registrado.
  /// @param password Contraseña de acceso.
  /// @return [Result] con [UserCredential] si las credenciales son válidas.
  Future<Result<UserCredential>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _client.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return Ok(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        return const Err(
          AuthFailure(
            code: 'INVALID_CREDENTIALS',
            debugMessage: 'Credenciales inválidas',
          ),
        );
      }
      return Err(Failure.fromException(e));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Envía un correo electrónico para restablecer la contraseña del usuario.
  ///
  /// Retorna éxito incluso si el correo no existe para evitar ataques de fuerza bruta o enumeración de cuentas.
  /// @param email Correo electrónico al que se enviará el enlace de recuperación.
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _client.sendPasswordResetEmail(email: email.trim());
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return const Ok(null);
      }
      return Err(Failure.fromException(e));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Reautentica la sesión del usuario exigiendo explícitamente su contraseña actual.
  ///
  /// Obligatorio como medida de seguridad perimetral antes de cambios de contraseña o desactivaciones.
  /// @param email Correo del usuario actual.
  /// @param currentPassword Contraseña en vigencia.
  Future<Result<void>> reauthenticateWithCredential({
    required String email,
    required String currentPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      return const Err(
        AuthFailure(
          code: 'NO_SESSION',
          debugMessage: 'No hay usuario autenticado para reautenticar',
        ),
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-mismatch') {
        return const Err(
          AuthFailure(
            code: 'INVALID_CREDENTIALS',
            debugMessage: 'Contraseña actual incorrecta',
          ),
        );
      }
      return Err(Failure.fromException(e));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Actualiza la contraseña del usuario actualmente autenticado en Firebase Auth.
  ///
  /// @param newPassword Nueva contraseña configurada por el usuario.
  Future<Result<void>> updatePassword({required String newPassword}) async {
    final user = currentUser;
    if (user == null) {
      return const Err(
        AuthFailure(
          code: 'NO_SESSION',
          debugMessage: 'No hay usuario autenticado para cambiar contraseña',
        ),
      );
    }

    try {
      await user.updatePassword(newPassword);
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const Err(
          AuthFailure(
            code: 'REAUTH_REQUIRED',
            debugMessage: 'Reautenticación requerida para actualizar clave',
          ),
        );
      }
      return Err(Failure.fromException(e));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Cierra de forma segura la sesión activa del usuario.
  Future<Result<void>> signOut() async {
    try {
      await _client.signOut();
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }
}
