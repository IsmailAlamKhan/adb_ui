// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'command_queue_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$CommandModel {
  String get id => throw _privateConstructorUsedError;
  String get command => throw _privateConstructorUsedError;
  AdbDevice? get device => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)
        adding,
    required TResult Function(
            String id, String command, AdbDevice? device, Stream<String> output)
        running,
    required TResult Function(
            String id, String command, AdbDevice? device, String output)
        done,
    required TResult Function(
            String id, String command, AdbDevice? device, String error)
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult? Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult? Function(
            String id, String command, AdbDevice? device, String error)?
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult Function(
            String id, String command, AdbDevice? device, String error)?
        error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Adding value) adding,
    required TResult Function(_Running value) running,
    required TResult Function(_Done value) done,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Adding value)? adding,
    TResult? Function(_Running value)? running,
    TResult? Function(_Done value)? done,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Adding value)? adding,
    TResult Function(_Running value)? running,
    TResult Function(_Done value)? done,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CommandModelCopyWith<CommandModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommandModelCopyWith<$Res> {
  factory $CommandModelCopyWith(
          CommandModel value, $Res Function(CommandModel) then) =
      _$CommandModelCopyWithImpl<$Res, CommandModel>;
  @useResult
  $Res call({String id, String command, AdbDevice? device});

  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class _$CommandModelCopyWithImpl<$Res, $Val extends CommandModel>
    implements $CommandModelCopyWith<$Res> {
  _$CommandModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      device: freezed == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as AdbDevice?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $AdbDeviceCopyWith<$Res>? get device {
    if (_value.device == null) {
      return null;
    }

    return $AdbDeviceCopyWith<$Res>(_value.device!, (value) {
      return _then(_value.copyWith(device: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_AddingCopyWith<$Res> implements $CommandModelCopyWith<$Res> {
  factory _$$_AddingCopyWith(_$_Adding value, $Res Function(_$_Adding) then) =
      __$$_AddingCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      Stream<String> stdout,
      Stream<String> stderr});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$_AddingCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$_Adding>
    implements _$$_AddingCopyWith<$Res> {
  __$$_AddingCopyWithImpl(_$_Adding _value, $Res Function(_$_Adding) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? stdout = null,
    Object? stderr = null,
  }) {
    return _then(_$_Adding(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      device: freezed == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as AdbDevice?,
      stdout: null == stdout
          ? _value.stdout
          : stdout // ignore: cast_nullable_to_non_nullable
              as Stream<String>,
      stderr: null == stderr
          ? _value.stderr
          : stderr // ignore: cast_nullable_to_non_nullable
              as Stream<String>,
    ));
  }
}

/// @nodoc

class _$_Adding implements _Adding {
  const _$_Adding(
      {required this.id,
      required this.command,
      required this.device,
      required this.stdout,
      required this.stderr});

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final Stream<String> stdout;
  @override
  final Stream<String> stderr;

  @override
  String toString() {
    return 'CommandModel.adding(id: $id, command: $command, device: $device, stdout: $stdout, stderr: $stderr)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Adding &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.stdout, stdout) || other.stdout == stdout) &&
            (identical(other.stderr, stderr) || other.stderr == stderr));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, command, device, stdout, stderr);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_AddingCopyWith<_$_Adding> get copyWith =>
      __$$_AddingCopyWithImpl<_$_Adding>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)
        adding,
    required TResult Function(
            String id, String command, AdbDevice? device, Stream<String> output)
        running,
    required TResult Function(
            String id, String command, AdbDevice? device, String output)
        done,
    required TResult Function(
            String id, String command, AdbDevice? device, String error)
        error,
  }) {
    return adding(id, command, device, stdout, stderr);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult? Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult? Function(
            String id, String command, AdbDevice? device, String error)?
        error,
  }) {
    return adding?.call(id, command, device, stdout, stderr);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult Function(
            String id, String command, AdbDevice? device, String error)?
        error,
    required TResult orElse(),
  }) {
    if (adding != null) {
      return adding(id, command, device, stdout, stderr);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Adding value) adding,
    required TResult Function(_Running value) running,
    required TResult Function(_Done value) done,
    required TResult Function(_Error value) error,
  }) {
    return adding(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Adding value)? adding,
    TResult? Function(_Running value)? running,
    TResult? Function(_Done value)? done,
    TResult? Function(_Error value)? error,
  }) {
    return adding?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Adding value)? adding,
    TResult Function(_Running value)? running,
    TResult Function(_Done value)? done,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (adding != null) {
      return adding(this);
    }
    return orElse();
  }
}

