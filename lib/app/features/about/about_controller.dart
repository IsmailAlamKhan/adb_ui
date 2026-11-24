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

  Future<void> featureRequest() => launchUrlString(featureRequestUrl);

  Future<void> reportBug(bool addDeviceDetails) async {
    Device? device;
    if (addDeviceDetails == true) {
      device = this.device;
    }
    try {
      showLoading();
      await LogFile.instance.getAllLogsAndReset(device: device);
      hideLoading();
      showSuccess(
        'Log file saved',
        message: 'GitHub is opening. Attach the saved zip to the new issue.',
      );
      await launchUrlString(bugReportUrl);
    } catch (e) {
      hideLoading();
      showError(e);
    }
  }

  /// In-app changelog (bundled CHANGELOG-ALL.md). See spec/features/updates.md.
  void showChangelog() => ref.read(updateControllerProvider.notifier).showChangelog();

  void openGitHub() => launchUrl(Uri.parse(appRepoUrl));
}
