// 🎯 Dart imports:
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

final deviceControllerProvider =
    StateNotifierProvider<DeviceController, Device?>(DeviceController.new);

final deviceInfoProvider = Provider<Device>(
  (ref) {
    final deviceInfo = ref.watch(deviceControllerProvider);
    assert(
      deviceInfo != null,
      "Device info is null. Make sure you have initialized the device controller.",
    );
    return deviceInfo!;
  },
  dependencies: [deviceControllerProvider],
);

class DeviceController extends StateNotifier<Device?> {
  final DeviceService service;

  DeviceController(Ref ref)
      : service = ref.read(deviceServiceProvider),
        super(null);

  BaseDeviceInfo? deviceInfo;

  bool get isPerAppLangSupported {
    final deviceInfo = this.deviceInfo;
    bool isPerAppLangSupported = false;
    if (deviceInfo is AndroidDeviceInfo) {
      final sdkInt = deviceInfo.version.sdkInt;
      isPerAppLangSupported = sdkInt != null && sdkInt >= 33;
    }
    if (deviceInfo is IosDeviceInfo) {
      final sdkInt = deviceInfo.systemVersion?.toInt();
      isPerAppLangSupported = sdkInt != null && sdkInt >= 14;
    }
    return isPerAppLangSupported;
  }

  Future<void> init() async {
    Device device = await service.getDeviceInfo();
    state = device;
    deviceInfo = await service.deviceInfo;
  }
}
