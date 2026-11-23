import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../utils/utils.dart';
import '../adb/adb.dart';
import 'apps_model.dart';

/// Talks to the on-device helper (spec/features/app-icons.md). Quiet: nothing goes to Activity.
abstract class AppInfoService {
  /// Installed packages with their version codes (fast; plain `pm`).
  Future<Map<String, int>> packageVersions(AdbDevice device, {bool includeSystem = false});

  /// Labels and icons for [packages], streamed as the helper prints them.
  Stream<AppInfo> info(AdbDevice device, List<String> packages, {int iconSize = 64});
}

final appInfoServiceProvider = Provider<AppInfoService>(AppInfoServiceImpl.new);

class AppInfoServiceImpl implements AppInfoService {
  AppInfoServiceImpl(this.ref);
  final Ref ref;

  /// Must match `Main.VERSION` in tool/device_helper.
  static const helperVersion = 1;
  static const asset = 'assets/device/adbui-helper.jar';
  static const remoteJar = '/data/local/tmp/adbui-helper.jar';

  /// Devices that already have this session's helper.
  final _pushed = <String>{};
  File? _localJar;

  AdbService get _adb => ref.read(adbServiceProvider);

  @override
  Future<Map<String, int>> packageVersions(AdbDevice device, {bool includeSystem = false}) async {
    final process = await _adb.startProcess([
      'shell',
      'pm',
      'list',
      'packages',
      '--show-versioncode',
      if (!includeSystem) '-3',
    ], device: device);
    final out = process.stdout.transform(utf8.decoder).join();
    final err = process.stderr.transform(utf8.decoder).join();
    if (await process.exitCode != 0) throw AppException((await err).trim());
    return parsePackageVersions(await out);
  }

  Future<void> _ensureHelper(AdbDevice device) async {
    if (_pushed.contains(device.id)) return;
    if (_localJar == null) {
      final data = await rootBundle.load(asset);
      final file = File(p.join(Directory.systemTemp.path, 'adbui-helper-$helperVersion.jar'));
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      _localJar = file;
    }
    final push = await _adb.startProcess(['push', _localJar!.path, remoteJar], device: device);
    final err = push.stderr.transform(utf8.decoder).join();
    await push.stdout.drain<void>();
    if (await push.exitCode != 0) throw AppException("Couldn't copy the app helper to the device. ${await err}".trim());
    _pushed.add(device.id);
  }

  @override
  Stream<AppInfo> info(AdbDevice device, List<String> packages, {int iconSize = 64}) async* {
    if (packages.isEmpty) return;
    await _ensureHelper(device);
    // Each helper start costs 1–5 s over Wi-Fi, so ask for many apps per run.
    for (var i = 0; i < packages.length; i += 150) {
      final batch = packages.sublist(i, (i + 150).clamp(0, packages.length));
      final process = await _adb.startProcess([
        'shell',
        'CLASSPATH=$remoteJar',
        'app_process',
        '/',
        'com.adbui.helper.Main',
        'info',
        '$iconSize',
        ...batch,
      ], device: device);
      final err = process.stderr.transform(utf8.decoder).join();
      await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        final info = parseHelperInfoLine(line);
        if (info != null) yield info;
      }
      if (await process.exitCode != 0) {
        _pushed.remove(device.id);
        throw AppException('The app helper failed on the device. ${await err}'.trim());
      }
    }
  }
}
