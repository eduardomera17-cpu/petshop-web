// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: account_deactivation_view_model.dart
// Propósito: ViewModel para la desactivación voluntaria de cuenta, previsualización de impacto (rubros a cancelar y retener) y confirmación segura con contraseña.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/data/services/functions_service.dart';

/// ViewModel para el flujo de desactivación voluntaria de cuenta de usuario (PR-03, CU-10).
///
/// Gestiona la experiencia informada previa a la desactivación:
/// 1. Consulta la Cloud Function `previewAccountDeactivation` para clasificar los registros del usuario en dos listas:
///    - `toCancel`: citas futuras pendientes o carritos activos que serán cancelados atómicamente.
///    - `toRetain`: comprobantes emitidos, proformas históricas y registros contables inmutables que deben conservarse.
/// 2. Solicita la contraseña actual del usuario y delega la ejecución irreversible a la Cloud Function `deactivateOwnAccount`.
class AccountDeactivationViewModel extends ChangeNotifier {
  /// Servicio intermediario para invocar Cloud Functions seguras.
  final FunctionsService functionsService;

  bool _isLoadingPreview = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _deactivationSuccess = false;

  List<Map<String, dynamic>> _toCancel = [];
  List<Map<String, dynamic>> _toRetain = [];

  /// Constructor con inyección del servicio de Cloud Functions.
  AccountDeactivationViewModel({
    required this.functionsService,
  });

  /// Indica si la previsualización del impacto se encuentra en proceso de consulta.
  bool get isLoadingPreview => _isLoadingPreview;

  /// Indica si la desactivación atómica está ejecutándose en el servidor.
  bool get isSubmitting => _isSubmitting;

  /// Mensaje descriptivo de error en caso de fallo.
  String? get errorMessage => _errorMessage;

  /// Bandera que confirma si la cuenta fue desactivada con éxito.
  bool get deactivationSuccess => _deactivationSuccess;

  /// Lista de citas y solicitudes activas que serán canceladas al desactivar la cuenta.
  List<Map<String, dynamic>> get toCancel => _toCancel;

  /// Lista de comprobantes fiscales y registros históricos que deben preservarse por exigencias legales.
  List<Map<String, dynamic>> get toRetain => _toRetain;

  /// Consulta la previsualización del impacto de la desactivación en el backend.
  ///
  /// Invoca `previewAccountDeactivation` y separa los resultados en [toCancel] y [toRetain].
  Future<void> loadPreview() async {
    _isLoadingPreview = true;
    _errorMessage = null;
    notifyListeners();

    final res = await functionsService.previewAccountDeactivation();

    _isLoadingPreview = false;

    if (res.isErr) {
      _errorMessage = res.failureOrNull?.code ?? 'ERROR_PREVIEW';
      notifyListeners();
      return;
    }

    final data = res.dataOrNull ?? {};
    final cancelList = (data['toCancel'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final retainList = (data['toRetain'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    _toCancel = cancelList;
    _toRetain = retainList;
    notifyListeners();
  }

  /// Ejecuta la desactivación atómica de la cuenta solicitando reautenticación por [password].
  ///
  /// La Cloud Function valida la contraseña actual, revierte citas y carritos, desactiva el perfil
  /// y anula las credenciales de acceso en Firebase Authentication.
  Future<bool> confirmDeactivation(String password) async {
    if (password.trim().isEmpty) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final res = await functionsService.deactivateOwnAccount(password: password);

    _isSubmitting = false;

    if (res.isErr) {
      _errorMessage = res.failureOrNull?.code ?? 'ERROR_DEACTIVATION';
      notifyListeners();
      return false;
    }

    _deactivationSuccess = true;
    notifyListeners();
    return true;
  }
}
