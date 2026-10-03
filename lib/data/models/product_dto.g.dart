// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductDto _$ProductDtoFromJson(Map<String, dynamic> json) => ProductDto(
  id: json['id'] as String?,
  name: json['name'] as String,
  searchName: json['searchName'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  basePriceCents: (json['basePriceCents'] as num).toInt(),
  iceBp: (json['iceBp'] as num?)?.toInt() ?? 0,
  stock: (json['stock'] as num).toInt(),
  imagePath: json['imagePath'] as String?,
  isActive: json['isActive'] as bool,
  audit: json['audit'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ProductDtoToJson(ProductDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'searchName': instance.searchName,
      'description': instance.description,
      'category': instance.category,
      'basePriceCents': instance.basePriceCents,
      'iceBp': instance.iceBp,
      'stock': instance.stock,
      'imagePath': instance.imagePath,
      'isActive': instance.isActive,
      'audit': instance.audit,
    };
