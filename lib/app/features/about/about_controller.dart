import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

part 'about_controller.g.dart';

@riverpod
class AboutController extends _$AboutController with NavigationController {
  late AboutService service;

  late PackageInfo? packageInfo;
  @override
  late EventBus eventBus;
  Device? device;

  @override
  FutureOr<AboutModel> build() {
    service = ref.read(aboutServiceProvider);
    packageInfo = ref.read(packageInfoControllerProvider);
    eventBus = ref.read(eventBusProvider);
    device = ref.watch(deviceControllerProvider);
    return service.checkUpdateAvailable();
  }

  Future<void> downloadUpdates() => service.downloadUpdates();

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
      showAlert(
        const Alert.success(
          title: 'Logs are successfully generated.',
          messege:
              'Please attact that file to the issue on the page that will be opened after this alert closes',
        ),
      );
      await Future.delayed(Alert.duration);
      launchUrlString(bugReportUrl);
    } on AppException catch (e) {
      hideLoading();
      showSnackbar(text: e.message);
    }
  }

  void showChangelog() => launchUrlString(changelogUrl);

  void openGitHub() => launchUrl(Uri.parse(appRepoUrl));
}
