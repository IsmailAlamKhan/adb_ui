import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../../shared/shared.dart';
import '../features.dart';

/// Settings: Appearance (style + theme) and About. ⌘/Ctrl+, opens it.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final style = state.style ?? AppStyle.workbench;
    return AdaptiveDialog(
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('Appearance', style: text.titleLarge),
            const SizedBox(height: 12),
            const SectionLabel('Style'),
            const SizedBox(height: 4),
            Text('Changes the whole layout. Your devices and activity stay the same.',
                style: TextStyle(color: t.textMuted)),
            const SizedBox(height: 10),
            StyleChooser(
              compact: true,
              selected: style,
              brightness: Theme.of(context).brightness,
              onChanged: controller.setStyle,
            ),
            const SizedBox(height: 10),
            Text(style.tagline, style: TextStyle(color: t.textMuted)),
            const SizedBox(height: 20),
            const SectionLabel('Theme'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ThemeModeChooser(value: state.themeMode, onChanged: controller.setThemeMode),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),
            Text('About', style: text.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const AppLogo(size: 28),
              title: const Text('About ADB UI'),
              subtitle: const Text('Version, changelog, report a bug'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: controller.aboutApp,
            ),
          ],
        ),
      ),
    );
  }
}
