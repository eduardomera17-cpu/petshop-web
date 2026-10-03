// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_record_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClinicalRecordVersion _$ClinicalRecordVersionFromJson(
  Map<String, dynamic> json,
) => ClinicalRecordVersion(
  versionNumber: (json['versionNumber'] as num).toInt(),
  editedBy: json['editedBy'] as String,
  editedByName: json['editedByName'] as String,
  editedAt: const _NullableTimestampConverter().fromJson(json['editedAt']),
  snapshot: json['snapshot'] as Map<String, dynamic>,
);

Map<String, dynamic> _$ClinicalRecordVersionToJson(
  ClinicalRecordVersion instance,
) => <String, dynamic>{
  'versionNumber': instance.versionNumber,
  'editedBy': instance.editedBy,
  'editedByName': instance.editedByName,
  'editedAt': const _NullableTimestampConverter().toJson(instance.editedAt),
  'snapshot': instance.snapshot,
};
