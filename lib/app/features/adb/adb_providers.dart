import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

part 'adb_providers.g.dart';

final connectedDevicesProvider = StreamProvider.autoDispose<List<AdbDevice>>(
  (ref) {
    final adb = ref.watch(adbServiceProvider);
    return adb.connectedDevicesStream;
  },
);

@riverpodKeepAlive
Future<List<AdbFileSystem>> adbFiles(
  AdbFilesRef ref, {
  required AdbDevice device,
  String? path,
}) async {
  final AdbService adb = ref.read(adbServiceProvider);
  final files = await adb.ls(device, path);
  return files;
}

@riverpodKeepAlive
Future<bool> scrcpyAvailable(ScrcpyAvailableRef ref) =>
    ref.read(adbServiceProvider).scrcpyAvailable();
