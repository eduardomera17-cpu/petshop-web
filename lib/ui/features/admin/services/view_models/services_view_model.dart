// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/services/view_models/services_view_model.dart
// Propósito: ViewModel para la administración del catálogo de servicios veterinarios,
//            alternancia activo/inactivo (baja lógica) y cálculo tributario en tiempo real.
// =========================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/domain/models/service.dart';

/// ViewModel para la administración del catálogo de servicios veterinarios y estéticos.
///
/// Gestiona la visualización reactiva de todos los servicios registrados (activos e inactivos),
/// la alternancia del estado activo/inactivo mediante baja lógica auditada en Firestore
/// y el cálculo de precios finales con impuestos (IVA e ICE) según la configuración tributaria vigente.
class ServicesViewModel extends ChangeNotifier {
  /// Repositorio de consulta y mutación de servicios del catálogo.
  final CatalogRepository repository;

  List<Service> _services = const [];
  bool _isLoading = true;
  String? _errorMessage;
  Failure? _failure;

  /// Detalle tipado del fallo reportado por el repositorio.
  Failure? get failure => _failure;

  PublicPricingConfig _pricingConfig = const PublicPricingConfig(
    ivaBp: 1500,
    iceIncludedInIvaBase: true,
  );

  StreamSubscription<List<Service>>? _servicesSub;
  StreamSubscription<PublicPricingConfig>? _pricingSub;

  /// Construye el ViewModel inyectando el repositorio del catálogo de servicios.
  ServicesViewModel({required this.repository});

  /// Lista integral de servicios cargados desde Firestore.
  List<Service> get services => _services;

  /// Indica si la lista de servicios está en proceso de carga.
  bool get isLoading => _isLoading;

  /// Mensaje o código de error ante anomalías de consulta.
  String? get errorMessage => _errorMessage;

  /// Configuración tributaria vigente para el cálculo de precios finales.
  PublicPricingConfig get pricingConfig => _pricingConfig;

  /// Inicia la escucha reactiva de servicios y parámetros fiscales.
  void startListening() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _servicesSub?.cancel();
    _servicesSub = repository.streamServices(onlyActive: false).listen(
      (items) {
        _services = items;
        _isLoading = false;
        _errorMessage = null;
        _failure = null;
        notifyListeners();
      },
      onError: (Object e) {
        _failure = Failure.fromException(e);
        _errorMessage = _failure?.code;
        _isLoading = false;
        notifyListeners();
      },
    );

    _pricingSub?.cancel();
    _pricingSub = repository.streamPublicPricing().listen(
      (pricing) {
        _pricingConfig = pricing;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Carga la lista inicial de servicios y configuración fiscal.
  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    final pricingRes = await repository.getPublicPricing();
    if (pricingRes.isOk) {
      _pricingConfig = pricingRes.dataOrNull!;
    }

    final servicesRes = await repository.getServices(onlyActive: false);
    if (servicesRes.isOk) {
      _services = servicesRes.dataOrNull!;
      _isLoading = false;
      _failure = null;
    } else {
      _failure = servicesRes.failureOrNull;
      _errorMessage = _failure?.code;
      _isLoading = false;
    }
    notifyListeners();
  }

  /// Alterna el estado activo/inactivo de un servicio mediante borrado lógico.
  Future<bool> toggleActive({
    required String serviceId,
    required String uid,
    required bool isActive,
  }) async {
    final res = await repository.toggleServiceActive(
      serviceId: serviceId,
      uid: uid,
      isActive: isActive,
    );
    if (res.isOk) {
      _failure = null;
      return true;
    } else {
      _failure = res.failureOrNull;
      _errorMessage = _failure?.code;
      notifyListeners();
      return false;
    }
  }

  /// Calcula el desglose impositivo y precio final para un servicio.
  LinePricingResult calculatePricing(Service service) {
    return calculateLinePricing(
      basePriceCents: service.basePriceCents,
      iceBp: service.iceBp,
      ivaBp: _pricingConfig.ivaBp,
      iceIncludedInIvaBase: _pricingConfig.iceIncludedInIvaBase,
    );
  }

  /// Cancela las suscripciones reactivas al catálogo y parámetros tributarios.
  @override
  void dispose() {
    _servicesSub?.cancel();
    _pricingSub?.cancel();
    super.dispose();
  }
}
