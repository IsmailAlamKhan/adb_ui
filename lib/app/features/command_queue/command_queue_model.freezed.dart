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
  String get rawCommand => throw _privateConstructorUsedError;
  List<String> get arguments => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        adding,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        running,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        done,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CommandModelAdding value) adding,
    required TResult Function(CommandModelRunning value) running,
    required TResult Function(CommandModelDone value) done,
    required TResult Function(CommandModelError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CommandModelAdding value)? adding,
    TResult? Function(CommandModelRunning value)? running,
    TResult? Function(CommandModelDone value)? done,
    TResult? Function(CommandModelError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CommandModelAdding value)? adding,
    TResult Function(CommandModelRunning value)? running,
    TResult Function(CommandModelDone value)? done,
    TResult Function(CommandModelError value)? error,
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
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      String rawCommand,
      List<String> arguments,
      DateTime startedAt});

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
    Object? rawCommand = null,
    Object? arguments = null,
    Object? startedAt = null,
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
      rawCommand: null == rawCommand
          ? _value.rawCommand
          : rawCommand // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value.arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
abstract class _$$CommandModelAddingCopyWith<$Res>
    implements $CommandModelCopyWith<$Res> {
  factory _$$CommandModelAddingCopyWith(_$CommandModelAdding value,
          $Res Function(_$CommandModelAdding) then) =
      __$$CommandModelAddingCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      Stream<String> stdout,
      Stream<String> stderr,
      String rawCommand,
      List<String> arguments,
      DateTime startedAt});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$CommandModelAddingCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$CommandModelAdding>
    implements _$$CommandModelAddingCopyWith<$Res> {
  __$$CommandModelAddingCopyWithImpl(
      _$CommandModelAdding _value, $Res Function(_$CommandModelAdding) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? stdout = null,
    Object? stderr = null,
    Object? rawCommand = null,
    Object? arguments = null,
    Object? startedAt = null,
  }) {
    return _then(_$CommandModelAdding(
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
      rawCommand: null == rawCommand
          ? _value.rawCommand
          : rawCommand // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value._arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$CommandModelAdding extends CommandModelAdding {
  const _$CommandModelAdding(
      {required this.id,
      required this.command,
      required this.device,
      required this.stdout,
      required this.stderr,
      required this.rawCommand,
      required final List<String> arguments,
      required this.startedAt})
      : _arguments = arguments,
        super._();

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
  final String rawCommand;
  final List<String> _arguments;
  @override
  List<String> get arguments {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_arguments);
  }

  @override
  final DateTime startedAt;

  @override
  String toString() {
    return 'CommandModel.adding(id: $id, command: $command, device: $device, stdout: $stdout, stderr: $stderr, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommandModelAdding &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.stdout, stdout) || other.stdout == stdout) &&
            (identical(other.stderr, stderr) || other.stderr == stderr) &&
            (identical(other.rawCommand, rawCommand) ||
                other.rawCommand == rawCommand) &&
            const DeepCollectionEquality()
                .equals(other._arguments, _arguments) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      command,
      device,
      stdout,
      stderr,
      rawCommand,
      const DeepCollectionEquality().hash(_arguments),
      startedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommandModelAddingCopyWith<_$CommandModelAdding> get copyWith =>
      __$$CommandModelAddingCopyWithImpl<_$CommandModelAdding>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        adding,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        running,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        done,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        error,
  }) {
    return adding(
        id, command, device, stdout, stderr, rawCommand, arguments, startedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
  }) {
    return adding?.call(
        id, command, device, stdout, stderr, rawCommand, arguments, startedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
    required TResult orElse(),
  }) {
    if (adding != null) {
      return adding(id, command, device, stdout, stderr, rawCommand, arguments,
          startedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CommandModelAdding value) adding,
    required TResult Function(CommandModelRunning value) running,
    required TResult Function(CommandModelDone value) done,
    required TResult Function(CommandModelError value) error,
  }) {
    return adding(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CommandModelAdding value)? adding,
    TResult? Function(CommandModelRunning value)? running,
    TResult? Function(CommandModelDone value)? done,
    TResult? Function(CommandModelError value)? error,
  }) {
    return adding?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CommandModelAdding value)? adding,
    TResult Function(CommandModelRunning value)? running,
    TResult Function(CommandModelDone value)? done,
    TResult Function(CommandModelError value)? error,
    required TResult orElse(),
  }) {
    if (adding != null) {
      return adding(this);
    }
    return orElse();
  }
}

