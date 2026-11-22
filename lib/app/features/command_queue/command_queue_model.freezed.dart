// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_queue_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommandModel {

 String get id; String get command; AdbDevice? get device; String get rawCommand; List<String> get arguments; DateTime get startedAt;
/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandModelCopyWith<CommandModel> get copyWith => _$CommandModelCopyWithImpl<CommandModel>(this as CommandModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandModel&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.device, device) || other.device == device)&&(identical(other.rawCommand, rawCommand) || other.rawCommand == rawCommand)&&const DeepCollectionEquality().equals(other.arguments, arguments)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,command,device,rawCommand,const DeepCollectionEquality().hash(arguments),startedAt);

@override
String toString() {
  return 'CommandModel(id: $id, command: $command, device: $device, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class $CommandModelCopyWith<$Res>  {
  factory $CommandModelCopyWith(CommandModel value, $Res Function(CommandModel) _then) = _$CommandModelCopyWithImpl;
@useResult
$Res call({
 String id, String command, AdbDevice? device, String rawCommand, List<String> arguments, DateTime startedAt
});


$AdbDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class _$CommandModelCopyWithImpl<$Res>
    implements $CommandModelCopyWith<$Res> {
  _$CommandModelCopyWithImpl(this._self, this._then);

  final CommandModel _self;
  final $Res Function(CommandModel) _then;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? command = null,Object? device = freezed,Object? rawCommand = null,Object? arguments = null,Object? startedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as AdbDevice?,rawCommand: null == rawCommand ? _self.rawCommand : rawCommand // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $AdbDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}


/// Adds pattern-matching-related methods to [CommandModel].
extension CommandModelPatterns on CommandModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommandModelAdding value)?  adding,TResult Function( CommandModelRunning value)?  running,TResult Function( CommandModelDone value)?  done,TResult Function( CommandModelError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommandModelAdding() when adding != null:
return adding(_that);case CommandModelRunning() when running != null:
return running(_that);case CommandModelDone() when done != null:
return done(_that);case CommandModelError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommandModelAdding value)  adding,required TResult Function( CommandModelRunning value)  running,required TResult Function( CommandModelDone value)  done,required TResult Function( CommandModelError value)  error,}){
final _that = this;
switch (_that) {
case CommandModelAdding():
return adding(_that);case CommandModelRunning():
return running(_that);case CommandModelDone():
return done(_that);case CommandModelError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommandModelAdding value)?  adding,TResult? Function( CommandModelRunning value)?  running,TResult? Function( CommandModelDone value)?  done,TResult? Function( CommandModelError value)?  error,}){
final _that = this;
switch (_that) {
case CommandModelAdding() when adding != null:
return adding(_that);case CommandModelRunning() when running != null:
return running(_that);case CommandModelDone() when done != null:
return done(_that);case CommandModelError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String command,  AdbDevice? device,  Stream<String> stdout,  Stream<String> stderr,  String rawCommand,  List<String> arguments,  DateTime startedAt)?  adding,TResult Function( String id,  String command,  AdbDevice? device,  Stream<String> output,  String rawCommand,  List<String> arguments,  DateTime startedAt)?  running,TResult Function( String id,  String command,  AdbDevice? device,  String output,  String rawCommand,  List<String> arguments,  DateTime startedAt,  DateTime endedAt)?  done,TResult Function( String id,  String command,  AdbDevice? device,  String error,  String rawCommand,  List<String> arguments,  DateTime startedAt,  DateTime endedAt)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommandModelAdding() when adding != null:
return adding(_that.id,_that.command,_that.device,_that.stdout,_that.stderr,_that.rawCommand,_that.arguments,_that.startedAt);case CommandModelRunning() when running != null:
return running(_that.id,_that.command,_that.device,_that.output,_that.rawCommand,_that.arguments,_that.startedAt);case CommandModelDone() when done != null:
return done(_that.id,_that.command,_that.device,_that.output,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt);case CommandModelError() when error != null:
return error(_that.id,_that.command,_that.device,_that.error,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String command,  AdbDevice? device,  Stream<String> stdout,  Stream<String> stderr,  String rawCommand,  List<String> arguments,  DateTime startedAt)  adding,required TResult Function( String id,  String command,  AdbDevice? device,  Stream<String> output,  String rawCommand,  List<String> arguments,  DateTime startedAt)  running,required TResult Function( String id,  String command,  AdbDevice? device,  String output,  String rawCommand,  List<String> arguments,  DateTime startedAt,  DateTime endedAt)  done,required TResult Function( String id,  String command,  AdbDevice? device,  String error,  String rawCommand,  List<String> arguments,  DateTime startedAt,  DateTime endedAt)  error,}) {final _that = this;
switch (_that) {
case CommandModelAdding():
return adding(_that.id,_that.command,_that.device,_that.stdout,_that.stderr,_that.rawCommand,_that.arguments,_that.startedAt);case CommandModelRunning():
return running(_that.id,_that.command,_that.device,_that.output,_that.rawCommand,_that.arguments,_that.startedAt);case CommandModelDone():
return done(_that.id,_that.command,_that.device,_that.output,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt);case CommandModelError():
return error(_that.id,_that.command,_that.device,_that.error,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String command,  AdbDevice? device,  Stream<String> stdout,  Stream<String> stderr,  String rawCommand,  List<String> arguments,  DateTime startedAt)?  adding,TResult? Function( String id,  String command,  AdbDevice? device,  Stream<String> output,  String rawCommand,  List<String> arguments,  DateTime startedAt)?  running,TResult? Function( String id,  String command,  AdbDevice? device,  String output,  String rawCommand,  List<String> arguments,  DateTime startedAt,  DateTime endedAt)?  done,TResult? Function( String id,  String command,  AdbDevice? device,  String error,  String rawCommand,  List<String> arguments,  DateTime startedAt,  DateTime endedAt)?  error,}) {final _that = this;
switch (_that) {
case CommandModelAdding() when adding != null:
return adding(_that.id,_that.command,_that.device,_that.stdout,_that.stderr,_that.rawCommand,_that.arguments,_that.startedAt);case CommandModelRunning() when running != null:
return running(_that.id,_that.command,_that.device,_that.output,_that.rawCommand,_that.arguments,_that.startedAt);case CommandModelDone() when done != null:
return done(_that.id,_that.command,_that.device,_that.output,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt);case CommandModelError() when error != null:
return error(_that.id,_that.command,_that.device,_that.error,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc


class CommandModelAdding extends CommandModel {
  const CommandModelAdding({required this.id, required this.command, required this.device, required this.stdout, required this.stderr, required this.rawCommand, required final  List<String> arguments, required this.startedAt}): _arguments = arguments,super._();
  

@override final  String id;
@override final  String command;
@override final  AdbDevice? device;
 final  Stream<String> stdout;
 final  Stream<String> stderr;
@override final  String rawCommand;
 final  List<String> _arguments;
@override List<String> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}

@override final  DateTime startedAt;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandModelAddingCopyWith<CommandModelAdding> get copyWith => _$CommandModelAddingCopyWithImpl<CommandModelAdding>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandModelAdding&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.device, device) || other.device == device)&&(identical(other.stdout, stdout) || other.stdout == stdout)&&(identical(other.stderr, stderr) || other.stderr == stderr)&&(identical(other.rawCommand, rawCommand) || other.rawCommand == rawCommand)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,command,device,stdout,stderr,rawCommand,const DeepCollectionEquality().hash(_arguments),startedAt);

