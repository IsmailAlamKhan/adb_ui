// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_model.codegen.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Device {

@JsonKey(name: 'device') String get name;@JsonKey(name: 'deviceId') String get id;@JsonKey(name: 'manufacturer') String? get manufacturer;@JsonKey(name: 'model') String? get model;@JsonKey(name: 'product') String? get product;
/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceCopyWith<Device> get copyWith => _$DeviceCopyWithImpl<Device>(this as Device, _$identity);

  /// Serializes this Device to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Device&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.product, product) || other.product == product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,id,manufacturer,model,product);

@override
String toString() {
  return 'Device(name: $name, id: $id, manufacturer: $manufacturer, model: $model, product: $product)';
}


}

/// @nodoc
abstract mixin class $DeviceCopyWith<$Res>  {
  factory $DeviceCopyWith(Device value, $Res Function(Device) _then) = _$DeviceCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'device') String name,@JsonKey(name: 'deviceId') String id,@JsonKey(name: 'manufacturer') String? manufacturer,@JsonKey(name: 'model') String? model,@JsonKey(name: 'product') String? product
});




}
/// @nodoc
class _$DeviceCopyWithImpl<$Res>
    implements $DeviceCopyWith<$Res> {
  _$DeviceCopyWithImpl(this._self, this._then);

  final Device _self;
  final $Res Function(Device) _then;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? id = null,Object? manufacturer = freezed,Object? model = freezed,Object? product = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Device].
extension DevicePatterns on Device {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Device value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Device value)  $default,){
final _that = this;
switch (_that) {
case _Device():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Device value)?  $default,){
final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'device')  String name, @JsonKey(name: 'deviceId')  String id, @JsonKey(name: 'manufacturer')  String? manufacturer, @JsonKey(name: 'model')  String? model, @JsonKey(name: 'product')  String? product)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that.name,_that.id,_that.manufacturer,_that.model,_that.product);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'device')  String name, @JsonKey(name: 'deviceId')  String id, @JsonKey(name: 'manufacturer')  String? manufacturer, @JsonKey(name: 'model')  String? model, @JsonKey(name: 'product')  String? product)  $default,) {final _that = this;
switch (_that) {
case _Device():
return $default(_that.name,_that.id,_that.manufacturer,_that.model,_that.product);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'device')  String name, @JsonKey(name: 'deviceId')  String id, @JsonKey(name: 'manufacturer')  String? manufacturer, @JsonKey(name: 'model')  String? model, @JsonKey(name: 'product')  String? product)?  $default,) {final _that = this;
switch (_that) {
case _Device() when $default != null:
return $default(_that.name,_that.id,_that.manufacturer,_that.model,_that.product);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Device extends Device {
  const _Device({@JsonKey(name: 'device') required this.name, @JsonKey(name: 'deviceId') required this.id, @JsonKey(name: 'manufacturer') this.manufacturer, @JsonKey(name: 'model') this.model, @JsonKey(name: 'product') this.product}): super._();
  factory _Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

@override@JsonKey(name: 'device') final  String name;
@override@JsonKey(name: 'deviceId') final  String id;
@override@JsonKey(name: 'manufacturer') final  String? manufacturer;
@override@JsonKey(name: 'model') final  String? model;
@override@JsonKey(name: 'product') final  String? product;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceCopyWith<_Device> get copyWith => __$DeviceCopyWithImpl<_Device>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Device&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.product, product) || other.product == product));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,id,manufacturer,model,product);

@override
String toString() {
  return 'Device(name: $name, id: $id, manufacturer: $manufacturer, model: $model, product: $product)';
}


}

/// @nodoc
abstract mixin class _$DeviceCopyWith<$Res> implements $DeviceCopyWith<$Res> {
  factory _$DeviceCopyWith(_Device value, $Res Function(_Device) _then) = __$DeviceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'device') String name,@JsonKey(name: 'deviceId') String id,@JsonKey(name: 'manufacturer') String? manufacturer,@JsonKey(name: 'model') String? model,@JsonKey(name: 'product') String? product
});




}
/// @nodoc
class __$DeviceCopyWithImpl<$Res>
    implements _$DeviceCopyWith<$Res> {
  __$DeviceCopyWithImpl(this._self, this._then);

  final _Device _self;
  final $Res Function(_Device) _then;

/// Create a copy of Device
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? id = null,Object? manufacturer = freezed,Object? model = freezed,Object? product = freezed,}) {
  return _then(_Device(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
