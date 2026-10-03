// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/core/validators/image_mime.dart
// Propósito: Validador de seguridad en cliente para inspección de firmas binarias (magic numbers), detección de tipos MIME y rechazo de vectores SVG o formatos incompatibles (HEIC).
// =========================================================================

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../l10n/app_localizations.dart';

/// {@template image_validation_result}
/// Resultado de la validación previa de archivos de imagen en memoria del cliente (TRD §3.5.A, V-08, N-22, CA-12, ADR-018).
/// {@endtemplate}
enum ImageValidationResult {
  /// Archivo binario íntegro que satisface cotas de tamaño y firma MIME permitida (JPEG, PNG, WebP, AVIF).
  valid,

  /// Imagen en formato HEIC/HEIF rechazada preventivamente para evitar incompatibilidad en navegadores.
  heicRejected,

  /// Formato no admitido o vector SVG bloqueado por prevención de inyección de scripts.
  unsupportedFormat,

  /// Archivo que supera la cota de tamaño establecida (5 MB).
  fileTooLarge,

  /// Búfer de bytes vacío.
  emptyFile,
}

/// {@template image_mime_validator}
/// Validador estático para la inspección de cabeceras binarias y tipos MIME reales en memoria.
///
/// Evalúa números mágicos antes de iniciar transferencias a Cloud Storage (`uploads/`),
/// garantizando inmunidad ante extensiones renombradas fraudulentamente.
/// {@endtemplate}
class ImageMimeValidator {
  /// Tamaño máximo permitido para archivos de imagen: 5 MB (TRD §3.5.A, N-22, CA-12).
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Evalúa el buffer binario y retorna el código de validación correspondiente.
  static ImageValidationResult evaluateBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return ImageValidationResult.emptyFile;
    }

    if (bytes.length > maxFileSizeBytes) {
      return ImageValidationResult.fileTooLarge;
    }

    // 1. Detección prioritaria de formatos de alta eficiencia HEIC/HEIF
    if (isHeic(bytes)) {
      return ImageValidationResult.heicRejected;
    }

    // 2. Detección y bloqueo estricto de SVG por seguridad
    if (isSvg(bytes)) {
      return ImageValidationResult.unsupportedFormat;
    }

    // 3. Validación de formatos autorizados (JPEG, PNG, WebP, AVIF)
    if (isJpeg(bytes) || isPng(bytes) || isWebp(bytes) || isAvif(bytes)) {
      return ImageValidationResult.valid;
    }

    return ImageValidationResult.unsupportedFormat;
  }

  /// Determina si los bytes corresponden a un contenedor ISOBMFF con marcas HEIC/HEIF (ADR-018)
  static bool isHeic(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // Si contiene marcas de AVIF (avif o avis), es un formato autorizado y no debe tratarse como HEIC
    if (isAvif(bytes)) return false;

    // Los contenedores ISOBMFF tienen la caja 'ftyp' en el offset 4
    final isFtyp = bytes[4] == 0x66 && // 'f'
        bytes[5] == 0x74 && // 't'
        bytes[6] == 0x79 && // 'y'
        bytes[7] == 0x70; // 'p'

    if (!isFtyp) return false;

    // Leer hasta los primeros 64 bytes para inspeccionar la marca principal y marcas compatibles
    final inspectLength = min(bytes.length, 64);
    final headerStr = ascii.decode(bytes.sublist(4, inspectLength), allowInvalid: true).toLowerCase();

    const heicBrands = [
      'heic',
      'heix',
      'hevc',
      'hevx',
      'heim',
      'heis',
      'mif1',
      'msf1',
    ];

    for (final brand in heicBrands) {
      if (headerStr.contains(brand)) {
        return true;
      }
    }

    return false;
  }

  /// Determina si los bytes corresponden a una imagen JPEG (FF D8 FF)
  static bool isJpeg(Uint8List bytes) {
    if (bytes.length < 3) return false;
    return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  }

  /// Determina si los bytes corresponden a una imagen PNG (89 50 4E 47 0D 0A 1A 0A)
  static bool isPng(Uint8List bytes) {
    if (bytes.length < 8) return false;
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
  }

  /// Determina si los bytes corresponden a una imagen WebP (RIFF .... WEBP)
  static bool isWebp(Uint8List bytes) {
    if (bytes.length < 12) return false;
    final isRiff = bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46;
    final isWebp = bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50;
    return isRiff && isWebp;
  }

  /// Determina si los bytes corresponden a un archivo AVIF (ftyp avif o avis)
  static bool isAvif(Uint8List bytes) {
    if (bytes.length < 12) return false;
    final isFtyp = bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70;
    if (!isFtyp) return false;

    final inspectLength = min(bytes.length, 64);
    final headerStr = ascii.decode(bytes.sublist(4, inspectLength), allowInvalid: true).toLowerCase();

    return headerStr.contains('avif') || headerStr.contains('avis');
  }

  /// Determina si los bytes corresponden a un vector SVG (bloqueado por seguridad)
  static bool isSvg(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    final inspectLength = min(bytes.length, 256);
    try {
      final headerStr = utf8.decode(bytes.sublist(0, inspectLength), allowMalformed: true).trim().toLowerCase();
      return headerStr.startsWith('<svg') ||
          headerStr.contains('<?xml') && headerStr.contains('<svg') ||
          headerStr.contains('xmlns="http://www.w3.org/2000/svg"');
    } catch (_) {
      return false;
    }
  }

  /// Valida los bytes y retorna el mensaje localizado de error, o `null` si el archivo es válido.
  /// Cumple con N-15 y V-08 al no exponer identificadores de arquitectura en la interfaz.
  static String? validateAndGetError(Uint8List bytes, AppLocalizations l10n) {
    final result = evaluateBytes(bytes);
    switch (result) {
      case ImageValidationResult.valid:
        return null;
      case ImageValidationResult.heicRejected:
        return l10n.imageFormatHeicRejected;
      case ImageValidationResult.unsupportedFormat:
      case ImageValidationResult.emptyFile:
        return l10n.imageFormatUnsupported;
      case ImageValidationResult.fileTooLarge:
        return l10n.imageSizeExceeded;
    }
  }
}
