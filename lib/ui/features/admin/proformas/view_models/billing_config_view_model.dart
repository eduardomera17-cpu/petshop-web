// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/view_models/billing_config_view_model.dart
// Propósito: ViewModel para la configuración de parámetros impositivos y de facturación
//            (RUC, razón social, serie de proformas, tasa IVA e inclusión de ICE).
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';
import 'package:mipetshop/domain/models/billing_parameters.dart';

/// Gestor de estado para la configuración de facturación y tributación del Petshop.
///
/// Gestiona la escucha reactiva de los parámetros de facturación institucional
/// (razón social, RUC/identificación fiscal, serie numérica de comprobantes, tasa de IVA en
/// puntos básicos y regla de inclusión de ICE en la base imponible del IVA) y procesa
/// su actualización en Firestore previa validación estricta de restricciones de negocio.
class BillingConfigViewModel extends ChangeNotifier {
  /// Repositorio para la consulta y actualización de parámetros de facturación.
  final ProformasRepository proformasRepository;

  StreamSubscription<BillingParameters>? _subscription;

  BillingParameters? _config;
  bool _isLoading = true;
  String? _errorMessage;
  Failure? _failure;

  /// Detalle tipado del error reportado por el repositorio.
  Failure? get failure => _failure;

  bool _isSaving = false;

  /// Construye el ViewModel e inicia la suscripción a los parámetros de facturación vigentes.
  BillingConfigViewModel({
    required this.proformasRepository,
  }) {
    _initConfig();
  }

  /// Configuración de facturación activa en memoria.
  BillingParameters? get config => _config;

  /// Indica si los parámetros de facturación se encuentran en proceso de carga.
  bool get isLoading => _isLoading;

  /// Mensaje o código de error en caso de fallo al consultar o guardar.
  String? get errorMessage => _errorMessage;

  /// Indica si se encuentra persistiendo los cambios de configuración.
  bool get isSaving => _isSaving;

  void _initConfig() {
    _isLoading = true;
    notifyListeners();

    _subscription = proformasRepository.streamBillingParameters().listen(
      (params) {
        _config = params;
        _isLoading = false;
        _errorMessage = null;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = Failure.fromException(error);
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Actualiza los parámetros de facturación respetando el esquema de seguridad.
  Future<bool> saveParameters({
    required String uid,
    required String businessName,
    required String taxId,
    required String address,
    required String phone,
    required String proformaSeries,
    required int ivaBp,
    required bool iceIncludedInIvaBase,
  }) async {
    if (businessName.trim().isEmpty || businessName.trim().length > 200) {
      _failure = const DomainFailure(code: 'INVALID_BUSINESS_NAME');
      _errorMessage = 'INVALID_BUSINESS_NAME';
      notifyListeners();
      return false;
    }
    if (taxId.trim().isEmpty || taxId.trim().length > 20) {
      _failure = const DomainFailure(code: 'INVALID_TAX_ID');
      _errorMessage = 'INVALID_TAX_ID';
      notifyListeners();
      return false;
    }
    if (ivaBp < 0 || ivaBp > 10000) {
      _failure = const DomainFailure(code: 'INVALID_IVA_RATE');
      _errorMessage = 'INVALID_IVA_RATE';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final res = await proformasRepository.updateBillingParameters(
      uid: uid,
      businessName: businessName,
      taxId: taxId,
      address: address,
      phone: phone,
      proformaSeries: proformaSeries,
      ivaBp: ivaBp,
      iceIncludedInIvaBase: iceIncludedInIvaBase,
    );

    _isSaving = false;

    if (res.isErr) {
      _failure = res.failureOrNull;
      _errorMessage = _failure?.code;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Cancela la suscripción reactiva al desmontar el ViewModel.
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
