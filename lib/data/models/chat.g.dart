// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatDto _$ChatDtoFromJson(Map<String, dynamic> json) => ChatDto(
  id: json['id'] as String?,
  type: json['type'] as String,
  clientId: json['clientId'] as String?,
  clientName: json['clientName'] as String?,
  clientSearchName: json['clientSearchName'] as String?,
  isArchived: json['isArchived'] as bool? ?? false,
  isBlocked: json['isBlocked'] as bool? ?? false,
  staffUnreadCount: (json['staffUnreadCount'] as num?)?.toInt() ?? 0,
  lastMessageText: json['lastMessageText'] as String?,
  lastMessageTimestamp: const _NullableTimestampConverter().fromJson(
    json['lastMessageTimestamp'],
  ),
  lastMessageSenderName: json['lastMessageSenderName'] as String?,
  lastMessageSenderUid: json['lastMessageSenderUid'] as String?,
  messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
  createdAt: const _NullableTimestampConverter().fromJson(json['createdAt']),
  updatedAt: const _NullableTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$ChatDtoToJson(ChatDto instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'clientId': instance.clientId,
  'clientName': instance.clientName,
  'clientSearchName': instance.clientSearchName,
  'isArchived': instance.isArchived,
  'isBlocked': instance.isBlocked,
  'staffUnreadCount': instance.staffUnreadCount,
  'lastMessageText': instance.lastMessageText,
  'lastMessageTimestamp': const _NullableTimestampConverter().toJson(
    instance.lastMessageTimestamp,
  ),
  'lastMessageSenderName': instance.lastMessageSenderName,
  'lastMessageSenderUid': instance.lastMessageSenderUid,
  'messageCount': instance.messageCount,
  'createdAt': const _NullableTimestampConverter().toJson(instance.createdAt),
  'updatedAt': const _NullableTimestampConverter().toJson(instance.updatedAt),
};
