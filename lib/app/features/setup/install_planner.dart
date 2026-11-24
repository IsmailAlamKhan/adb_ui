import 'setup_model.dart';

/// Decides how each requirement can be installed on a host. Pure; see
/// spec/features/onboarding.md "Install methods".
class InstallPlanner {
  const InstallPlanner._();

  static const _wingetFlags = [
    '-e',
    '--source',
    'winget',
    '--accept-source-agreements',
    '--accept-package-agreements',
    '--disable-interactivity',
  ];

  /// Ways to install [r] on [host], best first. Empty when ADB UI can't install it
  /// (the AI model has its own card).
  static List<InstallMethod> plansFor(Requirement r, HostInfo host) {
    final manager = host.manager;
    final pm = manager == null ? null : _packageManagerInstall(r, manager);
    final download = _download(r, host);
    return [
      if (pm != null) pm,
      if (download != null) download,
      if (pm == null && download == null && r == Requirement.libmpv)
        const ManualInstall("Install libmpv with your system's package manager (libmpv2, mpv-libs or mpv)."),
    ];
  }

  static PackageManagerInstall? _packageManagerInstall(Requirement r, PackageManager m) {
    List<String>? linux(String? package) => package == null
        ? null
        : switch (m) {
            PackageManager.apt => ['install', '-y', package],
            PackageManager.dnf => ['install', '-y', package],
            PackageManager.pacman => ['-S', '--noconfirm', package],
            PackageManager.zypper => ['--non-interactive', 'install', package],
            _ => null,
          };

    final args = switch ((r, m)) {
      (Requirement.adb, PackageManager.brew) => ['install', '--cask', 'android-platform-tools'],
      (Requirement.scrcpy, PackageManager.brew) => ['install', 'scrcpy'],
      (Requirement.adb, PackageManager.winget) => ['install', '--id', 'Google.PlatformTools', ..._wingetFlags],
      (Requirement.scrcpy, PackageManager.winget) => ['install', '--id', 'Genymobile.scrcpy', ..._wingetFlags],
      (Requirement.adb, _) => linux(switch (m) {
          PackageManager.apt => 'adb',
          _ => 'android-tools',
        }),
      // Fedora ships scrcpy only in COPR, so dnf has no plan.
      (Requirement.scrcpy, _) => linux(m == PackageManager.dnf ? null : 'scrcpy'),
      (Requirement.libmpv, _) => linux(switch (m) {
          PackageManager.apt => 'libmpv2',
          PackageManager.dnf => 'mpv-libs',
          PackageManager.pacman => 'mpv',
          PackageManager.zypper => 'libmpv2',
          _ => null,
        }),
      _ => null,
    };
    if (args == null) return null;
    if (r == Requirement.libmpv && !m.needsRoot) return null;
    return PackageManagerInstall(m, args);
  }

  static DownloadInstall? _download(Requirement r, HostInfo host) => switch (r) {
        Requirement.adb => const DownloadInstall(DownloadSource.googlePlatformTools),
        Requirement.scrcpy when scrcpyAssetPrefix(host.os, host.arch) != null =>
          const DownloadInstall(DownloadSource.scrcpyGithub),
        _ => null,
      };
}

/// Appends [dirs] to a PATH value, skipping ones already there. Pure.
String appendToPath(String? path, List<String> dirs, String separator) {
  final parts = (path ?? '').split(separator).where((p) => p.isNotEmpty).toList();
  bool has(String dir) => parts.any((p) => _samePath(p, dir, separator == ';'));
  for (final d in dirs) {
    if (d.isNotEmpty && !has(d)) parts.add(d);
  }
  return parts.join(separator);
}

bool _samePath(String a, String b, bool windows) {
  String norm(String s) {
    var v = s.trim();
    while (v.length > 1 && (v.endsWith('/') || v.endsWith(r'\'))) {
      v = v.substring(0, v.length - 1);
    }
    return windows ? v.toLowerCase() : v;
  }

  return norm(a) == norm(b);
}
