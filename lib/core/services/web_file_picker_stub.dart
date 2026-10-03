// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/services/web_file_picker_stub.dart
// Propósito: Definición de tipos y stub para el selector de archivos en entornos de prueba y plataformas nativas.
// =========================================================================

import 'dart:typed_data';

/// Encapsula la información y contenido binario de un archivo seleccionado por el usuario.
class PickedFileData {
  /// Nombre del archivo con su extensión.
  final String name;

  /// Tamaño del archivo en bytes.
  final int size;

  /// Tipo MIME detectado o inferido (ej. 'image/jpeg', 'image/png').
  final String mimeType;

  /// Bytes del archivo binario leídos en memoria.
  final Uint8List bytes;

  /// Constructor inmutable de los datos del archivo seleccionado.
  const PickedFileData({
    required this.name,
    required this.size,
    required this.mimeType,
    required this.bytes,
  });
}

/// Estados posibles resultantes de la interacción con el selector de archivos.
enum FilePickStatus {
  /// Archivo seleccionado y leído exitosamente.
  success,

  /// El usuario canceló o cerró el cuadro de diálogo de selección.
  cancelled,

  /// El formato o tipo MIME no está permitido por la política del sistema.
  unsupportedFormat,

  /// Archivo rechazado por corresponder a formato HEIC/HEIF sin soporte web directo.
  rejectedHeic,

  /// El archivo excede el tamaño máximo permitido en bytes.
  sizeExceeded,

  /// Ocurrió un error inesperado al leer el archivo.
  error,
}

/// Resultado estructurado de una operación de selección de archivo.
class FilePickResult {
  /// Estado final de la selección.
  final FilePickStatus status;

  /// Datos del archivo en caso de éxito.
  final PickedFileData? file;

  /// Mensaje de error descriptivo en caso de fallo.
  final String? errorMessage;

  /// Constructor privado para inicializar el resultado.
  const FilePickResult._({
    required this.status,
    this.file,
    this.errorMessage,
  });

  /// Crea un resultado exitoso con el archivo cargado.
  const FilePickResult.success(PickedFileData file)
      : this._(status: FilePickStatus.success, file: file);

  /// Crea un resultado cancelado por el usuario.
  const FilePickResult.cancelled()
      : this._(status: FilePickStatus.cancelled);

  /// Crea un resultado para formato no soportado.
  const FilePickResult.unsupportedFormat()
      : this._(status: FilePickStatus.unsupportedFormat);

  /// Crea un resultado para formato HEIC no admitido.
  const FilePickResult.rejectedHeic()
      : this._(status: FilePickStatus.rejectedHeic);

  /// Crea un resultado para tamaño excedido.
  const FilePickResult.sizeExceeded()
      : this._(status: FilePickStatus.sizeExceeded);

  /// Crea un resultado de error con mensaje explicativo.
  const FilePickResult.error(String message)
      : this._(status: FilePickStatus.error, errorMessage: message);

  /// Indica si la selección fue exitosa.
  bool get isSuccess => status == FilePickStatus.success;

  /// Indica si la selección fue cancelada.
  bool get isCancelled => status == FilePickStatus.cancelled;
}

/// Implementación stub del selector de archivos para plataformas que no soportan DOM o pruebas VM.
///
/// Simula la interfaz de selección de archivos retornando inmediatamente [FilePickResult.cancelled].
///
/// @param maxBytes Límite de tamaño máximo permitido en bytes (por defecto 5 MB).
/// @param allowedMimeTypes Colección de tipos MIME permitidos para el filtro de archivos.
/// @return [FilePickResult] con el resultado de la selección cancelada.
Future<FilePickResult> pickPlatformFile({
  int maxBytes = 5 * 1024 * 1024,
  List<String> allowedMimeTypes = const [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/avif',
  ],
}) async {
  return const FilePickResult.cancelled();
}