@override
String toString() {
  return 'CommandModel.adding(id: $id, command: $command, device: $device, stdout: $stdout, stderr: $stderr, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class $CommandModelAddingCopyWith<$Res> implements $CommandModelCopyWith<$Res> {
  factory $CommandModelAddingCopyWith(CommandModelAdding value, $Res Function(CommandModelAdding) _then) = _$CommandModelAddingCopyWithImpl;
@override @useResult
$Res call({
 String id, String command, AdbDevice? device, Stream<String> stdout, Stream<String> stderr, String rawCommand, List<String> arguments, DateTime startedAt
});


@override $AdbDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class _$CommandModelAddingCopyWithImpl<$Res>
    implements $CommandModelAddingCopyWith<$Res> {
  _$CommandModelAddingCopyWithImpl(this._self, this._then);

  final CommandModelAdding _self;
  final $Res Function(CommandModelAdding) _then;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? command = null,Object? device = freezed,Object? stdout = null,Object? stderr = null,Object? rawCommand = null,Object? arguments = null,Object? startedAt = null,}) {
  return _then(CommandModelAdding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as AdbDevice?,stdout: null == stdout ? _self.stdout : stdout // ignore: cast_nullable_to_non_nullable
as Stream<String>,stderr: null == stderr ? _self.stderr : stderr // ignore: cast_nullable_to_non_nullable
as Stream<String>,rawCommand: null == rawCommand ? _self.rawCommand : rawCommand // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $AdbDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}

/// @nodoc


class CommandModelRunning extends CommandModel {
  const CommandModelRunning({required this.id, required this.command, required this.device, required this.output, required this.rawCommand, required final  List<String> arguments, required this.startedAt}): _arguments = arguments,super._();
  

@override final  String id;
@override final  String command;
@override final  AdbDevice? device;
 final  Stream<String> output;
@override final  String rawCommand;
 final  List<String> _arguments;
@override List<String> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}

@override final  DateTime startedAt;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandModelRunningCopyWith<CommandModelRunning> get copyWith => _$CommandModelRunningCopyWithImpl<CommandModelRunning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandModelRunning&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.device, device) || other.device == device)&&(identical(other.output, output) || other.output == output)&&(identical(other.rawCommand, rawCommand) || other.rawCommand == rawCommand)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,command,device,output,rawCommand,const DeepCollectionEquality().hash(_arguments),startedAt);

