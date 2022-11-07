import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/services/local_storage.dart';
import '../features.dart';

part 'command_queue_model.freezed.dart';
part 'command_queue_model.g.dart';

@freezed
class CommandModel with _$CommandModel {
  const CommandModel._();
  const factory CommandModel.adding({
    required String id,
    required String command,
    required AdbDevice? device,
    required Stream<String> stdout,
    required Stream<String> stderr,
    required String rawCommand,
    required List<String> arguments,
    required DateTime startedAt,
  }) = CommandModelAdding;
  const factory CommandModel.running({
    required String id,
    required String command,
    required AdbDevice? device,
    required Stream<String> output,
    required String rawCommand,
    required List<String> arguments,
    required DateTime startedAt,
  }) = CommandModelRunning;

  const factory CommandModel.done({
    required String id,
    required String command,
    required AdbDevice? device,
    required String output,
    required String rawCommand,
    required List<String> arguments,
    required DateTime startedAt,
    required DateTime endedAt,
  }) = CommandModelDone;

  const factory CommandModel.error({
    required String id,
    required String command,
    required AdbDevice? device,
    required String error,
    required String rawCommand,
    required List<String> arguments,
    required DateTime startedAt,
    required DateTime endedAt,
  }) = CommandModelError;

  CommandModel toError(String error) => CommandModel.error(
        id: id,
        command: command,
        device: device,
        error: error,
        rawCommand: rawCommand,
        arguments: arguments,
        startedAt: startedAt,
        endedAt: DateTime.now(),
      );

  CommandModel toDone(String output) => CommandModel.done(
        id: id,
        command: command,
        device: device,
        output: output,
        rawCommand: rawCommand,
        arguments: arguments,
        startedAt: startedAt,
        endedAt: DateTime.now(),
      );

  CommandModel toRunning(Stream<String> output) => CommandModel.running(
        id: id,
        command: command,
        device: device,
        output: output,
        rawCommand: rawCommand,
        arguments: arguments,
        startedAt: startedAt,
      );
  bool get isDone => this is CommandModelDone || this is CommandModelError;

  bool get isRerun => id.startsWith('rerun-');

  T? whenAdding<T>(T Function(CommandModelAdding) action) {
    if (this is CommandModelAdding) {
      return action(this as CommandModelAdding);
    }
  }

  T? whenRunning<T>(T Function(CommandModelRunning) action) {
    if (this is CommandModelRunning) {
      return action(this as CommandModelRunning);
    }
  }

  T? whenDone<T>(T Function(CommandModelDone) action) {
    if (this is CommandModelDone) {
      return action(this as CommandModelDone);
    }
  }

  T? whenError<T>(T Function(CommandModelError) action) {
    if (this is CommandModelError) {
      return action(this as CommandModelError);
    }
  }

  int? get finishedIn {
    int? finishedIn;
    whenDone((command) {
      finishedIn = command.endedAt.difference(command.startedAt).inMilliseconds;
    });
    whenError((command) {
      finishedIn = command.endedAt.difference(command.startedAt).inMilliseconds;
    });
    return finishedIn;
  }

  CommandModelLocalStorage toLocalStorage() => CommandModelLocalStorage(
        id: id,
        command: command,
        device: device,
        rawCommand: rawCommand,
        arguments: arguments,
        startedAt: startedAt,
        endedAt:
            (whenDone((command) => command.endedAt) ?? whenError((command) => command.endedAt))!,
        output: whenDone((command) => command.output),
        error: whenError((command) => command.error),
      );
}

@freezed
class CommandModelLocalStorage with _$CommandModelLocalStorage, LocalStorageModel {
  const CommandModelLocalStorage._();
  const factory CommandModelLocalStorage({
    required String id,
    required String command,
    required AdbDevice? device,
    required String rawCommand,
    required List<String> arguments,
    @DateTimeJsonConverter() required DateTime startedAt,
    @DateTimeJsonConverter() required DateTime endedAt,
    required String? output,
    required String? error,
  }) = _CommandModelLocalStorage;

  factory CommandModelLocalStorage.fromJson(Map<String, dynamic> json) =>
      _$CommandModelLocalStorageFromJson(json);

  CommandModel toModel() {
    if (output != null) {
      return CommandModel.done(
        id: id,
        command: command,
        device: device,
        output: output!,
        rawCommand: rawCommand,
        arguments: arguments,
        startedAt: startedAt,
        endedAt: endedAt,
      );
    } else if (error != null) {
      return CommandModel.error(
        id: id,
        command: command,
        device: device,
        error: error!,
        rawCommand: rawCommand,
        arguments: arguments,
        startedAt: startedAt,
        endedAt: endedAt,
      );
    } else {
      throw Exception('Invalid CommandModelLocalStorage');
    }
  }
}

class DateTimeJsonConverter implements JsonConverter<DateTime, String> {
  const DateTimeJsonConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}
