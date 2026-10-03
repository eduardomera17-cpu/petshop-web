// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductRequestLineDto _$ProductRequestLineDtoFromJson(
  Map<String, dynamic> json,
) => ProductRequestLineDto(
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  agreedUnitPriceCents: (json['agreedUnitPriceCents'] as num).toInt(),
  iceBp: (json['iceBp'] as num).toInt(),
  ivaBp: (json['ivaBp'] as num).toInt(),
);

Map<String, dynamic> _$ProductRequestLineDtoToJson(
  ProductRequestLineDto instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'productName': instance.productName,
  'quantity': instance.quantity,
  'agreedUnitPriceCents': instance.agreedUnitPriceCents,
  'iceBp': instance.iceBp,
  'ivaBp': instance.ivaBp,
};

ProductRequestDto _$ProductRequestDtoFromJson(Map<String, dynamic> json) =>
    ProductRequestDto(
      id: json['id'] as String?,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ProductRequestLineDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      status: json['status'] as String,
      actionDateString: json['actionDateString'] as String,
      proformaId: json['proformaId'] as String?,
      cancelledReason: json['cancelledReason'] as String?,
      audit: json['audit'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProductRequestDtoToJson(ProductRequestDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'status': instance.status,
      'actionDateString': instance.actionDateString,
      'proformaId': instance.proformaId,
      'cancelledReason': instance.cancelledReason,
      'audit': instance.audit,
    };
