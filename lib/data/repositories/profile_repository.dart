// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: profile_repository.dart
// Propósito: Repositorio para la lectura, actualización y carga segura de avatar del perfil de usuario en Firestore y Firebase Storage.
// =========================================================================

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:mipetshop/domain/models/user_profile.dart';

/// Repositorio para la gestión del perfil del cliente y usuarios autenticados.
///
/// Implementa lectura y actualización directa sobre el documento `/users/{uid}`,
/// preservando rigurosamente la inmutabilidad de credenciales críticas (`email`),
/// rol institucional (`role`) y estado de cuenta (`status`).
/// Gestiona la carga de avatar a través de la arquitectura de intenciones de subida
/// (`upload_intents`) y la descarga de binarios en memoria mediante `Reference.getData()`.
class ProfileRepository {
  /// Instancia del cliente de Firestore.
  final FirebaseFirestore firestore;

  /// Servicio auxiliar para operaciones de carga y descarga en Firebase Storage.
  final StorageService storageService;

  /// Constructor del repositorio con inyección de dependencias.
  ProfileRepository({
    required this.firestore,
    StorageService? storageService,
  }) : storageService = storageService ?? StorageService();

  /// Normaliza el nombre completo para el campo de búsqueda `searchName` (minúsculas y sin acentos).
  ///
  /// Remueve tildes y diéresis de caracteres comunes en español y trunca a 100 caracteres
  /// para optimizar las consultas por prefijo en índices compuestos de Firestore.
  static String normalizeSearchName(String input) {
    var result = input.trim().toLowerCase();
    const accents = 'áéíóúüñ';
    const replacements = 'aeiouun';
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], replacements[i]);
    }
    if (result.length > 100) {
      result = result.substring(0, 100);
    }
    return result;
  }

  /// Obtiene el perfil de usuario a partir de su identificador único [uid].
  ///
  /// Realiza una consulta directa a la colección `/users/{uid}`. Si el documento
  /// no existe, retorna un fallo [DomainFailure] con código `NOT_FOUND`. Si la consulta
  /// es exitosa, deserializa y retorna la entidad [UserProfile] envuelta en [Ok].
  Future<Result<UserProfile>> getUserProfile(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Err(
          DomainFailure(
            code: 'NOT_FOUND',
            debugMessage: 'Usuario no encontrado en la colección users',
          ),
        );
      }

      final profile = UserProfile.fromFirestore(doc);
      return Ok(profile);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Escucha en tiempo real los cambios del perfil del usuario [uid].
  ///
  /// Emite una nueva instancia de [UserProfile] cada vez que el documento es modificado
  /// en Firestore (por ejemplo, tras una actualización de datos personales o avatar).
  /// Si el documento no existe, emite `null`.
  Stream<UserProfile?> profileStream(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromFirestore(snapshot);
    });
  }

  /// Actualiza los datos permitidos del perfil del cliente mediante escritura directa.
  ///
  /// Respeta estrictamente la lista blanca de campos modificables por el cliente:
  /// `fullName`, `phone`, `documentType`, `documentNumber`, `address`, `searchName` y `audit`.
  /// El correo `email`, `role`, `status` y `photoPath` son inmutables en este método y
  /// están protegidos adicionalmente por las reglas de seguridad de Firestore.
  /// Genera automáticamente [searchName] normalizado y sella la auditoría con [FieldValue.serverTimestamp].
  Future<Result<void>> updateUserProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String documentType,
    required String documentNumber,
    required String address,
  }) async {
    try {
      final docRef = firestore.collection('users').doc(uid);
      final searchName = normalizeSearchName(fullName);

      await docRef.update({
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'documentType': documentType.trim(),
        'documentNumber': documentNumber.trim(),
        'address': address.trim(),
        'searchName': searchName,
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      });

      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Inicia la carga de foto de perfil creando una intención de subida y depositando el binario.
  ///
  /// Implementa el patrón de dos fases:
  /// 1. Registra un documento en `upload_intents` con expiración a 1 hora y estado `PENDING`.
  /// 2. Sube el binario [bytes] a la ruta temporal `uploads/{uid}/{intentId}/{fileName}`
  ///    usando [storageService.uploadToUploads].
  /// Una Cloud Function en segundo plano procesa, valida el formato y publica la foto
  /// definitiva en la ruta canónica del usuario.
  Future<Result<String>> uploadProfilePhoto({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final intentId = firestore.collection('upload_intents').doc().id;
      final intentRef = firestore.collection('upload_intents').doc(intentId);

      final now = BusinessClock.now();
      final expiresAt = Timestamp.fromDate(now.add(const Duration(hours: 1)));

      await intentRef.set({
        'id': intentId,
        'ownerUid': uid,
        'purpose': 'USER_PHOTO',
        'targetId': null,
        'status': 'PENDING',
        'rejectionCode': null,
        'resultPath': null,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });

      final uploadTask = storageService.uploadToUploads(
        userId: uid,
        intentId: intentId,
        fileName: fileName,
        data: bytes,
        metadata: SettableMetadata(contentType: mimeType),
      );

      await uploadTask;
      return Ok(intentId);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Descarga los bytes de una foto utilizando `Reference.getData()`.
  ///
  /// Conforme a las directrices de seguridad de la tesis y ADR-019, está prohibido
  /// taxativamente el uso de `getDownloadURL()`. Las imágenes se descargan de forma
  /// autenticada directamente en memoria como [Uint8List].
  Future<Result<Uint8List?>> getPhotoBytes(String? storagePath) async {
    if (storagePath == null || storagePath.trim().isEmpty) {
      return const Ok(null);
    }

    try {
      final bytes = await storageService.getData(storagePath.trim());
      return Ok(bytes);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }
}
