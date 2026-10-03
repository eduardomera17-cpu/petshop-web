// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: audit_log_entry.dart
// Propósito: Entidad de dominio inmutable para los registros de auditoría y trazabilidad del sistema.
// =========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dominio inmutable para las entradas del registro de auditoría.
///
/// Modela los documentos inmutables de la colección `/audit_log` en Cloud Firestore,
/// garantizando la trazabilidad forense de acciones realizadas por el personal o usuarios.
class AuditLogEntry {
  /// Identificador único del evento de auditoría en Firestore.
  final String id;

  /// UID del usuario o servicio que ejecutó la acción auditada.
  final String actorUid;

  /// Nombre del actor responsable del evento.
  final String actorName;

  /// Rol operativo del actor ('ADMIN', 'SUPERADMIN', 'STAFF', 'CLIENT', 'SYSTEM').
  final String actorRole;

  /// Acción ejecutada (ej. 'CREATE_APPOINTMENT', 'CANCEL_APPOINTMENT', 'UPDATE_PRICE').
  final String action;

  /// Tipo de entidad afectada (ej. 'appointment', 'pet', 'proforma', 'product').
  final String targetType;

  /// Identificador de la entidad u objeto de destino modificado.
  final String targetId;

  /// Metadatos adicionales en formato clave-valor con detalles contextuales del cambio.
  final Map<String, dynamic> metadata;

  /// Fecha y hora exacta de registro del evento en el servidor.
  final DateTime? createdAt;

  /// Constructor inmutable para la entrada de auditoría.
  const AuditLogEntry({
    required this.id,
    required this.actorUid,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.metadata,
    this.createdAt,
  });

  /// Construye una instancia a partir de un [DocumentSnapshot] de Cloud Firestore.
  factory AuditLogEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AuditLogEntry.fromMap(data, id: doc.id);
  }

  /// Construye una instancia a partir de un mapa de valores y su identificador.
  factory AuditLogEntry.fromMap(Map<String, dynamic> map, {required String id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AuditLogEntry(
      id: id,
      actorUid: (map['actorUid'] as String?) ?? '',
      actorName: (map['actorName'] as String?) ?? '',
      actorRole: (map['actorRole'] as String?) ?? '',
      action: (map['action'] as String?) ?? '',
      targetType: (map['targetType'] as String?) ?? '',
      targetId: (map['targetId'] as String?) ?? '',
      metadata: map['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : (map['metadata'] is Map
              ? Map<String, dynamic>.from(map['metadata'] as Map)
              : const <String, dynamic>{}),
      createdAt: parseDate(map['createdAt']),
    );
  }

  /// Convierte la entrada de auditoría en un mapa para persistir en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actorUid': actorUid,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'metadata': metadata,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
