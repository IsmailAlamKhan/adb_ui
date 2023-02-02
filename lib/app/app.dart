import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

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

        WindowOptions windowOptions = const WindowOptions(
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          minimumSize: Size(400, 600),
          titleBarStyle: TitleBarStyle.hidden,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      }

      await container.read(packageInfoControllerProvider.notifier).init();
      await container.read(localStorageProvider).init();
      await container.read(deviceControllerProvider.notifier).init();
      await container.read(adbServiceProvider).verifyAdb();
      await container.read(settingsControllerProvider.notifier).init();
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

  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    NavigatorService.init();
    AppLogger.init();
    await LogFile.init();

    FlutterError.onError = LogFile.instance.dispatchFlutterErrorLogs;
    final container = ProviderContainer();
    runZonedGuarded(
      () async {
        await init(container);
        runApp(UncontrolledProviderScope(
          container: container,
          child: const _App(),
        ));
      },
      (error, stack) {
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
    final virtualWindowFrameBuilder = VirtualWindowFrameInit();
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => WindowTitleBar(
        darkDynamic: darkDynamic,
        lightDynamic: lightDynamic,
        themeMode: settings.themeMode,
        child: builder(
            context,
            settings.themeMode,
            AppTheme.themeDataFrom(colorScheme: lightDynamic, brightness: Brightness.light),
            AppTheme.themeDataFrom(colorScheme: darkDynamic, brightness: Brightness.dark),
            (context, child) {
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
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: NavigationEventListener(
                navigator: NavigatorService.instance.navigatorKey(false),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _App extends ConsumerWidget {
  const _App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppWrapper(
      builder: (context, themeMode, light, dark, builder) => MaterialApp(
        themeMode: themeMode,
        title: appName,
        darkTheme: dark,
        theme: light,
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigatorService.instance.navigatorKey(false),
        builder: builder,
        home: const UpdateChecker(child: HomeView()),
      ),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    super.key,
    required this.child,
    this.lightDynamic,
    this.darkDynamic,
    required this.themeMode,
  });

  final Widget child;
  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return CustomMenuBar(
        child: MediaQuery.fromWindow(
          child: Builder(
            builder: (context) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
                ),
                child: child,
              );
            },
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
        darkDynamic: darkDynamic,
        lightDynamic: lightDynamic,
        themeMode: themeMode,
        child: Material(
          child: Column(
            children: [
              SizedBox(
                height: 30,
                child: Builder(builder: (context) {
                  return Listener(
                    onPointerDown: (event) {
                      if (event.kind == PointerDeviceKind.mouse) {
                        final mouseEvent = event;
                        if (mouseEvent.buttons == kSecondaryMouseButton) {
                          windowManager.popUpWindowMenu();
                        }
                      }
                    },
                    child: WindowCaption(
                      brightness: Theme.of(context).brightness,
                      backgroundColor: Colors.transparent,
                      title: DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyText2!,
                        child: Row(
                          children: const [
                            AppLogo(size: 20),
                            Gap(4),
                            Text(appName),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class NoScrollBarScrollBehavior extends MaterialScrollBehavior {
  const NoScrollBarScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _AppThemeBuilder extends StatefulWidget {
  const _AppThemeBuilder({
    super.key,
    required this.child,
    this.lightDynamic,
    this.darkDynamic,
    required this.themeMode,
  });

  final Widget child;
  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;
  final ThemeMode themeMode;

  @override
  State<_AppThemeBuilder> createState() => __AppThemeBuilderState();
}

class __AppThemeBuilderState extends State<_AppThemeBuilder> with WidgetsBindingObserver {
  ThemeMode themeMode = ThemeMode.light;

  WidgetsBinding get _binding => WidgetsBinding.instance;

  @override
  void initState() {
    super.initState();
    _binding.addObserver(this);
    _updateThemeMode(true);
  }

  void _updateThemeMode([bool inital = false]) {
    ThemeMode themeMode = widget.themeMode;
    if (themeMode == ThemeMode.system) {
      themeMode = _binding.window.platformBrightness == Brightness.dark //
          ? ThemeMode.dark
          : ThemeMode.light;
    }
    if (themeMode != this.themeMode) {
      if (!inital) {
        setState(() => this.themeMode = themeMode);
      } else {
        this.themeMode = themeMode;
      }
    }
  }

  @override
  void dispose() {
    _binding.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _updateThemeMode();
    super.didChangePlatformBrightness();
  }

  @override
  void didUpdateWidget(covariant _AppThemeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = AppTheme.themeDataFrom(
      colorScheme: widget.darkDynamic,
      brightness: Brightness.dark,
    );
    final lightTheme = AppTheme.themeDataFrom(
      colorScheme: widget.lightDynamic,
      brightness: Brightness.light,
    );
    final theme = themeMode == ThemeMode.dark ? darkTheme : lightTheme;
    return AnimatedTheme(data: theme, child: widget.child);
  }
}
