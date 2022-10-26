// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'adb_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$AdbDevice {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AdbDeviceCopyWith<AdbDevice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdbDeviceCopyWith<$Res> {
  factory $AdbDeviceCopyWith(AdbDevice value, $Res Function(AdbDevice) then) =
      _$AdbDeviceCopyWithImpl<$Res, AdbDevice>;
  @useResult
  $Res call({String id, String type});
}

/// @nodoc
class _$AdbDeviceCopyWithImpl<$Res, $Val extends AdbDevice>
    implements $AdbDeviceCopyWith<$Res> {
  _$AdbDeviceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AdbDeviceCopyWith<$Res> implements $AdbDeviceCopyWith<$Res> {
  factory _$$_AdbDeviceCopyWith(
          _$_AdbDevice value, $Res Function(_$_AdbDevice) then) =
      __$$_AdbDeviceCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String type});
}

/// @nodoc
class __$$_AdbDeviceCopyWithImpl<$Res>
    extends _$AdbDeviceCopyWithImpl<$Res, _$_AdbDevice>
    implements _$$_AdbDeviceCopyWith<$Res> {
  __$$_AdbDeviceCopyWithImpl(
      _$_AdbDevice _value, $Res Function(_$_AdbDevice) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
  }) {
    return _then(_$_AdbDevice(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_AdbDevice extends _AdbDevice {
  const _$_AdbDevice({required this.id, required this.type}) : super._();

  @override
  final String id;
  @override
  final String type;

  @override
  String toString() {
    return 'AdbDevice(id: $id, type: $type)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AdbDevice &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, type);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AdbDeviceCopyWith<_$_AdbDevice> get copyWith =>
      __$$_AdbDeviceCopyWithImpl<_$_AdbDevice>(this, _$identity);
}

abstract class _AdbDevice extends AdbDevice {
  const factory _AdbDevice(
      {required final String id, required final String type}) = _$_AdbDevice;
  const _AdbDevice._() : super._();

  @override
  String get id;
  @override
  String get type;
  @override
  @JsonKey(ignore: true)
  _$$_AdbDeviceCopyWith<_$_AdbDevice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AdbFile {
  String get name => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AdbFileCopyWith<AdbFile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdbFileCopyWith<$Res> {
  factory $AdbFileCopyWith(AdbFile value, $Res Function(AdbFile) then) =
      _$AdbFileCopyWithImpl<$Res, AdbFile>;
  @useResult
  $Res call({String name});
}

/// @nodoc
class _$AdbFileCopyWithImpl<$Res, $Val extends AdbFile>
    implements $AdbFileCopyWith<$Res> {
  _$AdbFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AdbFileCopyWith<$Res> implements $AdbFileCopyWith<$Res> {
  factory _$$_AdbFileCopyWith(
          _$_AdbFile value, $Res Function(_$_AdbFile) then) =
      __$$_AdbFileCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name});
}

/// @nodoc
class __$$_AdbFileCopyWithImpl<$Res>
    extends _$AdbFileCopyWithImpl<$Res, _$_AdbFile>
    implements _$$_AdbFileCopyWith<$Res> {
  __$$_AdbFileCopyWithImpl(_$_AdbFile _value, $Res Function(_$_AdbFile) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
  }) {
    return _then(_$_AdbFile(
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_AdbFile extends _AdbFile {
  const _$_AdbFile(this.name) : super._();

  @override
  final String name;

  @override
  String toString() {
    return 'AdbFile(name: $name)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AdbFile &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AdbFileCopyWith<_$_AdbFile> get copyWith =>
      __$$_AdbFileCopyWithImpl<_$_AdbFile>(this, _$identity);
}

abstract class _AdbFile extends AdbFile {
  const factory _AdbFile(final String name) = _$_AdbFile;
  const _AdbFile._() : super._();

  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$_AdbFileCopyWith<_$_AdbFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AdbDirectory {
  String get name => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AdbDirectoryCopyWith<AdbDirectory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdbDirectoryCopyWith<$Res> {
  factory $AdbDirectoryCopyWith(
          AdbDirectory value, $Res Function(AdbDirectory) then) =
      _$AdbDirectoryCopyWithImpl<$Res, AdbDirectory>;
  @useResult
  $Res call({String name});
}

/// @nodoc
class _$AdbDirectoryCopyWithImpl<$Res, $Val extends AdbDirectory>
    implements $AdbDirectoryCopyWith<$Res> {
  _$AdbDirectoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AdbDirectoryCopyWith<$Res>
    implements $AdbDirectoryCopyWith<$Res> {
  factory _$$_AdbDirectoryCopyWith(
          _$_AdbDirectory value, $Res Function(_$_AdbDirectory) then) =
      __$$_AdbDirectoryCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name});
}

/// @nodoc
class __$$_AdbDirectoryCopyWithImpl<$Res>
    extends _$AdbDirectoryCopyWithImpl<$Res, _$_AdbDirectory>
    implements _$$_AdbDirectoryCopyWith<$Res> {
  __$$_AdbDirectoryCopyWithImpl(
      _$_AdbDirectory _value, $Res Function(_$_AdbDirectory) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
  }) {
    return _then(_$_AdbDirectory(
      null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_AdbDirectory extends _AdbDirectory {
  const _$_AdbDirectory(this.name) : super._();

  @override
  final String name;

  @override
  String toString() {
    return 'AdbDirectory(name: $name)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AdbDirectory &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AdbDirectoryCopyWith<_$_AdbDirectory> get copyWith =>
      __$$_AdbDirectoryCopyWithImpl<_$_AdbDirectory>(this, _$identity);
}

abstract class _AdbDirectory extends AdbDirectory {
  const factory _AdbDirectory(final String name) = _$_AdbDirectory;
  const _AdbDirectory._() : super._();

  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$_AdbDirectoryCopyWith<_$_AdbDirectory> get copyWith =>
      throw _privateConstructorUsedError;
}
