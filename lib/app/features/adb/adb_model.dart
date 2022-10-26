import 'package:freezed_annotation/freezed_annotation.dart';

part 'adb_model.freezed.dart';

@freezed
class AdbDevice with _$AdbDevice {
  const AdbDevice._();
  const factory AdbDevice({
    required String id,
    required String type,
  }) = _AdbDevice;
}
