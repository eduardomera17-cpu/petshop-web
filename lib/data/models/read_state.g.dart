// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadStateDto _$ReadStateDtoFromJson(Map<String, dynamic> json) => ReadStateDto(
  uid: json['uid'] as String?,
  lastReadAt: const _NullableTimestampConverter().fromJson(json['lastReadAt']),
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ReadStateDtoToJson(
  ReadStateDto instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'lastReadAt': const _NullableTimestampConverter().toJson(instance.lastReadAt),
  'unreadCount': instance.unreadCount,
};
