// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: pets_repository.dart
// Propósito: Repositorio para la gestión de mascotas, registro directo, actualización y carga de fotos.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/business_clock.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/models/pet_dto.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/data/services/storage_service.dart';
import 'package:mipetshop/domain/models/pet.dart';

/// Repositorio de datos para mascotas en la colección `/pets`.
///
/// Implementa operaciones de consulta, creación directa por el cliente, actualización
/// de ficha y canalización de bajas y tubería segura de imágenes sin URLs públicas.
class PetsRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Invocador de Cloud Functions de negocio.
  final FunctionsService functionsService;

  /// Servicio para la transferencia segura de fotografías en Storage.
  final StorageService storageService;

  /// Constructor del repositorio de mascotas.
  PetsRepository({
    required this.firestore,
    FunctionsService? functionsService,
    StorageService? storageService,
  })  : functionsService = functionsService ?? FunctionsService(),
        storageService = storageService ?? StorageService();

  /// Normaliza el nombre de la mascota para el campo `searchName` (minúsculas y sin acentos).
  static String normalizeSearchName(String input) {
    var result = input.trim().toLowerCase();
    const accents = 'áéíóúÁÉÍÓÚüÜñÑ';
    const replacements = 'aeiouaeiouuunn';
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], replacements[i]);
    }
    if (result.length > 60) {
      result = result.substring(0, 60);
    }
    return result;
  }

  /// Consulta en tiempo real las mascotas pertenecientes a un dueño específico en `/pets`.
  ///
  /// @param ownerId UID del propietario.
  /// @return Stream con la lista de mascotas [Pet].
  Stream<List<Pet>> streamPets(String ownerId) {
    return firestore
        .collection('pets')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PetDto.fromFirestore(doc).toDomain())
          .toList();
    });
  }

  /// Obtiene de forma única la lista de mascotas del cliente autenticado.
  Future<Result<List<Pet>>> getPets(String ownerId) async {
    try {
      final snapshot = await firestore
          .collection('pets')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final pets = snapshot.docs
          .map((doc) => PetDto.fromFirestore(doc).toDomain())
          .toList();

      return Ok(pets);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Obtiene una mascota específica por su ID.
  Future<Result<Pet>> getPetById(String petId) async {
    try {
      final doc = await firestore.collection('pets').doc(petId).get();
      if (!doc.exists) {
        return const Err(
          DomainFailure(
            code: 'NOT_FOUND',
            debugMessage: 'Mascota no encontrada',
          ),
        );
      }

      return Ok(PetDto.fromFirestore(doc).toDomain());
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Registra una nueva mascota en `/pets` mediante alta directa del cliente.
  ///
  /// Respeta estrictamente las reglas de seguridad:
  /// - `ownerId == uid`
  /// - `status == 'ACTIVE'`
  /// - Campos biométricos nulos al inicio.
  Future<Result<String>> createPet({
    required String ownerId,
    required String name,
    required String species,
    required String sex,
    required String reproductiveStatus,
    String? breed,
    String? birthDate,
    String? allergies,
  }) async {
    try {
      final petId = firestore.collection('pets').doc().id;
      final petRef = firestore.collection('pets').doc(petId);
      final searchName = normalizeSearchName(name);

      final cleanBreed = (breed != null && breed.trim().isNotEmpty) ? breed.trim() : null;
      final cleanBirthDate = (birthDate != null && birthDate.trim().isNotEmpty) ? birthDate.trim() : null;
      final cleanAllergies = (allergies != null && allergies.trim().isNotEmpty) ? allergies.trim() : null;

      final payload = <String, dynamic>{
        'id': petId,
        'ownerId': ownerId,
        'name': name.trim(),
        'searchName': searchName,
        'species': species.trim(),
        'breed': cleanBreed,
        'birthDate': cleanBirthDate,
        'sex': sex.trim(),
        'reproductiveStatus': reproductiveStatus.trim(),
        'allergies': cleanAllergies,
        'photoPath': null,
        'lastWeightGrams': null,
        'lastWeightDate': null,
        'status': 'ACTIVE',
        'audit': {
          'createdBy': ownerId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      };

      await petRef.set(payload);
      return Ok(petId);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Actualiza los atributos biológicos editables de una mascota.
  Future<Result<void>> updatePet({
    required String petId,
    required String uid,
    required String name,
    required String species,
    required String sex,
    required String reproductiveStatus,
    String? breed,
    String? birthDate,
    String? allergies,
  }) async {
    try {
      final petRef = firestore.collection('pets').doc(petId);
      final searchName = normalizeSearchName(name);

      final cleanBreed = (breed != null && breed.trim().isNotEmpty) ? breed.trim() : null;
      final cleanBirthDate = (birthDate != null && birthDate.trim().isNotEmpty) ? birthDate.trim() : null;
      final cleanAllergies = (allergies != null && allergies.trim().isNotEmpty) ? allergies.trim() : null;

      final payload = <String, dynamic>{
        'name': name.trim(),
        'searchName': searchName,
        'species': species.trim(),
        'sex': sex.trim(),
        'reproductiveStatus': reproductiveStatus.trim(),
        'breed': cleanBreed,
        'birthDate': cleanBirthDate,
        'allergies': cleanAllergies,
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      };

      await petRef.update(payload);
      return const Ok(null);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Previsualiza las citas activas que se verían afectadas si se desactiva la mascota.
  Future<Result<Map<String, dynamic>>> previewDeactivation(String petId) async {
    return functionsService.previewPetDeactivation(petId: petId);
  }

  /// Da de baja lógica a una mascota mediante la Cloud Function transaccional [deactivatePet].
  Future<Result<Map<String, dynamic>>> deactivatePet(String petId) async {
    return functionsService.deactivatePet(petId: petId);
  }

  /// Registra una intención de carga en `/upload_intents` y sube la foto a la zona de recepción en Storage.
  Future<Result<String>> uploadPetPhoto({
    required String uid,
    required String petId,
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
        'purpose': 'PET_PHOTO',
        'targetId': petId,
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

  /// Descarga directamente en memoria los bytes de la foto evaluando reglas de seguridad.
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
