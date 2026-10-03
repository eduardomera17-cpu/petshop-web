// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proforma.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ProformaItem _$ProformaItemFromJson(Map<String, dynamic> json) {
  return _ProformaItem.fromJson(json);
}

/// @nodoc
mixin _$ProformaItem {
  String get type =>
      throw _privateConstructorUsedError; // 'SERVICE' o 'PRODUCT'
  String get referenceId => throw _privateConstructorUsedError;
  String? get refLineId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get basePriceCents => throw _privateConstructorUsedError;
  int get iceBp => throw _privateConstructorUsedError;
  int get ivaBp => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  int get subtotalCents => throw _privateConstructorUsedError;
  int get iceAmountCents => throw _privateConstructorUsedError;
  int get ivaAmountCents => throw _privateConstructorUsedError;
  int get totalCents => throw _privateConstructorUsedError;

  /// Serializes this ProformaItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProformaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProformaItemCopyWith<ProformaItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProformaItemCopyWith<$Res> {
  factory $ProformaItemCopyWith(
    ProformaItem value,
    $Res Function(ProformaItem) then,
  ) = _$ProformaItemCopyWithImpl<$Res, ProformaItem>;
  @useResult
  $Res call({
    String type,
    String referenceId,
    String? refLineId,
    String title,
    int basePriceCents,
    int iceBp,
    int ivaBp,
    int quantity,
    int subtotalCents,
    int iceAmountCents,
    int ivaAmountCents,
    int totalCents,
  });
}

/// @nodoc
class _$ProformaItemCopyWithImpl<$Res, $Val extends ProformaItem>
    implements $ProformaItemCopyWith<$Res> {
  _$ProformaItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProformaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? referenceId = null,
    Object? refLineId = freezed,
    Object? title = null,
    Object? basePriceCents = null,
    Object? iceBp = null,
    Object? ivaBp = null,
    Object? quantity = null,
    Object? subtotalCents = null,
    Object? iceAmountCents = null,
    Object? ivaAmountCents = null,
    Object? totalCents = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            referenceId: null == referenceId
                ? _value.referenceId
                : referenceId // ignore: cast_nullable_to_non_nullable
                      as String,
            refLineId: freezed == refLineId
                ? _value.refLineId
                : refLineId // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            basePriceCents: null == basePriceCents
                ? _value.basePriceCents
                : basePriceCents // ignore: cast_nullable_to_non_nullable
                      as int,
            iceBp: null == iceBp
                ? _value.iceBp
                : iceBp // ignore: cast_nullable_to_non_nullable
                      as int,
            ivaBp: null == ivaBp
                ? _value.ivaBp
                : ivaBp // ignore: cast_nullable_to_non_nullable
                      as int,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            subtotalCents: null == subtotalCents
                ? _value.subtotalCents
                : subtotalCents // ignore: cast_nullable_to_non_nullable
                      as int,
            iceAmountCents: null == iceAmountCents
                ? _value.iceAmountCents
                : iceAmountCents // ignore: cast_nullable_to_non_nullable
                      as int,
            ivaAmountCents: null == ivaAmountCents
                ? _value.ivaAmountCents
                : ivaAmountCents // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCents: null == totalCents
                ? _value.totalCents
                : totalCents // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProformaItemImplCopyWith<$Res>
    implements $ProformaItemCopyWith<$Res> {
  factory _$$ProformaItemImplCopyWith(
    _$ProformaItemImpl value,
    $Res Function(_$ProformaItemImpl) then,
  ) = __$$ProformaItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String type,
    String referenceId,
    String? refLineId,
    String title,
    int basePriceCents,
    int iceBp,
    int ivaBp,
    int quantity,
    int subtotalCents,
    int iceAmountCents,
    int ivaAmountCents,
    int totalCents,
  });
}