abstract class CommandModelAdding extends CommandModel {
  const factory CommandModelAdding(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final Stream<String> stdout,
      required final Stream<String> stderr,
      required final String rawCommand,
      required final List<String> arguments,
      required final DateTime startedAt}) = _$CommandModelAdding;
  const CommandModelAdding._() : super._();

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  Stream<String> get stdout;
  Stream<String> get stderr;
  @override
  String get rawCommand;
  @override
  List<String> get arguments;
  @override
  DateTime get startedAt;
  @override
  @JsonKey(ignore: true)
  _$$CommandModelAddingCopyWith<_$CommandModelAdding> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CommandModelRunningCopyWith<$Res>
    implements $CommandModelCopyWith<$Res> {
  factory _$$CommandModelRunningCopyWith(_$CommandModelRunning value,
          $Res Function(_$CommandModelRunning) then) =
      __$$CommandModelRunningCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      Stream<String> output,
      String rawCommand,
      List<String> arguments,
      DateTime startedAt});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$CommandModelRunningCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$CommandModelRunning>
    implements _$$CommandModelRunningCopyWith<$Res> {
  __$$CommandModelRunningCopyWithImpl(
      _$CommandModelRunning _value, $Res Function(_$CommandModelRunning) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? output = null,
    Object? rawCommand = null,
    Object? arguments = null,
    Object? startedAt = null,
  }) {
    return _then(_$CommandModelRunning(
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
      rawCommand: null == rawCommand
          ? _value.rawCommand
          : rawCommand // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value._arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$CommandModelRunning extends CommandModelRunning {
  const _$CommandModelRunning(
      {required this.id,
      required this.command,
      required this.device,
      required this.output,
      required this.rawCommand,
      required final List<String> arguments,
      required this.startedAt})
      : _arguments = arguments,
        super._();

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final Stream<String> output;
  @override
  final String rawCommand;
  final List<String> _arguments;
  @override
  List<String> get arguments {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_arguments);
  }

  @override
  final DateTime startedAt;

  @override
  String toString() {
    return 'CommandModel.running(id: $id, command: $command, device: $device, output: $output, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommandModelRunning &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.output, output) || other.output == output) &&
            (identical(other.rawCommand, rawCommand) ||
                other.rawCommand == rawCommand) &&
            const DeepCollectionEquality()
                .equals(other._arguments, _arguments) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, command, device, output,
      rawCommand, const DeepCollectionEquality().hash(_arguments), startedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommandModelRunningCopyWith<_$CommandModelRunning> get copyWith =>
      __$$CommandModelRunningCopyWithImpl<_$CommandModelRunning>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        adding,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        running,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        done,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        error,
  }) {
    return running(
        id, command, device, output, rawCommand, arguments, startedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
  }) {
    return running?.call(
        id, command, device, output, rawCommand, arguments, startedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
    required TResult orElse(),
  }) {
    if (running != null) {
      return running(
          id, command, device, output, rawCommand, arguments, startedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CommandModelAdding value) adding,
    required TResult Function(CommandModelRunning value) running,
    required TResult Function(CommandModelDone value) done,
    required TResult Function(CommandModelError value) error,
  }) {
    return running(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CommandModelAdding value)? adding,
    TResult? Function(CommandModelRunning value)? running,
    TResult? Function(CommandModelDone value)? done,
    TResult? Function(CommandModelError value)? error,
  }) {
    return running?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CommandModelAdding value)? adding,
    TResult Function(CommandModelRunning value)? running,
    TResult Function(CommandModelDone value)? done,
    TResult Function(CommandModelError value)? error,
    required TResult orElse(),
  }) {
    if (running != null) {
      return running(this);
    }
    return orElse();
  }
}

