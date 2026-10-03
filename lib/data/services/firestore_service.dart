// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: firestore_service.dart
// Propósito: Factoría de inicialización desacoplada para la base de datos nombrada de Cloud Firestore.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Inicialización desacoplada de Firestore con base de datos nombrada 'petshopdev'.
///
/// Permite aislar el almacenamiento de datos del proyecto de desarrollo de petshop
/// en una instancia específica de Cloud Firestore asignada en Google Cloud Platform.
///
/// @param app Instancia de [FirebaseApp] inicializada en el arranque de la aplicación web.
/// @return Instancia configurada de [FirebaseFirestore] conectada a la base de datos 'petshopdev'.
FirebaseFirestore createFirestoreInstance(FirebaseApp app) {
  return FirebaseFirestore.instanceFor(
    app: app,
    databaseId: 'petshopdev',
  );
}