abstract class _Adding implements CommandModel {
  const factory _Adding(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final Stream<String> stdout,
      required final Stream<String> stderr}) = _$_Adding;

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  Stream<String> get stdout;
  Stream<String> get stderr;
  @override
  @JsonKey(ignore: true)
  _$$_AddingCopyWith<_$_Adding> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_RunningCopyWith<$Res>
    implements $CommandModelCopyWith<$Res> {
  factory _$$_RunningCopyWith(
          _$_Running value, $Res Function(_$_Running) then) =
      __$$_RunningCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String command, AdbDevice? device, Stream<String> output});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$_RunningCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$_Running>
    implements _$$_RunningCopyWith<$Res> {
  __$$_RunningCopyWithImpl(_$_Running _value, $Res Function(_$_Running) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? output = null,
  }) {
    return _then(_$_Running(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      device: freezed == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as AdbDevice?,
      output: null == output
          ? _value.output
          : output // ignore: cast_nullable_to_non_nullable
              as Stream<String>,
    ));
  }
}

/// @nodoc

class _$_Running implements _Running {
  const _$_Running(
      {required this.id,
      required this.command,
      required this.device,
      required this.output});

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final Stream<String> output;

  @override
  String toString() {
    return 'CommandModel.running(id: $id, command: $command, device: $device, output: $output)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Running &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.output, output) || other.output == output));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, command, device, output);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_RunningCopyWith<_$_Running> get copyWith =>
      __$$_RunningCopyWithImpl<_$_Running>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)
        adding,
    required TResult Function(
            String id, String command, AdbDevice? device, Stream<String> output)
        running,
    required TResult Function(
            String id, String command, AdbDevice? device, String output)
        done,
    required TResult Function(
            String id, String command, AdbDevice? device, String error)
        error,
  }) {
    return running(id, command, device, output);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult? Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult? Function(
            String id, String command, AdbDevice? device, String error)?
        error,
  }) {
    return running?.call(id, command, device, output);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult Function(
            String id, String command, AdbDevice? device, String error)?
        error,
    required TResult orElse(),
  }) {
    if (running != null) {
      return running(id, command, device, output);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Adding value) adding,
    required TResult Function(_Running value) running,
    required TResult Function(_Done value) done,
    required TResult Function(_Error value) error,
  }) {
    return running(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Adding value)? adding,
    TResult? Function(_Running value)? running,
    TResult? Function(_Done value)? done,
    TResult? Function(_Error value)? error,
  }) {
    return running?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Adding value)? adding,
    TResult Function(_Running value)? running,
    TResult Function(_Done value)? done,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (running != null) {
      return running(this);
    }
    return orElse();
  }
}

