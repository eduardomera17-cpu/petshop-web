// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: storage_service.dart
// Propósito: Servicio de almacenamiento autenticado y descarga segura en memoria con Firebase Cloud Storage.
// =========================================================================

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mipetshop/app/app_config.dart';

/// Servicio de infraestructura para almacenamiento de archivos en Firebase Cloud Storage.
///
/// Implementa políticas estrictas de seguridad:
/// 1. Zona de subida controlada: Escribe en la ruta perimetral `uploads/{userId}/{intentId}/{fileName}`.
/// 2. Lectura autenticada en memoria vía `Reference.getData()`: Evalúa las reglas de seguridad
///    sin exponer URLs públicas de descarga en ningún momento.
class StorageService {
  /// Instancia de conexión a Firebase Storage.
  final FirebaseStorage _storage;

  /// Tamaño máximo permitido para descargas en memoria: 10 MB (10485760 bytes).
  static const int maxDownloadBufferBytes = 10485760;

  /// Nombre del bucket de Cloud Storage del proyecto (inyectado en la compilación, ver [AppConfig]).
  static const String officialBucket = AppConfig.firebaseStorageBucket;

  /// Constructor del servicio de almacenamiento.
  StorageService({FirebaseStorage? storage})
      : _storage = storage ??
            FirebaseStorage.instanceFor(
              bucket: officialBucket,
            );

  /// Sube un archivo a la zona segura `uploads/{userId}/{intentId}/{fileName}`.
  ///
  /// @param userId UID del usuario autenticado que realiza la carga.
  /// @param intentId Identificador de intención único para aislamiento del archivo.
  /// @param fileName Nombre del archivo a cargar.
  /// @param data Bytes del archivo binario.
  /// @param metadata Metadatos opcionales (ej. Content-Type).
  /// @return [UploadTask] para supervisar el progreso de la subida.
  UploadTask uploadToUploads({
    required String userId,
    required String intentId,
    required String fileName,
    required Uint8List data,
    SettableMetadata? metadata,
  }) {
    final sanitizedFileName = fileName.trim().replaceAll('/', '_');
    final uploadPath = 'uploads/$userId/$intentId/$sanitizedFileName';
    final ref = _storage.ref(uploadPath);

    return ref.putData(data, metadata);
  }

  /// Descarga un archivo autenticado directamente en memoria evaluando las reglas de almacenamiento.
  ///
  /// @param storagePath Ruta relativa del objeto en Cloud Storage.
  /// @param maxBytes Límite de bytes permitidos en la descarga (por defecto 10 MB).
  /// @return Bytes del archivo en [Uint8List] o null si no se encuentra.
  Future<Uint8List?> getData(
    String storagePath, {
    int maxBytes = maxDownloadBufferBytes,
  }) async {
    final ref = _storage.ref(storagePath);
    return await ref.getData(maxBytes);
  }

  /// Descarga los bytes del avatar o fotografía de perfil del usuario.
  ///
  /// @param ownerUid UID del propietario del perfil.
  /// @param intentId Identificador de la imagen.
  /// @return Bytes de la imagen en formato WebP o null.
  Future<Uint8List?> getUserPhotoBytes({
    required String ownerUid,
    required String intentId,
  }) async {
    final path = 'media/users/$ownerUid/$intentId.webp';
    return await getData(path);
  }

  /// Descarga la fotografía de un producto del catálogo.
  ///
  /// @param imagePath Ruta relativa de la imagen del producto en Storage.
  Future<Uint8List?> getProductImageBytes(String imagePath) async {
    return await getData(imagePath);
  }

  /// Descarga en memoria un documento o estudio adjunto a la historia clínica.
  ///
  /// @param storagePath Ruta del archivo clínico en Storage.
  Future<Uint8List?> getClinicalAttachmentBytes(String storagePath) async {
    return await getData(storagePath);
  }

  /// Descarga una imagen compartida en una conversación de chat.
  ///
  /// @param imagePath Ruta de la imagen en Storage.
  Future<Uint8List?> getChatImageBytes(String imagePath) async {
    return await getData(imagePath);
  }
}
