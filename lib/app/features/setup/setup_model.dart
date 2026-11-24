import 'package:flutter/foundation.dart';

import '../../utils/exception.dart';
import '../errors/errors_model.dart';

/// Something ADB UI needs or can use. See spec/features/onboarding.md.
enum Requirement {
  adb('adb (Android SDK Platform-Tools)', "Talks to your phones. ADB UI can't work without it.", true),
  scrcpy('scrcpy', 'Live screen mirror. Without it, the mirror uses screenshots.', false),
  libmpv('libmpv', 'Plays the live mirror video inside ADB UI.', false),
  aiModel('AI log-filter model', 'Turns plain-English questions into logcat filters, on this computer.', false);

  const Requirement(this.label, this.purpose, this.required);
  final String label;
  final String purpose;
  final bool required;

  /// Short name for toasts and titles.
  String get shortName => switch (this) {
        Requirement.adb => 'adb',
        Requirement.scrcpy => 'scrcpy',
        Requirement.libmpv => 'libmpv',
        Requirement.aiModel => 'the AI model',
      };
}

enum HostOs { macos, windows, linux }

enum PackageManager {
  brew('brew', 'Homebrew'),
  winget('winget', 'winget'),
  apt('apt-get', 'apt'),
  dnf('dnf', 'dnf'),
  pacman('pacman', 'pacman'),
  zypper('zypper', 'zypper');

  const PackageManager(this.executable, this.label);
  final String executable;
  final String label;

  /// Linux package managers need root.
  bool get needsRoot => this != brew && this != winget;

  /// Detection order per OS; the first one found is used.
  static List<PackageManager> candidatesFor(HostOs os) => switch (os) {
        HostOs.macos => const [brew],
        HostOs.windows => const [winget],
        HostOs.linux => const [apt, dnf, pacman, zypper],
      };
}

/// What the installer knows about this computer.
@immutable
class HostInfo {
  const HostInfo({
    required this.os,
    required this.arch,
    this.managers = const [],
    this.hasPkexec = false,
  });

  final HostOs os;

  /// `x86_64`, `arm64` or `x86`.
  final String arch;

  /// Package managers found, in detection order.
  final List<PackageManager> managers;
  final bool hasPkexec;

  PackageManager? get manager => managers.isEmpty ? null : managers.first;

  List<Requirement> get requirements => [
        Requirement.adb,
        Requirement.scrcpy,
        if (os == HostOs.linux) Requirement.libmpv,
        Requirement.aiModel,
      ];
}

/// Result of detecting one requirement.
@immutable
class ToolStatus {
  const ToolStatus.checking()
      : checked = false,
        found = false,
        version = null,
        path = null,
        managedByApp = false;
  const ToolStatus.missing()
      : checked = true,
        found = false,
        version = null,
        path = null,
        managedByApp = false;
  const ToolStatus.found({this.version, this.path, this.managedByApp = false})
      : checked = true,
        found = true;

  final bool checked;
  final bool found;
  final String? version;
  final String? path;

  /// Installed into ADB UI's own tools folder.
  final bool managedByApp;
}

/// Where a download comes from and how it is checked.
enum DownloadSource { googlePlatformTools, scrcpyGithub }

/// One way to install a requirement.
@immutable
sealed class InstallMethod {
  const InstallMethod();
}

class PackageManagerInstall extends InstallMethod {
  const PackageManagerInstall(this.manager, this.arguments);
  final PackageManager manager;
  final List<String> arguments;

  bool get needsRoot => manager.needsRoot;

  /// The command as shown to the user (without pkexec).
  String get command => [manager.executable, ...arguments].join(' ');

  @override
  bool operator ==(Object other) =>
      other is PackageManagerInstall && other.manager == manager && listEquals(other.arguments, arguments);

  @override
  int get hashCode => Object.hash(manager, Object.hashAll(arguments));

  @override
  String toString() => 'PackageManagerInstall($command)';
}

class DownloadInstall extends InstallMethod {
  const DownloadInstall(this.source);
  final DownloadSource source;

