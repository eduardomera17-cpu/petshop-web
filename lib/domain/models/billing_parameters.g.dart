// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_parameters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BillingParametersImpl _$$BillingParametersImplFromJson(
  Map<String, dynamic> json,
) => _$BillingParametersImpl(
  businessName: json['businessName'] as String,
  taxId: json['taxId'] as String,
  address: json['address'] as String,
  phone: json['phone'] as String,
  proformaSeries: json['proformaSeries'] as String,
  ivaBp: (json['ivaBp'] as num).toInt(),
  iceIncludedInIvaBase: json['iceIncludedInIvaBase'] as bool,
  logoPath: json['logoPath'] as String?,
  nextProformaNumber: (json['nextProformaNumber'] as num?)?.toInt(),
  deliveryLock: json['deliveryLock'] as bool?,
);

Map<String, dynamic> _$$BillingParametersImplToJson(
  _$BillingParametersImpl instance,
) => <String, dynamic>{
  'businessName': instance.businessName,
  'taxId': instance.taxId,
  'address': instance.address,
  'phone': instance.phone,
  'proformaSeries': instance.proformaSeries,
  'ivaBp': instance.ivaBp,
  'iceIncludedInIvaBase': instance.iceIncludedInIvaBase,
  'logoPath': instance.logoPath,
  'nextProformaNumber': instance.nextProformaNumber,
  'deliveryLock': instance.deliveryLock,
};
