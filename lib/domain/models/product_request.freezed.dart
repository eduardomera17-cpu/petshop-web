// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProductRequestLine {
  /// Identificador del producto solicitado.
  String get productId => throw _privateConstructorUsedError;

  /// Nombre comercial del producto al momento de realizar la solicitud.
  String get productName => throw _privateConstructorUsedError;

  /// Cantidad de unidades requeridas.
  int get quantity => throw _privateConstructorUsedError;

  /// Precio unitario pactado en centavos de dólar.
  int get agreedUnitPriceCents => throw _privateConstructorUsedError;

  /// Puntos base del Impuesto a los Consumos Especiales (ICE).
  int get iceBp => throw _privateConstructorUsedError;

  /// Puntos base del Impuesto al Valor Agregado (IVA).
  int get ivaBp => throw _privateConstructorUsedError;

  /// Create a copy of ProductRequestLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductRequestLineCopyWith<ProductRequestLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductRequestLineCopyWith<$Res> {
  factory $ProductRequestLineCopyWith(
    ProductRequestLine value,
    $Res Function(ProductRequestLine) then,
  ) = _$ProductRequestLineCopyWithImpl<$Res, ProductRequestLine>;
  @useResult
  $Res call({
    String productId,
    String productName,
    int quantity,
    int agreedUnitPriceCents,
    int iceBp,
    int ivaBp,
  });
}

