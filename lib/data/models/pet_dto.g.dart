// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PetDto _$PetDtoFromJson(Map<String, dynamic> json) => PetDto(
  id: json['id'] as String?,
  ownerId: json['ownerId'] as String,
  name: json['name'] as String,
  searchName: json['searchName'] as String,
  species: json['species'] as String,
  sex: json['sex'] as String,
  reproductiveStatus: json['reproductiveStatus'] as String,
  breed: json['breed'] as String?,
  birthDate: json['birthDate'] as String?,
  allergies: json['allergies'] as String?,
  photoPath: json['photoPath'] as String?,
  status: json['status'] as String,
  lastWeightGrams: (json['lastWeightGrams'] as num?)?.toInt(),
  lastWeightDate: json['lastWeightDate'] as String?,
  deactivatedAt: PetDto._dateTimeFromTimestamp(json['deactivatedAt']),
  deactivatedBy: json['deactivatedBy'] as String?,
  audit: json['audit'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PetDtoToJson(PetDto instance) => <String, dynamic>{
  'id': instance.id,
  'ownerId': instance.ownerId,
  'name': instance.name,
  'searchName': instance.searchName,
  'species': instance.species,
  'sex': instance.sex,
  'reproductiveStatus': instance.reproductiveStatus,
  'breed': instance.breed,
  'birthDate': instance.birthDate,
  'allergies': instance.allergies,
  'photoPath': instance.photoPath,
  'status': instance.status,
  'lastWeightGrams': instance.lastWeightGrams,
  'lastWeightDate': instance.lastWeightDate,
  'deactivatedAt': PetDto._dateTimeToTimestamp(instance.deactivatedAt),
  'deactivatedBy': instance.deactivatedBy,
  'audit': instance.audit,
};
