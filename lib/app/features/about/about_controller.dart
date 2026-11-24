import 'dart:io';
import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/utils.dart';
import '../features.dart';

final aboutControllerProvider =
    AsyncNotifierProvider.autoDispose<AboutController, AboutModel>(AboutController.new);

class AboutController extends AutoDisposeAsyncNotifier<AboutModel> with NavigationController {
  late PackageInfo? packageInfo;
  @override
  late EventBus eventBus;
  Device? device;

  @override
  FutureOr<AboutModel> build() {
    packageInfo = ref.read(packageInfoControllerProvider);
    eventBus = ref.read(eventBusProvider);
    device = ref.watch(deviceControllerProvider);
    return AboutModel.updateNotAvailable;
  }

  Future<void> reportBugOrFeatureRequest() async {
    final reportBugOrFeature = await showDialog<Map<String, bool>>(
      pageBuilder: (context) => const FeatureRequestOrBugReportDialog(),
    );
    if (reportBugOrFeature == null) return;

    final isBugReport = reportBugOrFeature['is_bug_report']!;
    if (isBugReport) {
      final addDeviceDetails = reportBugOrFeature['add_device_details']!;
      await reportBug(addDeviceDetails);
    } else {
      await featureRequest();
    }
  }

  String get _os => '${switch (Platform.operatingSystem) {
        'macos' => 'macOS',
        'windows' => 'Windows',
        'linux' => 'Linux',
        final other => other,
      }} ${Platform.operatingSystemVersion}';

  Future<String> _version() async =>
      packageInfo?.version ?? (await ref.read(packageInfoServiceProvider).getPackageInfo()).version;

  Future<void> featureRequest() async =>
      launchUrlString(featureIssueUrl(version: await _version(), os: _os));

  /// Saves the logs to Downloads, shows the zip, and opens a pre-filled bug issue with the
  /// setup and recent log lines. See spec/features/about-updates-reporting.md.
  Future<void> reportBug(bool addDeviceDetails) async {
    try {
      showLoading();
      final zip = await LogFile.instance.exportLogs(device: addDeviceDetails ? device : null);
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      final excerpt = logExcerpt(await LogFile.instance.recentLogLines(), home: home);
      final info = BugReportInfo(
        version: await _version(),
        os: _os,
        style: ref.read(settingsControllerProvider).style?.label,
        adbVersion: await ref.read(adbServiceProvider).adbVersion(),
        phone: await _phone(),
      );
      final name = zip.uri.pathSegments.last;
      hideLoading();
      await revealFile(zip.path);
      await launchUrlString(bugIssueUrl(info, name, excerpt));
      showSuccess(
        'Logs saved to Downloads',
        message: 'Drag $name onto the GitHub issue that just opened.',
        actions: [('Show file', () => revealFile(zip.path))],
      );
    } catch (e) {
      hideLoading();
      showError(e);
    }
  }

  Future<String?> _phone() async {
    final phone = ref.read(selectedDeviceProvider);
    if (phone == null) return null;
    String? android;
    try {
      android = (await ref.read(devicePropertiesProvider(phone).future)
              .timeout(const Duration(seconds: 3)))
          .androidVersion;
    } catch (_) {}
    return [
      phone.displayName,
      if (android != null) 'Android $android',
      phone.isWireless ? 'Wi-Fi' : 'USB',
    ].join(', ');
  }

  /// Shows [path] selected in Finder / Explorer, or opens its folder on Linux.
  static Future<void> revealFile(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      } else {
        await Process.run('xdg-open', [File(path).parent.path]);
      }
    } catch (_) {}
  }

  /// In-app changelog (bundled CHANGELOG-ALL.md). See spec/features/updates.md.
  void showChangelog() => ref.read(updateControllerProvider.notifier).showChangelog();

  void openGitHub() => launchUrl(Uri.parse(appRepoUrl));
}
