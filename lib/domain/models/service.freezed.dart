// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Service {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get searchName => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get basePriceCents => throw _privateConstructorUsedError;
  int get iceBp => throw _privateConstructorUsedError;
  bool get isClinical => throw _privateConstructorUsedError;
  int get estimatedDurationMinutes => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceCopyWith<Service> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceCopyWith<$Res> {
  factory $ServiceCopyWith(Service value, $Res Function(Service) then) =
      _$ServiceCopyWithImpl<$Res, Service>;
  @useResult
  $Res call({
    String id,
    String name,
    String searchName,
    String description,
    int basePriceCents,
    int iceBp,
    bool isClinical,
    int estimatedDurationMinutes,
    bool isActive,
  });
}

/// @nodoc
class _$ServiceCopyWithImpl<$Res, $Val extends Service>
    implements $ServiceCopyWith<$Res> {
  _$ServiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? searchName = null,
    Object? description = null,
    Object? basePriceCents = null,
    Object? iceBp = null,
    Object? isClinical = null,
    Object? estimatedDurationMinutes = null,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            searchName: null == searchName
                ? _value.searchName
                : searchName // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            basePriceCents: null == basePriceCents
                ? _value.basePriceCents
                : basePriceCents // ignore: cast_nullable_to_non_nullable
                      as int,
            iceBp: null == iceBp
                ? _value.iceBp
                : iceBp // ignore: cast_nullable_to_non_nullable
                      as int,
            isClinical: null == isClinical
                ? _value.isClinical
                : isClinical // ignore: cast_nullable_to_non_nullable
                      as bool,
            estimatedDurationMinutes: null == estimatedDurationMinutes
                ? _value.estimatedDurationMinutes
                : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceImplCopyWith<$Res> implements $ServiceCopyWith<$Res> {
  factory _$$ServiceImplCopyWith(
    _$ServiceImpl value,
    $Res Function(_$ServiceImpl) then,
  ) = __$$ServiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String searchName,
    String description,
    int basePriceCents,
    int iceBp,
    bool isClinical,
    int estimatedDurationMinutes,
    bool isActive,
  });
}

/// @nodoc
class __$$ServiceImplCopyWithImpl<$Res>
    extends _$ServiceCopyWithImpl<$Res, _$ServiceImpl>
    implements _$$ServiceImplCopyWith<$Res> {
  __$$ServiceImplCopyWithImpl(
    _$ServiceImpl _value,
    $Res Function(_$ServiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? searchName = null,
    Object? description = null,
    Object? basePriceCents = null,
    Object? iceBp = null,
    Object? isClinical = null,
    Object? estimatedDurationMinutes = null,
    Object? isActive = null,
  }) {
    return _then(
      _$ServiceImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        searchName: null == searchName
            ? _value.searchName
            : searchName // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        basePriceCents: null == basePriceCents
            ? _value.basePriceCents
            : basePriceCents // ignore: cast_nullable_to_non_nullable
                  as int,
        iceBp: null == iceBp
            ? _value.iceBp
            : iceBp // ignore: cast_nullable_to_non_nullable
                  as int,
        isClinical: null == isClinical
            ? _value.isClinical
            : isClinical // ignore: cast_nullable_to_non_nullable
                  as bool,
        estimatedDurationMinutes: null == estimatedDurationMinutes
            ? _value.estimatedDurationMinutes
            : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ServiceImpl implements _Service {
  const _$ServiceImpl({
    required this.id,
    required this.name,
    required this.searchName,
    required this.description,
    required this.basePriceCents,
    this.iceBp = 0,
    required this.isClinical,
    required this.estimatedDurationMinutes,
    required this.isActive,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String searchName;
  @override
  final String description;
  @override
  final int basePriceCents;
  @override
  @JsonKey()
  final int iceBp;
  @override
  final bool isClinical;
  @override
  final int estimatedDurationMinutes;
  @override
  final bool isActive;

  @override
  String toString() {
    return 'Service(id: $id, name: $name, searchName: $searchName, description: $description, basePriceCents: $basePriceCents, iceBp: $iceBp, isClinical: $isClinical, estimatedDurationMinutes: $estimatedDurationMinutes, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.searchName, searchName) ||
                other.searchName == searchName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.basePriceCents, basePriceCents) ||
                other.basePriceCents == basePriceCents) &&
            (identical(other.iceBp, iceBp) || other.iceBp == iceBp) &&
            (identical(other.isClinical, isClinical) ||
                other.isClinical == isClinical) &&
            (identical(
                  other.estimatedDurationMinutes,
                  estimatedDurationMinutes,
                ) ||
                other.estimatedDurationMinutes == estimatedDurationMinutes) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    searchName,
    description,
    basePriceCents,
    iceBp,
    isClinical,
    estimatedDurationMinutes,
    isActive,
  );

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceImplCopyWith<_$ServiceImpl> get copyWith =>
      __$$ServiceImplCopyWithImpl<_$ServiceImpl>(this, _$identity);
}

abstract class _Service implements Service {
  const factory _Service({
    required final String id,
    required final String name,
    required final String searchName,
    required final String description,
    required final int basePriceCents,
    final int iceBp,
    required final bool isClinical,
    required final int estimatedDurationMinutes,
    required final bool isActive,
  }) = _$ServiceImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get searchName;
  @override
  String get description;
  @override
  int get basePriceCents;
  @override
  int get iceBp;
  @override
  bool get isClinical;
  @override
  int get estimatedDurationMinutes;
  @override
  bool get isActive;

  /// Create a copy of Service
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceImplCopyWith<_$ServiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
