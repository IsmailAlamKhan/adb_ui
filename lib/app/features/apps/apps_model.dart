import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

/// An installed app's real name and icon, from the on-device helper
/// (spec/features/app-icons.md). Both are null until loaded, or when the helper can't run.
@immutable
class AppInfo {
  const AppInfo(this.package, {this.label, this.icon});
  final String package;
  final String? label;
  final Uint8List? icon;

  /// The label when known, else the package name.
  String get name => (label == null || label!.isEmpty) ? package : label!;
}

/// Parses `pm list packages --show-versioncode` (`package:<name> versionCode:<n>`).
Map<String, int> parsePackageVersions(String output) {
  final versions = <String, int>{};
  for (final line in output.split('\n')) {
    final match = RegExp(r'^package:(\S+)\s+versionCode:(\d+)').firstMatch(line.trim());
    if (match != null) versions[match.group(1)!] = int.parse(match.group(2)!);
  }
  return versions;
}

/// One line of the helper's `info` command: `package \t label \t base64 PNG or -`.
/// Returns null for lines that aren't records.
AppInfo? parseHelperInfoLine(String line) {
  final parts = line.trimRight().split('\t');
  if (parts.length < 3 || parts[0].isEmpty || parts[0].contains(' ')) return null;
  Uint8List? icon;
  if (parts[2] != '-' && parts[2].isNotEmpty) {
    try {
      icon = base64Decode(parts[2]);
    } on FormatException {
      icon = null;
    }
  }
  final label = parts[1].trim();
  return AppInfo(parts[0], label: label.isEmpty ? null : label, icon: icon);
}

/// The letter shown on an app's fallback tile: first letter of the label, or of the
/// package's last meaningful segment.
String appLetter(String package, String? label) {
  final source = (label != null && label.trim().isNotEmpty)
      ? label.trim()
      : package.split('.').lastWhere((s) => s.isNotEmpty && s != 'android' && s != 'app', orElse: () => package);
  final letter = source.characters.isEmpty ? '?' : source.characters.first;
  return letter.toUpperCase();
}

/// A stable hue (0–360) for a package's fallback tile.
double appHue(String package) {
  var hash = 0;
  for (final unit in package.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return (hash % 360).toDouble();
}
