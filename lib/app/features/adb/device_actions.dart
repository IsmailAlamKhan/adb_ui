import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// Everything that can be done to a selected device. Every style renders this list
/// (tiles, palette rows, menus) so behaviour and shortcuts stay the same.
enum DeviceAction {
  installApk(Icons.download_rounded, 'Install APK', 'adb install', LogicalKeyboardKey.keyI),
  uninstallApp(Icons.delete_outline_rounded, 'Uninstall app', 'adb uninstall', LogicalKeyboardKey.keyU),
  pushFiles(Icons.upload_file_rounded, 'Push files', 'adb push', LogicalKeyboardKey.keyP),
  pullFiles(Icons.file_download_rounded, 'Pull files', 'adb pull', LogicalKeyboardKey.keyP, shift: true),
  logcat(Icons.subject_rounded, 'Logcat', 'adb logcat', LogicalKeyboardKey.keyL),
  runCommand(Icons.terminal_rounded, 'Run command', 'adb shell', LogicalKeyboardKey.keyR),
  typeText(Icons.keyboard_rounded, 'Type text', 'input text', LogicalKeyboardKey.keyT),
  mirror(Icons.cast_rounded, 'Mirror screen', 'scrcpy', LogicalKeyboardKey.keyM, shift: true),
  copyId(Icons.content_copy_rounded, 'Copy device id', 'serial', LogicalKeyboardKey.keyC, shift: true),
  disconnect(Icons.link_off_rounded, 'Disconnect', 'adb disconnect', LogicalKeyboardKey.keyD, shift: true);

  const DeviceAction(this.icon, this.label, this.command, this.key, {this.shift = false});

  final IconData icon;
  final String label;

  /// The adb command it runs, shown next to the label.
  final String command;
  final LogicalKeyboardKey key;
  final bool shift;

  SingleActivator get shortcut => platformShortcut(key, shift: shift);
  String get shortcutText => shortcutLabel(shortcut);

  bool get destructive => this == uninstallApp || this == disconnect;

  /// Why the action can't run on [device], or null when it can.
  String? unavailableReason(AdbDevice device, {required bool scrcpyAvailable}) {
    if (this == copyId) return null;
    if (this == disconnect) return device.isWireless ? null : 'Only Wi-Fi devices can be disconnected';
    if (!device.isOnline) return 'The device is ${device.state.label.toLowerCase()}';
    return null;
  }

  Future<void> perform(WidgetRef ref, AdbDevice device) {
    final adb = ref.read(adbControllerProvider);
    return switch (this) {
      installApk => adb.installApk(device),
      uninstallApp => adb.uninstallApp(device),
      pushFiles => adb.pushFile(device),
      pullFiles => adb.pullFile(device),
      logcat => adb.openLogcat(device),
      runCommand => adb.runCommand(device),
      typeText => adb.inputText(device),
      mirror => adb.openMirror(device),
      copyId => Future.sync(() => adb.copyId(device)),
      disconnect => adb.disconnect(device),
    };
  }
}

/// App-wide shortcuts: device actions on the selected device, palette, add device, settings.
class AppShortcuts extends ConsumerWidget {
  const AppShortcuts({super.key, required this.child});
  final Widget child;

  static final palette = platformShortcut(LogicalKeyboardKey.keyK);
  static final addDevice = platformShortcut(LogicalKeyboardKey.keyN);
  static final settings = platformShortcut(LogicalKeyboardKey.comma);
  static final activity = platformShortcut(LogicalKeyboardKey.keyA, shift: true);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adb = ref.read(adbControllerProvider);
    void onDevice(DeviceAction action) {
      final device = ref.read(selectedDeviceProvider);
      if (device == null) {
        adb.showToast(
          tone: ToastTone.info,
          title: 'Connect a device first',
          actions: [('Add device', adb.addDevice)],
        );
        return;
      }
      final scrcpy = ref.read(scrcpyAvailableProvider).valueOrNull ?? false;
      final reason = action.unavailableReason(device, scrcpyAvailable: scrcpy);
      if (reason != null) {
        adb.showToast(tone: ToastTone.info, title: "Can't ${action.label.toLowerCase()}", message: reason);
        return;
      }
      action.perform(ref, device);
    }

    return CallbackShortcuts(
      bindings: {
        palette: adb.openPalette,
        addDevice: adb.addDevice,
        settings: adb.openSettings,
        activity: adb.openActivity,
        for (final action in DeviceAction.values) action.shortcut: () => onDevice(action),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
