// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Pet {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get searchName => throw _privateConstructorUsedError;
  String get species => throw _privateConstructorUsedError;
  String get sex => throw _privateConstructorUsedError;
  String get reproductiveStatus => throw _privateConstructorUsedError;
  String? get breed => throw _privateConstructorUsedError;
  String? get birthDate => throw _privateConstructorUsedError;
  String? get allergies => throw _privateConstructorUsedError;
  String? get photoPath => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int? get lastWeightGrams => throw _privateConstructorUsedError;
  String? get lastWeightDate => throw _privateConstructorUsedError;
  DateTime? get deactivatedAt => throw _privateConstructorUsedError;
  String? get deactivatedBy => throw _privateConstructorUsedError;

  /// Create a copy of Pet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PetCopyWith<Pet> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PetCopyWith<$Res> {
  factory $PetCopyWith(Pet value, $Res Function(Pet) then) =
      _$PetCopyWithImpl<$Res, Pet>;
  @useResult
  $Res call({
    String id,
    String ownerId,
    String name,
    String searchName,
    String species,
    String sex,
    String reproductiveStatus,
    String? breed,
    String? birthDate,
    String? allergies,
    String? photoPath,
    String status,
    int? lastWeightGrams,
    String? lastWeightDate,
    DateTime? deactivatedAt,
    String? deactivatedBy,
  });
}

/// @nodoc
class _$PetCopyWithImpl<$Res, $Val extends Pet> implements $PetCopyWith<$Res> {
  _$PetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Pet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? searchName = null,
    Object? species = null,
    Object? sex = null,
    Object? reproductiveStatus = null,
    Object? breed = freezed,
    Object? birthDate = freezed,
    Object? allergies = freezed,
    Object? photoPath = freezed,
    Object? status = null,
    Object? lastWeightGrams = freezed,
    Object? lastWeightDate = freezed,
    Object? deactivatedAt = freezed,
    Object? deactivatedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerId: null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            searchName: null == searchName
                ? _value.searchName
                : searchName // ignore: cast_nullable_to_non_nullable
                      as String,
            species: null == species
                ? _value.species
                : species // ignore: cast_nullable_to_non_nullable
                      as String,
            sex: null == sex
                ? _value.sex
                : sex // ignore: cast_nullable_to_non_nullable
                      as String,
            reproductiveStatus: null == reproductiveStatus
                ? _value.reproductiveStatus
                : reproductiveStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            breed: freezed == breed
                ? _value.breed
                : breed // ignore: cast_nullable_to_non_nullable
                      as String?,
            birthDate: freezed == birthDate
                ? _value.birthDate
                : birthDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            allergies: freezed == allergies
                ? _value.allergies
                : allergies // ignore: cast_nullable_to_non_nullable
                      as String?,
            photoPath: freezed == photoPath
                ? _value.photoPath
                : photoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            lastWeightGrams: freezed == lastWeightGrams
                ? _value.lastWeightGrams
                : lastWeightGrams // ignore: cast_nullable_to_non_nullable
                      as int?,
            lastWeightDate: freezed == lastWeightDate
                ? _value.lastWeightDate
                : lastWeightDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            deactivatedAt: freezed == deactivatedAt
                ? _value.deactivatedAt
                : deactivatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deactivatedBy: freezed == deactivatedBy
                ? _value.deactivatedBy
                : deactivatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PetImplCopyWith<$Res> implements $PetCopyWith<$Res> {
  factory _$$PetImplCopyWith(_$PetImpl value, $Res Function(_$PetImpl) then) =
      __$$PetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String ownerId,
    String name,
    String searchName,
    String species,
    String sex,
    String reproductiveStatus,
    String? breed,
    String? birthDate,
    String? allergies,
    String? photoPath,
    String status,
    int? lastWeightGrams,
    String? lastWeightDate,
    DateTime? deactivatedAt,
    String? deactivatedBy,
  });
}

