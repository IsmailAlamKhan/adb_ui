import '../../shared/shared.dart';
import '../errors/errors.dart';

/// A release version (`1.2.3`), compared number by number. See spec/features/updates.md.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.parts);
  final List<int> parts;

  /// `v0.0.18`, `0.0.18`, `0.0.19-beta`, `1.2.3+4` → numbers; null when unparsable.
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    s = s.split(RegExp('[-+]')).first;
    if (s.isEmpty) return null;
    final parts = <int>[];
    for (final p in s.split('.')) {
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      parts.add(n);
    }
    return AppVersion(parts);
  }

  @override
  int compareTo(AppVersion other) {
    final length = parts.length > other.parts.length ? parts.length : other.parts.length;
    for (var i = 0; i < length; i++) {
      final a = i < parts.length ? parts[i] : 0;
      final b = i < other.parts.length ? other.parts[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) => other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hashAll(_trimmed);

  List<int> get _trimmed {
    var end = parts.length;
    while (end > 0 && parts[end - 1] == 0) {
      end--;
    }
    return parts.sublist(0, end);
  }

  @override
  String toString() => parts.join('.');
}

class InstallerAsset {
  const InstallerAsset({required this.name, required this.url, required this.size});
  final String name;
  final String url;
  final int size;
}

class AppRelease {
  const AppRelease({
    required this.version,
    required this.tag,
    required this.notes,
    this.assets = const [],
    this.draft = false,
    this.prerelease = false,
  });
  final AppVersion version;
  final String tag;

  /// Markdown body of the GitHub release (the CHANGELOG.md of that release).
  final String notes;
  final List<InstallerAsset> assets;
  final bool draft;
  final bool prerelease;

  /// This OS's installer (`*-setup-<os>.<ext>`), or null if it isn't uploaded.
  InstallerAsset? installerFor(String os) {
    final suffix = switch (os) {
      'macos' => '-setup-macos.dmg',
      'windows' => '-setup-windows.exe',
      'linux' => '-setup-linux.zip',
      _ => null,
    };
    if (suffix == null) return null;
    for (final a in assets) {
      if (a.name.endsWith(suffix)) return a;
    }
    return null;
  }
}

/// The newest stable release newer than [current] that has [os]'s installer.
AppRelease? pickUpdate(List<AppRelease> releases, AppVersion current, String os) {
  AppRelease? best;
  for (final r in releases) {
    if (r.draft || r.prerelease || !(r.version > current) || r.installerFor(os) == null) continue;
    if (best == null || r.version > best.version) best = r;
  }
  return best;
}

/// Releases newer than [current] up to and including [target], newest first.
List<AppRelease> releasesBetween(List<AppRelease> releases, AppVersion current, AppVersion target) {
  final list = releases
      .where((r) => !r.draft && !r.prerelease && r.version > current && !(r.version > target))
      .toList()
    ..sort((a, b) => b.version.compareTo(a.version));
  return list;
}

/// One `## <version>` section of a changelog.
class ChangelogEntry {
  const ChangelogEntry({required this.title, required this.lines});

  /// Heading text, e.g. `0.0.18` or `Unreleased`.
  final String title;

  /// Body lines without the heading; blank lines at either end removed.
  final List<String> lines;

  AppVersion? get version => AppVersion.tryParse(title);
}

/// Splits a changelog (`## <version>` headings) into entries, in file order.
List<ChangelogEntry> parseChangelog(String markdown) {
  final entries = <ChangelogEntry>[];
  String? title;
  var lines = <String>[];
  void flush() {
    if (title == null) return;
    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    entries.add(ChangelogEntry(title: title, lines: lines));
  }

  for (final line in markdown.replaceAll('\r\n', '\n').split('\n')) {
    final heading = RegExp(r'^##\s+(.+?)\s*$').firstMatch(line);
    if (heading != null) {
      flush();
      title = heading.group(1)!;
      lines = <String>[];
    } else if (title != null) {
      lines.add(line);
    }
  }
  flush();
  return entries;
}

/// Release notes body → lines, dropping a leading `## <version>` heading (the release
/// body is that version's CHANGELOG.md).
List<String> releaseNoteLines(String notes) {
  final entries = parseChangelog(notes);
  if (entries.isEmpty) {
    return notes.replaceAll('\r\n', '\n').trim().split('\n');
  }
  return [for (final e in entries) ...e.lines];
}

enum UpdateStatus { idle, checking, upToDate, available, downloading, ready, installing, failed }

/// See spec/features/updates.md.
class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.current,
    this.release,
    this.notes = const [],
    this.received = 0,
    this.total = 0,
    this.file,
    this.error,
  });

  final UpdateStatus status;
  final AppVersion? current;

  /// The update on offer.
  final AppRelease? release;

  /// Every release between [current] and [release], newest first.
  final List<AppRelease> notes;
  final int received;
  final int total;

  /// Downloaded installer path.
  final String? file;
  final AppError? error;

  bool get hasUpdate => release != null;

  UpdateState copyWith({
    UpdateStatus? status,
    AppVersion? current,
    AppRelease? release,
    List<AppRelease>? notes,
    int? received,
    int? total,
    String? file,
    AppError? error,
  }) =>
      UpdateState(
        status: status ?? this.status,
        current: current ?? this.current,
        release: release ?? this.release,
        notes: notes ?? this.notes,
        received: received ?? this.received,
        total: total ?? this.total,
        file: file ?? this.file,
        error: error ?? this.error,
      );
}

/// Saved under `LocalStorageKeys.updates`.
class UpdatePrefs with LocalStorageModel {
  const UpdatePrefs({this.skippedVersion, this.lastSeenVersion});
  final String? skippedVersion;
  final String? lastSeenVersion;

  static const initial = UpdatePrefs();

  factory UpdatePrefs.fromJson(Map<String, dynamic> json) => UpdatePrefs(
        skippedVersion: json['skippedVersion'] as String?,
        lastSeenVersion: json['lastSeenVersion'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        if (skippedVersion != null) 'skippedVersion': skippedVersion,
        if (lastSeenVersion != null) 'lastSeenVersion': lastSeenVersion,
      };

  UpdatePrefs copyWith({String? skippedVersion, String? lastSeenVersion}) => UpdatePrefs(
        skippedVersion: skippedVersion ?? this.skippedVersion,
        lastSeenVersion: lastSeenVersion ?? this.lastSeenVersion,
      );
}