/// @nodoc
class __$$ProformaItemImplCopyWithImpl<$Res>
    extends _$ProformaItemCopyWithImpl<$Res, _$ProformaItemImpl>
    implements _$$ProformaItemImplCopyWith<$Res> {
  __$$ProformaItemImplCopyWithImpl(
    _$ProformaItemImpl _value,
    $Res Function(_$ProformaItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProformaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? referenceId = null,
    Object? refLineId = freezed,
    Object? title = null,
    Object? basePriceCents = null,
    Object? iceBp = null,
    Object? ivaBp = null,
    Object? quantity = null,
    Object? subtotalCents = null,
    Object? iceAmountCents = null,
    Object? ivaAmountCents = null,
    Object? totalCents = null,
  }) {
    return _then(
      _$ProformaItemImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        referenceId: null == referenceId
            ? _value.referenceId
            : referenceId // ignore: cast_nullable_to_non_nullable
                  as String,
        refLineId: freezed == refLineId
            ? _value.refLineId
            : refLineId // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        basePriceCents: null == basePriceCents
            ? _value.basePriceCents
            : basePriceCents // ignore: cast_nullable_to_non_nullable
                  as int,
        iceBp: null == iceBp
            ? _value.iceBp
            : iceBp // ignore: cast_nullable_to_non_nullable
                  as int,
        ivaBp: null == ivaBp
            ? _value.ivaBp
            : ivaBp // ignore: cast_nullable_to_non_nullable
                  as int,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        subtotalCents: null == subtotalCents
            ? _value.subtotalCents
            : subtotalCents // ignore: cast_nullable_to_non_nullable
                  as int,
        iceAmountCents: null == iceAmountCents
            ? _value.iceAmountCents
            : iceAmountCents // ignore: cast_nullable_to_non_nullable
                  as int,
        ivaAmountCents: null == ivaAmountCents
            ? _value.ivaAmountCents
            : ivaAmountCents // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCents: null == totalCents
            ? _value.totalCents
            : totalCents // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProformaItemImpl implements _ProformaItem {
  const _$ProformaItemImpl({
    required this.type,
    required this.referenceId,
    this.refLineId,
    required this.title,
    required this.basePriceCents,
    required this.iceBp,
    required this.ivaBp,
    required this.quantity,
    required this.subtotalCents,
    required this.iceAmountCents,
    required this.ivaAmountCents,
    required this.totalCents,
  });

  factory _$ProformaItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProformaItemImplFromJson(json);

  @override
  final String type;
  // 'SERVICE' o 'PRODUCT'
  @override
  final String referenceId;
  @override
  final String? refLineId;
  @override
  final String title;
  @override
  final int basePriceCents;
  @override
  final int iceBp;
  @override
  final int ivaBp;
  @override
  final int quantity;
  @override
  final int subtotalCents;
  @override
  final int iceAmountCents;
  @override
  final int ivaAmountCents;
  @override
  final int totalCents;

  @override
  String toString() {
    return 'ProformaItem(type: $type, referenceId: $referenceId, refLineId: $refLineId, title: $title, basePriceCents: $basePriceCents, iceBp: $iceBp, ivaBp: $ivaBp, quantity: $quantity, subtotalCents: $subtotalCents, iceAmountCents: $iceAmountCents, ivaAmountCents: $ivaAmountCents, totalCents: $totalCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProformaItemImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.referenceId, referenceId) ||
                other.referenceId == referenceId) &&
            (identical(other.refLineId, refLineId) ||
                other.refLineId == refLineId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.basePriceCents, basePriceCents) ||
                other.basePriceCents == basePriceCents) &&
            (identical(other.iceBp, iceBp) || other.iceBp == iceBp) &&
            (identical(other.ivaBp, ivaBp) || other.ivaBp == ivaBp) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.subtotalCents, subtotalCents) ||
                other.subtotalCents == subtotalCents) &&
            (identical(other.iceAmountCents, iceAmountCents) ||
                other.iceAmountCents == iceAmountCents) &&
            (identical(other.ivaAmountCents, ivaAmountCents) ||
                other.ivaAmountCents == ivaAmountCents) &&
            (identical(other.totalCents, totalCents) ||
                other.totalCents == totalCents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    referenceId,
    refLineId,
    title,
    basePriceCents,
    iceBp,
    ivaBp,
    quantity,
    subtotalCents,
    iceAmountCents,
    ivaAmountCents,
    totalCents,
  );

  /// Create a copy of ProformaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProformaItemImplCopyWith<_$ProformaItemImpl> get copyWith =>
      __$$ProformaItemImplCopyWithImpl<_$ProformaItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProformaItemImplToJson(this);
  }
}

abstract class _ProformaItem implements ProformaItem {
  const factory _ProformaItem({
    required final String type,
    required final String referenceId,
    final String? refLineId,
    required final String title,
    required final int basePriceCents,
    required final int iceBp,
    required final int ivaBp,
    required final int quantity,
    required final int subtotalCents,
    required final int iceAmountCents,
    required final int ivaAmountCents,
    required final int totalCents,
  }) = _$ProformaItemImpl;

  factory _ProformaItem.fromJson(Map<String, dynamic> json) =
      _$ProformaItemImpl.fromJson;

