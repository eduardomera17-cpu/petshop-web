// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/ui/features/admin/proformas/view_models/pending_concepts_view_model.dart
// Propósito: ViewModel para la selección y unificación de conceptos pendientes
//            de cobro (citas completadas y solicitudes listas) en una proforma.
// =========================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/money.dart';
import 'package:mipetshop/data/repositories/catalog_repository.dart';
import 'package:mipetshop/data/repositories/proformas_repository.dart';

/// Reúne las citas completadas sin facturar y las solicitudes listas para
/// retirar de un cliente, y sostiene la selección con la que se compone la
/// proforma.
///
/// El total que calcula es una vista previa para que el personal sepa lo que
/// va a cobrar antes de crear el documento; los importes autoritativos los
/// recalcula el servidor al incorporar los conceptos.
class PendingConceptsViewModel extends ChangeNotifier {
  /// Repositorio de consulta y agrupación de conceptos facturables.
  final ProformasRepository repository;

  /// Identificador único del cliente cuyos conceptos pendientes se administran.
  final String clientId;

  /// Construye el ViewModel asignando el repositorio y el cliente de referencia.
  PendingConceptsViewModel({
    required this.repository,
    required this.clientId,
  });

  StreamSubscription<List<BillableConcept>>? _appointmentsSub;
  StreamSubscription<List<BillableConcept>>? _requestsSub;

  List<BillableConcept> _appointments = const [];
  List<BillableConcept> _requests = const [];
  final Set<String> _selected = <String>{};

  bool _appointmentsLoaded = false;
  bool _requestsLoaded = false;
  String? _errorMessage;
  Failure? _failure;

  /// Detalle tipado de la falla reportada por las suscripciones.
  Failure? get failure => _failure;

  /// Configuración fiscal vigente para la vista previa del total.
  PublicPricingConfig pricingConfig = const PublicPricingConfig(
    ivaBp: 1500,
    iceIncludedInIvaBase: true,
  );

  /// Lista integral combinada de citas completadas y pedidos listos para entrega.
  List<BillableConcept> get concepts => [..._appointments, ..._requests];

  /// Conjunto inmutable de identificadores de conceptos seleccionados.
  Set<String> get selectedRefIds => Set.unmodifiable(_selected);

  /// Indica si alguna de las dos fuentes de conceptos pendientes continúa cargando.
  bool get isLoading => !_appointmentsLoaded || !_requestsLoaded;

  /// Mensaje o código de error en caso de fallo al consultar conceptos.
  String? get errorMessage => _errorMessage;

  /// Determina si el operador administrativo ha seleccionado al menos un concepto.
  bool get hasSelection => _selected.isNotEmpty;

  /// Inicia la escucha reactiva de citas y pedidos facturables del cliente.
  void init() {
    _appointmentsLoaded = false;
    _requestsLoaded = false;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    _appointmentsSub?.cancel();
    _appointmentsSub =
        repository.streamBillableAppointments(clientId).listen((items) {
      _appointments = items;
      _appointmentsLoaded = true;
      _pruneSelection();
      notifyListeners();
    }, onError: (Object e) {
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      _appointmentsLoaded = true;
      notifyListeners();
    });

    _requestsSub?.cancel();
    _requestsSub =
        repository.streamBillableProductRequests(clientId).listen((items) {
      _requests = items;
      _requestsLoaded = true;
      _pruneSelection();
      notifyListeners();
    }, onError: (Object e) {
      _failure = Failure.fromException(e);
      _errorMessage = _failure?.code;
      _requestsLoaded = true;
      notifyListeners();
    });
  }

  /// Retira de la selección lo que dejó de estar disponible.
  ///
  /// Un concepto puede desaparecer mientras la pantalla está abierta —el cliente
  /// lo cancela, u otro miembro del personal lo incorpora a su propia proforma—,
  /// y enviarlo entonces sólo conseguiría que la callable rechazara la operación
  /// entera.
  void _pruneSelection() {
    final vivos = concepts.map((c) => c.refId).toSet();
    _selected.removeWhere((refId) => !vivos.contains(refId));
  }

  /// Alterna el estado de selección de un concepto facturable por su identificador.
  void toggle(String refId) {
    if (!_selected.remove(refId)) {
      _selected.add(refId);
    }
    notifyListeners();
  }

  /// Comprueba si un concepto particular se encuentra actualmente seleccionado.
  bool isSelected(String refId) => _selected.contains(refId);

  /// Conceptos seleccionados en la forma que espera `addProformaItems`.
  List<Map<String, dynamic>> selectedItemRefs() {
    return concepts
        .where((c) => _selected.contains(c.refId))
        .map((c) => c.toItemRef())
        .toList();
  }

  /// Desglose de un concepto con los porcentajes congelados en él, no con los
  /// vigentes hoy: es lo que se le prometió al cliente y lo que se le cobrará.
  LinePricingResult pricingOf(BillableConcept concept) {
    return calculateLinePricing(
      basePriceCents: concept.basePriceCents * concept.quantity,
      iceBp: concept.iceBp,
      ivaBp: concept.ivaBp,
      iceIncludedInIvaBase: pricingConfig.iceIncludedInIvaBase,
    );
  }

  /// Total con impuestos de lo seleccionado, para que el personal sepa cuánto
  /// va a cobrar antes de crear el documento.
  int get selectedTotalCents {
    var total = 0;
    for (final concept in concepts) {
      if (!_selected.contains(concept.refId)) continue;
      total += pricingOf(concept).finalPriceCents;
    }
    return total;
  }

  /// Subtotal base en centavos (sin impuestos) sumando los conceptos seleccionados.
  int get selectedSubtotalCents {
    var subtotal = 0;
    for (final concept in concepts) {
      if (!_selected.contains(concept.refId)) continue;
      subtotal += concept.basePriceCents * concept.quantity;
    }
    return subtotal;
  }

  /// Cancela las suscripciones reactivas de citas y solicitudes facturables.
  @override
  void dispose() {
    _appointmentsSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }
}