abstract class _Running implements CommandModel {
  const factory _Running(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final Stream<String> output}) = _$_Running;

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  Stream<String> get output;
  @override
  @JsonKey(ignore: true)
  _$$_RunningCopyWith<_$_Running> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_DoneCopyWith<$Res> implements $CommandModelCopyWith<$Res> {
  factory _$$_DoneCopyWith(_$_Done value, $Res Function(_$_Done) then) =
      __$$_DoneCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String command, AdbDevice? device, String output});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$_DoneCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$_Done>
    implements _$$_DoneCopyWith<$Res> {
  __$$_DoneCopyWithImpl(_$_Done _value, $Res Function(_$_Done) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? output = null,
  }) {
    return _then(_$_Done(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      device: freezed == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as AdbDevice?,
      output: null == output
          ? _value.output
          : output // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_Done implements _Done {
  const _$_Done(
      {required this.id,
      required this.command,
      required this.device,
      required this.output});

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final String output;

  @override
  String toString() {
    return 'CommandModel.done(id: $id, command: $command, device: $device, output: $output)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Done &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.output, output) || other.output == output));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, command, device, output);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_DoneCopyWith<_$_Done> get copyWith =>
      __$$_DoneCopyWithImpl<_$_Done>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)
        adding,
    required TResult Function(
            String id, String command, AdbDevice? device, Stream<String> output)
        running,
    required TResult Function(
            String id, String command, AdbDevice? device, String output)
        done,
    required TResult Function(
            String id, String command, AdbDevice? device, String error)
        error,
  }) {
    return done(id, command, device, output);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult? Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult? Function(
            String id, String command, AdbDevice? device, String error)?
        error,
  }) {
    return done?.call(id, command, device, output);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult Function(
            String id, String command, AdbDevice? device, String error)?
        error,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(id, command, device, output);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Adding value) adding,
    required TResult Function(_Running value) running,
    required TResult Function(_Done value) done,
    required TResult Function(_Error value) error,
  }) {
    return done(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Adding value)? adding,
    TResult? Function(_Running value)? running,
    TResult? Function(_Done value)? done,
    TResult? Function(_Error value)? error,
  }) {
    return done?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Adding value)? adding,
    TResult Function(_Running value)? running,
    TResult Function(_Done value)? done,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(this);
    }
    return orElse();
  }
}

abstract class _Done implements CommandModel {
  const factory _Done(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final String output}) = _$_Done;

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  String get output;
  @override
  @JsonKey(ignore: true)
  _$$_DoneCopyWith<_$_Done> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_ErrorCopyWith<$Res> implements $CommandModelCopyWith<$Res> {
  factory _$$_ErrorCopyWith(_$_Error value, $Res Function(_$_Error) then) =
      __$$_ErrorCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String command, AdbDevice? device, String error});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$_ErrorCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$_Error>
    implements _$$_ErrorCopyWith<$Res> {
  __$$_ErrorCopyWithImpl(_$_Error _value, $Res Function(_$_Error) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? error = null,
  }) {
    return _then(_$_Error(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      command: null == command
          ? _value.command
          : command // ignore: cast_nullable_to_non_nullable
              as String,
      device: freezed == device
          ? _value.device
          : device // ignore: cast_nullable_to_non_nullable
              as AdbDevice?,
      error: null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_Error implements _Error {
  const _$_Error(
      {required this.id,
      required this.command,
      required this.device,
      required this.error});

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final String error;

  @override
  String toString() {
    return 'CommandModel.error(id: $id, command: $command, device: $device, error: $error)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Error &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, command, device, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ErrorCopyWith<_$_Error> get copyWith =>
      __$$_ErrorCopyWithImpl<_$_Error>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)
        adding,
    required TResult Function(
            String id, String command, AdbDevice? device, Stream<String> output)
        running,
    required TResult Function(
            String id, String command, AdbDevice? device, String output)
        done,
    required TResult Function(
            String id, String command, AdbDevice? device, String error)
        error,
  }) {
    return error(id, command, device, this.error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult? Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult? Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult? Function(
            String id, String command, AdbDevice? device, String error)?
        error,
  }) {
    return error?.call(id, command, device, this.error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> stdout, Stream<String> stderr)?
        adding,
    TResult Function(String id, String command, AdbDevice? device,
            Stream<String> output)?
        running,
    TResult Function(
            String id, String command, AdbDevice? device, String output)?
        done,
    TResult Function(
            String id, String command, AdbDevice? device, String error)?
        error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(id, command, device, this.error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Adding value) adding,
    required TResult Function(_Running value) running,
    required TResult Function(_Done value) done,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Adding value)? adding,
    TResult? Function(_Running value)? running,
    TResult? Function(_Done value)? done,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Adding value)? adding,
    TResult Function(_Running value)? running,
    TResult Function(_Done value)? done,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements CommandModel {
  const factory _Error(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final String error}) = _$_Error;

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  String get error;
  @override
  @JsonKey(ignore: true)
  _$$_ErrorCopyWith<_$_Error> get copyWith =>
      throw _privateConstructorUsedError;
}
