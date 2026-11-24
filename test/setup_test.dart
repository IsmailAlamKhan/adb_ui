import 'package:adb_ui/app/features/adb/adb_service.dart';
import 'package:adb_ui/app/features/errors/errors.dart';
import 'package:adb_ui/app/features/setup/install_planner.dart';
import 'package:adb_ui/app/features/setup/setup_model.dart';
import 'package:adb_ui/app/features/setup/tool_paths.dart';
import 'package:flutter_test/flutter_test.dart';

const _repositoryXml = '''
<sdk:sdk-repository>
  <remotePackage path="platform-tools">
    <revision><major>38</major><minor>0</minor><micro>0</micro><preview>1</preview></revision>
    <channelRef ref="channel-2"/>
    <archives>
      <archive><complete><size>1</size><checksum type="sha1">1111111111111111111111111111111111111111</checksum><url>platform-tools_r38.0.0-rc1-darwin.zip</url></complete><host-os>macosx</host-os></archive>
    </archives>
  </remotePackage>
  <remotePackage path="platform-tools">
    <type-details xsi:type="generic:genericDetailsType"/>
    <revision><major>37</major><minor>0</minor><micro>3</micro></revision>
    <display-name>Android SDK Platform-Tools</display-name>
    <channelRef ref="channel-0"/>
    <archives>
      <archive><complete><size>9571024</size><checksum type="sha1">e1579b288a7ae4e9bc28dedec6a154d78b3c04ed</checksum><url>platform-tools_r37.0.3-linux.zip</url></complete><host-os>linux</host-os></archive>
      <archive><complete><size>16597626</size><checksum type="sha1">D48920E2650321710B4D15D3ACD9E277D59CD55B</checksum><url>platform-tools_r37.0.3-darwin.zip</url></complete><host-os>macosx</host-os></archive>
      <archive><complete><size>8188601</size><checksum type="sha1">7fea85bc18d0480bc81d3603952d666f49496e5a</checksum><url>platform-tools_r37.0.3-win.zip</url></complete><host-os>windows</host-os></archive>
    </archives>
  </remotePackage>
  <remotePackage path="emulator">
    <archives><archive><complete><size>2</size><checksum type="sha1">2222222222222222222222222222222222222222</checksum><url>emulator-darwin.zip</url></complete><host-os>macosx</host-os></archive></archives>
  </remotePackage>
</sdk:sdk-repository>
''';

