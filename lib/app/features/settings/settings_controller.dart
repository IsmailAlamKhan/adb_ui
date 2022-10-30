import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsModel>(SettingsController.new);

class SettingsController extends StateNotifier<SettingsModel> with NavigationController {
  final SettingsService settingsService;
  @override
  final EventBus eventBus;
  SettingsController(Ref ref)
      : settingsService = ref.read(settingsServiceProvider),
        eventBus = ref.read(eventBusProvider),
        super(SettingsModel.initial);

  Future<void> init() async => state = await settingsService.init();

  Future<void> save(SettingsModel settings) async {
    await settingsService.save(settings);
    state = settings;
  }

  void setThemeMode(ThemeMode themeMode) => save(state.copyWith(themeMode: themeMode));

  void aboutApp() => adaptivePush((context) => const AboutView());
}
