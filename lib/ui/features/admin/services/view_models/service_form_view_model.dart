// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/services/view_models/service_form_view_model.dart
// Propósito: ViewModel para el formulario de alta y edición de servicios veterinarios,
//            validaciones canónicas y previsualización de cálculo impositivo en vivo.
// =========================================================================

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/domain/models/service.dart';

/// ViewModel para el formulario de creación y edición de servicios veterinarios y de peluquería.
///
/// Gestiona la captura interactiva y validación canónica de los atributos del servicio:
/// denominación, descripción, precio base en centavos, tarifa de ICE, marcación clínica
/// (que exige historia médica al ser completada), duración estimada en minutos y estado activo.
/// Calcula en tiempo real el desglose impositivo proyectado (PVP con IVA e ICE).
class ServiceFormViewModel extends ChangeNotifier {
  /// Repositorio del catálogo de servicios.
  final CatalogRepository repository;

  /// Instancia del servicio original en caso de modificación, o nulo si es nuevo registro.
  final Service? initialService;

  String _name;
  String _description;
  int _basePriceCents;
  int _iceBp;
  bool _isClinical;
  int _estimatedDurationMinutes;
  bool _isActive;
  int _ivaBp;
  final bool _iceIncludedInIvaBase;

  bool _isSaving = false;
  String? _errorMessage;
  Failure? _failure;

  /// Detalle tipado del fallo suscitado durante la validación o persistencia.
  Failure? get failure => _failure;

  /// Construye e inicializa el ViewModel cargando los valores por defecto o del servicio existente.
  ServiceFormViewModel({
    required this.repository,
    this.initialService,
    int? ivaBp,
    bool? iceIncludedInIvaBase,
  })  : _name = initialService?.name ?? '',
        _description = initialService?.description ?? '',
        _basePriceCents = initialService?.basePriceCents ?? 0,
        _iceBp = initialService?.iceBp ?? 0,
        _isClinical = initialService?.isClinical ?? false,
        _estimatedDurationMinutes = initialService?.estimatedDurationMinutes ?? 30,
        _isActive = initialService?.isActive ?? true,
        _ivaBp = ivaBp ?? 1500,
        _iceIncludedInIvaBase = iceIncludedInIvaBase ?? true;

  /// Determina si el formulario se encuentra en modo edición o creación.
  bool get isEdit => initialService != null;

  /// Nombre comercial del servicio.
  String get name => _name;

  /// Descripción detallada de las prestaciones del servicio.
  String get description => _description;

  /// Precio base sin impuestos expresado en centavos.
  int get basePriceCents => _basePriceCents;

  /// Tasa de ICE en puntos básicos (ej. 1000 = 10%).
  int get iceBp => _iceBp;

  /// Determina si el servicio reviste carácter clínico y genera historial médico.
  bool get isClinical => _isClinical;

  /// Duración estimada del servicio expresada en minutos.
  int get estimatedDurationMinutes => _estimatedDurationMinutes;

  /// Determina si el servicio está disponible para agendamiento público.
  bool get isActive => _isActive;

  /// Tasa vigente de IVA en puntos básicos para la vista previa.
  int get ivaBp => _ivaBp;

  /// Indica si se está guardando la información en Firestore.
  bool get isSaving => _isSaving;

  /// Mensaje explicativo ante anomalías de validación de campos.
  String? get errorMessage => _errorMessage;

  /// Cálculo reactivo del desglose financiero (base, ICE, IVA y PVP final) en centavos.
  LinePricingResult get pricingPreview {
    return calculateLinePricing(
      basePriceCents: _basePriceCents,
      iceBp: _iceBp,
      ivaBp: _ivaBp,
      iceIncludedInIvaBase: _iceIncludedInIvaBase,
    );
  }

  /// Modifica el nombre del servicio y notifica a los escuchas.
  void setName(String val) {
    _name = val;
    notifyListeners();
  }

  /// Modifica la descripción detallada del servicio.
  void setDescription(String val) {
    _description = val;
    notifyListeners();
  }

  /// Modifica el precio base en centavos validando que no sea negativo.
  void setBasePriceCents(int val) {
    _basePriceCents = val < 0 ? 0 : val;
    notifyListeners();
  }

  /// Establece la tarifa de ICE en puntos básicos limitándola entre 0 y 10000 pb.
  void setIceBp(int val) {
    _iceBp = (val < 0) ? 0 : (val > 10000 ? 10000 : val);
    notifyListeners();
  }

  /// Define si la atención requiere consulta clínica veterinaria obligatoria.
  void setIsClinical(bool val) {
    _isClinical = val;
    notifyListeners();
  }

  /// Define la duración estimada de la sesión en minutos.
  void setEstimatedDurationMinutes(int val) {
    _estimatedDurationMinutes = val <= 0 ? 30 : val;
    notifyListeners();
  }

  /// Establece el estado de disponibilidad comercial del servicio.
  void setIsActive(bool val) {
    _isActive = val;
    notifyListeners();
  }

  /// Establece la tasa de IVA aplicada a la vista previa del cálculo impositivo.
  void setIvaBp(int val) {
    _ivaBp = val;
    notifyListeners();
  }

  /// Guarda el servicio (creación o actualización) con validaciones canónicas.
  Future<bool> save(String uid) async {
    final trimmedName = _name.trim();
    if (trimmedName.isEmpty || trimmedName.length > 80) {
      _errorMessage = 'El nombre del servicio debe tener entre 1 y 80 caracteres.';
      notifyListeners();
      return false;
    }

    if (_description.length > 500) {
      _errorMessage = 'La descripción no puede exceder 500 caracteres.';
      notifyListeners();
      return false;
    }

    if (_basePriceCents < 0) {
      _errorMessage = 'El precio base no puede ser negativo.';
      notifyListeners();
      return false;
    }

    if (_iceBp < 0 || _iceBp > 10000) {
      _errorMessage = 'El ICE debe ubicarse entre 0 y 10000 puntos básicos.';
      notifyListeners();
      return false;
    }

    if (_estimatedDurationMinutes <= 0) {
      _errorMessage = 'La duración estimada debe ser mayor a 0 minutos.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    if (isEdit) {
      final res = await repository.updateService(
        serviceId: initialService!.id,
        uid: uid,
        name: trimmedName,
        description: _description.trim(),
        basePriceCents: _basePriceCents,
        iceBp: _iceBp,
        isClinical: _isClinical,
        estimatedDurationMinutes: _estimatedDurationMinutes,
        isActive: _isActive,
      );

      _isSaving = false;
      if (res.isOk) {
        _failure = null;
        return true;
      } else {
        _failure = res.failureOrNull;
        _errorMessage = _failure?.code;
        notifyListeners();
        return false;
      }
    } else {
      final res = await repository.createService(
        uid: uid,
        name: trimmedName,
        description: _description.trim(),
        basePriceCents: _basePriceCents,
        iceBp: _iceBp,
        isClinical: _isClinical,
        estimatedDurationMinutes: _estimatedDurationMinutes,
        isActive: _isActive,
      );

      _isSaving = false;
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
  }
}
