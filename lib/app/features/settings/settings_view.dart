import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return AdaptiveDialog(
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          children: [
            ListTile(
              title: const Text('Theme mode'),
              subtitle: Text(state.themeMode.name.capitalizeFirst),
              trailing: PopupMenu<ThemeMode>(
                itemBuilder: (_) => ThemeMode.values
                    .map((e) => PopupMenuItem(value: e, child: Text(e.name.capitalizeFirst)))
                    .toList(),
                initialValue: state.themeMode,
                onSelected: (value) => controller.setThemeMode(value),
              ),
            ),
            ListTile(title: const Text('About app'), onTap: controller.aboutApp),
          ],
        ),
      ),
    );
  }
}
