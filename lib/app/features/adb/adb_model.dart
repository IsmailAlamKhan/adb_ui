import 'package:freezed_annotation/freezed_annotation.dart';

part 'adb_model.freezed.dart';

@freezed
class AdbDevice with _$AdbDevice {
  const AdbDevice._();
  const factory AdbDevice({
    required String id,
    required String type,
  }) = _AdbDevice;

  bool get isOffline => type.trim().toLowerCase() == 'offline';
}

mixin AdbFileSystem {
  abstract final String name;
}

@freezed
class AdbFile with _$AdbFile, AdbFileSystem {
  const AdbFile._();
  const factory AdbFile(String name) = _AdbFile;
}

@freezed
class AdbDirectory with _$AdbDirectory, AdbFileSystem {
  const AdbDirectory._();
  const factory AdbDirectory(String name) = _AdbDirectory;
}
