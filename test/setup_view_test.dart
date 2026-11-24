import 'package:adb_ui/app/design/design.dart';
import 'package:adb_ui/app/features/features.dart';
import 'package:adb_ui/app/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSetupService implements SetupService {
  _FakeSetupService(this.hostInfo, this.statuses);
  final HostInfo hostInfo;
  final Map<Requirement, ToolStatus> statuses;

  @override
  Future<HostInfo> host() async => hostInfo;

  @override
  Future<ToolStatus> detect(Requirement r) async => statuses[r] ?? const ToolStatus.missing();

  @override
  Future<DownloadTarget> resolveDownload(Requirement r, DownloadSource source, HostInfo host) =>
      throw UnimplementedError();

  @override
  Future<void> runPackageManager(Requirement r, PackageManagerInstall method,
          {required void Function(String line) onOutput}) async {}

  @override
  Future<void> download(Requirement r, DownloadTarget target,
          {required void Function(String line) onOutput, void Function(double? progress)? onProgress}) async {}
}

Future<void> _pump(WidgetTester tester, SetupService service, SetupMode mode, {double width = 1000}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [setupServiceProvider.overrideWithValue(service)]);
  addTearDown(container.dispose);
  await container.read(localStorageProvider).init();
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppThemeFactory.build(AppStyle.workbench, Brightness.light),
      home: SetupView(mode: mode),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('adb missing on Linux with apt: Continue disabled, install methods shown', (tester) async {
    await _pump(
      tester,
      _FakeSetupService(
        const HostInfo(os: HostOs.linux, arch: 'x86_64', managers: [PackageManager.apt], hasPkexec: true),
        {Requirement.libmpv: const ToolStatus.found(version: 'libmpv.so.2')},
      ),
      SetupMode.adbMissing,
    );
    expect(find.text('Set up ADB UI'), findsOneWidget);
    expect(find.text("adb wasn't found"), findsOneWidget);
    expect(find.textContaining('Installs use apt'), findsOneWidget);
    expect(find.text('↳ sudo apt-get install -y adb'), findsOneWidget);
    expect(find.text('Install…'), findsWidgets);
    expect(find.text('Download instead'), findsWidgets);
    expect(find.text('Found · libmpv.so.2'), findsOneWidget);
    expect(find.text('Install required'), findsOneWidget);
    expect(find.text('1 required tool is missing'), findsOneWidget);
    expect(find.text('Required'), findsWidgets);
    final cont = tester.widget<FilledButton>(find.ancestor(of: find.text('Continue'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
    expect(cont.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first run on macOS, everything found, compact width', (tester) async {
    await _pump(
      tester,
      _FakeSetupService(
        const HostInfo(os: HostOs.macos, arch: 'arm64', managers: [PackageManager.brew]),
        {
          Requirement.adb: const ToolStatus.found(version: '37.0.3', path: '/opt/homebrew/bin/adb'),
          Requirement.scrcpy: const ToolStatus.found(version: '5.0.1', path: '/x/tools/scrcpy/scrcpy', managedByApp: true),
        },
      ),
      SetupMode.firstRun,
      width: 480,
    );
    expect(find.text('Found · 37.0.3'), findsOneWidget);
    expect(find.text('Installed by ADB UI · 5.0.1'), findsOneWidget);
    expect(find.text('libmpv'), findsNothing);
    expect(find.text('Install required'), findsNothing);
    expect(find.text('Get your tools ready'), findsOneWidget);
    expect(find.text('Everything ADB UI needs is ready'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 2 of 2: Tools'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<void> pumpDialog(WidgetTester tester, Widget dialog) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppThemeFactory.build(AppStyle.console, Brightness.dark),
      home: Scaffold(body: dialog),
    ));
  }

  testWidgets('consent for a root command offers Copy and pkexec, never sudo', (tester) async {
    await pumpDialog(
      tester,
      const InstallConsentDialog(
        requirement: Requirement.adb,
        method: PackageManagerInstall(PackageManager.apt, ['install', '-y', 'adb']),
        hasPkexec: true,
      ),
    );
    expect(find.text('Install adb?'), findsOneWidget);
    expect(find.text('This needs administrator rights'), findsOneWidget);
    expect(find.text('Copy command'), findsOneWidget);
    expect(find.text('Run with pkexec'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consent without pkexec only offers Copy', (tester) async {
    await pumpDialog(
      tester,
      const InstallConsentDialog(
        requirement: Requirement.libmpv,
        method: PackageManagerInstall(PackageManager.dnf, ['install', '-y', 'mpv-libs']),
      ),
    );
    expect(find.text('Run with pkexec'), findsNothing);
    expect(find.text('Copy command'), findsOneWidget);
  });

  testWidgets('consent for a download shows URL and checksum', (tester) async {
    await pumpDialog(
      tester,
      const InstallConsentDialog(
        requirement: Requirement.adb,
        method: DownloadInstall(DownloadSource.googlePlatformTools),
        target: DownloadTarget(
          url: 'https://dl.google.com/android/repository/platform-tools_r37.0.3-darwin.zip',
          checksum: 'd48920e2650321710b4d15d3acd9e277d59cd55b',
          algorithm: 'sha1',
          size: 16597626,
          version: '37.0.3',
        ),
      ),
    );
    expect(find.textContaining('platform-tools_r37.0.3-darwin.zip'), findsWidgets);
    expect(find.textContaining("SHA-1 d48920e2650321710b4d15d3acd9e277d59cd55b from Google's repository index"), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