  @override
  String get type; // 'SERVICE' o 'PRODUCT'
  @override
  String get referenceId;
  @override
  String? get refLineId;
  @override
  String get title;
  @override
  int get basePriceCents;
  @override
  int get iceBp;
  @override
  int get ivaBp;
  @override
  int get quantity;
  @override
  int get subtotalCents;
  @override
  int get iceAmountCents;
  @override
  int get ivaAmountCents;
  @override
  int get totalCents;

  /// Create a copy of ProformaItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProformaItemImplCopyWith<_$ProformaItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Proforma _$ProformaFromJson(Map<String, dynamic> json) {
  return _Proforma.fromJson(json);
}

/// @nodoc
mixin _$Proforma {
  String get id => throw _privateConstructorUsedError;
  String get clientId => throw _privateConstructorUsedError;
  String get clientName => throw _privateConstructorUsedError;
  List<ProformaItem> get items => throw _privateConstructorUsedError;
  int get discountsCents => throw _privateConstructorUsedError;
  int get surchargesCents => throw _privateConstructorUsedError;
  int get subtotalCents => throw _privateConstructorUsedError;
  int get iceTotalCents => throw _privateConstructorUsedError;
  int get ivaTotalCents => throw _privateConstructorUsedError;
  int get totalCents => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'DRAFT', 'DELIVERED', 'FINALIZED', 'VOIDED'
  DateTime get issuedAt => throw _privateConstructorUsedError;
  DateTime? get deliveredAt => throw _privateConstructorUsedError;
  DateTime? get finalizedAt => throw _privateConstructorUsedError;
  DateTime? get voidedAt => throw _privateConstructorUsedError;
  String? get voidReason => throw _privateConstructorUsedError;
  String? get pdfStoragePath => throw _privateConstructorUsedError;

  /// Serializes this Proforma to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Proforma
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProformaCopyWith<Proforma> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProformaCopyWith<$Res> {
  factory $ProformaCopyWith(Proforma value, $Res Function(Proforma) then) =
      _$ProformaCopyWithImpl<$Res, Proforma>;
  @useResult
  $Res call({
    String id,
    String clientId,
    String clientName,
    List<ProformaItem> items,
    int discountsCents,
    int surchargesCents,
    int subtotalCents,
    int iceTotalCents,
    int ivaTotalCents,
    int totalCents,
    String status,
    DateTime issuedAt,
    DateTime? deliveredAt,
    DateTime? finalizedAt,
    DateTime? voidedAt,
    String? voidReason,
    String? pdfStoragePath,
  });
}

/// @nodoc
class _$ProformaCopyWithImpl<$Res, $Val extends Proforma>
    implements $ProformaCopyWith<$Res> {
  _$ProformaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Proforma
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? clientName = null,
    Object? items = null,
    Object? discountsCents = null,
    Object? surchargesCents = null,
    Object? subtotalCents = null,
    Object? iceTotalCents = null,
    Object? ivaTotalCents = null,
    Object? totalCents = null,
    Object? status = null,
    Object? issuedAt = null,
    Object? deliveredAt = freezed,
    Object? finalizedAt = freezed,
    Object? voidedAt = freezed,
    Object? voidReason = freezed,
    Object? pdfStoragePath = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            clientId: null == clientId
                ? _value.clientId
                : clientId // ignore: cast_nullable_to_non_nullable
                      as String,
            clientName: null == clientName
                ? _value.clientName
                : clientName // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<ProformaItem>,
            discountsCents: null == discountsCents
                ? _value.discountsCents
                : discountsCents // ignore: cast_nullable_to_non_nullable
                      as int,
            surchargesCents: null == surchargesCents
                ? _value.surchargesCents
                : surchargesCents // ignore: cast_nullable_to_non_nullable
                      as int,
            subtotalCents: null == subtotalCents
                ? _value.subtotalCents
                : subtotalCents // ignore: cast_nullable_to_non_nullable
                      as int,
            iceTotalCents: null == iceTotalCents
                ? _value.iceTotalCents
                : iceTotalCents // ignore: cast_nullable_to_non_nullable
                      as int,
            ivaTotalCents: null == ivaTotalCents
                ? _value.ivaTotalCents
                : ivaTotalCents // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCents: null == totalCents
                ? _value.totalCents
                : totalCents // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            issuedAt: null == issuedAt
                ? _value.issuedAt
                : issuedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            deliveredAt: freezed == deliveredAt
                ? _value.deliveredAt
                : deliveredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            finalizedAt: freezed == finalizedAt
                ? _value.finalizedAt
                : finalizedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            voidedAt: freezed == voidedAt
                ? _value.voidedAt
                : voidedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            voidReason: freezed == voidReason
                ? _value.voidReason
                : voidReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            pdfStoragePath: freezed == pdfStoragePath
                ? _value.pdfStoragePath
                : pdfStoragePath // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProformaImplCopyWith<$Res>
    implements $ProformaCopyWith<$Res> {
  factory _$$ProformaImplCopyWith(
    _$ProformaImpl value,
    $Res Function(_$ProformaImpl) then,
  ) = __$$ProformaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String clientId,
    String clientName,
    List<ProformaItem> items,
    int discountsCents,
    int surchargesCents,
    int subtotalCents,
    int iceTotalCents,
    int ivaTotalCents,
    int totalCents,
    String status,
    DateTime issuedAt,
    DateTime? deliveredAt,
    DateTime? finalizedAt,
    DateTime? voidedAt,
    String? voidReason,
    String? pdfStoragePath,
  });
}

