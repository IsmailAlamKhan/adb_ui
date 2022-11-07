import 'package:github/github.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/shared.dart';
import '../features.dart';

final settingsServiceProvider = Provider<SettingsService>(LocalStorageSettingsServiceImpl.new);

abstract class SettingsService {
  Future<SettingsModel> init();
  Future<void> save(SettingsModel settings);
  Future<SettingsModel> getSettings();
}

class LocalStorageSettingsServiceImpl extends SettingsService {
  final LocalStorage localStorage;
  final PackageInfo? packageInfo;
  final GitHub github;
  LocalStorageSettingsServiceImpl(Ref ref)
      : localStorage = ref.read(localStorageProvider),
        packageInfo = ref.watch(packageInfoControllerProvider),
        github = ref.read(githubProvider);
  @override
  Future<SettingsModel> getSettings() => localStorage.get<SettingsModel>(
        LocalStorageKeys.settings,
        defaultValue: SettingsModel.initial,
        fromJson: (json) => SettingsModel.fromJson(json),
      );

  @override
  Future<SettingsModel> init() => getSettings();

  @override
  Future<void> save(SettingsModel settings) =>
      localStorage.set<SettingsModel>(LocalStorageKeys.settings, settings);
}
