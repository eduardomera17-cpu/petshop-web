// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: auth_repository.dart
// Propósito: Repositorio central de autenticación, control de sesiones e hidratación de claims para control de acceso.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';

/// Repositorio de autenticación, persistencia de sesión y claims en Flutter Web.
///
/// Implementa hidratación reactiva asíncrona para sobrevivir a recargas del navegador (F5),
/// exponiendo el estado de los Custom Claims ('role', 'status') como fuente de verdad
/// para la autorización y protección de rutas en el router de la aplicación.
class AuthRepository extends ChangeNotifier {
  /// Cliente de Firebase Auth inyectable.
  final FirebaseAuth? auth;

  /// Instancia de Firestore para sincronización de parámetros de negocio.
  final FirebaseFirestore? firestore;

  StreamSubscription<User?>? _subscription;
  User? _currentUser;
  IdTokenResult? _idTokenResult;
  bool _isHydrated = false;

  /// Inicializa el repositorio y arranca la escucha continua de cambios en el estado de autenticación.
  AuthRepository({
    this.auth,
    this.firestore,
  }) {
    _initListener();
  }

  FirebaseAuth get _authClient => auth ?? FirebaseAuth.instance;

  void _initListener() {
    final stream = _authClient.userChanges();
    _subscription = stream.listen((user) async {
      await _processUserChange(user);
    });
  }

  /// Procesa los eventos de cambio de usuario, extrayendo los custom claims del token JWT.
  Future<void> _processUserChange(User? user) async {
    if (user == null) {
      _currentUser = null;
      _idTokenResult = null;
      _isHydrated = true;
      notifyListeners();
      return;
    }

    try {
      final tokenResult = await user.getIdTokenResult(false);
      _currentUser = user;
      _idTokenResult = tokenResult;
    } catch (_) {
      _currentUser = user;
      _idTokenResult = null;
    } finally {
      _isHydrated = true;
      notifyListeners();
      if (_currentUser != null && firestore != null) {
        unawaited(reloadBusinessConfigTimezone(firestore!));
      }
    }
  }

  /// Sincroniza y recarga la zona horaria del negocio desde `/business_config/public_operating`.
  ///
  /// @param firestoreInstance Instancia de Firestore.
  Future<void> reloadBusinessConfigTimezone(FirebaseFirestore firestoreInstance) async {
    try {
      final configDoc = await firestoreInstance
          .collection('business_config')
          .doc('public_operating')
          .get();
      final data = configDoc.data();
      if (data != null && data.containsKey('timezone')) {
        final docTz = data['timezone'] as String?;
        if (docTz != null && docTz.isNotEmpty) {
          BusinessClock.init(timezone: docTz);
        }
      }
    } catch (_) {}
  }

  /// Indica si la sesión ha culminado la hidratación inicial tras el arranque.
  bool get isHydrated => _isHydrated;

  /// Usuario de Firebase Authentication actualmente autenticado.
  User? get currentUser => _currentUser;

  /// Resultado detallado del token JWT que contiene los Custom Claims.
  IdTokenResult? get idTokenResult => _idTokenResult;

  /// Rol operativo del usuario ('CLIENT', 'ADMIN', 'SUPERADMIN').
  String? get role => _idTokenResult?.claims?['role'] as String?;

  /// Estado de habilitación de la cuenta ('ACTIVE', 'DEACTIVATED').
  String? get status => _idTokenResult?.claims?['status'] as String?;

  /// Determina si hay un usuario con sesión válida e hidratada.
  bool get isAuthenticated => _isHydrated && _currentUser != null;

  /// Determina si el usuario autenticado tiene rol de cliente.
  bool get isClient => role == 'CLIENT';

  /// Determina si el usuario autenticado tiene rol de administrador.
  bool get isAdmin => role == 'ADMIN';

  /// Determina si el usuario autenticado tiene rol de superadministrador.
  bool get isSuperAdmin => role == 'SUPERADMIN';

  /// Determina si el usuario pertenece al equipo de gestión (ADMIN o SUPERADMIN).
  bool get isStaff => isAdmin || isSuperAdmin;

  /// Fuerza la actualización del token JWT para reflejar cambios inmediatos en los Custom Claims.
  Future<Result<void>> forceRefreshToken() async {
    final user = _currentUser;
    if (user == null) {
      return const Err(
        AuthFailure(
          code: 'NO_SESSION',
          debugMessage: 'No hay usuario autenticado para refrescar token',
        ),
      );
    }

    try {
      final tokenResult = await user.getIdTokenResult(true);
      _idTokenResult = tokenResult;
      notifyListeners();
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Cierra la sesión activa en el cliente y restablece las variables de estado.
  Future<Result<void>> signOut() async {
    try {
      await _authClient.signOut();
      _currentUser = null;
      _idTokenResult = null;
      _isHydrated = true;
      notifyListeners();
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
