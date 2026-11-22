// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'adb_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdbDevice {

 String get id; String get type; String get model;
/// Create a copy of AdbDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<AdbDevice> get copyWith => _$AdbDeviceCopyWithImpl<AdbDevice>(this as AdbDevice, _$identity);

  /// Serializes this AdbDevice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdbDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.model, model) || other.model == model));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,model);

@override
String toString() {
  return 'AdbDevice(id: $id, type: $type, model: $model)';
}


}

/// @nodoc
abstract mixin class $AdbDeviceCopyWith<$Res>  {
  factory $AdbDeviceCopyWith(AdbDevice value, $Res Function(AdbDevice) _then) = _$AdbDeviceCopyWithImpl;
@useResult
$Res call({
 String id, String type, String model
});




}
/// @nodoc
class _$AdbDeviceCopyWithImpl<$Res>
    implements $AdbDeviceCopyWith<$Res> {
  _$AdbDeviceCopyWithImpl(this._self, this._then);

  final AdbDevice _self;
  final $Res Function(AdbDevice) _then;

/// Create a copy of AdbDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? model = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdbDevice].
extension AdbDevicePatterns on AdbDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdbDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdbDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdbDevice value)  $default,){
final _that = this;
switch (_that) {
case _AdbDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdbDevice value)?  $default,){
final _that = this;
switch (_that) {
case _AdbDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String model)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdbDevice() when $default != null:
return $default(_that.id,_that.type,_that.model);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String model)  $default,) {final _that = this;
switch (_that) {
case _AdbDevice():
return $default(_that.id,_that.type,_that.model);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String model)?  $default,) {final _that = this;
switch (_that) {
case _AdbDevice() when $default != null:
return $default(_that.id,_that.type,_that.model);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdbDevice extends AdbDevice {
  const _AdbDevice({required this.id, required this.type, required this.model}): super._();
  factory _AdbDevice.fromJson(Map<String, dynamic> json) => _$AdbDeviceFromJson(json);

@override final  String id;
@override final  String type;
@override final  String model;

/// Create a copy of AdbDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdbDeviceCopyWith<_AdbDevice> get copyWith => __$AdbDeviceCopyWithImpl<_AdbDevice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdbDeviceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdbDevice&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.model, model) || other.model == model));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,model);

@override
String toString() {
  return 'AdbDevice(id: $id, type: $type, model: $model)';
}


}

/// @nodoc
abstract mixin class _$AdbDeviceCopyWith<$Res> implements $AdbDeviceCopyWith<$Res> {
  factory _$AdbDeviceCopyWith(_AdbDevice value, $Res Function(_AdbDevice) _then) = __$AdbDeviceCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String model
});




}
/// @nodoc
class __$AdbDeviceCopyWithImpl<$Res>
    implements _$AdbDeviceCopyWith<$Res> {
  __$AdbDeviceCopyWithImpl(this._self, this._then);

  final _AdbDevice _self;
  final $Res Function(_AdbDevice) _then;

/// Create a copy of AdbDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? model = null,}) {
  return _then(_AdbDevice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AdbFile {

 String get name;
/// Create a copy of AdbFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdbFileCopyWith<AdbFile> get copyWith => _$AdbFileCopyWithImpl<AdbFile>(this as AdbFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdbFile&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'AdbFile(name: $name)';
}


}

/// @nodoc
abstract mixin class $AdbFileCopyWith<$Res>  {
  factory $AdbFileCopyWith(AdbFile value, $Res Function(AdbFile) _then) = _$AdbFileCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$AdbFileCopyWithImpl<$Res>
    implements $AdbFileCopyWith<$Res> {
  _$AdbFileCopyWithImpl(this._self, this._then);

  final AdbFile _self;
  final $Res Function(AdbFile) _then;

/// Create a copy of AdbFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdbFile].
extension AdbFilePatterns on AdbFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdbFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdbFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdbFile value)  $default,){
final _that = this;
switch (_that) {
case _AdbFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdbFile value)?  $default,){
final _that = this;
switch (_that) {
case _AdbFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdbFile() when $default != null:
return $default(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _AdbFile():
return $default(_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _AdbFile() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _AdbFile extends AdbFile {
  const _AdbFile(this.name): super._();
  

@override final  String name;

/// Create a copy of AdbFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdbFileCopyWith<_AdbFile> get copyWith => __$AdbFileCopyWithImpl<_AdbFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdbFile&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'AdbFile(name: $name)';
}


}

/// @nodoc
abstract mixin class _$AdbFileCopyWith<$Res> implements $AdbFileCopyWith<$Res> {
  factory _$AdbFileCopyWith(_AdbFile value, $Res Function(_AdbFile) _then) = __$AdbFileCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$AdbFileCopyWithImpl<$Res>
    implements _$AdbFileCopyWith<$Res> {
  __$AdbFileCopyWithImpl(this._self, this._then);

  final _AdbFile _self;
  final $Res Function(_AdbFile) _then;

/// Create a copy of AdbFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_AdbFile(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AdbDirectory {

 String get name;
/// Create a copy of AdbDirectory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdbDirectoryCopyWith<AdbDirectory> get copyWith => _$AdbDirectoryCopyWithImpl<AdbDirectory>(this as AdbDirectory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdbDirectory&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'AdbDirectory(name: $name)';
}


}

/// @nodoc
abstract mixin class $AdbDirectoryCopyWith<$Res>  {
  factory $AdbDirectoryCopyWith(AdbDirectory value, $Res Function(AdbDirectory) _then) = _$AdbDirectoryCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$AdbDirectoryCopyWithImpl<$Res>
    implements $AdbDirectoryCopyWith<$Res> {
  _$AdbDirectoryCopyWithImpl(this._self, this._then);

  final AdbDirectory _self;
  final $Res Function(AdbDirectory) _then;

/// Create a copy of AdbDirectory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdbDirectory].
extension AdbDirectoryPatterns on AdbDirectory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdbDirectory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdbDirectory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdbDirectory value)  $default,){
final _that = this;
switch (_that) {
case _AdbDirectory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdbDirectory value)?  $default,){
final _that = this;
switch (_that) {
case _AdbDirectory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdbDirectory() when $default != null:
return $default(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _AdbDirectory():
return $default(_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _AdbDirectory() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _AdbDirectory extends AdbDirectory {
  const _AdbDirectory(this.name): super._();
  

@override final  String name;

/// Create a copy of AdbDirectory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdbDirectoryCopyWith<_AdbDirectory> get copyWith => __$AdbDirectoryCopyWithImpl<_AdbDirectory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdbDirectory&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'AdbDirectory(name: $name)';
}


}

/// @nodoc
abstract mixin class _$AdbDirectoryCopyWith<$Res> implements $AdbDirectoryCopyWith<$Res> {
  factory _$AdbDirectoryCopyWith(_AdbDirectory value, $Res Function(_AdbDirectory) _then) = __$AdbDirectoryCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$AdbDirectoryCopyWithImpl<$Res>
    implements _$AdbDirectoryCopyWith<$Res> {
  __$AdbDirectoryCopyWithImpl(this._self, this._then);

  final _AdbDirectory _self;
  final $Res Function(_AdbDirectory) _then;

/// Create a copy of AdbDirectory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_AdbDirectory(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