@override
String toString() {
  return 'CommandModel.running(id: $id, command: $command, device: $device, output: $output, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class $CommandModelRunningCopyWith<$Res> implements $CommandModelCopyWith<$Res> {
  factory $CommandModelRunningCopyWith(CommandModelRunning value, $Res Function(CommandModelRunning) _then) = _$CommandModelRunningCopyWithImpl;
@override @useResult
$Res call({
 String id, String command, AdbDevice? device, Stream<String> output, String rawCommand, List<String> arguments, DateTime startedAt
});


@override $AdbDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class _$CommandModelRunningCopyWithImpl<$Res>
    implements $CommandModelRunningCopyWith<$Res> {
  _$CommandModelRunningCopyWithImpl(this._self, this._then);

  final CommandModelRunning _self;
  final $Res Function(CommandModelRunning) _then;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? command = null,Object? device = freezed,Object? output = null,Object? rawCommand = null,Object? arguments = null,Object? startedAt = null,}) {
  return _then(CommandModelRunning(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as AdbDevice?,output: null == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as Stream<String>,rawCommand: null == rawCommand ? _self.rawCommand : rawCommand // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $AdbDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}

/// @nodoc


class CommandModelDone extends CommandModel {
  const CommandModelDone({required this.id, required this.command, required this.device, required this.output, required this.rawCommand, required final  List<String> arguments, required this.startedAt, required this.endedAt}): _arguments = arguments,super._();
  

@override final  String id;
@override final  String command;
@override final  AdbDevice? device;
 final  String output;
@override final  String rawCommand;
 final  List<String> _arguments;
@override List<String> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}

@override final  DateTime startedAt;
 final  DateTime endedAt;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandModelDoneCopyWith<CommandModelDone> get copyWith => _$CommandModelDoneCopyWithImpl<CommandModelDone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandModelDone&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.device, device) || other.device == device)&&(identical(other.output, output) || other.output == output)&&(identical(other.rawCommand, rawCommand) || other.rawCommand == rawCommand)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,command,device,output,rawCommand,const DeepCollectionEquality().hash(_arguments),startedAt,endedAt);

@override
String toString() {
  return 'CommandModel.done(id: $id, command: $command, device: $device, output: $output, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $CommandModelDoneCopyWith<$Res> implements $CommandModelCopyWith<$Res> {
  factory $CommandModelDoneCopyWith(CommandModelDone value, $Res Function(CommandModelDone) _then) = _$CommandModelDoneCopyWithImpl;
@override @useResult
$Res call({
 String id, String command, AdbDevice? device, String output, String rawCommand, List<String> arguments, DateTime startedAt, DateTime endedAt
});


@override $AdbDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class _$CommandModelDoneCopyWithImpl<$Res>
    implements $CommandModelDoneCopyWith<$Res> {
  _$CommandModelDoneCopyWithImpl(this._self, this._then);

  final CommandModelDone _self;
  final $Res Function(CommandModelDone) _then;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? command = null,Object? device = freezed,Object? output = null,Object? rawCommand = null,Object? arguments = null,Object? startedAt = null,Object? endedAt = null,}) {
  return _then(CommandModelDone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as AdbDevice?,output: null == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String,rawCommand: null == rawCommand ? _self.rawCommand : rawCommand // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $AdbDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}

/// @nodoc


class CommandModelError extends CommandModel {
  const CommandModelError({required this.id, required this.command, required this.device, required this.error, required this.rawCommand, required final  List<String> arguments, required this.startedAt, required this.endedAt}): _arguments = arguments,super._();
  

@override final  String id;
@override final  String command;
@override final  AdbDevice? device;
 final  String error;
@override final  String rawCommand;
 final  List<String> _arguments;
@override List<String> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}

@override final  DateTime startedAt;
 final  DateTime endedAt;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandModelErrorCopyWith<CommandModelError> get copyWith => _$CommandModelErrorCopyWithImpl<CommandModelError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandModelError&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.device, device) || other.device == device)&&(identical(other.error, error) || other.error == error)&&(identical(other.rawCommand, rawCommand) || other.rawCommand == rawCommand)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,command,device,error,rawCommand,const DeepCollectionEquality().hash(_arguments),startedAt,endedAt);

