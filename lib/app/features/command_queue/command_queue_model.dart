import 'package:freezed_annotation/freezed_annotation.dart';

import '../features.dart';

part 'command_queue_model.freezed.dart';

@freezed
class CommandModel with _$CommandModel {
  const factory CommandModel.adding({
    required String id,
    required String command,
    required AdbDevice? device,
    required Stream<String> stdout,
    required Stream<String> stderr,
  }) = _Adding;
  const factory CommandModel.running({
    required String id,
    required String command,
    required AdbDevice? device,
    required Stream<String> output,
  }) = _Running;

  const factory CommandModel.done({
    required String id,
    required String command,
    required AdbDevice? device,
    required String output,
  }) = _Done;

  const factory CommandModel.error({
    required String id,
    required String command,
    required AdbDevice? device,
    required String error,
  }) = _Error;
}
