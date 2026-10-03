// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proforma_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProformaItemDto _$ProformaItemDtoFromJson(Map<String, dynamic> json) =>
    ProformaItemDto(
      type: json['itemType'] as String,
      referenceId: json['refId'] as String,
      refLineId: json['refLineId'] as String?,
      title: json['concept'] as String,
      basePriceCents: (json['unitBasePriceCents'] as num).toInt(),
      iceBp: (json['iceBp'] as num).toInt(),
      ivaBp: (json['ivaBp'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      subtotalCents: (json['lineSubtotalCents'] as num).toInt(),
      iceAmountCents: (json['iceAmountCents'] as num).toInt(),
      ivaAmountCents: (json['ivaAmountCents'] as num).toInt(),
      totalCents: (json['lineTotalCents'] as num).toInt(),
    );

Map<String, dynamic> _$ProformaItemDtoToJson(ProformaItemDto instance) =>
    <String, dynamic>{
      'itemType': instance.type,
      'refId': instance.referenceId,
      'refLineId': instance.refLineId,
      'concept': instance.title,
      'unitBasePriceCents': instance.basePriceCents,
      'iceBp': instance.iceBp,
      'ivaBp': instance.ivaBp,
      'quantity': instance.quantity,
      'lineSubtotalCents': instance.subtotalCents,
      'iceAmountCents': instance.iceAmountCents,
      'ivaAmountCents': instance.ivaAmountCents,
      'lineTotalCents': instance.totalCents,
    };

ProformaDto _$ProformaDtoFromJson(Map<String, dynamic> json) => ProformaDto(
  id: json['id'] as String?,
  clientId: json['clientId'] as String,
  clientName: json['clientName'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ProformaItemDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  discountsCents: (json['totalDiscountCents'] as num?)?.toInt() ?? 0,
  surchargesCents: (json['totalSurchargeCents'] as num?)?.toInt() ?? 0,
  subtotalCents: (json['subtotalCents'] as num?)?.toInt() ?? 0,
  iceTotalCents: (json['totalIceCents'] as num?)?.toInt() ?? 0,
  ivaTotalCents: (json['totalIvaCents'] as num?)?.toInt() ?? 0,
  totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
  status: json['status'] as String,
  issuedAt: const _TimestampConverter().fromJson(json['createdAt'] as Object),
  deliveredAt: const _NullableTimestampConverter().fromJson(
    json['deliveredAt'],
  ),
  finalizedAt: const _NullableTimestampConverter().fromJson(
    json['finalizedAt'],
  ),
  voidedAt: const _NullableTimestampConverter().fromJson(json['voidedAt']),
  voidReason: json['voidReason'] as String?,
  pdfStoragePath: json['pdfPath'] as String?,
);

Map<String, dynamic> _$ProformaDtoToJson(ProformaDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'totalDiscountCents': instance.discountsCents,
      'totalSurchargeCents': instance.surchargesCents,
      'subtotalCents': instance.subtotalCents,
      'totalIceCents': instance.iceTotalCents,
      'totalIvaCents': instance.ivaTotalCents,
      'totalCents': instance.totalCents,
      'status': instance.status,
      'createdAt': const _TimestampConverter().toJson(instance.issuedAt),
      'deliveredAt': const _NullableTimestampConverter().toJson(
        instance.deliveredAt,
      ),
      'finalizedAt': const _NullableTimestampConverter().toJson(
        instance.finalizedAt,
      ),
      'voidedAt': const _NullableTimestampConverter().toJson(instance.voidedAt),
      'voidReason': instance.voidReason,
      'pdfPath': instance.pdfStoragePath,
    };
