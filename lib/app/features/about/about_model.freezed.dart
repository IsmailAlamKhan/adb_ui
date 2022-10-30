// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'about_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$AboutModel {
  bool get updateAvailable => throw _privateConstructorUsedError;
  String? get updateAvailableVersion => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AboutModelCopyWith<AboutModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AboutModelCopyWith<$Res> {
  factory $AboutModelCopyWith(
          AboutModel value, $Res Function(AboutModel) then) =
      _$AboutModelCopyWithImpl<$Res, AboutModel>;
  @useResult
  $Res call({bool updateAvailable, String? updateAvailableVersion});
}

/// @nodoc
class _$AboutModelCopyWithImpl<$Res, $Val extends AboutModel>
    implements $AboutModelCopyWith<$Res> {
  _$AboutModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? updateAvailable = null,
    Object? updateAvailableVersion = freezed,
  }) {
    return _then(_value.copyWith(
      updateAvailable: null == updateAvailable
          ? _value.updateAvailable
          : updateAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      updateAvailableVersion: freezed == updateAvailableVersion
          ? _value.updateAvailableVersion
          : updateAvailableVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_AboutModelCopyWith<$Res>
    implements $AboutModelCopyWith<$Res> {
  factory _$$_AboutModelCopyWith(
          _$_AboutModel value, $Res Function(_$_AboutModel) then) =
      __$$_AboutModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool updateAvailable, String? updateAvailableVersion});
}

/// @nodoc
class __$$_AboutModelCopyWithImpl<$Res>
    extends _$AboutModelCopyWithImpl<$Res, _$_AboutModel>
    implements _$$_AboutModelCopyWith<$Res> {
  __$$_AboutModelCopyWithImpl(
      _$_AboutModel _value, $Res Function(_$_AboutModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? updateAvailable = null,
    Object? updateAvailableVersion = freezed,
  }) {
    return _then(_$_AboutModel(
      updateAvailable: null == updateAvailable
          ? _value.updateAvailable
          : updateAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      updateAvailableVersion: freezed == updateAvailableVersion
          ? _value.updateAvailableVersion
          : updateAvailableVersion // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$_AboutModel implements _AboutModel {
  const _$_AboutModel(
      {required this.updateAvailable, this.updateAvailableVersion});

  @override
  final bool updateAvailable;
  @override
  final String? updateAvailableVersion;

  @override
  String toString() {
    return 'AboutModel(updateAvailable: $updateAvailable, updateAvailableVersion: $updateAvailableVersion)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_AboutModel &&
            (identical(other.updateAvailable, updateAvailable) ||
                other.updateAvailable == updateAvailable) &&
            (identical(other.updateAvailableVersion, updateAvailableVersion) ||
                other.updateAvailableVersion == updateAvailableVersion));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, updateAvailable, updateAvailableVersion);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AboutModelCopyWith<_$_AboutModel> get copyWith =>
      __$$_AboutModelCopyWithImpl<_$_AboutModel>(this, _$identity);
}

abstract class _AboutModel implements AboutModel {
  const factory _AboutModel(
      {required final bool updateAvailable,
      final String? updateAvailableVersion}) = _$_AboutModel;

  @override
  bool get updateAvailable;
  @override
  String? get updateAvailableVersion;
  @override
  @JsonKey(ignore: true)
  _$$_AboutModelCopyWith<_$_AboutModel> get copyWith =>
      throw _privateConstructorUsedError;
}
