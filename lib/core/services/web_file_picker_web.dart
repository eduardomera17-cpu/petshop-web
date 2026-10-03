// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/services/web_file_picker_web.dart
// Propósito: Implementación para Flutter Web del selector de archivos mediante input HTML y FileReader.
// =========================================================================

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'web_file_picker_stub.dart';

export 'web_file_picker_stub.dart';

/// Abre un selector nativo de archivos en el navegador web y lee su contenido como buffer de memoria.
///
/// Valida extensiones, tipos MIME permitidos, rechazo explícito de formatos HEIC/HEIF
/// y límites máximos de peso en bytes para resguardar la estabilidad y cuotas de transferencia.
///
/// @param maxBytes Límite superior permitido en bytes (por defecto 5 MB).
/// @param allowedMimeTypes Lista de tipos MIME permitidos para la selección.
/// @return [FilePickResult] con el estado de la operación y los bytes cargados.
Future<FilePickResult> pickPlatformFile({
  int maxBytes = 5 * 1024 * 1024,
  List<String> allowedMimeTypes = const [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/avif',
  ],
}) async {
  final completer = Completer<FilePickResult>();

  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = allowedMimeTypes.join(',');

  input.addEventListener(
    'cancel',
    (web.Event _) {
      if (!completer.isCompleted) {
        completer.complete(const FilePickResult.cancelled());
      }
    }.toJS,
  );

  input.addEventListener(
    'change',
    (web.Event _) {
      if (completer.isCompleted) return;

      final files = input.files;
      if (files == null || files.length == 0) {
        completer.complete(const FilePickResult.cancelled());
        return;
      }

      final file = files.item(0);
      if (file == null) {
        completer.complete(const FilePickResult.cancelled());
        return;
      }

      final fileType = file.type.toLowerCase();
      final fileName = file.name;
      final fileExt = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

      final isHeic = fileType.contains('heic') || fileType.contains('heif') || fileExt == 'heic' || fileExt == 'heif';
      if (isHeic) {
        completer.complete(const FilePickResult.rejectedHeic());
        return;
      }

      final isValidMime = allowedMimeTypes.contains(fileType) ||
          (fileType.isEmpty && (fileExt == 'jpg' || fileExt == 'jpeg' || fileExt == 'png' || fileExt == 'webp' || fileExt == 'avif'));

      if (!isValidMime) {
        completer.complete(const FilePickResult.unsupportedFormat());
        return;
      }

      if (file.size >= maxBytes) {
        completer.complete(const FilePickResult.sizeExceeded());
        return;
      }

      final resolvedMime = fileType.isNotEmpty ? fileType : switch (fileExt) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'avif' => 'image/avif',
        _ => 'image/jpeg',
      };

      final reader = web.FileReader();
      reader.addEventListener(
        'loadend',
        (web.Event _) {
          if (completer.isCompleted) return;
          try {
            final result = reader.result;
            if (result != null) {
              final jsBuffer = result as JSArrayBuffer;
              final bytes = jsBuffer.toDart.asUint8List();
              completer.complete(FilePickResult.success(
                PickedFileData(
                  name: fileName,
                  size: file.size,
                  mimeType: resolvedMime,
                  bytes: bytes,
                ),
              ));
            } else {
              completer.complete(const FilePickResult.error('No se pudo leer el archivo seleccionado'));
            }
          } catch (e) {
            completer.complete(FilePickResult.error('Error al procesar el archivo: $e'));
          }
        }.toJS,
      );

      reader.addEventListener(
        'error',
        (web.Event _) {
          if (!completer.isCompleted) {
            completer.complete(const FilePickResult.error('Error al leer el archivo'));
          }
        }.toJS,
      );

      reader.readAsArrayBuffer(file);
    }.toJS,
  );

  input.click();

  return completer.future;
}
