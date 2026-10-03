// =========================================================================
// Proyecto: Web App Petshop - Gestión de citas
// Grado/Título: Tesis para graduación en tecnología universitaria en desarrollo de software
// Institución: Instituto Superior Tecnológico Portoviejo
// Autor: Eduardo Andrés Mera Moreira
// Archivo: functions_service.dart
// Propósito: Invocación segura y tipada de Cloud Functions (2da Gen) para transacciones atómicas de negocio.
// =========================================================================
// ignore_for_file: use_null_aware_elements

import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:flutter/foundation.dart';
import 'package:mipetshop/core/failures.dart';
import 'package:mipetshop/core/result.dart';

/// Servicio cliente para invocar Cloud Functions de 2ª generación en la región oficial us-east1.
class FunctionsService {
  final FirebaseFunctions? functions;

  /// Región canónica de ejecución de Cloud Functions vinculada a petshopdev (TRD §1.5.2).
  static const String officialRegion = 'us-east1';

  FunctionsService({
    this.functions,
  });

  FirebaseFunctions get _client =>
      functions ?? FirebaseFunctions.instanceFor(region: officialRegion);

  /// Invoca la callable [verifyHuman] con el token de casilla y el correo del usuario (TRD §3.1.C).
  ///
  /// NOTA DE SEGURIDAD (AppFlow §2.1): La contraseña NUNCA se envía aquí.
  /// Genera la prueba efímera en `/human_checks/{sha256(email)}` con TTL de 2 minutos.
  Future<Result<bool>> verifyHuman({
    required String token,
    required String email,
  }) async {
    final payload = <String, dynamic>{
      'token': token,
      'email': email.trim().toLowerCase(),
    };

    try {
      final callable = _client.httpsCallable('verifyHuman');
      final result = await callable.call<Map<String, dynamic>>(payload);
      final data = result.data;
      final verified = data['verified'] == true;
      return Ok(verified);
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [completeRegistration] para finalizar el registro y elevar claims a ACTIVE (TRD §3.2.A).
  ///
  /// Valida los cinco campos autoritativos y escribe el documento /users/{uid} antes
  /// de actualizar Custom Claims a { role: 'CLIENT', status: 'ACTIVE' }.
  Future<Result<Map<String, dynamic>>> completeRegistration({
    required String fullName,
    required String phone,
    required String documentType,
    required String documentNumber,
    required String address,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'documentType': documentType.trim(),
      'documentNumber': documentNumber.trim(),
      'address': address.trim(),
    };

    try {
      final callable = _client.httpsCallable('completeRegistration');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [previewPetDeactivation] para previsualizar citas afectadas.
  Future<Result<Map<String, dynamic>>> previewPetDeactivation({
    required String petId,
  }) async {
    final payload = <String, dynamic>{
      'petId': petId.trim(),
    };

    try {
      final callable = _client.httpsCallable('previewPetDeactivation');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [deactivatePet] para realizar la baja atómica de una mascota.
  Future<Result<Map<String, dynamic>>> deactivatePet({
    required String petId,
  }) async {
    final payload = <String, dynamic>{
      'petId': petId.trim(),
    };

    try {
      final callable = _client.httpsCallable('deactivatePet');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [createAppointment] para realizar el agendamiento transaccional de una cita.
  Future<Result<Map<String, dynamic>>> createAppointment({
    required String petId,
    required String serviceId,
    required String dateString,
    required String timeSlot,
    String? clientNotes,
    String? requestId,
  }) async {
    final payload = <String, dynamic>{
      'petId': petId.trim(),
      'serviceId': serviceId.trim(),
      'dateString': dateString.trim(),
      'timeSlot': timeSlot.trim(),
      if (clientNotes != null && clientNotes.trim().isNotEmpty)
        'clientNotes': clientNotes.trim(),
      if (requestId != null && requestId.trim().isNotEmpty)
        'requestId': requestId.trim(),
    };

    try {
      final callable = _client.httpsCallable('createAppointment');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [cancelAppointmentByClient] para realizar la cancelación transaccional de una cita (TRD §3.2.C, C-09).
  Future<Result<Map<String, dynamic>>> cancelAppointmentByClient({
    required String appointmentId,
  }) async {
    final payload = <String, dynamic>{
      'appointmentId': appointmentId.trim(),
    };

    try {
      final callable = _client.httpsCallable('cancelAppointmentByClient');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [createProductRequest] para crear una solicitud de productos con descuento atómico de stock.
  Future<Result<Map<String, dynamic>>> createProductRequest({
    required List<Map<String, dynamic>> items,
    String? requestId,
  }) async {
    final payload = <String, dynamic>{
      'items': items,
      if (requestId != null && requestId.trim().isNotEmpty)
        'requestId': requestId.trim(),
    };

    try {
      final callable = _client.httpsCallable('createProductRequest');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [cancelProductRequestByClient] para cancelar una solicitud y reponer stock.
  Future<Result<Map<String, dynamic>>> cancelProductRequestByClient({
    required String requestId,
  }) async {
    final payload = <String, dynamic>{
      'requestId': requestId.trim(),
    };

    try {
      final callable = _client.httpsCallable('cancelProductRequestByClient');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [advanceProductRequest] para avanzar de PENDING_DISPATCH a READY_FOR_PICKUP (personal).
  Future<Result<Map<String, dynamic>>> advanceProductRequest({
    required String requestId,
  }) async {
    final payload = <String, dynamic>{
      'requestId': requestId.trim(),
    };

    try {
      final callable = _client.httpsCallable('advanceProductRequest');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [adjustProductStock] para ajustar stock mediante delta con signo (personal).
  Future<Result<Map<String, dynamic>>> adjustProductStock({
    required String productId,
    required int delta,
  }) async {
    final payload = <String, dynamic>{
      'productId': productId.trim(),
      'delta': delta,
    };

    try {
      final callable = _client.httpsCallable('adjustProductStock');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [previewAccountDeactivation] para previsualizar los dos grupos de la baja de cuenta.
  Future<Result<Map<String, dynamic>>> previewAccountDeactivation() async {
    final payload = <String, dynamic>{};

    try {
      final callable = _client.httpsCallable('previewAccountDeactivation');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [deactivateOwnAccount] para ejecutar la baja atómica de la cuenta del titular.
  Future<Result<Map<String, dynamic>>> deactivateOwnAccount({
    required String password,
  }) async {
    final payload = <String, dynamic>{
      'password': password,
    };

    try {
      final callable = _client.httpsCallable('deactivateOwnAccount');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [createProformaDraft] para iniciar un borrador de proforma.
  Future<Result<Map<String, dynamic>>> createProformaDraft({
    required String clientId,
  }) async {
    final payload = <String, dynamic>{
      'clientId': clientId.trim(),
    };

    try {
      final callable = _client.httpsCallable('createProformaDraft');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [addProformaItems] para añadir citas y solicitudes al borrador.
  Future<Result<Map<String, dynamic>>> addProformaItems({
    required String proformaId,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = <String, dynamic>{
      'proformaId': proformaId.trim(),
      'items': items,
    };

    try {
      final callable = _client.httpsCallable('addProformaItems');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [setProformaAdjustments] para definir descuentos o recargos en el borrador.
  Future<Result<Map<String, dynamic>>> setProformaAdjustments({
    required String proformaId,
    required List<Map<String, dynamic>> adjustments,
  }) async {
    final payload = <String, dynamic>{
      'proformaId': proformaId.trim(),
      'adjustments': adjustments,
    };

    try {
      final callable = _client.httpsCallable('setProformaAdjustments');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [deliverProforma] para emitir y congelar la proforma, generando su PDF.
  Future<Result<Map<String, dynamic>>> deliverProforma({
    required String proformaId,
  }) async {
    final payload = <String, dynamic>{
      'proformaId': proformaId.trim(),
    };

    try {
      final callable = _client.httpsCallable('deliverProforma');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [finalizeProforma] para marcar como finalizada la proforma y sus conceptos.
  Future<Result<Map<String, dynamic>>> finalizeProforma({
    required String proformaId,
  }) async {
    final payload = <String, dynamic>{
      'proformaId': proformaId.trim(),
    };

    try {
      final callable = _client.httpsCallable('finalizeProforma');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [voidProforma] para anular una proforma entregada o finalizada con motivo obligatorio.
  Future<Result<Map<String, dynamic>>> voidProforma({
    required String proformaId,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      'proformaId': proformaId.trim(),
      'reason': reason.trim(),
    };

    try {
      final callable = _client.httpsCallable('voidProforma');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [purgeChatByClient] para vaciar los mensajes de la sala propia (TRD §3.4.D, CH-05, CA-31).
  Future<Result<Map<String, dynamic>>> purgeChatByClient({
    required String chatId,
  }) async {
    final payload = <String, dynamic>{
      'chatId': chatId.trim(),
    };

    try {
      final callable = _client.httpsCallable('purgeChatByClient');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [moderateChat] exclusiva para SUPERADMIN (TRD §3.4.E, MC-08, CA-AD-47).
  Future<Result<Map<String, dynamic>>> moderateChat({
    required String operation,
    required String chatId,
    String? messageId,
  }) async {
    final payload = <String, dynamic>{
      'operation': operation.trim(),
      'chatId': chatId.trim(),
      if (messageId != null) 'messageId': messageId.trim(),
    };

    try {
      final callable = _client.httpsCallable('moderateChat');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [markChatAsRead] para poner a cero staffUnreadCount y marcar pendientes (TRD §3.4.F, MC-09, CA-16, CA-AD-17).
  Future<Result<Map<String, dynamic>>> markChatAsRead({
    required String chatId,
  }) async {
    final payload = <String, dynamic>{
      'chatId': chatId.trim(),
    };

    try {
      final callable = _client.httpsCallable('markChatAsRead');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [confirmAppointment] para confirmar una cita pendiente (personal).
  Future<Result<Map<String, dynamic>>> confirmAppointment({
    required String appointmentId,
  }) async {
    final payload = <String, dynamic>{
      'appointmentId': appointmentId.trim(),
    };

    try {
      final callable = _client.httpsCallable('confirmAppointment');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [completeAppointment] para completar una cita (personal).
  Future<Result<Map<String, dynamic>>> completeAppointment({
    required String appointmentId,
  }) async {
    final payload = <String, dynamic>{
      'appointmentId': appointmentId.trim(),
    };

    try {
      final callable = _client.httpsCallable('completeAppointment');
      final result = await callable.call<dynamic>(payload);
      final data = result.data;
      if (data is Map) {
        return Ok(Map<String, dynamic>.from(data));
      }
      return const Ok(<String, dynamic>{});
    } catch (e, st) {
      debugPrint('>>> [functions_service.completeAppointment error]: $e\n$st');
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [cancelAppointmentByStaff] para cancelar una cita por el personal.
  Future<Result<Map<String, dynamic>>> cancelAppointmentByStaff({
    required String appointmentId,
  }) async {
    final payload = <String, dynamic>{
      'appointmentId': appointmentId.trim(),
    };

    try {
      final callable = _client.httpsCallable('cancelAppointmentByStaff');
      final result = await callable.call<dynamic>(payload);
      final data = result.data;
      if (data is Map) {
        return Ok(Map<String, dynamic>.from(data));
      }
      return const Ok(<String, dynamic>{});
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [rescheduleAppointment] para reagendar indivisiblemente una cita (personal).
  Future<Result<Map<String, dynamic>>> rescheduleAppointment({
    required String appointmentId,
    required String toDateString,
    required String toTimeSlot,
  }) async {
    final payload = <String, dynamic>{
      'appointmentId': appointmentId.trim(),
      'dateString': toDateString.trim(),
      'timeSlot': toTimeSlot.trim(),
    };

    try {
      final callable = _client.httpsCallable('rescheduleAppointment');
      final result = await callable.call<dynamic>(payload);
      final data = result.data;
      if (data is Map) {
        return Ok(Map<String, dynamic>.from(data));
      }
      return const Ok(<String, dynamic>{});
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [setAvailabilityBlock] para bloquear o desbloquear franjas o fechas (personal).
  Future<Result<Map<String, dynamic>>> setAvailabilityBlock({
    required String dateString,
    String? timeSlot,
    String? reason,
    String action = 'BLOCK',
  }) async {
    final payload = <String, dynamic>{
      'dateString': dateString.trim(),
      if (timeSlot != null && timeSlot.trim().isNotEmpty)
        'timeSlot': timeSlot.trim(),
      if (reason != null && reason.trim().isNotEmpty)
        'reason': reason.trim(),
      'action': action.trim(),
    };

    try {
      final callable = _client.httpsCallable('setAvailabilityBlock');
      final result = await callable.call<dynamic>(payload);
      final data = result.data;
      if (data is Map) {
        return Ok(Map<String, dynamic>.from(data));
      }
      return const Ok(<String, dynamic>{});
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [reactivateAccountOrPet] para reactivar cuentas de usuario o mascotas inactivas (personal).
  Future<Result<Map<String, dynamic>>> reactivateAccountOrPet({
    required String entityType,
    required String entityId,
  }) async {
    final payload = <String, dynamic>{
      'entityType': entityType.trim(),
      'entityId': entityId.trim(),
    };

    try {
      final callable = _client.httpsCallable('reactivateAccountOrPet');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [createClinicalRecord] para registrar una nueva entrada clínica (TRD §3.4.A, CL-03, CL-10, CL-11).
  Future<Result<Map<String, dynamic>>> createClinicalRecord({
    required String petId,
    required String type,
    String? attentionDate,
    String? attentionTime,
    String? sourceAppointmentId,
    Map<String, dynamic>? consultation,
    Map<String, dynamic>? physicalExam,
    Map<String, dynamic>? plan,
    Map<String, dynamic>? followUp,
    Map<String, dynamic>? prevention,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final payload = <String, dynamic>{
      'petId': petId.trim(),
      'type': type.trim(),
      if (attentionDate != null) 'attentionDate': attentionDate.trim(),
      if (attentionTime != null) 'attentionTime': attentionTime.trim(),
      if (sourceAppointmentId != null) 'sourceAppointmentId': sourceAppointmentId.trim(),
      if (consultation != null) 'consultation': consultation,
      if (physicalExam != null) 'physicalExam': physicalExam,
      if (plan != null) 'plan': plan,
      if (followUp != null) 'followUp': followUp,
      if (prevention != null) 'prevention': prevention,
      if (attachments != null) 'attachments': attachments,
    };

    try {
      final callable = _client.httpsCallable('createClinicalRecord');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [updateClinicalRecord] para corregir y versionar una entrada clínica (TRD §3.4.B, CL-12).
  Future<Result<Map<String, dynamic>>> updateClinicalRecord({
    required String petId,
    required String recordId,
    Map<String, dynamic>? consultation,
    Map<String, dynamic>? physicalExam,
    Map<String, dynamic>? plan,
    Map<String, dynamic>? followUp,
    Map<String, dynamic>? prevention,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final payload = <String, dynamic>{
      'petId': petId.trim(),
      'recordId': recordId.trim(),
      if (consultation != null) 'consultation': consultation,
      if (physicalExam != null) 'physicalExam': physicalExam,
      if (plan != null) 'plan': plan,
      if (followUp != null) 'followUp': followUp,
      if (prevention != null) 'prevention': prevention,
      if (attachments != null) 'attachments': attachments,
    };

    try {
      final callable = _client.httpsCallable('updateClinicalRecord');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [annulClinicalRecord] para anular inmutablemente una entrada clínica (TRD §3.4.C, CL-08).
  Future<Result<Map<String, dynamic>>> annulClinicalRecord({
    required String petId,
    required String recordId,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      'petId': petId.trim(),
      'recordId': recordId.trim(),
      'reason': reason.trim(),
    };

    try {
      final callable = _client.httpsCallable('annulClinicalRecord');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [createUserAccount] para aprovisionar cuentas CLIENT o ADMIN por el Super Usuario (TRD §3.4.I, CF-07).
  Future<Result<Map<String, dynamic>>> createUserAccount({
    required String email,
    required String fullName,
    required String role,
    required String phone,
    required String documentType,
    required String documentNumber,
    required String address,
  }) async {
    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'fullName': fullName.trim(),
      'role': role.trim(),
      'phone': phone.trim(),
      'documentType': documentType.trim(),
      'documentNumber': documentNumber.trim(),
      'address': address.trim(),
    };

    try {
      final callable = _client.httpsCallable('createUserAccount');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [updateUserIdentity] para modificar datos de identidad conservando el email inmutable (TRD §3.4.I, CF-08).
  Future<Result<Map<String, dynamic>>> updateUserIdentity({
    required String targetUid,
    String? fullName,
    String? phone,
    String? documentType,
    String? documentNumber,
    String? address,
  }) async {
    final payload = <String, dynamic>{
      'targetUid': targetUid.trim(),
      if (fullName != null) 'fullName': fullName.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (documentType != null) 'documentType': documentType.trim(),
      if (documentNumber != null) 'documentNumber': documentNumber.trim(),
      if (address != null) 'address': address.trim(),
    };

    try {
      final callable = _client.httpsCallable('updateUserIdentity');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [resetUserPassword] para generar enlace de restablecimiento sin enviar correos (TRD §3.4.I, CF-06, CF-10).
  Future<Result<Map<String, dynamic>>> resetUserPassword({
    required String targetUid,
  }) async {
    final payload = <String, dynamic>{
      'targetUid': targetUid.trim(),
    };

    try {
      final callable = _client.httpsCallable('resetUserPassword');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [deactivateUserAccount] para desactivar administrativamente una cuenta (TRD §3.4.I, CF-09).
  Future<Result<Map<String, dynamic>>> deactivateUserAccount({
    required String targetUid,
  }) async {
    final payload = <String, dynamic>{
      'targetUid': targetUid.trim(),
    };

    try {
      final callable = _client.httpsCallable('deactivateUserAccount');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [deleteStaffAccount] para dar de baja lógica a personal administrativo (TRD §3.4.I, CF-12).
  Future<Result<Map<String, dynamic>>> deleteStaffAccount({
    required String targetUid,
  }) async {
    final payload = <String, dynamic>{
      'targetUid': targetUid.trim(),
    };

    try {
      final callable = _client.httpsCallable('deleteStaffAccount');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }

  /// Invoca la callable [updateOperatingParameters] para actualizar configuración operativa del negocio (TRD §3.4.J, CF-01, CF-02, IN-03, CA-AD-60).
  Future<Result<Map<String, dynamic>>> updateOperatingParameters({
    String? openingTime,
    String? closingTime,
    int? slotDurationMinutes,
    List<int>? workingWeekdays,
    int? lowStockThreshold,
  }) async {
    final payload = <String, dynamic>{
      if (openingTime != null) 'openingTime': openingTime.trim(),
      if (closingTime != null) 'closingTime': closingTime.trim(),
      if (slotDurationMinutes != null) 'slotDurationMinutes': slotDurationMinutes,
      if (workingWeekdays != null) 'workingWeekdays': workingWeekdays,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
    };

    try {
      final callable = _client.httpsCallable('updateOperatingParameters');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Ok(Map<String, dynamic>.from(result.data));
    } catch (e) {
      return Err(Failure.fromException(e));
    }
  }
}
