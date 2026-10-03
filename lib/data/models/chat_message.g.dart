// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageDto _$ChatMessageDtoFromJson(Map<String, dynamic> json) =>
    ChatMessageDto(
      id: json['id'] as String?,
      senderUid: json['senderUid'] as String,
      senderName: json['senderName'] as String,
      senderRole: json['senderRole'] as String,
      text: json['text'] as String?,
      imagePath: json['imagePath'] as String?,
      readByStaff: json['readByStaff'] as bool? ?? false,
      createdAt: const _NullableTimestampConverter().fromJson(
        json['createdAt'],
      ),
    );

Map<String, dynamic> _$ChatMessageDtoToJson(
  ChatMessageDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'senderUid': instance.senderUid,
  'senderName': instance.senderName,
  'senderRole': instance.senderRole,
  'text': instance.text,
  'imagePath': instance.imagePath,
  'readByStaff': instance.readByStaff,
  'createdAt': const _NullableTimestampConverter().toJson(instance.createdAt),
};