/// @nodoc
class __$$PetImplCopyWithImpl<$Res> extends _$PetCopyWithImpl<$Res, _$PetImpl>
    implements _$$PetImplCopyWith<$Res> {
  __$$PetImplCopyWithImpl(_$PetImpl _value, $Res Function(_$PetImpl) _then)
    : super(_value, _then);

  /// Create a copy of Pet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? searchName = null,
    Object? species = null,
    Object? sex = null,
    Object? reproductiveStatus = null,
    Object? breed = freezed,
    Object? birthDate = freezed,
    Object? allergies = freezed,
    Object? photoPath = freezed,
    Object? status = null,
    Object? lastWeightGrams = freezed,
    Object? lastWeightDate = freezed,
    Object? deactivatedAt = freezed,
    Object? deactivatedBy = freezed,
  }) {
    return _then(
      _$PetImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        searchName: null == searchName
            ? _value.searchName
            : searchName // ignore: cast_nullable_to_non_nullable
                  as String,
        species: null == species
            ? _value.species
            : species // ignore: cast_nullable_to_non_nullable
                  as String,
        sex: null == sex
            ? _value.sex
            : sex // ignore: cast_nullable_to_non_nullable
                  as String,
        reproductiveStatus: null == reproductiveStatus
            ? _value.reproductiveStatus
            : reproductiveStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        breed: freezed == breed
            ? _value.breed
            : breed // ignore: cast_nullable_to_non_nullable
                  as String?,
        birthDate: freezed == birthDate
            ? _value.birthDate
            : birthDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        allergies: freezed == allergies
            ? _value.allergies
            : allergies // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoPath: freezed == photoPath
            ? _value.photoPath
            : photoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        lastWeightGrams: freezed == lastWeightGrams
            ? _value.lastWeightGrams
            : lastWeightGrams // ignore: cast_nullable_to_non_nullable
                  as int?,
        lastWeightDate: freezed == lastWeightDate
            ? _value.lastWeightDate
            : lastWeightDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        deactivatedAt: freezed == deactivatedAt
            ? _value.deactivatedAt
            : deactivatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deactivatedBy: freezed == deactivatedBy
            ? _value.deactivatedBy
            : deactivatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PetImpl implements _Pet {
  const _$PetImpl({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.searchName,
    required this.species,
    required this.sex,
    required this.reproductiveStatus,
    this.breed,
    this.birthDate,
    this.allergies,
    this.photoPath,
    required this.status,
    this.lastWeightGrams,
    this.lastWeightDate,
    this.deactivatedAt,
    this.deactivatedBy,
  });

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String species;
  @override
  final String sex;
  @override
  final String reproductiveStatus;
  @override
  final String? breed;
  @override
  final String? birthDate;
  @override
  final String? allergies;
  @override
  final String? photoPath;
  @override
  final String status;
  @override
  final int? lastWeightGrams;
  @override
  final String? lastWeightDate;
  @override
  final DateTime? deactivatedAt;
  @override
  final String? deactivatedBy;

  @override
  String toString() {
    return 'Pet(id: $id, ownerId: $ownerId, name: $name, searchName: $searchName, species: $species, sex: $sex, reproductiveStatus: $reproductiveStatus, breed: $breed, birthDate: $birthDate, allergies: $allergies, photoPath: $photoPath, status: $status, lastWeightGrams: $lastWeightGrams, lastWeightDate: $lastWeightDate, deactivatedAt: $deactivatedAt, deactivatedBy: $deactivatedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.searchName, searchName) ||
                other.searchName == searchName) &&
            (identical(other.species, species) || other.species == species) &&
            (identical(other.sex, sex) || other.sex == sex) &&
            (identical(other.reproductiveStatus, reproductiveStatus) ||
                other.reproductiveStatus == reproductiveStatus) &&
            (identical(other.breed, breed) || other.breed == breed) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.allergies, allergies) ||
                other.allergies == allergies) &&
            (identical(other.photoPath, photoPath) ||
                other.photoPath == photoPath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastWeightGrams, lastWeightGrams) ||
                other.lastWeightGrams == lastWeightGrams) &&
            (identical(other.lastWeightDate, lastWeightDate) ||
                other.lastWeightDate == lastWeightDate) &&
            (identical(other.deactivatedAt, deactivatedAt) ||
                other.deactivatedAt == deactivatedAt) &&
            (identical(other.deactivatedBy, deactivatedBy) ||
                other.deactivatedBy == deactivatedBy));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    ownerId,
    name,
    searchName,
    species,
    sex,
    reproductiveStatus,
    breed,
    birthDate,
    allergies,
    photoPath,
    status,
    lastWeightGrams,
    lastWeightDate,
    deactivatedAt,
    deactivatedBy,
  );

  /// Create a copy of Pet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PetImplCopyWith<_$PetImpl> get copyWith =>
      __$$PetImplCopyWithImpl<_$PetImpl>(this, _$identity);
}

abstract class _Pet implements Pet {
  const factory _Pet({
    required final String id,
    required final String ownerId,
    required final String name,
    required final String searchName,
    required final String species,
    required final String sex,
    required final String reproductiveStatus,
    final String? breed,
    final String? birthDate,
    final String? allergies,
    final String? photoPath,
    required final String status,
    final int? lastWeightGrams,
    final String? lastWeightDate,
    final DateTime? deactivatedAt,
    final String? deactivatedBy,
  }) = _$PetImpl;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  String get searchName;
  @override
  String get species;
  @override
  String get sex;
  @override
  String get reproductiveStatus;
  @override
  String? get breed;
  @override
  String? get birthDate;
  @override
  String? get allergies;
  @override
  String? get photoPath;
  @override
  String get status;
  @override
  int? get lastWeightGrams;
  @override
  String? get lastWeightDate;
  @override
  DateTime? get deactivatedAt;
  @override
  String? get deactivatedBy;

  /// Create a copy of Pet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PetImplCopyWith<_$PetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
