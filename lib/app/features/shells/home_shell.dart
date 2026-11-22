import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// Home in the user's style, with app shortcuts and drop-an-APK-anywhere (U8, U9).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(settingsControllerProvider.select((s) => s.style)) ?? AppStyle.workbench;
    final child = switch (style) {
      AppStyle.workbench => const WorkbenchHome(),
      AppStyle.console => const ConsoleHome(),
      AppStyle.launcher => const LauncherHome(),
    };
    return AppShortcuts(child: ApkDropZone(child: child));
  }
}

/// Installs `.apk` files dropped anywhere on the window on the selected device.
/// Areas that take drops themselves (the Files tab) register with [ApkDropZone.exclude].
class ApkDropZone extends HookConsumerWidget {
  const ApkDropZone({super.key, required this.child});
  final Widget child;

  static final _excluded = <GlobalKey>{};

  /// Keeps drops inside [key]'s widget for that widget.
  static void exclude(GlobalKey key) => _excluded.add(key);
  static void include(GlobalKey key) => _excluded.remove(key);

  static bool _isExcluded(Offset globalPosition) {
    for (final key in _excluded) {
      final box = key.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (rect.contains(globalPosition)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragging = useState(false);
    final device = ref.watch(selectedDeviceProvider);
    final t = AppTokens.of(context);
    return DropTarget(
      onDragEntered: (d) => dragging.value = !_isExcluded(d.globalPosition),
      onDragUpdated: (d) => dragging.value = !_isExcluded(d.globalPosition),
      onDragExited: (_) => dragging.value = false,
      onDragDone: (details) {
        dragging.value = false;
        if (_isExcluded(details.globalPosition)) return;
        final adb = ref.read(adbControllerProvider);
        final paths = details.files.map((f) => f.path).toList();
        final target = ref.read(selectedDeviceProvider);
        if (target == null) {
          adb.showToast(
            tone: ToastTone.info,
            title: 'Connect a device first',
            message: 'Then drop the APK again to install it.',
            actions: [('Add device', adb.addDevice)],
          );
          return;
        }
        adb.installDropped(target, paths);
      },
      child: Stack(
        children: [
          child,
          if (dragging.value)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: t.canvas.withValues(alpha: 0.85),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: t.borderRadiusLarge,
                      border: Border.all(color: t.accent, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: 36, color: t.accent),
                        const SizedBox(height: 10),
                        Text(
                          device == null ? 'Connect a device to install' : 'Drop to install on ${device.displayName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('.apk files only', style: TextStyle(color: t.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge counts for the Activity entry: running and failed (unseen) commands.
final activityCountsProvider = Provider<({int running, int errors})>((ref) {
  final list = ref.watch(commandQueueControllerProvider);
  return (
    running: list.where((c) => !c.isDone).length,
    errors: list.whereType<CommandModelError>().length,
  );
});
