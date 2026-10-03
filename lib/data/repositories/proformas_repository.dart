// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: proformas_repository.dart
// Propósito: Repositorio para la gestión de proformas, cotizaciones, cálculo de impuestos ecuatorianos (IVA/ICE) y descarga segura de PDF en memoria.
// =========================================================================

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/billing_parameters_dto.dart';
import 'package:mipetshop/data/models/proforma_dto.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:mipetshop/domain/models/billing_parameters.dart';
import 'package:mipetshop/domain/models/proforma.dart';

/// Concepto o rubro de un cliente pendiente de facturar (FA-03).
///
/// Modela una cita completada no facturada o un pedido de productos listo para
/// retiro que todavía no ha sido asignado a ninguna proforma. Representa la
/// estructura canónica que consume la Cloud Function `addProformaItems`.
class BillableConcept {
  /// Discriminador de origen: `'APPOINTMENT'` o `'PRODUCT_REQUEST'`.
  final String itemType;

  /// Identificador único del documento de referencia (ID de cita o ID de pedido).
  final String refId;

  /// Descripción legible del servicio o artículo facturable.
  final String description;

  /// Detalle contextual complementario (ej. nombre de mascota, fecha y hora de cita).
  final String detail;

  /// Cantidad de unidades a facturar.
  final int quantity;

  /// Precio unitario base expresado en centavos enteros de dólar.
  final int basePriceCents;

  /// Tarifa de Impuesto a los Consumos Especiales (ICE) en puntos básicos.
  final int iceBp;

  /// Tarifa de Impuesto al Valor Agregado (IVA) en puntos básicos.
  final int ivaBp;

  /// Constructor inmutable de un concepto facturable.
  const BillableConcept({
    required this.itemType,
    required this.refId,
    required this.description,
    required this.detail,
    required this.quantity,
    required this.basePriceCents,
    required this.iceBp,
    required this.ivaBp,
  });

  /// Convierte el concepto a la estructura de referencia requerida por `addProformaItems`.
  Map<String, dynamic> toItemRef() => {'itemType': itemType, 'refId': refId};
}

/// Repositorio para la gestión de proformas, cotizaciones y parámetros tributarios (FA-01 a FA-08, ADR-019).
///
/// Orquesta el ciclo de vida documental de las cotizaciones y facturas preliminares:
/// creación de borrador (`DRAFT`), adición de rubros, ajuste de recargos/descuentos,
/// entrega al cliente (`DELIVERED`), cobro en ventanilla (`FINALIZED`) o anulación (`VOIDED`).
/// Centraliza la consulta reactiva de proformas y la descarga autenticada de comprobantes PDF.
class ProformasRepository {
  /// Instancia del cliente de Firestore.
  final FirebaseFirestore firestore;

  /// Servicio intermediario para invocar Cloud Functions transaccionales de facturación.
  final FunctionsService _functionsService;

  /// Servicio auxiliar para la descarga segura de archivos PDF en Firebase Storage.
  final StorageService _storageService;

  /// Constructor con soporte para inyección de dependencias y pruebas de unidad.
  ProformasRepository({
    required this.firestore,
    FunctionsService? functionsService,
    StorageService? storageService,
  })  : _functionsService = functionsService ?? FunctionsService(),
        _storageService = storageService ?? StorageService();

  /// Getter interno para acceder a Firestore.
  FirebaseFirestore get _firestore => firestore;

  /// Referencia a la colección raíz `proformas`.
  CollectionReference<Map<String, dynamic>> get _proformasCol =>
      _firestore.collection('proformas');

  /// Referencia al documento de configuración tributaria institucional.
  DocumentReference<Map<String, dynamic>> get _billingParamsDoc =>
      _firestore.collection('business_config').doc('billing_parameters');

