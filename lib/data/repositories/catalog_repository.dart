// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: catalog_repository.dart
// Propósito: Repositorio para la administración y consulta del catálogo de servicios y parámetros fiscales.
// =========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/service_dto.dart';
import 'package:mipetshop/domain/models/service.dart';

/// Configuración pública impositiva leída desde `/business_config/public_pricing`.
class PublicPricingConfig {
  /// Tarifa de IVA en puntos base (ej. 1500 = 15%).
  final int ivaBp;

  /// Indica si el ICE integra la base imponible sujeta a IVA.
  final bool iceIncludedInIvaBase;

  /// Constructor inmutable de configuración de precios e impuestos.
  const PublicPricingConfig({
    required this.ivaBp,
    required this.iceIncludedInIvaBase,
  });

  /// Mapea el documento de Firestore a la configuración impositiva.
  factory PublicPricingConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException('Datos de configuración impositiva nulos.');
    }
    final rawIvaBp = data['ivaBp'];
    if (rawIvaBp == null || rawIvaBp is! num) {
      throw const FormatException('ivaBp es obligatorio en /business_config/public_pricing y debe ser numérico.');
    }
    return PublicPricingConfig(
      ivaBp: rawIvaBp.toInt(),
      iceIncludedInIvaBase: (data['iceIncludedInIvaBase'] as bool?) ?? true,
    );
  }
}

/// Repositorio de catálogo de servicios interactuando con Cloud Firestore.
///
/// Gestiona la colección `/services` bajo reglas de inmutabilidad y filtrado seguro,
/// además de proveer acceso a los parámetros impositivos del establecimiento.
class CatalogRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Constructor del repositorio de catálogo.
  CatalogRepository({required this.firestore});

  FirebaseFirestore get _firestore => firestore;

  CollectionReference<Map<String, dynamic>> get _servicesCol =>
      _firestore.collection('services');

  DocumentReference<Map<String, dynamic>> get _pricingDoc =>
      _firestore.collection('business_config').doc('public_pricing');

  /// Normaliza una cadena de texto a minúsculas, sin tildes ni caracteres diacríticos para búsqueda canónica.
  static String normalizeSearchName(String input) {
    var output = input.toLowerCase().trim();
    const withDiacritics = 'áéíóúüñÁÉÍÓÚÜÑ';
    const withoutDiacritics = 'aeiouunAEIOUUN';

    for (var i = 0; i < withDiacritics.length; i++) {
      output = output.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return output.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Mapea los documentos de la colección descartando de manera segura aquellos que presenten esquemas corruptos.
  List<Service> _mapServices(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final services = <Service>[];
    for (final doc in snapshot.docs) {
      try {
        services.add(ServiceDto.fromFirestore(doc).toDomain());
      } on Object {
        continue;
      }
    }
    return services;
  }

  /// Escucha en tiempo real la lista de servicios del catálogo en `/services`.
  ///
  /// @param onlyActive Si es true, filtra únicamente los servicios marcados como activos.
  Stream<List<Service>> streamServices({bool onlyActive = false}) {
    Query<Map<String, dynamic>> query = _servicesCol;
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map(_mapServices);
  }

  /// Obtiene de forma única la lista completa de servicios.
  ///
  /// @param onlyActive Si es true, retorna solo servicios activos.
  Future<Result<List<Service>>> getServices({bool onlyActive = false}) async {
    try {
      Query<Map<String, dynamic>> query = _servicesCol;
      if (onlyActive) {
        query = query.where('isActive', isEqualTo: true);
      }

      final snapshot = await query.get();
      return Ok(_mapServices(snapshot));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Obtiene un servicio específico a partir de su ID en Firestore.
  ///
  /// @param serviceId Identificador del documento.
  Future<Result<Service>> getServiceById(String serviceId) async {
    try {
      final doc = await _servicesCol.doc(serviceId).get();
      if (!doc.exists || doc.data() == null) {
        return const Err(
          DomainFailure(
            code: 'NOT_FOUND',
            debugMessage: 'Servicio no encontrado.',
          ),
        );
      }
      return Ok(ServiceDto.fromFirestore(doc).toDomain());
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Registra un nuevo servicio en el catálogo respetando la lista blanca de 10 atributos autoritativos.
  ///
  /// @param uid UID del administrador responsable.
  /// @param name Nombre comercial del servicio.
  /// @param description Descripción detallada.
  /// @param basePriceCents Precio base en centavos.
  /// @param iceBp Tasa impositiva de ICE en puntos base.
  /// @param isClinical Requiere historial clínico.
  /// @param estimatedDurationMinutes Minutos requeridos en agenda.
  /// @param isActive Habilitado para agendamiento.
  /// @param customId Identificador personalizado opcional.
  /// @return [Result] con el ID del servicio creado.
  Future<Result<String>> createService({
    required String uid,
    required String name,
    required String description,
    required int basePriceCents,
    int iceBp = 0,
    required bool isClinical,
    required int estimatedDurationMinutes,
    bool isActive = true,
    String? customId,
  }) async {
    try {
      final docRef = customId != null && customId.isNotEmpty
          ? _servicesCol.doc(customId)
          : _servicesCol.doc();

      final serviceId = docRef.id;
      final trimmedName = name.trim();
      final searchName = normalizeSearchName(trimmedName);

      final payload = <String, dynamic>{
        'id': serviceId,
        'name': trimmedName,
        'searchName': searchName,
        'description': description.trim(),
        'basePriceCents': basePriceCents,
        'iceBp': iceBp,
        'isClinical': isClinical,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'isActive': isActive,
        'audit': <String, dynamic>{
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      };

      await docRef.set(payload);
      return Ok(serviceId);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Actualiza los parámetros de un servicio existente en `/services/{serviceId}`.
  Future<Result<void>> updateService({
    required String serviceId,
    required String uid,
    required String name,
    required String description,
    required int basePriceCents,
    int iceBp = 0,
    required bool isClinical,
    required int estimatedDurationMinutes,
    required bool isActive,
  }) async {
    try {
      final trimmedName = name.trim();
      final searchName = normalizeSearchName(trimmedName);

      final payload = <String, dynamic>{
        'id': serviceId,
        'name': trimmedName,
        'searchName': searchName,
        'description': description.trim(),
        'basePriceCents': basePriceCents,
        'iceBp': iceBp,
        'isClinical': isClinical,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'isActive': isActive,
        'audit': <String, dynamic>{
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      };

      await _servicesCol.doc(serviceId).set(payload, SetOptions(merge: true));
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Cambia el estado de activación lógica de un servicio (baja lógica).
  Future<Result<void>> toggleServiceActive({
    required String serviceId,
    required String uid,
    required bool isActive,
  }) async {
    try {
      await _servicesCol.doc(serviceId).update({
        'isActive': isActive,
        'audit': <String, dynamic>{
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Consulta los parámetros fiscales del establecimiento desde `/business_config/public_pricing`.
  Future<Result<PublicPricingConfig>> getPublicPricing() async {
    try {
      final doc = await _pricingDoc.get();
      return Ok(PublicPricingConfig.fromMap(doc.data()));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real la configuración impositiva vigente.
  Stream<PublicPricingConfig> streamPublicPricing() {
    return _pricingDoc.snapshots().map((snapshot) {
      return PublicPricingConfig.fromMap(snapshot.data());
    });
  }
}