void main() {
  group('parsers', () {
    test('adb version', () {
      const out = 'Android Debug Bridge version 1.0.41\n'
          'Version 37.0.3-14177519\n'
          'Installed as /opt/homebrew/bin/adb\n'
          'Running on Darwin 25.0.0 (arm64)\n';
      final v = parseAdbVersion(out)!;
      expect(v.adb, '1.0.41');
      expect(v.platformTools, '37.0.3-14177519');
      expect(v.path, '/opt/homebrew/bin/adb');
      expect(parseAdbVersion('Android Debug Bridge version 1.0.39\n')!.platformTools, isNull);
      expect(parseAdbVersion('zsh: command not found: adb'), isNull);
    });

    test('scrcpy version', () {
      expect(parseScrcpyVersion('scrcpy 3.1 <https://github.com/Genymobile/scrcpy>\n\nDependencies'), '3.1');
      expect(parseScrcpyVersion('scrcpy v5.0.1 <https://…>'), '5.0.1');
      expect(parseScrcpyVersion('command not found'), isNull);
    });

    test('libmpv from ldconfig -p', () {
      const out = '1532 libs found in cache `/etc/ld.so.cache\'\n'
          '\tlibmpv.so.2 (libc6,x86-64) => /lib/x86_64-linux-gnu/libmpv.so.2\n'
          '\tlibm.so.6 (libc6,x86-64) => /lib/x86_64-linux-gnu/libm.so.6\n';
      expect(parseLibmpv(out), 'libmpv.so.2');
      expect(parseLibmpv('\tlibm.so.6 (libc6,x86-64) => /lib/libm.so.6\n'), isNull);
    });

    test('SHA256SUMS.txt', () {
      const sums = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  scrcpy-server-v5.0.1\r\n'
          'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB *scrcpy-macos-aarch64-v5.0.1.tar.gz\n';
      expect(parseSha256Sums(sums, 'scrcpy-macos-aarch64-v5.0.1.tar.gz'), 'b' * 64);
      expect(parseSha256Sums(sums, 'scrcpy-server-v5.0.1'), 'a' * 64);
      expect(parseSha256Sums(sums, 'scrcpy-win64-v5.0.1.zip'), isNull);
    });

    test('Platform-Tools from the repository index (stable channel only)', () {
      final mac = parsePlatformToolsRepository(_repositoryXml, HostOs.macos)!;
      expect(mac.url, 'https://dl.google.com/android/repository/platform-tools_r37.0.3-darwin.zip');
      expect(mac.checksum, 'd48920e2650321710b4d15d3acd9e277d59cd55b');
      expect(mac.algorithm, 'sha1');
      expect(mac.size, 16597626);
      expect(mac.version, '37.0.3');
      expect(parsePlatformToolsRepository(_repositoryXml, HostOs.windows)!.url, endsWith('r37.0.3-win.zip'));
      expect(parsePlatformToolsRepository(_repositoryXml, HostOs.linux)!.checksum,
          'e1579b288a7ae4e9bc28dedec6a154d78b3c04ed');
      expect(parsePlatformToolsRepository('<sdk/>', HostOs.linux), isNull);
    });

    test('Platform-Tools URL must be a plain file name', () {
      final evil = _repositoryXml.replaceAll('platform-tools_r37.0.3-linux.zip', '../evil/linux.zip');
      expect(parsePlatformToolsRepository(evil, HostOs.linux), isNull);
    });

    test('scrcpy release asset', () {
      const names = [
        'scrcpy-linux-x86_64-v5.0.1.tar.gz',
        'scrcpy-macos-aarch64-v5.0.1.tar.gz',
        'scrcpy-macos-x86_64-v5.0.1.tar.gz',
        'scrcpy-server-v5.0.1',
        'scrcpy-win32-v5.0.1.zip',
        'scrcpy-win64-v5.0.1.zip',
        'scrcpy-winarm64-v5.0.1.zip',
        'SHA256SUMS.txt',
      ];
      expect(selectScrcpyAsset(names, HostOs.macos, 'arm64'), 'scrcpy-macos-aarch64-v5.0.1.tar.gz');
      expect(selectScrcpyAsset(names, HostOs.macos, 'x86_64'), 'scrcpy-macos-x86_64-v5.0.1.tar.gz');
      expect(selectScrcpyAsset(names, HostOs.windows, 'x86_64'), 'scrcpy-win64-v5.0.1.zip');
      expect(selectScrcpyAsset(names, HostOs.windows, 'arm64'), 'scrcpy-winarm64-v5.0.1.zip');
      expect(selectScrcpyAsset(names, HostOs.linux, 'x86_64'), 'scrcpy-linux-x86_64-v5.0.1.tar.gz');
      expect(selectScrcpyAsset(names, HostOs.linux, 'arm64'), isNull);
    });

    test('shell "command not found"', () {
      expect(isCommandNotFound('/bin/sh: adb: command not found', 127), isTrue);
      expect(isCommandNotFound('sh: 1: adb: not found', 127), isTrue);
      expect(isCommandNotFound("'adb' is not recognized as an internal or external command,", 1), isTrue);
      expect(isCommandNotFound('* daemon not running; starting now', 0), isFalse);
    });
  });

  group('InstallPlanner', () {
    HostInfo host(HostOs os, [List<PackageManager> m = const [], String arch = 'x86_64']) =>
        HostInfo(os: os, arch: arch, managers: m, hasPkexec: os == HostOs.linux);

    test('macOS with Homebrew: brew first, download as alternative', () {
      final adb = InstallPlanner.plansFor(Requirement.adb, host(HostOs.macos, [PackageManager.brew]));
      expect(adb.first, const PackageManagerInstall(PackageManager.brew, ['install', '--cask', 'android-platform-tools']));
      expect(adb.last, const DownloadInstall(DownloadSource.googlePlatformTools));
      final scrcpy = InstallPlanner.plansFor(Requirement.scrcpy, host(HostOs.macos, [PackageManager.brew], 'arm64'));
      expect((scrcpy.first as PackageManagerInstall).command, 'brew install scrcpy');
      expect((scrcpy.first as PackageManagerInstall).needsRoot, isFalse);
    });

    test('no package manager: download only', () {
      expect(InstallPlanner.plansFor(Requirement.adb, host(HostOs.macos)),
          [const DownloadInstall(DownloadSource.googlePlatformTools)]);
      expect(InstallPlanner.plansFor(Requirement.scrcpy, host(HostOs.windows)),
          [const DownloadInstall(DownloadSource.scrcpyGithub)]);
    });

    test('Windows winget accepts agreements non-interactively', () {
      final m = InstallPlanner.plansFor(Requirement.adb, host(HostOs.windows, [PackageManager.winget])).first
          as PackageManagerInstall;
      expect(m.command, startsWith('winget install --id Google.PlatformTools -e'));
      expect(m.arguments, containsAll(['--accept-package-agreements', '--disable-interactivity']));
      expect(m.needsRoot, isFalse);
    });

    test('Linux package managers need root and use the right package names', () {
      String cmd(Requirement r, PackageManager m) =>
          (InstallPlanner.plansFor(r, host(HostOs.linux, [m])).first as PackageManagerInstall).command;
      expect(cmd(Requirement.adb, PackageManager.apt), 'apt-get install -y adb');
      expect(cmd(Requirement.adb, PackageManager.dnf), 'dnf install -y android-tools');
      expect(cmd(Requirement.adb, PackageManager.pacman), 'pacman -S --noconfirm android-tools');
      expect(cmd(Requirement.adb, PackageManager.zypper), 'zypper --non-interactive install android-tools');
      expect(cmd(Requirement.libmpv, PackageManager.apt), 'apt-get install -y libmpv2');
      expect(cmd(Requirement.libmpv, PackageManager.dnf), 'dnf install -y mpv-libs');
      expect(cmd(Requirement.libmpv, PackageManager.pacman), 'pacman -S --noconfirm mpv');
      expect(PackageManager.apt.needsRoot, isTrue);
    });

    test('Fedora has no scrcpy package: download instead', () {
      expect(InstallPlanner.plansFor(Requirement.scrcpy, host(HostOs.linux, [PackageManager.dnf])),
          [const DownloadInstall(DownloadSource.scrcpyGithub)]);
      // No Linux arm64 scrcpy build either.
      expect(InstallPlanner.plansFor(Requirement.scrcpy, host(HostOs.linux, [PackageManager.dnf], 'arm64')), isEmpty);
    });

    test('libmpv without a package manager is manual; AI model has no plan', () {
      expect(InstallPlanner.plansFor(Requirement.libmpv, host(HostOs.linux)).single, isA<ManualInstall>());
      expect(InstallPlanner.plansFor(Requirement.aiModel, host(HostOs.macos, [PackageManager.brew])), isEmpty);
    });

    test('requirements per OS', () {
      expect(host(HostOs.linux).requirements, contains(Requirement.libmpv));
      expect(host(HostOs.macos).requirements, isNot(contains(Requirement.libmpv)));
    });
  });

  group('PATH', () {
    test('appendToPath keeps order and skips duplicates', () {
      expect(appendToPath('/usr/bin:/bin', ['/opt/a', '/usr/bin/', '/opt/a'], ':'), '/usr/bin:/bin:/opt/a');
      expect(appendToPath(null, ['/opt/a'], ':'), '/opt/a');
      expect(appendToPath(r'C:\Windows;C:\Tools', [r'c:\tools\', r'C:\New'], ';'), r'C:\Windows;C:\Tools;C:\New');
    });

    test('withExtraPath reuses the Windows Path key', () {
      final env = withExtraPath({'Path': r'C:\Windows', 'HOME': 'x'}, [r'C:\adb'], windows: true);
      expect(env['Path'], r'C:\Windows;C:\adb');
      expect(env.containsKey('PATH'), isFalse);
      final unix = withExtraPath({'PATH': '/usr/bin'}, ['/tools'], windows: false);
      expect(unix['PATH'], '/usr/bin:/tools');
    });
  });

  group('ErrorCatalogue setup rows', () {
    test('install, permission, checksum, download', () {
      expect(ErrorCatalogue.explain(InstallFailedException(Requirement.scrcpy, 1, 'E: Unable to locate package')).kind,
          ErrorKind.setupInstall);
      final denied = ErrorCatalogue.explain(InstallFailedException(Requirement.adb, 126, '', viaPkexec: true));
      expect(denied.kind, ErrorKind.setupPermission);
      expect(denied.title, 'Administrator permission was not given');
      expect(ErrorCatalogue.explain(InstallFailedException(Requirement.adb, 126, '')).kind, ErrorKind.setupInstall);
      expect(ErrorCatalogue.explain(ChecksumMismatchException('https://dl.google.com/x.zip', 'a', 'b')).kind,
          ErrorKind.setupChecksum);
      final dl = ErrorCatalogue.explain(DownloadFailedException(Requirement.adb, 'https://dl.google.com/x', 'HTTP 404'));
      expect(dl.kind, ErrorKind.setupDownload);
      expect(dl.title, "Couldn't download adb");
    });
  });
}
