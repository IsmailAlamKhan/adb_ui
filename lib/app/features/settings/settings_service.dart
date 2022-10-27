import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  LocalStorageSettingsServiceImpl(Ref ref) : localStorage = ref.read(localStorageProvider);
  @override
  Future<SettingsModel> getSettings() => localStorage.get<SettingsModel>(
        LocalStorageKeys.settings,
        defaultValue: SettingsModel.initial,
        fromJson: SettingsModel.fromJson,
      );

  @override
  Future<SettingsModel> init() => getSettings();

  @override
  Future<void> save(SettingsModel settings) =>
      localStorage.set<SettingsModel>(LocalStorageKeys.settings, settings);
}
