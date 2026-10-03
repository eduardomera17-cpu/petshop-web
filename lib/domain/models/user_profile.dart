// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: user_profile.dart
// Propósito: Entidad de dominio para la gestión del perfil de usuario y control de roles y accesos.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dominio inmutable para el perfil del usuario.
///
/// Modela los documentos almacenados en la colección `/users/{userId}` en Cloud Firestore,
/// gestionando información personal, roles de autorización ('CLIENT', 'ADMIN', 'SUPERADMIN')
/// y estado de cuenta ('ACTIVE', 'INACTIVE').
class UserProfile {
  /// Identificador único del usuario (UID) en Firebase Authentication.
  final String uid;

  /// Correo electrónico institucional o personal del usuario.
  final String email;

  /// Nombres y apellidos completos.
  final String fullName;

  /// Teléfono principal de contacto.
  final String phone;

  /// Tipo de documento de identidad ('CEDULA', 'RUC', 'PASAPORTE').
  final String documentType;

  /// Número de documento de identificación ciudadana o tributaria.
  final String documentNumber;

  /// Dirección física domiciliaria.
  final String address;

  /// Ruta de la imagen de avatar o perfil en Cloud Storage.
  final String? photoPath;

  /// Rol asignado dentro del sistema ('CLIENT', 'ADMIN', 'SUPERADMIN').
  final String role;

  /// Estado operativo de la cuenta ('ACTIVE', 'INACTIVE').
  final String status;

  /// Nombre normalizado en minúsculas y sin acentos para búsquedas predictivas.
  final String searchName;

  /// Metadatos de auditoría para trazabilidad de creación y cambios.
  final Map<String, dynamic>? audit;

  /// Constructor inmutable para el perfil de usuario.
  const UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.documentType,
    required this.documentNumber,
    required this.address,
    this.photoPath,
    required this.role,
    required this.status,
    required this.searchName,
    this.audit,
  });

  /// Construye un [UserProfile] a partir de un [DocumentSnapshot] de Firestore.
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile.fromMap(data, uid: doc.id);
  }

  /// Construye un [UserProfile] a partir de un mapa de datos deserializado.
  factory UserProfile.fromMap(Map<String, dynamic> map, {required String uid}) {
    return UserProfile(
      uid: uid,
      email: (map['email'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? 'CEDULA',
      documentNumber: (map['documentNumber'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      photoPath: map['photoPath'] as String?,
      role: (map['role'] as String?) ?? 'CLIENT',
      status: (map['status'] as String?) ?? 'ACTIVE',
      searchName: (map['searchName'] as String?) ?? '',
      audit: map['audit'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['audit'] as Map)
          : null,
    );
  }

  /// Crea una copia del perfil modificando selectivamente los campos autorizados.
  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? documentType,
    String? documentNumber,
    String? address,
    String? photoPath,
    String? searchName,
    Map<String, dynamic>? audit,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      address: address ?? this.address,
      photoPath: photoPath ?? this.photoPath,
      role: role,
      status: status,
      searchName: searchName ?? this.searchName,
      audit: audit ?? this.audit,
    );
  }
}