abstract class CommandModelRunning extends CommandModel {
  const factory CommandModelRunning(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final Stream<String> output,
      required final String rawCommand,
      required final List<String> arguments,
      required final DateTime startedAt}) = _$CommandModelRunning;
  const CommandModelRunning._() : super._();

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  Stream<String> get output;
  @override
  String get rawCommand;
  @override
  List<String> get arguments;
  @override
  DateTime get startedAt;
  @override
  @JsonKey(ignore: true)
  _$$CommandModelRunningCopyWith<_$CommandModelRunning> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CommandModelDoneCopyWith<$Res>
    implements $CommandModelCopyWith<$Res> {
  factory _$$CommandModelDoneCopyWith(
          _$CommandModelDone value, $Res Function(_$CommandModelDone) then) =
      __$$CommandModelDoneCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      String output,
      String rawCommand,
      List<String> arguments,
      DateTime startedAt,
      DateTime endedAt});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$CommandModelDoneCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$CommandModelDone>
    implements _$$CommandModelDoneCopyWith<$Res> {
  __$$CommandModelDoneCopyWithImpl(
      _$CommandModelDone _value, $Res Function(_$CommandModelDone) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? output = null,
    Object? rawCommand = null,
    Object? arguments = null,
    Object? startedAt = null,
    Object? endedAt = null,
  }) {
    return _then(_$CommandModelDone(
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
      rawCommand: null == rawCommand
          ? _value.rawCommand
          : rawCommand // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value._arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$CommandModelDone extends CommandModelDone {
  const _$CommandModelDone(
      {required this.id,
      required this.command,
      required this.device,
      required this.output,
      required this.rawCommand,
      required final List<String> arguments,
      required this.startedAt,
      required this.endedAt})
      : _arguments = arguments,
        super._();

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final String output;
  @override
  final String rawCommand;
  final List<String> _arguments;
  @override
  List<String> get arguments {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_arguments);
  }

  @override
  final DateTime startedAt;
  @override
  final DateTime endedAt;

  @override
  String toString() {
    return 'CommandModel.done(id: $id, command: $command, device: $device, output: $output, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt, endedAt: $endedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommandModelDone &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.output, output) || other.output == output) &&
            (identical(other.rawCommand, rawCommand) ||
                other.rawCommand == rawCommand) &&
            const DeepCollectionEquality()
                .equals(other._arguments, _arguments) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      command,
      device,
      output,
      rawCommand,
      const DeepCollectionEquality().hash(_arguments),
      startedAt,
      endedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommandModelDoneCopyWith<_$CommandModelDone> get copyWith =>
      __$$CommandModelDoneCopyWithImpl<_$CommandModelDone>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        adding,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        running,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        done,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        error,
  }) {
    return done(
        id, command, device, output, rawCommand, arguments, startedAt, endedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
  }) {
    return done?.call(
        id, command, device, output, rawCommand, arguments, startedAt, endedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(id, command, device, output, rawCommand, arguments, startedAt,
          endedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CommandModelAdding value) adding,
    required TResult Function(CommandModelRunning value) running,
    required TResult Function(CommandModelDone value) done,
    required TResult Function(CommandModelError value) error,
  }) {
    return done(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CommandModelAdding value)? adding,
    TResult? Function(CommandModelRunning value)? running,
    TResult? Function(CommandModelDone value)? done,
    TResult? Function(CommandModelError value)? error,
  }) {
    return done?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CommandModelAdding value)? adding,
    TResult Function(CommandModelRunning value)? running,
    TResult Function(CommandModelDone value)? done,
    TResult Function(CommandModelError value)? error,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(this);
    }
    return orElse();
  }
}

