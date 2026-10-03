// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: clinical_repository.dart
// Propósito: Repositorio para la gestión de registros clínicos electrónicos, versiones históricas y adjuntos.
// =========================================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/clinical_record.dart';
import 'package:mipetshop/data/models/clinical_record_version.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/data/services/storage_service.dart';

/// Repositorio para la gestión del expediente clínico electrónico veterinario.
///
/// Administra las entradas clínicas en `/pets/{petId}/clinical_records`, su historial de versiones
/// en `/versions`, y la carga segura de archivos y fotografías a través de intenciones en Cloud Storage.
class ClinicalRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Invocador de Cloud Functions de negocio.
  final FunctionsService _functionsService;

  /// Servicio para la transferencia segura de archivos en Cloud Storage.
  final StorageService _storageService;

  /// Constructor del repositorio clínico.
  ClinicalRepository({
    required this.firestore,
    FunctionsService? functionsService,
    StorageService? storageService,
  })  : _functionsService = functionsService ?? FunctionsService(),
        _storageService = storageService ?? StorageService();

  FirebaseFirestore get _firestore => firestore;

  CollectionReference<Map<String, dynamic>> _recordsCol(String petId) =>
      _firestore.collection('pets').doc(petId).collection('clinical_records');

  CollectionReference<Map<String, dynamic>> _versionsCol(String petId, String recordId) =>
      _recordsCol(petId).doc(recordId).collection('versions');

  /// Escucha en tiempo real los registros clínicos de una mascota ordenados descendentemente por fecha.
  ///
  /// @param petId Identificador de la mascota.
  /// @return Stream con la lista reactiva de [ClinicalRecord].
  Stream<List<ClinicalRecord>> streamClinicalRecords(String petId) {
    return _recordsCol(petId)
        .orderBy('attentionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClinicalRecord.fromFirestore(doc))
          .toList();
    });
  }

  /// Recupera un registro clínico específico por su ID.
  ///
  /// @param petId ID de la mascota.
  /// @param recordId ID del registro clínico.
  Future<Result<ClinicalRecord?>> getClinicalRecord(String petId, String recordId) async {
    try {
      final doc = await _recordsCol(petId).doc(recordId).get();
      if (!doc.exists || doc.data() == null) {
        return const Ok(null);
      }
      return Ok(ClinicalRecord.fromFirestore(doc));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real el historial inmutable de versiones de una entrada médica.
  ///
  /// Consulta la subcolección `/pets/{petId}/clinical_records/{recordId}/versions`.
  Stream<List<ClinicalRecordVersion>> streamRecordVersions(String petId, String recordId) {
    return _versionsCol(petId, recordId)
        .orderBy('version', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClinicalRecordVersion.fromFirestore(doc))
          .toList();
    });
  }

  /// Crea una nueva entrada clínica mediante la Cloud Function [createClinicalRecord].
  ///
  /// Congela la instantánea legal del paciente y su tutor, registrando bloques médicos opcionales.
  Future<Result<String>> createClinicalRecord({
    required String petId,
    required String type,
    String? attentionDate,
    String? attentionTime,
    String? sourceAppointmentId,
    Map<String, dynamic>? consultation,
    Map<String, dynamic>? physicalExam,
    Map<String, dynamic>? plan,
    Map<String, dynamic>? followUp,
    Map<String, dynamic>? prevention,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final res = await _functionsService.createClinicalRecord(
      petId: petId,
      type: type,
      attentionDate: attentionDate,
      attentionTime: attentionTime,
      sourceAppointmentId: sourceAppointmentId,
      consultation: consultation,
      physicalExam: physicalExam,
      plan: plan,
      followUp: followUp,
      prevention: prevention,
      attachments: attachments,
    );

    return res.when(
      ok: (data) => Ok(data['recordId'] as String? ?? ''),
      err: (f) => Err(f),
    );
  }

  /// Corrige y versiona una entrada clínica existente mediante [updateClinicalRecord].
  Future<Result<void>> updateClinicalRecord({
    required String petId,
    required String recordId,
    Map<String, dynamic>? consultation,
    Map<String, dynamic>? physicalExam,
    Map<String, dynamic>? plan,
    Map<String, dynamic>? followUp,
    Map<String, dynamic>? prevention,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final res = await _functionsService.updateClinicalRecord(
      petId: petId,
      recordId: recordId,
      consultation: consultation,
      physicalExam: physicalExam,
      plan: plan,
      followUp: followUp,
      prevention: prevention,
      attachments: attachments,
    );

    return res.when(
      ok: (_) => const Ok(null),
      err: (f) => Err(f),
    );
  }

  /// Anula inmutablemente una entrada clínica errónea mediante [annulClinicalRecord].
  ///
  /// @param petId ID de la mascota.
  /// @param recordId ID del registro a anular.
  /// @param reason Motivo obligatorio de la anulación.
  Future<Result<void>> annulClinicalRecord({
    required String petId,
    required String recordId,
    required String reason,
  }) async {
    final res = await _functionsService.annulClinicalRecord(
      petId: petId,
      recordId: recordId,
      reason: reason,
    );

    return res.when(
      ok: (_) => const Ok(null),
      err: (f) => Err(f),
    );
  }

  /// Sube la fotografía de una mascota mediante la tubería segura de intenciones de carga.
  ///
  /// @param ownerUid UID del dueño.
  /// @param petId ID de la mascota.
  /// @param fileName Nombre del archivo.
  /// @param mimeType Tipo MIME.
  /// @param bytes Contenido en bytes.
  /// @return [Result] con la ruta final en Cloud Storage.
  Future<Result<String>> uploadPetPhoto({
    required String ownerUid,
    required String petId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    try {
      final intentId = _firestore.collection('upload_intents').doc().id;
      final intentRef = _firestore.collection('upload_intents').doc(intentId);

      final now = BusinessClock.now();
      final expiresAt = Timestamp.fromDate(now.add(const Duration(hours: 1)));

      await intentRef.set({
        'id': intentId,
        'ownerUid': ownerUid,
        'purpose': 'PET_PHOTO',
        'targetId': petId,
        'status': 'PENDING',
        'rejectionCode': null,
        'resultPath': null,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });

      final uploadTask = _storageService.uploadToUploads(
        userId: ownerUid,
        intentId: intentId,
        fileName: fileName,
        data: bytes,
        metadata: SettableMetadata(contentType: mimeType),
      );

      await uploadTask;

      final resultPath = 'media/pets/$petId/$intentId.webp';
      return Ok(resultPath);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Sube un documento o estudio complementario mediante la tubería de intenciones.
  Future<Result<ClinicalAttachment>> uploadClinicalAttachment({
    required String staffUid,
    required String petId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    required String description,
  }) async {
    try {
      final intentId = _firestore.collection('upload_intents').doc().id;
      final intentRef = _firestore.collection('upload_intents').doc(intentId);

      final now = BusinessClock.now();
      final expiresAt = Timestamp.fromDate(now.add(const Duration(hours: 1)));

      await intentRef.set({
        'id': intentId,
        'ownerUid': staffUid,
        'purpose': 'CLINICAL_ATTACHMENT',
        'targetId': petId,
        'status': 'PENDING',
        'rejectionCode': null,
        'resultPath': null,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });

      final uploadTask = _storageService.uploadToUploads(
        userId: staffUid,
        intentId: intentId,
        fileName: fileName,
        data: bytes,
        metadata: SettableMetadata(contentType: mimeType),
      );

      await uploadTask;

      final resultPath = 'media/clinical/$petId/$intentId.pdf';
      final attachment = ClinicalAttachment(
        id: intentId,
        storagePath: resultPath,
        fileType: mimeType,
        description: description,
        sizeBytes: bytes.lengthInBytes,
        uploadedAt: now,
      );

      return Ok(attachment);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Descarga directamente en memoria los bytes de un archivo adjunto clínico evaluando reglas de Storage.
  Future<Result<Uint8List?>> getAttachmentBytes(String storagePath) async {
    try {
      final bytes = await _storageService.getClinicalAttachmentBytes(storagePath);
      return Ok(bytes);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }
}
