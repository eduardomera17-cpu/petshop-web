// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceDto _$ServiceDtoFromJson(Map<String, dynamic> json) => ServiceDto(
  id: json['id'] as String?,
  name: json['name'] as String,
  searchName: json['searchName'] as String,
  description: json['description'] as String,
  basePriceCents: (json['basePriceCents'] as num).toInt(),
  iceBp: (json['iceBp'] as num?)?.toInt() ?? 0,
  isClinical: json['isClinical'] as bool,
  estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num).toInt(),
  isActive: json['isActive'] as bool,
  audit: json['audit'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ServiceDtoToJson(ServiceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'searchName': instance.searchName,
      'description': instance.description,
      'basePriceCents': instance.basePriceCents,
      'iceBp': instance.iceBp,
      'isClinical': instance.isClinical,
      'estimatedDurationMinutes': instance.estimatedDurationMinutes,
      'isActive': instance.isActive,
      'audit': instance.audit,
    };