abstract class CommandModelDone extends CommandModel {
  const factory CommandModelDone(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final String output,
      required final String rawCommand,
      required final List<String> arguments,
      required final DateTime startedAt,
      required final DateTime endedAt}) = _$CommandModelDone;
  const CommandModelDone._() : super._();

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  String get output;
  @override
  String get rawCommand;
  @override
  List<String> get arguments;
  @override
  DateTime get startedAt;
  DateTime get endedAt;
  @override
  @JsonKey(ignore: true)
  _$$CommandModelDoneCopyWith<_$CommandModelDone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CommandModelErrorCopyWith<$Res>
    implements $CommandModelCopyWith<$Res> {
  factory _$$CommandModelErrorCopyWith(
          _$CommandModelError value, $Res Function(_$CommandModelError) then) =
      __$$CommandModelErrorCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      String error,
      String rawCommand,
      List<String> arguments,
      DateTime startedAt,
      DateTime endedAt});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$CommandModelErrorCopyWithImpl<$Res>
    extends _$CommandModelCopyWithImpl<$Res, _$CommandModelError>
    implements _$$CommandModelErrorCopyWith<$Res> {
  __$$CommandModelErrorCopyWithImpl(
      _$CommandModelError _value, $Res Function(_$CommandModelError) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? error = null,
    Object? rawCommand = null,
    Object? arguments = null,
    Object? startedAt = null,
    Object? endedAt = null,
  }) {
    return _then(_$CommandModelError(
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
      rawCommand: null == rawCommand
          ? _value.rawCommand
          : rawCommand // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value._arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$CommandModelError extends CommandModelError {
  const _$CommandModelError(
      {required this.id,
      required this.command,
      required this.device,
      required this.error,
      required this.rawCommand,
      required final List<String> arguments,
      required this.startedAt,
      required this.endedAt})
      : _arguments = arguments,
        super._();

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final String error;
  @override
  final String rawCommand;
  final List<String> _arguments;
  @override
  List<String> get arguments {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_arguments);
  }

  @override
  final DateTime startedAt;
  @override
  final DateTime endedAt;

  @override
  String toString() {
    return 'CommandModel.error(id: $id, command: $command, device: $device, error: $error, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt, endedAt: $endedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommandModelError &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.rawCommand, rawCommand) ||
                other.rawCommand == rawCommand) &&
            const DeepCollectionEquality()
                .equals(other._arguments, _arguments) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      command,
      device,
      error,
      rawCommand,
      const DeepCollectionEquality().hash(_arguments),
      startedAt,
      endedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommandModelErrorCopyWith<_$CommandModelError> get copyWith =>
      __$$CommandModelErrorCopyWithImpl<_$CommandModelError>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        adding,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)
        running,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        done,
    required TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)
        error,
  }) {
    return error(id, command, device, this.error, rawCommand, arguments,
        startedAt, endedAt);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult? Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
  }) {
    return error?.call(id, command, device, this.error, rawCommand, arguments,
        startedAt, endedAt);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> stdout,
            Stream<String> stderr,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        adding,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            Stream<String> output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt)?
        running,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String output,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        done,
    TResult Function(
            String id,
            String command,
            AdbDevice? device,
            String error,
            String rawCommand,
            List<String> arguments,
            DateTime startedAt,
            DateTime endedAt)?
        error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(id, command, device, this.error, rawCommand, arguments,
          startedAt, endedAt);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CommandModelAdding value) adding,
    required TResult Function(CommandModelRunning value) running,
    required TResult Function(CommandModelDone value) done,
    required TResult Function(CommandModelError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CommandModelAdding value)? adding,
    TResult? Function(CommandModelRunning value)? running,
    TResult? Function(CommandModelDone value)? done,
    TResult? Function(CommandModelError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CommandModelAdding value)? adding,
    TResult Function(CommandModelRunning value)? running,
    TResult Function(CommandModelDone value)? done,
    TResult Function(CommandModelError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class CommandModelError extends CommandModel {
  const factory CommandModelError(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final String error,
      required final String rawCommand,
      required final List<String> arguments,
      required final DateTime startedAt,
      required final DateTime endedAt}) = _$CommandModelError;
  const CommandModelError._() : super._();

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  String get error;
  @override
  String get rawCommand;
  @override
  List<String> get arguments;
  @override
  DateTime get startedAt;
  DateTime get endedAt;
  @override
  @JsonKey(ignore: true)
  _$$CommandModelErrorCopyWith<_$CommandModelError> get copyWith =>
      throw _privateConstructorUsedError;
}

CommandModelLocalStorage _$CommandModelLocalStorageFromJson(
    Map<String, dynamic> json) {
  return _CommandModelLocalStorage.fromJson(json);
}

/// @nodoc
mixin _$CommandModelLocalStorage {
  String get id => throw _privateConstructorUsedError;
  String get command => throw _privateConstructorUsedError;
  AdbDevice? get device => throw _privateConstructorUsedError;
  String get rawCommand => throw _privateConstructorUsedError;
  List<String> get arguments => throw _privateConstructorUsedError;
  @DateTimeJsonConverter()
  DateTime get startedAt => throw _privateConstructorUsedError;
  @DateTimeJsonConverter()
  DateTime get endedAt => throw _privateConstructorUsedError;
  String? get output => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CommandModelLocalStorageCopyWith<CommandModelLocalStorage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommandModelLocalStorageCopyWith<$Res> {
  factory $CommandModelLocalStorageCopyWith(CommandModelLocalStorage value,
          $Res Function(CommandModelLocalStorage) then) =
      _$CommandModelLocalStorageCopyWithImpl<$Res, CommandModelLocalStorage>;
  @useResult
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      String rawCommand,
      List<String> arguments,
      @DateTimeJsonConverter() DateTime startedAt,
      @DateTimeJsonConverter() DateTime endedAt,
      String? output,
      String? error});

  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class _$CommandModelLocalStorageCopyWithImpl<$Res,
        $Val extends CommandModelLocalStorage>
    implements $CommandModelLocalStorageCopyWith<$Res> {
  _$CommandModelLocalStorageCopyWithImpl(this._value, this._then);

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
    Object? rawCommand = null,
    Object? arguments = null,
    Object? startedAt = null,
    Object? endedAt = null,
    Object? output = freezed,
    Object? error = freezed,
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
      rawCommand: null == rawCommand
          ? _value.rawCommand
          : rawCommand // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value.arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      output: freezed == output
          ? _value.output
          : output // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$_CommandModelLocalStorageCopyWith<$Res>
    implements $CommandModelLocalStorageCopyWith<$Res> {
  factory _$$_CommandModelLocalStorageCopyWith(
          _$_CommandModelLocalStorage value,
          $Res Function(_$_CommandModelLocalStorage) then) =
      __$$_CommandModelLocalStorageCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String command,
      AdbDevice? device,
      String rawCommand,
      List<String> arguments,
      @DateTimeJsonConverter() DateTime startedAt,
      @DateTimeJsonConverter() DateTime endedAt,
      String? output,
      String? error});

  @override
  $AdbDeviceCopyWith<$Res>? get device;
}