  @override
  bool operator ==(Object other) => other is DownloadInstall && other.source == source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() => 'DownloadInstall($source)';
}

class ManualInstall extends InstallMethod {
  const ManualInstall(this.text);
  final String text;

  @override
  bool operator ==(Object other) => other is ManualInstall && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A resolved download: URL, expected checksum and size.
@immutable
class DownloadTarget {
  const DownloadTarget({
    required this.url,
    required this.checksum,
    required this.algorithm,
    this.size,
    this.version,
  });

  final String url;
  final String checksum;

  /// `sha1` or `sha256`.
  final String algorithm;
  final int? size;
  final String? version;

  String get fileName => Uri.parse(url).pathSegments.last;
}

enum SetupMode { firstRun, adbMissing, manual }

@immutable
class SetupState {
  const SetupState({
    this.host,
    this.statuses = const {},
    this.running,
    this.log = const [],
    this.errors = const {},
    this.progress,
  });

  final HostInfo? host;
  final Map<Requirement, ToolStatus> statuses;

  /// The requirement being installed now, if any.
  final Requirement? running;

  /// Output of the current/last install.
  final List<String> log;
  final Map<Requirement, AppError> errors;

  /// Download progress 0–1 of the running install, if known.
  final double? progress;

  ToolStatus statusOf(Requirement r) => statuses[r] ?? const ToolStatus.checking();

  bool get requiredReady => statusOf(Requirement.adb).found;

  SetupState copyWith({
    HostInfo? host,
    Map<Requirement, ToolStatus>? statuses,
    Requirement? running,
    bool clearRunning = false,
    List<String>? log,
    Map<Requirement, AppError>? errors,
    double? progress,
    bool clearProgress = false,
  }) =>
      SetupState(
        host: host ?? this.host,
        statuses: statuses ?? this.statuses,
        running: clearRunning ? null : (running ?? this.running),
        log: log ?? this.log,
        errors: errors ?? this.errors,
        progress: clearProgress ? null : (progress ?? this.progress),
      );
}

/// A package manager exited with a non-zero code.
class InstallFailedException extends AppException {
  InstallFailedException(this.requirement, this.exitCode, this.output, {this.viaPkexec = false})
      : super("Couldn't install ${requirement.shortName} (exit code $exitCode)\n$output");
  final Requirement requirement;
  final int exitCode;
  final String output;
  final bool viaPkexec;

  /// pkexec: 126 = not authorised / dismissed, 127 = authentication failed.
  bool get permissionDenied => viaPkexec && (exitCode == 126 || exitCode == 127);
}

class DownloadFailedException extends AppException {
  DownloadFailedException(this.requirement, this.url, this.reason)
      : super("Couldn't download ${requirement.shortName} from $url: $reason");
  final Requirement requirement;
  final String url;
  final String reason;
}

class ChecksumMismatchException extends AppException {
  ChecksumMismatchException(this.url, this.expected, this.actual)
      : super('Checksum mismatch for $url\nexpected $expected\ngot      $actual');
  final String url;
  final String expected;
  final String actual;
}

// ── Parsers (pure, unit tested) ──────────────────────────────────────────────

/// `adb version` output.
({String adb, String? platformTools, String? path})? parseAdbVersion(String output) {
  final adb = RegExp(r'Android Debug Bridge version\s+(\S+)').firstMatch(output);
  if (adb == null) return null;
  final tools = RegExp(r'^Version\s+(\S+)', multiLine: true).firstMatch(output);
  final path = RegExp(r'^Installed as\s+(.+)$', multiLine: true).firstMatch(output);
  return (
    adb: adb.group(1)!,
    platformTools: tools?.group(1),
    path: path?.group(1)?.trim(),
  );
}

/// `scrcpy --version` output, e.g. `scrcpy 3.1 <https://github.com/Genymobile/scrcpy>`.
String? parseScrcpyVersion(String output) =>
    RegExp(r'^scrcpy\s+v?(\d[\w.\-]*)', multiLine: true).firstMatch(output)?.group(1);

/// `ldconfig -p` output → the libmpv soname, e.g. `libmpv.so.2`.
String? parseLibmpv(String output) =>
    RegExp(r'^\s*(libmpv\.so(?:\.\d+)*)\s', multiLine: true).firstMatch(output)?.group(1);

/// The checksum for [fileName] from a `SHA256SUMS.txt` (`<hash>  <name>` or `<hash> *<name>`).
String? parseSha256Sums(String text, String fileName) {
  for (final line in text.split(RegExp(r'\r?\n'))) {
    final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+?)\s*$').firstMatch(line);
    if (m != null && m.group(2) == fileName) return m.group(1)!.toLowerCase();
  }
  return null;
}

