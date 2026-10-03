// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: product_requests_repository.dart
// Propósito: Repositorio para la gestión de solicitudes y pedidos de productos, coordinando flujos reactivos de Firestore con transacciones atómicas en Cloud Functions.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/product_request_dto.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/domain/models/product_request.dart';

/// Repositorio de solicitudes de productos (TRD §2.8, PR-04 a PR-07, IN-04, FA-03, FA-05).
///
/// Implementa el patrón Repository para centralizar la lógica de persistencia y consumo
/// de pedidos de artículos. Separa las consultas de solo lectura (Streams reactivos y
/// Futures hacia Firestore) de las mutaciones que afectan el inventario comercial, las
/// cuales se delegan exclusivamente a Cloud Functions para garantizar atomicidad e
/// integridad transaccional del stock.
class ProductRequestsRepository {
  /// Instancia de Firestore para consultas y flujos en tiempo real.
  final FirebaseFirestore firestore;

  /// Servicio intermediario para invocar Cloud Functions seguras.
  final FunctionsService _functionsService;

  /// Constructor principal que permite la inyección de dependencias de infraestructura.
  ///
  /// Recibe [firestore] de forma obligatoria y opcionalmente [functionsService].
  ProductRequestsRepository({
    required this.firestore,
    FunctionsService? functionsService,
  })  : _functionsService = functionsService ?? FunctionsService();

  /// Getter interno para acceder a la instancia configurada de [FirebaseFirestore].
  FirebaseFirestore get _firestore => firestore;

  /// Referencia a la colección raíz `product_requests` en Firestore.
  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection('product_requests');

  /// Retorna un flujo en tiempo real de las solicitudes del cliente autenticado.
  ///
  /// Filtra la colección por el identificador de cliente [clientId] para cumplir
  /// con el aislamiento de datos entre usuarios. Cada documento obtenido se transforma
  /// de [ProductRequestDto] a la entidad inmutable [ProductRequest].
  Stream<List<ProductRequest>> streamMyRequests(String clientId) {
    return _requestsCol
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return ProductRequestDto.fromFirestore(doc).toDomain();
      }).toList();
      return items;
    });
  }

  /// Retorna un flujo en tiempo real de las solicitudes activas del cliente para el carrito (TRD §1.3.7).
  ///
  /// Filtra los documentos pertenecientes a [clientId] cuyos estados correspondan a
  /// `PENDING_DISPATCH` o `READY_FOR_PICKUP`. Permite a la interfaz del carrito y
  /// pedidos mostrar únicamente ítems pendientes de entrega o cobro.
  Stream<List<ProductRequest>> streamCartRequests(String clientId) {
    return _requestsCol
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: ['PENDING_DISPATCH', 'READY_FOR_PICKUP'])
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return ProductRequestDto.fromFirestore(doc).toDomain();
      }).toList();
      return items;
    });
  }

  /// Obtiene de forma puntual la lista de solicitudes registradas del cliente.
  ///
  /// Ejecuta un [get] único sobre Firestore para [clientId], encapsulando el resultado
  /// en un [Result] para garantizar el manejo seguro de fallos y excepciones de red.
  Future<Result<List<ProductRequest>>> getMyRequests(String clientId) async {
    try {
      final snapshot =
          await _requestsCol.where('clientId', isEqualTo: clientId).get();
      final items = snapshot.docs.map((doc) {
        return ProductRequestDto.fromFirestore(doc).toDomain();
      }).toList();
      return Ok(items);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Retorna un flujo de solicitudes para la cola de despacho y gestión de personal (IN-04).
  ///
  /// Permite filtrar dinámicamente por [status] (por ejemplo, 'PENDING_DISPATCH') si se
  /// proporciona un valor no vacío. Retorna una lista mapeada al dominio [ProductRequest].
  Stream<List<ProductRequest>> streamAdminRequests({String? status}) {
    Query<Map<String, dynamic>> query = _requestsCol;
    if (status != null && status.trim().isNotEmpty) {
      query = query.where('status', isEqualTo: status.trim());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductRequestDto.fromFirestore(doc).toDomain();
      }).toList();
    });
  }

  /// Crea una solicitud de productos con descuento atómico de stock mediante Cloud Functions (PR-04).
  ///
  /// Recibe la lista de artículos [items] estructurada según el contrato del backend y
  /// opcionalmente un [requestId] pregenerado. Si la función se ejecuta con éxito,
  /// retorna un [Ok] con el identificador asignado al nuevo pedido. En caso de falta de
  /// stock o error de validación, retorna un [Err] con el [Failure] correspondiente.
  Future<Result<String>> createProductRequest({
    required List<Map<String, dynamic>> items,
    String? requestId,
  }) async {
    final res = await _functionsService.createProductRequest(
      items: items,
      requestId: requestId,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    final data = res.dataOrNull ?? {};
    final newId = (data['requestId'] as String?) ?? '';
    return Ok(newId);
  }

  /// Cancela una solicitud de producto como cliente reponiendo stock de forma atómica (PR-07).
  ///
  /// Invoca la Cloud Function `cancelProductRequestByClient` pasando el identificador [requestId].
  /// El backend valida la propiedad del pedido y revierte el stock deducido dentro de
  /// una transacción atómica antes de marcar la solicitud como cancelada.
  Future<Result<void>> cancelProductRequestByClient({
    required String requestId,
  }) async {
    final res = await _functionsService.cancelProductRequestByClient(
      requestId: requestId,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    return const Ok(null);
  }

  /// Avanza el estado de una solicitud de `PENDING_DISPATCH` a `READY_FOR_PICKUP` (IN-04).
  ///
  /// Utilizado por el personal de la tienda para notificar que los artículos solicitados
  /// han sido preparados y están listos para retiro físico por el cliente.
  Future<Result<void>> advanceProductRequest({
    required String requestId,
  }) async {
    final res = await _functionsService.advanceProductRequest(
      requestId: requestId,
    );

    if (res.isErr) {
      return Err(res.failureOrNull!);
    }

    return const Ok(null);
  }
}