/// @nodoc
class __$$_CommandModelLocalStorageCopyWithImpl<$Res>
    extends _$CommandModelLocalStorageCopyWithImpl<$Res,
        _$_CommandModelLocalStorage>
    implements _$$_CommandModelLocalStorageCopyWith<$Res> {
  __$$_CommandModelLocalStorageCopyWithImpl(_$_CommandModelLocalStorage _value,
      $Res Function(_$_CommandModelLocalStorage) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? command = null,
    Object? device = freezed,
    Object? rawCommand = null,
    Object? arguments = null,
    Object? startedAt = null,
    Object? endedAt = null,
    Object? output = freezed,
    Object? error = freezed,
  }) {
    return _then(_$_CommandModelLocalStorage(
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
      rawCommand: null == rawCommand
          ? _value.rawCommand
          : rawCommand // ignore: cast_nullable_to_non_nullable
              as String,
      arguments: null == arguments
          ? _value._arguments
          : arguments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      output: freezed == output
          ? _value.output
          : output // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_CommandModelLocalStorage extends _CommandModelLocalStorage {
  const _$_CommandModelLocalStorage(
      {required this.id,
      required this.command,
      required this.device,
      required this.rawCommand,
      required final List<String> arguments,
      @DateTimeJsonConverter() required this.startedAt,
      @DateTimeJsonConverter() required this.endedAt,
      required this.output,
      required this.error})
      : _arguments = arguments,
        super._();

  factory _$_CommandModelLocalStorage.fromJson(Map<String, dynamic> json) =>
      _$$_CommandModelLocalStorageFromJson(json);

  @override
  final String id;
  @override
  final String command;
  @override
  final AdbDevice? device;
  @override
  final String rawCommand;
  final List<String> _arguments;
  @override
  List<String> get arguments {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_arguments);
  }

  @override
  @DateTimeJsonConverter()
  final DateTime startedAt;
  @override
  @DateTimeJsonConverter()
  final DateTime endedAt;
  @override
  final String? output;
  @override
  final String? error;

  @override
  String toString() {
    return 'CommandModelLocalStorage(id: $id, command: $command, device: $device, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt, endedAt: $endedAt, output: $output, error: $error)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CommandModelLocalStorage &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.command, command) || other.command == command) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.rawCommand, rawCommand) ||
                other.rawCommand == rawCommand) &&
            const DeepCollectionEquality()
                .equals(other._arguments, _arguments) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.output, output) || other.output == output) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      command,
      device,
      rawCommand,
      const DeepCollectionEquality().hash(_arguments),
      startedAt,
      endedAt,
      output,
      error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_CommandModelLocalStorageCopyWith<_$_CommandModelLocalStorage>
      get copyWith => __$$_CommandModelLocalStorageCopyWithImpl<
          _$_CommandModelLocalStorage>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_CommandModelLocalStorageToJson(
      this,
    );
  }
}

abstract class _CommandModelLocalStorage extends CommandModelLocalStorage {
  const factory _CommandModelLocalStorage(
      {required final String id,
      required final String command,
      required final AdbDevice? device,
      required final String rawCommand,
      required final List<String> arguments,
      @DateTimeJsonConverter() required final DateTime startedAt,
      @DateTimeJsonConverter() required final DateTime endedAt,
      required final String? output,
      required final String? error}) = _$_CommandModelLocalStorage;
  const _CommandModelLocalStorage._() : super._();

  factory _CommandModelLocalStorage.fromJson(Map<String, dynamic> json) =
      _$_CommandModelLocalStorage.fromJson;

  @override
  String get id;
  @override
  String get command;
  @override
  AdbDevice? get device;
  @override
  String get rawCommand;
  @override
  List<String> get arguments;
  @override
  @DateTimeJsonConverter()
  DateTime get startedAt;
  @override
  @DateTimeJsonConverter()
  DateTime get endedAt;
  @override
  String? get output;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$_CommandModelLocalStorageCopyWith<_$_CommandModelLocalStorage>
      get copyWith => throw _privateConstructorUsedError;
}