/// @nodoc
class _$ProductRequestLineCopyWithImpl<$Res, $Val extends ProductRequestLine>
    implements $ProductRequestLineCopyWith<$Res> {
  _$ProductRequestLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductRequestLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? productName = null,
    Object? quantity = null,
    Object? agreedUnitPriceCents = null,
    Object? iceBp = null,
    Object? ivaBp = null,
  }) {
    return _then(
      _value.copyWith(
            productId: null == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                      as String,
            productName: null == productName
                ? _value.productName
                : productName // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            agreedUnitPriceCents: null == agreedUnitPriceCents
                ? _value.agreedUnitPriceCents
                : agreedUnitPriceCents // ignore: cast_nullable_to_non_nullable
                      as int,
            iceBp: null == iceBp
                ? _value.iceBp
                : iceBp // ignore: cast_nullable_to_non_nullable
                      as int,
            ivaBp: null == ivaBp
                ? _value.ivaBp
                : ivaBp // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductRequestLineImplCopyWith<$Res>
    implements $ProductRequestLineCopyWith<$Res> {
  factory _$$ProductRequestLineImplCopyWith(
    _$ProductRequestLineImpl value,
    $Res Function(_$ProductRequestLineImpl) then,
  ) = __$$ProductRequestLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String productId,
    String productName,
    int quantity,
    int agreedUnitPriceCents,
    int iceBp,
    int ivaBp,
  });
}

/// @nodoc
class __$$ProductRequestLineImplCopyWithImpl<$Res>
    extends _$ProductRequestLineCopyWithImpl<$Res, _$ProductRequestLineImpl>
    implements _$$ProductRequestLineImplCopyWith<$Res> {
  __$$ProductRequestLineImplCopyWithImpl(
    _$ProductRequestLineImpl _value,
    $Res Function(_$ProductRequestLineImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductRequestLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? productName = null,
    Object? quantity = null,
    Object? agreedUnitPriceCents = null,
    Object? iceBp = null,
    Object? ivaBp = null,
  }) {
    return _then(
      _$ProductRequestLineImpl(
        productId: null == productId
            ? _value.productId
            : productId // ignore: cast_nullable_to_non_nullable
                  as String,
        productName: null == productName
            ? _value.productName
            : productName // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        agreedUnitPriceCents: null == agreedUnitPriceCents
            ? _value.agreedUnitPriceCents
            : agreedUnitPriceCents // ignore: cast_nullable_to_non_nullable
                  as int,
        iceBp: null == iceBp
            ? _value.iceBp
            : iceBp // ignore: cast_nullable_to_non_nullable
                  as int,
        ivaBp: null == ivaBp
            ? _value.ivaBp
            : ivaBp // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ProductRequestLineImpl implements _ProductRequestLine {
  const _$ProductRequestLineImpl({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.agreedUnitPriceCents,
    required this.iceBp,
    required this.ivaBp,
  });

  /// Identificador del producto solicitado.
  @override
  final String productId;

  /// Nombre comercial del producto al momento de realizar la solicitud.
  @override
  final String productName;

  /// Cantidad de unidades requeridas.
  @override
  final int quantity;

  /// Precio unitario pactado en centavos de dólar.
  @override
  final int agreedUnitPriceCents;

  /// Puntos base del Impuesto a los Consumos Especiales (ICE).
  @override
  final int iceBp;

  /// Puntos base del Impuesto al Valor Agregado (IVA).
  @override
  final int ivaBp;

  @override
  String toString() {
    return 'ProductRequestLine(productId: $productId, productName: $productName, quantity: $quantity, agreedUnitPriceCents: $agreedUnitPriceCents, iceBp: $iceBp, ivaBp: $ivaBp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductRequestLineImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.agreedUnitPriceCents, agreedUnitPriceCents) ||
                other.agreedUnitPriceCents == agreedUnitPriceCents) &&
            (identical(other.iceBp, iceBp) || other.iceBp == iceBp) &&
            (identical(other.ivaBp, ivaBp) || other.ivaBp == ivaBp));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    productId,
    productName,
    quantity,
    agreedUnitPriceCents,
    iceBp,
    ivaBp,
  );

  /// Create a copy of ProductRequestLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductRequestLineImplCopyWith<_$ProductRequestLineImpl> get copyWith =>
      __$$ProductRequestLineImplCopyWithImpl<_$ProductRequestLineImpl>(
        this,
        _$identity,
      );
}

abstract class _ProductRequestLine implements ProductRequestLine {
  const factory _ProductRequestLine({
    required final String productId,
    required final String productName,
    required final int quantity,
    required final int agreedUnitPriceCents,
    required final int iceBp,
    required final int ivaBp,
  }) = _$ProductRequestLineImpl;

  /// Identificador del producto solicitado.
  @override
  String get productId;

  /// Nombre comercial del producto al momento de realizar la solicitud.
  @override
  String get productName;

  /// Cantidad de unidades requeridas.
  @override
  int get quantity;

  /// Precio unitario pactado en centavos de dólar.
  @override
  int get agreedUnitPriceCents;

  /// Puntos base del Impuesto a los Consumos Especiales (ICE).
  @override
  int get iceBp;

  /// Puntos base del Impuesto al Valor Agregado (IVA).
  @override
  int get ivaBp;

  /// Create a copy of ProductRequestLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductRequestLineImplCopyWith<_$ProductRequestLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ProductRequest {
  /// Identificador único del pedido.
  String get id => throw _privateConstructorUsedError;

  /// Identificador del cliente solicitante.
  String get clientId => throw _privateConstructorUsedError;

  /// Nombre del cliente para visualización en paneles de gestión.
  String get clientName => throw _privateConstructorUsedError;

  /// Lista de ítems detallados que componen la totalidad de la orden: la única fuente de sus líneas
  /// (WP-6.11-B; los campos planos de la transición se retiraron).
  List<ProductRequestLine> get items => throw _privateConstructorUsedError;

  /// Estado actual de la solicitud ('PENDING', 'PROCESSED', 'CANCELLED').
  String get status => throw _privateConstructorUsedError;

  /// Fecha y hora en formato texto en la que se radicó el pedido.
  String get actionDateString => throw _privateConstructorUsedError;

  /// Identificador de la proforma que consolida este pedido, si ya fue facturado.
  String? get proformaId => throw _privateConstructorUsedError;

  /// Justificación registrada en caso de haberse cancelado el pedido.
  String? get cancelledReason => throw _privateConstructorUsedError;

  /// Create a copy of ProductRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductRequestCopyWith<ProductRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductRequestCopyWith<$Res> {
  factory $ProductRequestCopyWith(
    ProductRequest value,
    $Res Function(ProductRequest) then,
  ) = _$ProductRequestCopyWithImpl<$Res, ProductRequest>;
  @useResult
  $Res call({
    String id,
    String clientId,
    String clientName,
    List<ProductRequestLine> items,
    String status,
    String actionDateString,
    String? proformaId,
    String? cancelledReason,
  });
}

/// @nodoc
class _$ProductRequestCopyWithImpl<$Res, $Val extends ProductRequest>
    implements $ProductRequestCopyWith<$Res> {
  _$ProductRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? clientName = null,
    Object? items = null,
    Object? status = null,
    Object? actionDateString = null,
    Object? proformaId = freezed,
    Object? cancelledReason = freezed,
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
                      as List<ProductRequestLine>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            actionDateString: null == actionDateString
                ? _value.actionDateString
                : actionDateString // ignore: cast_nullable_to_non_nullable
                      as String,
            proformaId: freezed == proformaId
                ? _value.proformaId
                : proformaId // ignore: cast_nullable_to_non_nullable
                      as String?,
            cancelledReason: freezed == cancelledReason
                ? _value.cancelledReason
                : cancelledReason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductRequestImplCopyWith<$Res>
    implements $ProductRequestCopyWith<$Res> {
  factory _$$ProductRequestImplCopyWith(
    _$ProductRequestImpl value,
    $Res Function(_$ProductRequestImpl) then,
  ) = __$$ProductRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String clientId,
    String clientName,
    List<ProductRequestLine> items,
    String status,
    String actionDateString,
    String? proformaId,
    String? cancelledReason,
  });
}

/// @nodoc
class __$$ProductRequestImplCopyWithImpl<$Res>
    extends _$ProductRequestCopyWithImpl<$Res, _$ProductRequestImpl>
    implements _$$ProductRequestImplCopyWith<$Res> {
  __$$ProductRequestImplCopyWithImpl(
    _$ProductRequestImpl _value,
    $Res Function(_$ProductRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProductRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? clientName = null,
    Object? items = null,
    Object? status = null,
    Object? actionDateString = null,
    Object? proformaId = freezed,
    Object? cancelledReason = freezed,
  }) {
    return _then(
      _$ProductRequestImpl(
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
                  as List<ProductRequestLine>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        actionDateString: null == actionDateString
            ? _value.actionDateString
            : actionDateString // ignore: cast_nullable_to_non_nullable
                  as String,
        proformaId: freezed == proformaId
            ? _value.proformaId
            : proformaId // ignore: cast_nullable_to_non_nullable
                  as String?,
        cancelledReason: freezed == cancelledReason
            ? _value.cancelledReason
            : cancelledReason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ProductRequestImpl implements _ProductRequest {
  const _$ProductRequestImpl({
    required this.id,
    required this.clientId,
    required this.clientName,
    final List<ProductRequestLine> items = const [],
    required this.status,
    required this.actionDateString,
    this.proformaId,
    this.cancelledReason,
  }) : _items = items;

  /// Identificador único del pedido.
  @override
  final String id;

  /// Identificador del cliente solicitante.
  @override
  final String clientId;

  /// Nombre del cliente para visualización en paneles de gestión.
  @override
  final String clientName;

  /// Lista de ítems detallados que componen la totalidad de la orden: la única fuente de sus líneas
  /// (WP-6.11-B; los campos planos de la transición se retiraron).
  final List<ProductRequestLine> _items;

  /// Lista de ítems detallados que componen la totalidad de la orden: la única fuente de sus líneas
  /// (WP-6.11-B; los campos planos de la transición se retiraron).
  @override
  @JsonKey()
  List<ProductRequestLine> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Estado actual de la solicitud ('PENDING', 'PROCESSED', 'CANCELLED').
  @override
  final String status;

  /// Fecha y hora en formato texto en la que se radicó el pedido.
  @override
  final String actionDateString;

  /// Identificador de la proforma que consolida este pedido, si ya fue facturado.
  @override
  final String? proformaId;

  /// Justificación registrada en caso de haberse cancelado el pedido.
  @override
  final String? cancelledReason;

  @override
  String toString() {
    return 'ProductRequest(id: $id, clientId: $clientId, clientName: $clientName, items: $items, status: $status, actionDateString: $actionDateString, proformaId: $proformaId, cancelledReason: $cancelledReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.actionDateString, actionDateString) ||
                other.actionDateString == actionDateString) &&
            (identical(other.proformaId, proformaId) ||
                other.proformaId == proformaId) &&
            (identical(other.cancelledReason, cancelledReason) ||
                other.cancelledReason == cancelledReason));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clientId,
    clientName,
    const DeepCollectionEquality().hash(_items),
    status,
    actionDateString,
    proformaId,
    cancelledReason,
  );

  /// Create a copy of ProductRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductRequestImplCopyWith<_$ProductRequestImpl> get copyWith =>
      __$$ProductRequestImplCopyWithImpl<_$ProductRequestImpl>(
        this,
        _$identity,
      );
}

abstract class _ProductRequest implements ProductRequest {
  const factory _ProductRequest({
    required final String id,
    required final String clientId,
    required final String clientName,
    final List<ProductRequestLine> items,
    required final String status,
    required final String actionDateString,
    final String? proformaId,
    final String? cancelledReason,
  }) = _$ProductRequestImpl;

  /// Identificador único del pedido.
  @override
  String get id;

  /// Identificador del cliente solicitante.
  @override
  String get clientId;

  /// Nombre del cliente para visualización en paneles de gestión.
  @override
  String get clientName;

  /// Lista de ítems detallados que componen la totalidad de la orden: la única fuente de sus líneas
  /// (WP-6.11-B; los campos planos de la transición se retiraron).
  @override
  List<ProductRequestLine> get items;

  /// Estado actual de la solicitud ('PENDING', 'PROCESSED', 'CANCELLED').
  @override
  String get status;

  /// Fecha y hora en formato texto en la que se radicó el pedido.
  @override
  String get actionDateString;

  /// Identificador de la proforma que consolida este pedido, si ya fue facturado.
  @override
  String? get proformaId;

  /// Justificación registrada en caso de haberse cancelado el pedido.
  @override
  String? get cancelledReason;

  /// Create a copy of ProductRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductRequestImplCopyWith<_$ProductRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