@override
String toString() {
  return 'CommandModel.error(id: $id, command: $command, device: $device, error: $error, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $CommandModelErrorCopyWith<$Res> implements $CommandModelCopyWith<$Res> {
  factory $CommandModelErrorCopyWith(CommandModelError value, $Res Function(CommandModelError) _then) = _$CommandModelErrorCopyWithImpl;
@override @useResult
$Res call({
 String id, String command, AdbDevice? device, String error, String rawCommand, List<String> arguments, DateTime startedAt, DateTime endedAt
});


@override $AdbDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class _$CommandModelErrorCopyWithImpl<$Res>
    implements $CommandModelErrorCopyWith<$Res> {
  _$CommandModelErrorCopyWithImpl(this._self, this._then);

  final CommandModelError _self;
  final $Res Function(CommandModelError) _then;

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? command = null,Object? device = freezed,Object? error = null,Object? rawCommand = null,Object? arguments = null,Object? startedAt = null,Object? endedAt = null,}) {
  return _then(CommandModelError(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as AdbDevice?,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,rawCommand: null == rawCommand ? _self.rawCommand : rawCommand // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of CommandModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $AdbDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}


/// @nodoc
mixin _$CommandModelLocalStorage {

 String get id; String get command; AdbDevice? get device; String get rawCommand; List<String> get arguments;@DateTimeJsonConverter() DateTime get startedAt;@DateTimeJsonConverter() DateTime get endedAt; String? get output; String? get error;
/// Create a copy of CommandModelLocalStorage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandModelLocalStorageCopyWith<CommandModelLocalStorage> get copyWith => _$CommandModelLocalStorageCopyWithImpl<CommandModelLocalStorage>(this as CommandModelLocalStorage, _$identity);

  /// Serializes this CommandModelLocalStorage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandModelLocalStorage&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.device, device) || other.device == device)&&(identical(other.rawCommand, rawCommand) || other.rawCommand == rawCommand)&&const DeepCollectionEquality().equals(other.arguments, arguments)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.output, output) || other.output == output)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,command,device,rawCommand,const DeepCollectionEquality().hash(arguments),startedAt,endedAt,output,error);

@override
String toString() {
  return 'CommandModelLocalStorage(id: $id, command: $command, device: $device, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt, endedAt: $endedAt, output: $output, error: $error)';
}


}

/// @nodoc
abstract mixin class $CommandModelLocalStorageCopyWith<$Res>  {
  factory $CommandModelLocalStorageCopyWith(CommandModelLocalStorage value, $Res Function(CommandModelLocalStorage) _then) = _$CommandModelLocalStorageCopyWithImpl;
@useResult
$Res call({
 String id, String command, AdbDevice? device, String rawCommand, List<String> arguments,@DateTimeJsonConverter() DateTime startedAt,@DateTimeJsonConverter() DateTime endedAt, String? output, String? error
});


$AdbDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class _$CommandModelLocalStorageCopyWithImpl<$Res>
    implements $CommandModelLocalStorageCopyWith<$Res> {
  _$CommandModelLocalStorageCopyWithImpl(this._self, this._then);

  final CommandModelLocalStorage _self;
  final $Res Function(CommandModelLocalStorage) _then;

/// Create a copy of CommandModelLocalStorage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? command = null,Object? device = freezed,Object? rawCommand = null,Object? arguments = null,Object? startedAt = null,Object? endedAt = null,Object? output = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as AdbDevice?,rawCommand: null == rawCommand ? _self.rawCommand : rawCommand // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CommandModelLocalStorage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $AdbDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}


/// Adds pattern-matching-related methods to [CommandModelLocalStorage].
extension CommandModelLocalStoragePatterns on CommandModelLocalStorage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommandModelLocalStorage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommandModelLocalStorage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommandModelLocalStorage value)  $default,){
final _that = this;
switch (_that) {
case _CommandModelLocalStorage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommandModelLocalStorage value)?  $default,){
final _that = this;
switch (_that) {
case _CommandModelLocalStorage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String command,  AdbDevice? device,  String rawCommand,  List<String> arguments, @DateTimeJsonConverter()  DateTime startedAt, @DateTimeJsonConverter()  DateTime endedAt,  String? output,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommandModelLocalStorage() when $default != null:
return $default(_that.id,_that.command,_that.device,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt,_that.output,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String command,  AdbDevice? device,  String rawCommand,  List<String> arguments, @DateTimeJsonConverter()  DateTime startedAt, @DateTimeJsonConverter()  DateTime endedAt,  String? output,  String? error)  $default,) {final _that = this;
switch (_that) {
case _CommandModelLocalStorage():
return $default(_that.id,_that.command,_that.device,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt,_that.output,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String command,  AdbDevice? device,  String rawCommand,  List<String> arguments, @DateTimeJsonConverter()  DateTime startedAt, @DateTimeJsonConverter()  DateTime endedAt,  String? output,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _CommandModelLocalStorage() when $default != null:
return $default(_that.id,_that.command,_that.device,_that.rawCommand,_that.arguments,_that.startedAt,_that.endedAt,_that.output,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommandModelLocalStorage extends CommandModelLocalStorage {
  const _CommandModelLocalStorage({required this.id, required this.command, required this.device, required this.rawCommand, required final  List<String> arguments, @DateTimeJsonConverter() required this.startedAt, @DateTimeJsonConverter() required this.endedAt, required this.output, required this.error}): _arguments = arguments,super._();
  factory _CommandModelLocalStorage.fromJson(Map<String, dynamic> json) => _$CommandModelLocalStorageFromJson(json);

@override final  String id;
@override final  String command;
@override final  AdbDevice? device;
@override final  String rawCommand;
 final  List<String> _arguments;
@override List<String> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}

@override@DateTimeJsonConverter() final  DateTime startedAt;
@override@DateTimeJsonConverter() final  DateTime endedAt;
@override final  String? output;
@override final  String? error;

/// Create a copy of CommandModelLocalStorage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommandModelLocalStorageCopyWith<_CommandModelLocalStorage> get copyWith => __$CommandModelLocalStorageCopyWithImpl<_CommandModelLocalStorage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommandModelLocalStorageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommandModelLocalStorage&&(identical(other.id, id) || other.id == id)&&(identical(other.command, command) || other.command == command)&&(identical(other.device, device) || other.device == device)&&(identical(other.rawCommand, rawCommand) || other.rawCommand == rawCommand)&&const DeepCollectionEquality().equals(other._arguments, _arguments)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.output, output) || other.output == output)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,command,device,rawCommand,const DeepCollectionEquality().hash(_arguments),startedAt,endedAt,output,error);

@override
String toString() {
  return 'CommandModelLocalStorage(id: $id, command: $command, device: $device, rawCommand: $rawCommand, arguments: $arguments, startedAt: $startedAt, endedAt: $endedAt, output: $output, error: $error)';
}


}

/// @nodoc
abstract mixin class _$CommandModelLocalStorageCopyWith<$Res> implements $CommandModelLocalStorageCopyWith<$Res> {
  factory _$CommandModelLocalStorageCopyWith(_CommandModelLocalStorage value, $Res Function(_CommandModelLocalStorage) _then) = __$CommandModelLocalStorageCopyWithImpl;
@override @useResult
$Res call({
 String id, String command, AdbDevice? device, String rawCommand, List<String> arguments,@DateTimeJsonConverter() DateTime startedAt,@DateTimeJsonConverter() DateTime endedAt, String? output, String? error
});


@override $AdbDeviceCopyWith<$Res>? get device;

}
/// @nodoc
class __$CommandModelLocalStorageCopyWithImpl<$Res>
    implements _$CommandModelLocalStorageCopyWith<$Res> {
  __$CommandModelLocalStorageCopyWithImpl(this._self, this._then);

  final _CommandModelLocalStorage _self;
  final $Res Function(_CommandModelLocalStorage) _then;

/// Create a copy of CommandModelLocalStorage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? command = null,Object? device = freezed,Object? rawCommand = null,Object? arguments = null,Object? startedAt = null,Object? endedAt = null,Object? output = freezed,Object? error = freezed,}) {
  return _then(_CommandModelLocalStorage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,device: freezed == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as AdbDevice?,rawCommand: null == rawCommand ? _self.rawCommand : rawCommand // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CommandModelLocalStorage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdbDeviceCopyWith<$Res>? get device {
    if (_self.device == null) {
    return null;
  }

  return $AdbDeviceCopyWith<$Res>(_self.device!, (value) {
    return _then(_self.copyWith(device: value));
  });
}
}

// dart format on
