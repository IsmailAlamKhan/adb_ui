import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  DeviceService Function(Ref ref) constructor;
  if (kIsWeb) {
    constructor = WebDeviceServiceImpl.new;
  } else if (Platform.isAndroid) {
    constructor = AndroidDeviceServiceImpl.new;
  } else if (Platform.isIOS) {
    constructor = IosDeviceServiceImpl.new;
  } else if (Platform.isWindows) {
    constructor = WindowsDeviceServiceImpl.new;
  } else if (Platform.isLinux) {
    constructor = LinuxDeviceServiceImpl.new;
  } else if (Platform.isMacOS) {
    constructor = MacDeviceServiceImpl.new;
  } else {
    throw UnimplementedError('Platform not supported');
  }
  return constructor(ref);
});

final _deviceInfo = DeviceInfoPlugin();

abstract class DeviceService {
  Future<Device> getDeviceInfo();
  // Future<Device> getIosInfo();
  // Future<Device> getBrowserInfo();
  // Future<Device> getWindowsInfo();
  // Future<Device> getLinuxInfo();
  // Future<Device> getMacInfo();

  Future<BaseDeviceInfo> get deviceInfo;
}

class AndroidDeviceServiceImpl extends DeviceService {
  final Ref ref;

  AndroidDeviceServiceImpl(this.ref);

  @override
  Future<Device> getDeviceInfo() async {
    final info = await deviceInfo;
    // final id = await AppManager.instance.getAndroidId();
    return Device(
      name: info.model,
      id: info.id,
      manufacturer: info.manufacturer,
      model: info.model,
      product: info.product,
    );
  }

  @override
  Future<AndroidDeviceInfo> get deviceInfo => _deviceInfo.androidInfo;
}

class IosDeviceServiceImpl extends DeviceService {
  final Ref ref;

  IosDeviceServiceImpl(this.ref);

  @override
  Future<Device> getDeviceInfo() async {
    final info = await deviceInfo;
    return Device(
      name: info.name ?? info.systemName ?? info.model ?? '',
      id: info.identifierForVendor ?? '',
      manufacturer: 'Apple',
      model: info.model,
      product: '',
    );
  }

  @override
  Future<IosDeviceInfo> get deviceInfo => _deviceInfo.iosInfo;
}

class WebDeviceServiceImpl extends DeviceService {
  final Ref ref;

  WebDeviceServiceImpl(this.ref);

  @override
  Future<Device> getDeviceInfo() async {
    final info = await deviceInfo;
    return Device(name: info.appName ?? '', id: '');
  }

  @override
  Future<WebBrowserInfo> get deviceInfo => _deviceInfo.webBrowserInfo;
}

class WindowsDeviceServiceImpl extends DeviceService {
  final Ref ref;

  WindowsDeviceServiceImpl(this.ref);

  @override
  Future<Device> getDeviceInfo() async {
    final info = await deviceInfo;
    return Device(name: info.computerName, id: '');
  }

  @override
  Future<WindowsDeviceInfo> get deviceInfo => _deviceInfo.windowsInfo;
}

class LinuxDeviceServiceImpl extends DeviceService {
  final Ref ref;

  LinuxDeviceServiceImpl(this.ref);

  @override
  Future<Device> getDeviceInfo() async {
    final info = await _deviceInfo.linuxInfo;
    return Device(name: info.name, id: info.id);
  }

  @override
  Future<LinuxDeviceInfo> get deviceInfo => _deviceInfo.linuxInfo;
}

class MacDeviceServiceImpl extends DeviceService {
  final Ref ref;

  MacDeviceServiceImpl(this.ref);

  @override
  Future<Device> getDeviceInfo() async {
    final info = await deviceInfo;
    return Device(name: info.computerName, id: '', model: info.model);
  }

  @override
  Future<MacOsDeviceInfo> get deviceInfo => _deviceInfo.macOsInfo;
}

// Future<String> getName({String? model, DeviceType? deviceType}) {
//   final deviceNames = DeviceMarketingNames();
//   if (model != null) {
//     return Future.value(deviceNames.getNamesFromModel(deviceType!, model));
//   }
//   return deviceNames.getSingleName();
// }

// @override
// Future<Device> getAndroidInfo() async {
//   final info = await _deviceInfo.androidInfo;
//   final id = await AppManager.instance.getAndroidId();
//   return Device(
//     name: await getName(model: info.model, deviceType: DeviceType.android),
//     id: id ?? '',
//     manufacturer: info.manufacturer,
//     model: info.model,
//     product: info.product,
//   );
// }

// @override
// Future<Device> getIosInfo() async {
//   final info = await _deviceInfo.iosInfo;
//   return Device(
//     name: await getName(model: info.model, deviceType: DeviceType.ios),
//     id: info.identifierForVendor ?? '',
//     manufacturer: 'Apple',
//     model: info.model,
//     product: '',
//   );
// }

// @override
// Future<Device> getBrowserInfo() async {
//   final info = await _deviceInfo.webBrowserInfo;
//   return Device(name: info.appName ?? '', id: '');
// }

// @override
// Future<Device> getLinuxInfo() async {
//   final info = await _deviceInfo.linuxInfo;
//   return Device(name: info.name, id: info.id);
// }

// @override
// Future<Device> getMacInfo() async {
//   final info = await _deviceInfo.macOsInfo;
//   return Device(name: info.computerName, id: '', model: info.model);
// }

// @override
// Future<Device> getWindowsInfo() async {
//   final info = await _deviceInfo.windowsInfo;
//   return Device(name: info.computerName, id: '');
// }

// @override
// Future<BaseDeviceInfo> get deviceInfo {
//   if (kIsWeb) {
//     return _deviceInfo.webBrowserInfo;
//   } else if (Platform.isAndroid) {
//     return _deviceInfo.androidInfo;
//   } else if (Platform.isIOS) {
//     return _deviceInfo.iosInfo;
//   } else if (Platform.isWindows) {
//     return _deviceInfo.windowsInfo;
//   } else if (Platform.isLinux) {
//     return _deviceInfo.linuxInfo;
//   } else if (Platform.isMacOS) {
//     return _deviceInfo.macOsInfo;
//   } else {
//     throw UnimplementedError('Platform not supported');
//   }
// }