/// @nodoc
class __$$ProformaImplCopyWithImpl<$Res>
    extends _$ProformaCopyWithImpl<$Res, _$ProformaImpl>
    implements _$$ProformaImplCopyWith<$Res> {
  __$$ProformaImplCopyWithImpl(
    _$ProformaImpl _value,
    $Res Function(_$ProformaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Proforma
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? clientName = null,
    Object? items = null,
    Object? discountsCents = null,
    Object? surchargesCents = null,
    Object? subtotalCents = null,
    Object? iceTotalCents = null,
    Object? ivaTotalCents = null,
    Object? totalCents = null,
    Object? status = null,
    Object? issuedAt = null,
    Object? deliveredAt = freezed,
    Object? finalizedAt = freezed,
    Object? voidedAt = freezed,
    Object? voidReason = freezed,
    Object? pdfStoragePath = freezed,
  }) {
    return _then(
      _$ProformaImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        clientId: null == clientId
            ? _value.clientId
            : clientId // ignore: cast_nullable_to_non_nullable
                  as String,
        clientName: null == clientName
            ? _value.clientName
            : clientName // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<ProformaItem>,
        discountsCents: null == discountsCents
            ? _value.discountsCents
            : discountsCents // ignore: cast_nullable_to_non_nullable
                  as int,
        surchargesCents: null == surchargesCents
            ? _value.surchargesCents
            : surchargesCents // ignore: cast_nullable_to_non_nullable
                  as int,
        subtotalCents: null == subtotalCents
            ? _value.subtotalCents
            : subtotalCents // ignore: cast_nullable_to_non_nullable
                  as int,
        iceTotalCents: null == iceTotalCents
            ? _value.iceTotalCents
            : iceTotalCents // ignore: cast_nullable_to_non_nullable
                  as int,
        ivaTotalCents: null == ivaTotalCents
            ? _value.ivaTotalCents
            : ivaTotalCents // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCents: null == totalCents
            ? _value.totalCents
            : totalCents // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        issuedAt: null == issuedAt
            ? _value.issuedAt
            : issuedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        deliveredAt: freezed == deliveredAt
            ? _value.deliveredAt
            : deliveredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        finalizedAt: freezed == finalizedAt
            ? _value.finalizedAt
            : finalizedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        voidedAt: freezed == voidedAt
            ? _value.voidedAt
            : voidedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        voidReason: freezed == voidReason
            ? _value.voidReason
            : voidReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        pdfStoragePath: freezed == pdfStoragePath
            ? _value.pdfStoragePath
            : pdfStoragePath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProformaImpl implements _Proforma {
  const _$ProformaImpl({
    required this.id,
    required this.clientId,
    required this.clientName,
    final List<ProformaItem> items = const [],
    this.discountsCents = 0,
    this.surchargesCents = 0,
    this.subtotalCents = 0,
    this.iceTotalCents = 0,
    this.ivaTotalCents = 0,
    this.totalCents = 0,
    required this.status,
    required this.issuedAt,
    this.deliveredAt,
    this.finalizedAt,
    this.voidedAt,
    this.voidReason,
    this.pdfStoragePath,
  }) : _items = items;

  factory _$ProformaImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProformaImplFromJson(json);

  @override
  final String id;
  @override
  final String clientId;
  @override
  final String clientName;
  final List<ProformaItem> _items;
  @override
  @JsonKey()
  List<ProformaItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final int discountsCents;
  @override
  @JsonKey()
  final int surchargesCents;
  @override
  @JsonKey()
  final int subtotalCents;
  @override
  @JsonKey()
  final int iceTotalCents;
  @override
  @JsonKey()
  final int ivaTotalCents;
  @override
  @JsonKey()
  final int totalCents;
  @override
  final String status;
  // 'DRAFT', 'DELIVERED', 'FINALIZED', 'VOIDED'
  @override
  final DateTime issuedAt;
  @override
  final DateTime? deliveredAt;
  @override
  final DateTime? finalizedAt;
  @override
  final DateTime? voidedAt;
  @override
  final String? voidReason;
  @override
  final String? pdfStoragePath;

  @override
  String toString() {
    return 'Proforma(id: $id, clientId: $clientId, clientName: $clientName, items: $items, discountsCents: $discountsCents, surchargesCents: $surchargesCents, subtotalCents: $subtotalCents, iceTotalCents: $iceTotalCents, ivaTotalCents: $ivaTotalCents, totalCents: $totalCents, status: $status, issuedAt: $issuedAt, deliveredAt: $deliveredAt, finalizedAt: $finalizedAt, voidedAt: $voidedAt, voidReason: $voidReason, pdfStoragePath: $pdfStoragePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProformaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.discountsCents, discountsCents) ||
                other.discountsCents == discountsCents) &&
            (identical(other.surchargesCents, surchargesCents) ||
                other.surchargesCents == surchargesCents) &&
            (identical(other.subtotalCents, subtotalCents) ||
                other.subtotalCents == subtotalCents) &&
            (identical(other.iceTotalCents, iceTotalCents) ||
                other.iceTotalCents == iceTotalCents) &&
            (identical(other.ivaTotalCents, ivaTotalCents) ||
                other.ivaTotalCents == ivaTotalCents) &&
            (identical(other.totalCents, totalCents) ||
                other.totalCents == totalCents) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.issuedAt, issuedAt) ||
                other.issuedAt == issuedAt) &&
            (identical(other.deliveredAt, deliveredAt) ||
                other.deliveredAt == deliveredAt) &&
            (identical(other.finalizedAt, finalizedAt) ||
                other.finalizedAt == finalizedAt) &&
            (identical(other.voidedAt, voidedAt) ||
                other.voidedAt == voidedAt) &&
            (identical(other.voidReason, voidReason) ||
                other.voidReason == voidReason) &&
            (identical(other.pdfStoragePath, pdfStoragePath) ||
                other.pdfStoragePath == pdfStoragePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clientId,
    clientName,
    const DeepCollectionEquality().hash(_items),
    discountsCents,
    surchargesCents,
    subtotalCents,
    iceTotalCents,
    ivaTotalCents,
    totalCents,
    status,
    issuedAt,
    deliveredAt,
    finalizedAt,
    voidedAt,
    voidReason,
    pdfStoragePath,
  );

  /// Create a copy of Proforma
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProformaImplCopyWith<_$ProformaImpl> get copyWith =>
      __$$ProformaImplCopyWithImpl<_$ProformaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProformaImplToJson(this);
  }
}

