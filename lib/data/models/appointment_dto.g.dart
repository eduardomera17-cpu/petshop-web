// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentDto _$AppointmentDtoFromJson(Map<String, dynamic> json) =>
    AppointmentDto(
      id: json['id'] as String?,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      petId: json['petId'] as String,
      petName: json['petName'] as String,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      isClinical: json['isClinical'] as bool,
      dateString: json['dateString'] as String,
      timeSlot: json['timeSlot'] as String,
      slotKey: json['slotKey'] as String,
      petDayKey: json['petDayKey'] as String,
      actionDateString: json['actionDateString'] as String,
      status: json['status'] as String,
      basePriceCents: (json['basePriceCents'] as num).toInt(),
      iceBp: (json['iceBp'] as num?)?.toInt() ?? 0,
      ivaBp: (json['ivaBp'] as num).toInt(),
      iceAmountCents: (json['iceAmountCents'] as num).toInt(),
      ivaAmountCents: (json['ivaAmountCents'] as num).toInt(),
      finalPriceCents: (json['finalPriceCents'] as num).toInt(),
      clientNotes: json['clientNotes'] as String?,
      hasPendingClinicalRecord:
          json['hasPendingClinicalRecord'] as bool? ?? false,
      isBilled: json['isBilled'] as bool? ?? false,
      proformaId: json['proformaId'] as String?,
      cancelledReason: json['cancelledReason'] as String?,
      rescheduleCount: (json['rescheduleCount'] as num?)?.toInt() ?? 0,
      rescheduleHistory:
          (json['rescheduleHistory'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      hasBlockConflict: json['hasBlockConflict'] as bool? ?? false,
      audit: json['audit'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AppointmentDtoToJson(AppointmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'petId': instance.petId,
      'petName': instance.petName,
      'serviceId': instance.serviceId,
      'serviceName': instance.serviceName,
      'isClinical': instance.isClinical,
      'dateString': instance.dateString,
      'timeSlot': instance.timeSlot,
      'slotKey': instance.slotKey,
      'petDayKey': instance.petDayKey,
      'actionDateString': instance.actionDateString,
      'status': instance.status,
      'basePriceCents': instance.basePriceCents,
      'iceBp': instance.iceBp,
      'ivaBp': instance.ivaBp,
      'iceAmountCents': instance.iceAmountCents,
      'ivaAmountCents': instance.ivaAmountCents,
      'finalPriceCents': instance.finalPriceCents,
      'clientNotes': instance.clientNotes,
      'hasPendingClinicalRecord': instance.hasPendingClinicalRecord,
      'isBilled': instance.isBilled,
      'proformaId': instance.proformaId,
      'cancelledReason': instance.cancelledReason,
      'rescheduleCount': instance.rescheduleCount,
      'rescheduleHistory': instance.rescheduleHistory,
      'hasBlockConflict': instance.hasBlockConflict,
      'audit': instance.audit,
    };
