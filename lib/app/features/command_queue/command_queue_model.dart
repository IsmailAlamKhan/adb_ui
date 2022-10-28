import 'package:freezed_annotation/freezed_annotation.dart';

import '../features.dart';

part 'command_queue_model.freezed.dart';

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
  }) = _Adding;
  const factory CommandModel.running({
    required String id,
    required String command,
    required AdbDevice? device,
    required Stream<String> output,
    required String rawCommand,
    required List<String> arguments,
  }) = _Running;

  const factory CommandModel.done({
    required String id,
    required String command,
    required AdbDevice? device,
    required String output,
    required String rawCommand,
    required List<String> arguments,
  }) = _Done;

  const factory CommandModel.error({
    required String id,
    required String command,
    required AdbDevice? device,
    required String error,
    required String rawCommand,
    required List<String> arguments,
  }) = _Error;

  CommandModel toError(String error) => CommandModel.error(
        id: id,
        command: command,
        device: device,
        error: error,
        rawCommand: rawCommand,
        arguments: arguments,
      );

  CommandModel toDone(String output) => CommandModel.done(
        id: id,
        command: command,
        device: device,
        output: output,
        rawCommand: rawCommand,
        arguments: arguments,
      );

  CommandModel toRunning(Stream<String> output) => CommandModel.running(
        id: id,
        command: command,
        device: device,
        output: output,
        rawCommand: rawCommand,
        arguments: arguments,
      );
  bool get isDone => this is _Done || this is _Error;

  bool get isRerun => id.startsWith('rerun-');
}