abstract class _Proforma implements Proforma {
  const factory _Proforma({
    required final String id,
    required final String clientId,
    required final String clientName,
    final List<ProformaItem> items,
    final int discountsCents,
    final int surchargesCents,
    final int subtotalCents,
    final int iceTotalCents,
    final int ivaTotalCents,
    final int totalCents,
    required final String status,
    required final DateTime issuedAt,
    final DateTime? deliveredAt,
    final DateTime? finalizedAt,
    final DateTime? voidedAt,
    final String? voidReason,
    final String? pdfStoragePath,
  }) = _$ProformaImpl;

  factory _Proforma.fromJson(Map<String, dynamic> json) =
      _$ProformaImpl.fromJson;

  @override
  String get id;
  @override
  String get clientId;
  @override
  String get clientName;
  @override
  List<ProformaItem> get items;
  @override
  int get discountsCents;
  @override
  int get surchargesCents;
  @override
  int get subtotalCents;
  @override
  int get iceTotalCents;
  @override
  int get ivaTotalCents;
  @override
  int get totalCents;
  @override
  String get status; // 'DRAFT', 'DELIVERED', 'FINALIZED', 'VOIDED'
  @override
  DateTime get issuedAt;
  @override
  DateTime? get deliveredAt;
  @override
  DateTime? get finalizedAt;
  @override
  DateTime? get voidedAt;
  @override
  String? get voidReason;
  @override
  String? get pdfStoragePath;

  /// Create a copy of Proforma
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProformaImplCopyWith<_$ProformaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
