import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../utils/utils.dart';
import '../adb/adb.dart';
import 'apps_model.dart';
import 'apps_service.dart';

/// Labels and icons per device, filled in as they load (spec/features/app-icons.md).
final appInfoProvider = StateNotifierProvider.family<AppInfoController, Map<String, AppInfo>, AdbDevice>(
  AppInfoController.new,
);

/// Disk cache shared by all devices: icons are PNGs named `package@versionCode.png`,
/// labels in `labels.json` under the same keys.
class AppInfoDiskCache {
  AppInfoDiskCache._();
  static final instance = AppInfoDiskCache._();

  Directory? _dir;
  Map<String, String>? _labels;
  Timer? _saveLabels;

  Future<Directory> _folder() async {
    if (_dir != null) return _dir!;
    final support = await getApplicationSupportDirectory();
    return _dir = await Directory(p.join(support.path, 'app_icons')).create(recursive: true);
  }

  Future<Map<String, String>> _labelMap() async {
    if (_labels != null) return _labels!;
    try {
      final file = File(p.join((await _folder()).path, 'labels.json'));
      _labels = file.existsSync()
          ? Map<String, String>.from(jsonDecode(await file.readAsString()) as Map)
          : <String, String>{};
    } catch (_) {
      _labels = <String, String>{};
    }
    return _labels!;
  }

  static String _safe(String key) => key.replaceAll(RegExp(r'[^\w.@-]'), '_');

  /// The cached entry, or null when this package version was never seen.
  Future<AppInfo?> read(String package, String key) async {
    final labels = await _labelMap();
    if (!labels.containsKey(key)) return null;
    final file = File(p.join((await _folder()).path, '${_safe(key)}.png'));
    Uint8List? icon;
    if (file.existsSync()) icon = await file.readAsBytes();
    final label = labels[key]!;
    return AppInfo(package, label: label.isEmpty ? null : label, icon: icon);
  }

  Future<void> write(String key, AppInfo info) async {
    final labels = await _labelMap();
    labels[key] = info.label ?? '';
    if (info.icon != null) {
      await File(p.join((await _folder()).path, '${_safe(key)}.png')).writeAsBytes(info.icon!);
    }
    _saveLabels?.cancel();
    _saveLabels = Timer(const Duration(milliseconds: 500), () async {
      final file = File(p.join((await _folder()).path, 'labels.json'));
      await file.writeAsString(jsonEncode(labels));
    });
  }
}

class AppInfoController extends StateNotifier<Map<String, AppInfo>> {
  AppInfoController(this.ref, this.device) : super(const {});

  final Ref ref;
  final AdbDevice device;
  final _requested = <String>{};
  bool _helperFailed = false;

  AppInfoService get _service => ref.read(appInfoServiceProvider);

  /// Loads names and icons for [packages] that aren't known yet: disk cache first, then
  /// one helper run for the rest. Never throws; failures leave letter tiles in place.
  Future<void> ensure(List<String> packages, {bool includeSystem = false}) async {
    final wanted = packages.where(_requested.add).toList();
    if (wanted.isEmpty) return;
    try {
      final versions = await _service.packageVersions(device, includeSystem: includeSystem);
      final found = <String, AppInfo>{};
      final missing = <String>[];
      for (final package in wanted) {
        final key = '$package@${versions[package] ?? 0}';
        final cached = await AppInfoDiskCache.instance.read(package, key);
        if (cached != null) {
          found[package] = cached;
        } else {
          missing.add(package);
        }
      }
      if (found.isNotEmpty && mounted) state = {...state, ...found};
      if (missing.isEmpty || _helperFailed) return;

      var pending = <String, AppInfo>{};
      void flush() {
        if (pending.isEmpty || !mounted) return;
        state = {...state, ...pending};
        pending = {};
      }

      await for (final info in _service.info(device, missing)) {
        pending[info.package] = info;
        unawaited(AppInfoDiskCache.instance.write('${info.package}@${versions[info.package] ?? 0}', info));
        if (pending.length >= 12) flush();
      }
      flush();
    } catch (e, s) {
      _helperFailed = true;
      LogFile.instance.dispath('App icons: helper failed for ${device.id}', error: e, stackTrace: s);
    }
  }
}
