import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsModel>(SettingsController.new);

class SettingsController extends StateNotifier<SettingsModel> with NavigationController {
  final SettingsService settingsService;
  @override
  final EventBus eventBus;
  final Device? device;
  SettingsController(Ref ref)
      : settingsService = ref.read(settingsServiceProvider),
        eventBus = ref.read(eventBusProvider),
        device = ref.watch(deviceControllerProvider),
        super(SettingsModel.initial);

  Future<void> init() async => state = await settingsService.init();

  Future<void> save(SettingsModel settings) async {
    await settingsService.save(settings);
    state = settings;
  }

  void setThemeMode(ThemeMode themeMode) => save(state.copyWith(themeMode: themeMode));

  Future<void> reportBug() async {
    final addDeviceInfoToLog = await confirmDialog(
      (context) => 'Would you like to add the device info to logs?',
      cancelText: 'No',
      confirmText: 'Yes',
      title: 'Add device info',
    );
    Device? device;
    if (addDeviceInfoToLog == true) {
      device = this.device;
    }
    try {
      showLoading();
      await LogFile.instance.getAllLogsAndReset(device: device);
      hideLoading();
      showAlert(
        const Alert.success(
          title:
              'Logs are successfully generated please attact that file to the issue on the page that will be opened after this alert closes',
        ),
      );
      await Future.delayed(Alert.duration);
      launchUrl(Uri.parse(bugReportUrl));
    } on AppException catch (e) {
      hideLoading();
      showSnackbar(text: e.message);
    }
  }

  void goToGitHub() => launchUrl(Uri.parse(appRepoUrl));

  void goToAuthorGitHub() => launchUrl(Uri.parse(authorGitHubUrl));
}
