import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'install_planner.dart';

/// Where ADB UI keeps tools it installed itself, and the extra folders appended to `PATH`
/// for every process it starts, so those tools work without the user editing PATH.
/// See spec/features/onboarding.md "Finding tools without editing PATH".
class ToolPaths {
  ToolPaths._(this.toolsDir);

  static ToolPaths? _instance;

  /// Null until [init]; callers then fall back to the plain environment.
  static ToolPaths? get maybeInstance => _instance;

  static ToolPaths get instance {
    final i = _instance;
    if (i == null) throw StateError('ToolPaths.init() was not called');
    return i;
  }

  static Future<ToolPaths> init() async {
    if (_instance != null) return _instance!;
    final support = await getApplicationSupportDirectory();
    return _instance = ToolPaths._(p.join(support.absolute.path, 'tools'));
  }

  /// `<app support>/tools`.
  final String toolsDir;

  String get platformToolsDir => p.join(toolsDir, 'platform-tools');
  String get scrcpyDir => p.join(toolsDir, 'scrcpy');
  String get downloadDir => p.join(toolsDir, '.download');

  /// Folders appended to PATH, in order.
  List<String> get extraDirs => [
        platformToolsDir,
        scrcpyDir,
        if (Platform.isMacOS) ...['/opt/homebrew/bin', '/usr/local/bin'],
        if (Platform.isWindows && Platform.environment['LOCALAPPDATA'] != null)
          p.join(Platform.environment['LOCALAPPDATA']!, 'Microsoft', 'WinGet', 'Links'),
      ];

  bool isManaged(String? path) => path != null && p.isWithin(toolsDir, path);

  /// [base] (or the app's own environment) with [extraDirs] appended to PATH.
  Map<String, String> environment([Map<String, String>? base]) =>
      withExtraPath(base ?? Platform.environment, extraDirs, windows: Platform.isWindows);

  /// The file for [name] in the app's own tool folders, if it exists.
  String? managedExecutable(String name) {
    final file = Platform.isWindows ? '$name.exe' : name;
    for (final dir in [platformToolsDir, scrcpyDir]) {
      final f = File(p.join(dir, file));
      if (f.existsSync()) return f.path;
    }
    return null;
  }
}

/// Copy of [env] with [dirs] appended to its PATH. On Windows the existing key
/// (`Path` or `PATH`) is reused, since names are case-insensitive there. Pure.
Map<String, String> withExtraPath(Map<String, String> env, List<String> dirs, {required bool windows}) {
  final copy = Map<String, String>.of(env);
  final key = windows
      ? copy.keys.firstWhere((k) => k.toUpperCase() == 'PATH', orElse: () => 'PATH')
      : 'PATH';
  copy[key] = appendToPath(copy[key], dirs, windows ? ';' : ':');
  return copy;
}

/// The data of the first `REG_SZ` / `REG_EXPAND_SZ` value in `reg query … /v <name>` output,
/// or null. Pure. See spec/features/onboarding.md "Fresh PATH on Windows".
String? parseRegQueryValue(String output) {
  final value = RegExp(r'^\s+\S+\s+REG_(?:EXPAND_)?SZ\s+(.*)$');
  for (final line in output.split(RegExp(r'\r?\n'))) {
    final m = value.firstMatch(line);
    if (m != null) return m.group(1)!.trim();
  }
  return null;
}

/// [value] with `%NAME%` replaced from [env] (names case-insensitive, as on Windows);
/// unknown names are left as they are. Pure.
String expandWindowsVariables(String value, Map<String, String> env) {
  final upper = {for (final e in env.entries) e.key.toUpperCase(): e.value};
  return value.replaceAllMapped(RegExp('%([^%]+)%'), (m) => upper[m.group(1)!.toUpperCase()] ?? m.group(0)!);
}
