import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../adb/adb.dart';
import 'apps_controller.dart';
import 'apps_model.dart';

/// An app's real icon, or a letter tile while it loads or when it can't be loaded.
class AppIcon extends ConsumerWidget {
  const AppIcon({super.key, required this.device, required this.package, this.size = 32});
  final AdbDevice device;
  final String package;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appInfoProvider(device).select((map) => map[package]));
    final radius = BorderRadius.circular(size * 0.24);
    if (info?.icon != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.memory(info!.icon!, width: size, height: size, gaplessPlayback: true),
      );
    }
    return AppLetterTile(package: package, label: info?.label, size: size);
  }
}

/// Coloured tile with the app's first letter: the fallback for [AppIcon].
class AppLetterTile extends StatelessWidget {
  const AppLetterTile({super.key, required this.package, this.label, this.size = 32});
  final String package;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = appHue(package);
    final background = HSLColor.fromAHSL(1, hue, 0.45, dark ? 0.30 : 0.88).toColor();
    final foreground = HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.88 : 0.28).toColor();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.24)),
      child: Text(
        appLetter(package, label),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: size * 0.46, height: 1),
      ),
    );
  }
}

/// The app's label when known, else its package name.
String appDisplayName(WidgetRef ref, AdbDevice device, String package) =>
    ref.watch(appInfoProvider(device).select((map) => map[package]?.name)) ?? package;

/// Muted mono style for a package name shown under its label.
TextStyle packageTextStyle(BuildContext context) {
  final t = AppTokens.of(context);
  return AppThemeFactory.mono(t, size: 12, color: t.textMuted);
}
