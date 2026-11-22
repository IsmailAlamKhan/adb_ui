import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

final connectedDevicesProvider = StreamProvider.autoDispose<List<AdbDevice>>(
  (ref) {
    final adb = ref.watch(adbServiceProvider);
    return adb.connectedDevicesStream;
  },
);

/// Key for [adbFilesProvider]. A record, so it has value equality.
typedef AdbFilesQuery = ({AdbDevice device, String? path});

/// Directory listing of [AdbFilesQuery.path] on a device. Kept alive (cached per path).
final adbFilesProvider = FutureProvider.family<List<AdbFileSystem>, AdbFilesQuery>(
  (ref, query) async {
    try {
      final AdbService adb = ref.read(adbServiceProvider);
      return await adb.ls(query.device, query.path);
    } catch (e, s) {
      LogFile.instance.dispath('adbFiles', error: e, stackTrace: s);
      rethrow;
    }
  },
);

final scrcpyAvailableProvider = FutureProvider<bool>(
  (ref) => ref.read(adbServiceProvider).scrcpyAvailable(),
);

/// Id of the device the user picked. See [selectedDeviceProvider].
final selectedDeviceIdProvider = StateProvider<String?>((ref) => null);

/// The picked device if it's still connected, else the first connected device.
final selectedDeviceProvider = Provider<AdbDevice?>((ref) {
  final devices = ref.watch(connectedDevicesProvider).valueOrNull ?? const <AdbDevice>[];
  if (devices.isEmpty) return null;
  final id = ref.watch(selectedDeviceIdProvider);
  for (final device in devices) {
    if (device.id == id) return device;
  }
  return devices.first;
});

/// `getprop` values of a device, for the device page.
final devicePropertiesProvider = FutureProvider.autoDispose.family<DeviceProperties, AdbDevice>(
  (ref, device) => ref.read(adbServiceProvider).deviceProperties(device),
);

typedef PackagesQuery = ({AdbDevice device, bool includeSystem});

/// Installed packages, for the Apps tab and the uninstall picker.
final installedPackagesProvider = FutureProvider.autoDispose.family<List<String>, PackagesQuery>(
  (ref, query) => ref
      .read(adbServiceProvider)
      .listPackages(query.device, includeSystem: query.includeSystem),
);