/// Picks the stable Platform-Tools archive for [os] out of Google's `repository2-3.xml`.
DownloadTarget? parsePlatformToolsRepository(String xml, HostOs os) {
  final hostOs = switch (os) {
    HostOs.macos => 'macosx',
    HostOs.windows => 'windows',
    HostOs.linux => 'linux',
  };
  final packages = RegExp(
    r'<remotePackage\s+path="platform-tools">(.*?)</remotePackage>',
    dotAll: true,
  ).allMatches(xml);
  for (final pkg in packages) {
    final body = pkg.group(1)!;
    final channel = RegExp(r'<channelRef\s+ref="([^"]+)"').firstMatch(body)?.group(1);
    if (channel != null && channel != 'channel-0') continue;
    String? num(String tag) => RegExp('<$tag>(\\d+)</$tag>').firstMatch(body)?.group(1);
    final version = [num('major'), num('minor'), num('micro')].whereType<String>().join('.');
    for (final archive in RegExp(r'<archive>(.*?)</archive>', dotAll: true).allMatches(body)) {
      final a = archive.group(1)!;
      if (RegExp('<host-os>$hostOs</host-os>').hasMatch(a)) {
        final url = RegExp(r'<url>([^<]+)</url>').firstMatch(a)?.group(1);
        final sha1 = RegExp(r'<checksum type="sha1">([0-9a-fA-F]{40})</checksum>').firstMatch(a)?.group(1);
        final size = int.tryParse(RegExp(r'<size>(\d+)</size>').firstMatch(a)?.group(1) ?? '');
        if (url == null || sha1 == null) continue;
        // Only plain file names: the URL is always resolved against Google's repository.
        if (url.contains('/') || url.contains('..')) continue;
        return DownloadTarget(
          url: 'https://dl.google.com/android/repository/$url',
          checksum: sha1.toLowerCase(),
          algorithm: 'sha1',
          size: size,
          version: version.isEmpty ? null : version,
        );
      }
    }
  }
  return null;
}

/// The scrcpy release asset name prefix for this OS / CPU, or null when scrcpy ships none.
String? scrcpyAssetPrefix(HostOs os, String arch) => switch (os) {
      HostOs.macos => arch == 'arm64' ? 'scrcpy-macos-aarch64-' : 'scrcpy-macos-x86_64-',
      HostOs.windows => switch (arch) {
          'arm64' => 'scrcpy-winarm64-',
          'x86' => 'scrcpy-win32-',
          _ => 'scrcpy-win64-',
        },
      HostOs.linux => arch == 'x86_64' ? 'scrcpy-linux-x86_64-' : null,
    };

/// Picks the release asset for this host out of [names].
String? selectScrcpyAsset(Iterable<String> names, HostOs os, String arch) {
  final prefix = scrcpyAssetPrefix(os, arch);
  if (prefix == null) return null;
  for (final n in names) {
    if (n.startsWith(prefix) && (n.endsWith('.zip') || n.endsWith('.tar.gz'))) return n;
  }
  return null;
}

/// First non-empty line of `command -v` / `where` output (where lists every match). Pure.
String? firstPathLine(String output) {
  for (final line in output.split(RegExp(r'\r?\n'))) {
    final t = line.trim();
    if (t.isNotEmpty) return t;
  }
  return null;
}
