// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proforma.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProformaItemImpl _$$ProformaItemImplFromJson(Map<String, dynamic> json) =>
    _$ProformaItemImpl(
      type: json['type'] as String,
      referenceId: json['referenceId'] as String,
      refLineId: json['refLineId'] as String?,
      title: json['title'] as String,
      basePriceCents: (json['basePriceCents'] as num).toInt(),
      iceBp: (json['iceBp'] as num).toInt(),
      ivaBp: (json['ivaBp'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      subtotalCents: (json['subtotalCents'] as num).toInt(),
      iceAmountCents: (json['iceAmountCents'] as num).toInt(),
      ivaAmountCents: (json['ivaAmountCents'] as num).toInt(),
      totalCents: (json['totalCents'] as num).toInt(),
    );

Map<String, dynamic> _$$ProformaItemImplToJson(_$ProformaItemImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'referenceId': instance.referenceId,
      'refLineId': instance.refLineId,
      'title': instance.title,
      'basePriceCents': instance.basePriceCents,
      'iceBp': instance.iceBp,
      'ivaBp': instance.ivaBp,
      'quantity': instance.quantity,
      'subtotalCents': instance.subtotalCents,
      'iceAmountCents': instance.iceAmountCents,
      'ivaAmountCents': instance.ivaAmountCents,
      'totalCents': instance.totalCents,
    };

_$ProformaImpl _$$ProformaImplFromJson(Map<String, dynamic> json) =>
    _$ProformaImpl(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ProformaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      discountsCents: (json['discountsCents'] as num?)?.toInt() ?? 0,
      surchargesCents: (json['surchargesCents'] as num?)?.toInt() ?? 0,
      subtotalCents: (json['subtotalCents'] as num?)?.toInt() ?? 0,
      iceTotalCents: (json['iceTotalCents'] as num?)?.toInt() ?? 0,
      ivaTotalCents: (json['ivaTotalCents'] as num?)?.toInt() ?? 0,
      totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      finalizedAt: json['finalizedAt'] == null
          ? null
          : DateTime.parse(json['finalizedAt'] as String),
      voidedAt: json['voidedAt'] == null
          ? null
          : DateTime.parse(json['voidedAt'] as String),
      voidReason: json['voidReason'] as String?,
      pdfStoragePath: json['pdfStoragePath'] as String?,
    );

Map<String, dynamic> _$$ProformaImplToJson(_$ProformaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'items': instance.items,
      'discountsCents': instance.discountsCents,
      'surchargesCents': instance.surchargesCents,
      'subtotalCents': instance.subtotalCents,
      'iceTotalCents': instance.iceTotalCents,
      'ivaTotalCents': instance.ivaTotalCents,
      'totalCents': instance.totalCents,
      'status': instance.status,
      'issuedAt': instance.issuedAt.toIso8601String(),
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'finalizedAt': instance.finalizedAt?.toIso8601String(),
      'voidedAt': instance.voidedAt?.toIso8601String(),
      'voidReason': instance.voidReason,
      'pdfStoragePath': instance.pdfStoragePath,
    };
