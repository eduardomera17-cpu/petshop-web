// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: governance_repository.dart
// Propósito: Repositorio para la gobernanza administrativa de cuentas, parámetros operativos y auditoría forense.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';
import 'package:mipetshop/data/services/functions_service.dart';
import 'package:mipetshop/domain/models/audit_log_entry.dart';
import 'package:mipetshop/domain/models/operating_parameters.dart';
import 'package:mipetshop/domain/models/user_profile.dart';

/// Repositorio para el gobierno de cuentas, configuración operativa y auditoría en Cloud Firestore.
///
/// Centraliza la lectura de usuarios, consulta de registros inmutables de auditoría en `/audit_log`
/// y canaliza las mutaciones de administración mediante Cloud Functions con privilegios de SUPERADMIN.
class GovernanceRepository {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore firestore;

  /// Invocador de Cloud Functions de gobernanza.
  final FunctionsService functionsService;

  /// Constructor del repositorio de gobernanza.
  GovernanceRepository({
    required this.firestore,
    required this.functionsService,
  });

  /// Obtiene la lista completa de usuarios registrados en la colección `/users`.
  ///
  /// @return [Result] con lista de perfiles [UserProfile] ordenados alfabéticamente.
  Future<Result<List<UserProfile>>> getUsers() async {
    try {
      final snapshot = await firestore.collection('users').get();
      final users = snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
      users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return Ok(users);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Emite en tiempo real la lista de usuarios registrados.
  Stream<List<UserProfile>> streamUsers() {
    return firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
      users.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      return users;
    });
  }

  /// Obtiene los parámetros operativos del negocio desde `/business_config/operating_parameters`.
  Future<Result<OperatingParameters>> getOperatingParameters() async {
    try {
      final doc = await firestore
          .collection('business_config')
          .doc('operating_parameters')
          .get();

      if (!doc.exists) {
        return const Ok(OperatingParameters());
      }

      return Ok(OperatingParameters.fromFirestore(doc));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Obtiene las entradas del registro inmutable de auditoría en `/audit_log` ordenadas por fecha.
  ///
  /// @param limit Límite de eventos a recuperar.
  Future<Result<List<AuditLogEntry>>> getAuditLogs({int limit = 50}) async {
    try {
      final snapshot = await firestore
          .collection('audit_log')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final entries = snapshot.docs
          .map((doc) => AuditLogEntry.fromFirestore(doc))
          .toList();
      return Ok(entries);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Aprovisiona una nueva cuenta de usuario (CLIENT o ADMIN) mediante [FunctionsService.createUserAccount].
  ///
  /// @param email Correo electrónico institucional o personal.
  /// @param fullName Nombre completo del usuario.
  /// @param role Rol del sistema asignado.
  /// @param phone Teléfono celular.
  /// @param documentType Tipo de identificación ciudadana.
  /// @param documentNumber Número de cédula/RUC.
  /// @param address Dirección domiciliaria.
  Future<Result<Map<String, dynamic>>> createUserAccount({
    required String email,
    required String fullName,
    required String role,
    required String phone,
    required String documentType,
    required String documentNumber,
    required String address,
  }) {
    return functionsService.createUserAccount(
      email: email,
      fullName: fullName,
      role: role,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
      address: address,
    );
  }

  /// Actualiza los datos de identidad de una cuenta conservando el email inmutable mediante Cloud Function.
  Future<Result<Map<String, dynamic>>> updateUserIdentity({
    required String targetUid,
    String? fullName,
    String? phone,
    String? documentType,
    String? documentNumber,
    String? address,
  }) {
    return functionsService.updateUserIdentity(
      targetUid: targetUid,
      fullName: fullName,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
      address: address,
    );
  }

  /// Genera un enlace seguro de restablecimiento de contraseña mediante [FunctionsService.resetUserPassword].
  Future<Result<Map<String, dynamic>>> resetUserPassword({
    required String targetUid,
  }) {
    return functionsService.resetUserPassword(targetUid: targetUid);
  }

  /// Desactiva administrativamente una cuenta de usuario mediante Cloud Function.
  Future<Result<Map<String, dynamic>>> deactivateUserAccount({
    required String targetUid,
  }) {
    return functionsService.deactivateUserAccount(targetUid: targetUid);
  }

  /// Reactiva una cuenta de usuario previamente desactivada mediante [FunctionsService.reactivateAccountOrPet].
  Future<Result<Map<String, dynamic>>> reactivateUserAccount({
    required String targetUid,
  }) {
    return functionsService.reactivateAccountOrPet(
      entityType: 'USER',
      entityId: targetUid,
    );
  }

  /// Da de baja lógica a una cuenta de colaborador o administrativo.
  Future<Result<Map<String, dynamic>>> deleteStaffAccount({
    required String targetUid,
  }) {
    return functionsService.deleteStaffAccount(targetUid: targetUid);
  }

  /// Actualiza los parámetros de funcionamiento del establecimiento en Cloud Firestore.
  Future<Result<Map<String, dynamic>>> updateOperatingParameters({
    String? openingTime,
    String? closingTime,
    int? slotDurationMinutes,
    List<int>? workingWeekdays,
    int? lowStockThreshold,
  }) {
    return functionsService.updateOperatingParameters(
      openingTime: openingTime,
      closingTime: closingTime,
      slotDurationMinutes: slotDurationMinutes,
      workingWeekdays: workingWeekdays,
      lowStockThreshold: lowStockThreshold,
    );
  }
}
