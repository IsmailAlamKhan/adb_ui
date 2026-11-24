import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'design/design.dart';
import 'features/features.dart';
import 'shared/shared.dart';
import 'utils/utils.dart';

class App {
  static Future<void> init(ProviderContainer container) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      runApp(const ProviderScope(child: SplashView()));
      if (Platform.isWindows) {
        await windowManager.ensureInitialized();

        const windowOptions = WindowOptions(
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          minimumSize: WindowSize.minimum,
          titleBarStyle: TitleBarStyle.hidden,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      }

      await container.read(packageInfoControllerProvider.notifier).init();
      await container.read(localStorageProvider).init();
      // Settings first, so even the startup error screen uses the user's style.
      await container.read(settingsControllerProvider.notifier).init();
      await container.read(deviceControllerProvider.notifier).init();
      await ToolPaths.init();
      try {
        await container.read(adbServiceProvider).verifyAdb();
      } on AdbNotFoundException catch (e) {
        // Not a startup error: Setup offers to install it.
        LogFile.instance.dispath('adb not found at startup, opening Setup', error: e);
        container.read(setupGateProvider.notifier).state = SetupMode.adbMissing;
      }
      await container.read(commandQueueControllerProvider.notifier).init();
    } on Exception catch (e, stackTrace) {
      Exception exception = e;
      if (e is AppException) {
        exception = AppInitializationException(e);
      } else if (e is ProcessException) {
        exception = AppInitializationException(AppException(e.message, e.errorCode.toString()));
      }
      throw Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  static bool _loggingReady = false;

  static Future<void> run() async {
    final container = ProviderContainer();
    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        if (!_loggingReady) {
          NavigatorService.init();
          AppLogger.init();
          await LogFile.init();
          FlutterError.onError = LogFile.instance.dispatchFlutterErrorLogs;
          MediaKit.ensureInitialized(); // video decoding for the in-app mirror
          _loggingReady = true;
        }
        await init(container);
        runApp(UncontrolledProviderScope(container: container, child: const _App()));
      },
      (error, stack) async {
        WidgetsFlutterBinding.ensureInitialized();
        if (!_loggingReady) {
          NavigatorService.init();
          AppLogger.init();
          await LogFile.init();
          _loggingReady = true;
        }
        if (error is AppInitializationException) {
          runApp(UncontrolledProviderScope(
            container: container,
            child: AppInitErrorView(exception: error),
          ));
        }
        LogFile.instance.dispath('Error on zone', error: error, stackTrace: stack);
      },
    );
  }
}

/// Builds `MaterialApp` themes from the user's style (or Workbench before one is chosen)
/// and wraps every route in the window chrome, navigation listener and macOS insets.
class AppWrapper extends ConsumerWidget {
  const AppWrapper({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ThemeMode themeMode,
    ThemeData light,
    ThemeData dark,
    TransitionBuilder builder,
  ) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final style = settings.style ?? AppStyle.workbench;
    final light = AppThemeFactory.build(style, Brightness.light);
    final dark = AppThemeFactory.build(style, Brightness.dark);
    final virtualWindowFrameBuilder = VirtualWindowFrameInit();
    return WindowTitleBar(
      light: light,
      dark: dark,
      themeMode: settings.themeMode,
      child: builder(context, settings.themeMode, light, dark, (context, child) {
        if (Platform.isWindows) {
          child = virtualWindowFrameBuilder(context, child);
        }
        var data = MediaQuery.of(context);
        if (Platform.isMacOS) {
          data = data.copyWith(padding: const EdgeInsets.only(top: 22));
        }
        return MediaQuery(
          data: data,
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: NavigationEventListener(
              navigator: NavigatorService.instance.navigatorKey(false),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      }),
    );
  }
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(settingsControllerProvider.select((s) => s.style != null));
    final setup = ref.watch(setupGateProvider);
    return AppWrapper(
      builder: (context, themeMode, light, dark, builder) => MaterialApp(
        themeMode: themeMode,
        title: appName,
        darkTheme: dark,
        theme: light,
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigatorService.instance.navigatorKey(false),
        builder: builder,
        home: !chosen
            ? const StylePickerView()
            : setup != null
                ? SetupView(key: ValueKey(setup), mode: setup)
                : const UpdateChecker(child: HomeShell()),
      ),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    super.key,
    required this.child,
    required this.light,
    required this.dark,
    required this.themeMode,
  });

  final Widget child;
  final ThemeData light;
  final ThemeData dark;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return CustomMenuBar(
        child: MediaQuery.fromView(
          view: View.of(context),
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
              ),
              child: child,
            ),
          ),
        ),
      );
    }
    if (Platform.isLinux) {
      return child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: _AppThemeBuilder(
        light: light,
        dark: dark,
        themeMode: themeMode,
        child: Builder(builder: (context) {
          final t = AppTokens.of(context);
          return Material(
            color: t.canvas,
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                  child: Listener(
                    onPointerDown: (event) {
                      if (event.kind == PointerDeviceKind.mouse &&
                          event.buttons == kSecondaryMouseButton) {
                        windowManager.popUpWindowMenu();
                      }
                    },
                    child: WindowCaption(
                      brightness: Theme.of(context).brightness,
                      backgroundColor: Colors.transparent,
                      title: DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyMedium!,
                        child: const Row(
                          children: [AppLogo(size: 20), Gap(6), Text(appName)],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class NoScrollBarScrollBehavior extends MaterialScrollBehavior {
  const NoScrollBarScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

/// Theme for the Windows caption, which sits outside `MaterialApp`.
class _AppThemeBuilder extends StatefulWidget {
  const _AppThemeBuilder({
    required this.child,
    required this.light,
    required this.dark,
    required this.themeMode,
  });

  final Widget child;
  final ThemeData light;
  final ThemeData dark;
  final ThemeMode themeMode;

  @override
  State<_AppThemeBuilder> createState() => _AppThemeBuilderState();
}

class _AppThemeBuilderState extends State<_AppThemeBuilder> with WidgetsBindingObserver {
  WidgetsBinding get _binding => WidgetsBinding.instance;

  @override
  void initState() {
    super.initState();
    _binding.addObserver(this);
  }

  @override
  void dispose() {
    _binding.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
    super.didChangePlatformBrightness();
  }

  bool get _dark => switch (widget.themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
      };

  @override
  Widget build(BuildContext context) =>
      AnimatedTheme(data: _dark ? widget.dark : widget.light, child: widget.child);
}
