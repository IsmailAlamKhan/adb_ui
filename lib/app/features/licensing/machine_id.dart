import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Stable anonymous id for this desktop install (used for license device slots).
Future<String> stableMachineId() async {
  if (kIsWeb) return 'web';
  final plugin = DeviceInfoPlugin();
  try {
    if (Platform.isWindows) {
      final w = await plugin.windowsInfo;
      final raw = '${w.computerName}|${w.deviceId}|${w.productName}|${w.displayVersion}';
      return _hash(raw);
    }
    if (Platform.isMacOS) {
      final m = await plugin.macOsInfo;
      final raw = '${m.computerName}|${m.systemGUID}|${m.model}';
      return _hash(raw);
    }
    if (Platform.isLinux) {
      final l = await plugin.linuxInfo;
      final raw = '${l.name}|${l.id}|${l.machineId}';
      return _hash(raw);
    }
  } catch (_) {
    // ignore
  }
  return _hash(Platform.operatingSystem);
}

String _hash(String input) =>
    sha256.convert(input.codeUnits).toString().substring(0, 32);
