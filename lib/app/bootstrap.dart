// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: lib/app/bootstrap.dart
// Propósito: Inicialización y orquestación del entorno base de la aplicación (Firebase, App Check, Firestore named database y zona horaria de negocio).
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:mipetshop/app/app_config.dart';
import 'package:mipetshop/core/business_clock.dart';
import '../data/services/firestore_service.dart';

/// {@template bootstrap_result}
/// Contenedor de servicios e infraestructura central inicializados exitosamente durante el arranque de la aplicación.
///
/// Encapsula la instancia principal de [FirebaseApp], la conexión anclada a la base de datos
/// Firestore multientorno ('petshopdev') y la zona horaria operacional verificada del negocio.
/// {@endtemplate}
class BootstrapResult {
  /// Instancia de la aplicación de Firebase inicializada.
  final FirebaseApp app;

  /// Instancia de Cloud Firestore configurada con la base de datos de negocio correspondiente.
  final FirebaseFirestore firestore;

  /// Identificador IANA de la zona horaria del negocio (por defecto 'America/Guayaquil').
  final String timezone;

  /// Constructor inmutable del resultado de inicialización.
  const BootstrapResult({
    required this.app,
    required this.firestore,
    required this.timezone,
  });
}

/// Opciones de configuración de Firebase para Web.
///
/// Se construyen a partir de [AppConfig], que lee los valores inyectados en la compilación
/// (`--dart-define-from-file=config/app_config.json`). No hay identificadores de proyecto en el código.
final FirebaseOptions webFirebaseOptions = FirebaseOptions(
  apiKey: AppConfig.firebaseApiKey,
  appId: AppConfig.firebaseAppId,
  messagingSenderId: AppConfig.firebaseMessagingSenderId,
  projectId: AppConfig.firebaseProjectId,
  authDomain: AppConfig.firebaseAuthDomain,
  storageBucket: AppConfig.firebaseStorageBucket,
  measurementId:
      AppConfig.firebaseMeasurementId.isEmpty ? null : AppConfig.firebaseMeasurementId,
);

/// Inicialización del entorno base de la aplicación (WP-1.3, WP-1.9).
///
/// Configura:
/// 1. Instancia de FirebaseApp y Firestore anclada a named database 'petshopdev'.
/// 2. Firebase App Check con proveedor oficial ReCaptchaEnterpriseProvider en Web (TRD §4.3.2.B).
/// 3. Zona horaria de negocio 'America/Guayaquil' leída de /business_config/public_operating (N-12).
/// 4. Enrutamiento de errores no capturados sin trazas técnicas (N-15).
Future<BootstrapResult> bootstrapApp({FirebaseOptions? options}) async {
  if (options == null && kIsWeb) {
    final missing = AppConfig.missingKeys;
    if (missing.isNotEmpty) {
      throw StateError(
        'Configuración incompleta: faltan ${missing.join(', ')}. '
        'Compila con --dart-define-from-file=config/app_config.json (ver README.md, sección Configuración).',
      );
    }
  }
  final effectiveOptions = options ?? (kIsWeb ? webFirebaseOptions : null);
  final app = Firebase.apps.isEmpty
      ? await Firebase.initializeApp(options: effectiveOptions)
      : Firebase.app();

  final firestore = createFirestoreInstance(app);

  // 1. Configuración de App Check perimetral (TRD §4.3.2.B)
  if (kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaEnterpriseProvider(
          AppConfig.recaptchaScoreSiteKey, // clave de sitio reCAPTCHA Enterprise (puntuación)
        ),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Continuidad de arranque ante entornos o redes donde App Check no responda de forma síncrona
    }
  }

  // 2. Carga e inicialización de zona horaria de negocio (TRD §1.3.5, N-12)
  String tz = BusinessClock.defaultTimezone;
  try {
    final configDoc = await firestore
        .collection('business_config')
        .doc('public_operating')
        .get()
        .timeout(const Duration(seconds: 2));

    final data = configDoc.data();
    if (data != null && data.containsKey('timezone')) {
      final docTz = data['timezone'] as String?;
      if (docTz != null && docTz.isNotEmpty) {
        tz = docTz;
      }
    }
  } catch (_) {
    // Fallback garantizado a America/Guayaquil ante arranques iniciales o modo offline
    tz = BusinessClock.defaultTimezone;
  }

  BusinessClock.init(timezone: tz);

  // 3. Configuración de errores de renderizado de Flutter (TRD §1.3.6, N-15)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  return BootstrapResult(
    app: app,
    firestore: firestore,
    timezone: tz,
  );
}
