import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../../design/design.dart';
import '../../utils/utils.dart';

/// Makes the app window a small fixed window while onboarding shows, and restores it after.
/// See spec/features/onboarding.md "Onboarding window".
class OnboardingWindow {
  OnboardingWindow._();

  static const size = Size(920, 640);

  /// True while the window is in onboarding mode (read by the Windows caption).
  static final active = ValueNotifier<bool>(false);

  static Rect? _previous;
  static Future<void> _queue = Future.value();

  static bool get _supported => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  static Future<void> enter() => _enqueue(() async {
        if (active.value || !_supported) return;
        active.value = true;
        await windowManager.ensureInitialized();
        if (await windowManager.isFullScreen()) await windowManager.setFullScreen(false);
        if (await windowManager.isMaximized()) await windowManager.unmaximize();
        _previous = await windowManager.getBounds();
        await windowManager.setResizable(true);
        await windowManager.setMinimumSize(size);
        await windowManager.setMaximumSize(size);
        await windowManager.setSize(size);
        await windowManager.center();
        await windowManager.setResizable(false);
        if (!Platform.isLinux) await windowManager.setMaximizable(false);
        if (Platform.isMacOS) await windowManager.setMovable(false);
      });

  static Future<void> exit() => _enqueue(() async {
        if (!active.value) return;
        active.value = false;
        await windowManager.setResizable(true);
        if (!Platform.isLinux) await windowManager.setMaximizable(true);
        if (Platform.isMacOS) await windowManager.setMovable(true);
        // No maximum: a size far above any screen.
        await windowManager.setMaximumSize(const Size(100000, 100000));
        await windowManager.setMinimumSize(WindowSize.minimum);
        final previous = _previous;
        if (previous != null && previous.width > size.width && previous.height > size.height) {
          await windowManager.setBounds(previous);
        } else {
          await windowManager.setSize(const Size(1280, 820));
          await windowManager.center();
        }
      });

  static Future<void> _enqueue(Future<void> Function() job) {
    _queue = _queue.then((_) => job()).catchError((Object e, StackTrace s) {
      LogFile.instance.dispath('[window] onboarding window change failed', error: e, stackTrace: s);
    });
    return _queue;
  }
}

/// Puts the window in onboarding mode while [active] is true.
class OnboardingWindowScope extends StatefulWidget {
  const OnboardingWindowScope({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<OnboardingWindowScope> createState() => _OnboardingWindowScopeState();
}

class _OnboardingWindowScopeState extends State<OnboardingWindowScope> {
  @override
  void initState() {
    super.initState();
    if (widget.active) OnboardingWindow.enter();
  }

  @override
  void didUpdateWidget(OnboardingWindowScope old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) widget.active ? OnboardingWindow.enter() : OnboardingWindow.exit();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