  /// Retorna un flujo en tiempo real de las proformas visibles para el cliente (DELIVERED, FINALIZED, VOIDED).
  ///
  /// Excluye explícitamente proformas en estado borrador (`DRAFT`) según la regla de negocio CA-35.
  /// Ordena los comprobantes cronológicamente de forma descendente por [createdAt].
  Stream<List<Proforma>> streamClientProformas(String clientId) {
    return _proformasCol
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: ['DELIVERED', 'FINALIZED', 'VOIDED'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ProformaDto.fromFirestore(doc).toDomain())
          .toList();

      return items;
    });
  }

  /// Retorna un flujo administrativo de todas las proformas registradas, incluyendo borradores (`DRAFT`).
  ///
  /// Permite filtrar opcionalmente por [status]. Los resultados se ordenan en memoria
  /// de forma descendente por la fecha de emisión [issuedAt].
  Stream<List<Proforma>> streamAdminProformas({String? status}) {
    Query<Map<String, dynamic>> query = _proformasCol;
    if (status != null && status.trim().isNotEmpty) {
      query = query.where('status', isEqualTo: status.trim());
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ProformaDto.fromFirestore(doc).toDomain())
          .toList();

      items.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      return items;
    });
  }

  /// Obtiene de forma puntual una proforma específica a partir de su identificador [id].
  ///
  /// Retorna un [DomainFailure] con código `NOT_FOUND` si el documento no existe o
  /// carece de datos. En caso exitoso, retorna la entidad [Proforma] correspondiente.
  Future<Result<Proforma>> getProformaById(String id) async {
    try {
      final doc = await _proformasCol.doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return const Err(
          DomainFailure(
            code: 'NOT_FOUND',
            debugMessage: 'Proforma no encontrada.',
          ),
        );
      }

      return Ok(ProformaDto.fromFirestore(doc).toDomain());
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Descarga los bytes del archivo PDF generado de la proforma en memoria (ADR-019 / V-06).
  ///
  /// Prohibido taxativamente el uso de URLs públicas (`getDownloadURL`). La descarga
  /// se realiza de manera autenticada a través de [StorageService.getData] utilizando [storagePath].
  Future<Result<Uint8List>> downloadProformaPdf(String storagePath) async {
    try {
      final bytes = await _storageService.getData(storagePath);
      if (bytes == null || bytes.isEmpty) {
        return const Err(
          DomainFailure(
            code: 'STORAGE_ERROR',
            debugMessage: 'No se pudieron descargar los bytes del PDF.',
          ),
        );
      }
      return Ok(bytes);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  CollectionReference<Map<String, dynamic>> get _appointmentsCol =>
      _firestore.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _productRequestsCol =>
      _firestore.collection('product_requests');

  /// Retorna un flujo con las citas del cliente completadas y aún no facturadas (FA-03).
  ///
  /// Utiliza el índice compuesto `clientId + status + isBilled` (`status == 'COMPLETED'`,
  /// `isBilled == false`). Además, descarta en cliente aquellas citas que ya contengan
  /// un `proformaId` asignado para prevenir que un mismo rubro se facture dos veces.
  Stream<List<BillableConcept>> streamBillableAppointments(String clientId) {
    return _appointmentsCol
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'COMPLETED')
        .where('isBilled', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final concepts = <BillableConcept>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['proformaId'] != null) continue;
          concepts.add(BillableConcept(
            itemType: 'APPOINTMENT',
            refId: doc.id,
            description: (data['serviceName'] as String?) ?? '',
            detail: [
              (data['petName'] as String?) ?? '',
              (data['dateString'] as String?) ?? '',
              (data['timeSlot'] as String?) ?? '',
            ].where((p) => p.isNotEmpty).join(' · '),
            quantity: 1,
            basePriceCents: (data['basePriceCents'] as num?)?.toInt() ?? 0,
            iceBp: (data['iceBp'] as num?)?.toInt() ?? 0,
            ivaBp: (data['ivaBp'] as num?)?.toInt() ?? 0,
          ));
        } on Object {
          continue;
        }
      }
      return concepts;
    });
  }

  /// Retorna un flujo con las solicitudes de productos listas para retirar y no incorporadas (FA-03).
  ///
  /// Filtra pedidos del cliente con estado `READY_FOR_PICKUP` y excluye aquellos que
  /// ya posean un `proformaId` asociado en un borrador concurrente.
  Stream<List<BillableConcept>> streamBillableProductRequests(String clientId) {
    return _productRequestsCol
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'READY_FOR_PICKUP')
        .snapshots()
        .map((snapshot) {
      final concepts = <BillableConcept>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data['proformaId'] != null) continue;
          concepts.add(BillableConcept(
            itemType: 'PRODUCT_REQUEST',
            refId: doc.id,
            description: (data['productName'] as String?) ?? '',
            detail: (data['actionDateString'] as String?) ?? '',
            quantity: (data['quantity'] as num?)?.toInt() ?? 1,
            basePriceCents: (data['agreedUnitPriceCents'] as num?)?.toInt() ?? 0,
            iceBp: (data['iceBp'] as num?)?.toInt() ?? 0,
            ivaBp: (data['ivaBp'] as num?)?.toInt() ?? 0,
          ));
        } on Object {
          continue;
        }
      }
      return concepts;
    });
  }

  /// Crea un borrador de proforma mediante Cloud Function (`createProformaDraft`).
  ///
  /// Recibe el identificador del cliente [clientId] y opcionalmente una lista inicial de [items].
  /// Si se proporcionan [items], invoca secuencialmente `addProformaItems` para incluirlos
  /// dentro del nuevo borrador antes de retornar.
  Future<Result<String>> createProformaDraft({
    required String clientId,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final res = await _functionsService.createProformaDraft(
      clientId: clientId,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    final data = res.dataOrNull ?? {};
    final proformaId = (data['proformaId'] as String?) ?? '';

    if (items.isNotEmpty && proformaId.isNotEmpty) {
      final addRes = await _functionsService.addProformaItems(
        proformaId: proformaId,
        items: items,
      );
      if (addRes.isErr) {
        return Err(addRes.failureOrNull!);
      }
    }

    return Ok(proformaId);
  }

  /// Agrega ítems a una proforma en estado borrador mediante Cloud Function (`addProformaItems`).
  ///
  /// Recibe el [proformaId] y los [items] referenciados a citas o solicitudes de productos.
  /// El backend recalcula atómicamente subtotal, impuestos (IVA/ICE) y total general.
  Future<Result<void>> addProformaItems({
    required String proformaId,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _functionsService.addProformaItems(
      proformaId: proformaId,
      items: items,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    return const Ok(null);
  }

  /// Establece descuentos y recargos comerciales en la proforma (`setProformaAdjustments`).
  ///
  /// Recibe la lista de [adjustments] que modifican el valor final de la cotización
  /// garantizando que el total no sea negativo y recalculando bases imponibles.
  Future<Result<void>> setProformaAdjustments({
    required String proformaId,
    required List<Map<String, dynamic>> adjustments,
  }) async {
    final res = await _functionsService.setProformaAdjustments(
      proformaId: proformaId,
      adjustments: adjustments,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    return const Ok(null);
  }

  /// Marca una proforma como entregada al cliente mediante Cloud Function (`deliverProforma`).
  ///
  /// Transiciona el estado de `DRAFT` a `DELIVERED`, lo que hace visible la cotización
  /// en la interfaz del cliente y congela los rubros agregados para evitar modificaciones imprevistas.
  Future<Result<void>> deliverProforma({
    required String proformaId,
  }) async {
    final res = await _functionsService.deliverProforma(
      proformaId: proformaId,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    return const Ok(null);
  }

  /// Finaliza una proforma tras el cobro físico en ventanilla mediante Cloud Function (`finalizeProforma`).
  ///
  /// Transiciona el estado a `FINALIZED`, genera y guarda el documento PDF tributario definitivo
  /// en Firebase Storage y marca las citas involucradas como facturadas (`isBilled = true`).
  Future<Result<void>> finalizeProforma({
    required String proformaId,
  }) async {
    final res = await _functionsService.finalizeProforma(
      proformaId: proformaId,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    return const Ok(null);
  }

  /// Anula una proforma registrando el motivo mandatorio mediante Cloud Function (`voidProforma`).
  ///
  /// Transiciona el estado a `VOIDED`, liberando las citas y solicitudes de productos asociadas
  /// para que puedan ser facturadas en otro comprobante si corresponde, y registrando [reason]
  /// para auditoría contable.
  Future<Result<void>> voidProforma({
    required String proformaId,
    required String reason,
  }) async {
    final res = await _functionsService.voidProforma(
      proformaId: proformaId,
      reason: reason,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    return const Ok(null);
  }

  /// Obtiene de forma puntual los parámetros de facturación institucional (CF-13).
  ///
  /// Consulta el documento `/business_config/billing_parameters`. Si no existe,
  /// retorna un error de configuración no disponible [DomainFailure] con código `CONFIG_UNAVAILABLE`.
  Future<Result<BillingParameters>> getBillingParameters() async {
    try {
      final doc = await _billingParamsDoc.get();
      if (!doc.exists || doc.data() == null) {
        return const Err(
          DomainFailure(
            code: 'CONFIG_UNAVAILABLE',
            debugMessage: 'Parámetros de facturación no configurados.',
          ),
        );
      }
      return Ok(BillingParametersDto.fromFirestore(doc).toDomain());
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real los parámetros de facturación institucional (CF-13).
  ///
  /// Emite un nuevo [BillingParameters] ante cambios en las alícuotas de IVA o datos de razón social.
  Stream<BillingParameters> streamBillingParameters() {
    return _billingParamsDoc.snapshots().map((snapshot) {
      return BillingParametersDto.fromFirestore(snapshot).toDomain();
    });
  }

  /// Actualiza los parámetros de facturación respetando el esquema de seguridad y auditoría (CF-13).
  ///
  /// Persiste la razón social [businessName], RUC/identificación tributaria [taxId],
  /// dirección física [address], teléfono [phone], serie secuencial [proformaSeries],
  /// alícuota de IVA en puntos básicos [ivaBp] y la bandera [iceIncludedInIvaBase].
  /// Adjunta metadatos de auditoría con el usuario que efectúa el cambio [uid] y marca de tiempo del servidor.
  Future<Result<void>> updateBillingParameters({
    required String uid,
    required String businessName,
    required String taxId,
    required String address,
    required String phone,
    required String proformaSeries,
    required int ivaBp,
    required bool iceIncludedInIvaBase,
  }) async {
    try {
      final payload = <String, dynamic>{
        'businessName': businessName.trim(),
        'taxId': taxId.trim(),
        'address': address.trim(),
        'phone': phone.trim(),
        'proformaSeries': proformaSeries.trim(),
        'ivaBp': ivaBp,
        'iceIncludedInIvaBase': iceIncludedInIvaBase,
        'audit': <String, dynamic>{
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      };

      await _billingParamsDoc.update(payload);
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }
}
