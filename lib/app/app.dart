import 'dart:async';
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
  static Future<void> run() async {
    NavigatorService.init();
    AppLogger.init();
    WidgetsFlutterBinding.ensureInitialized();
    runZonedGuarded(
      () async {
        await windowManager.ensureInitialized();

        WindowOptions windowOptions = const WindowOptions(
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
        runApp(const ProviderScope(child: _App()));
      },
      (error, stack) {
        logError('Error on zone', error: error, stackTrace: stack);
      },
    );
  }
}

class _App extends StatelessWidget {
  const _App({super.key});

  @override
  Widget build(BuildContext context) {
    final virtualWindowFrameBuilder = VirtualWindowFrameInit();
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => WindowTitleBar(
        darkDynamic: darkDynamic,
        lightDynamic: lightDynamic,
        child: MaterialApp(
          title: appName,
          theme: AppTheme.themeDataFrom(colorScheme: lightDynamic, brightness: Brightness.light),
          darkTheme: AppTheme.themeDataFrom(colorScheme: darkDynamic, brightness: Brightness.dark),
          navigatorKey: NavigatorService.instance.navigatorKey(false),
          builder: (context, child) {
            child = virtualWindowFrameBuilder(context, child);
            return GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: NavigationEventListener(
                navigator: NavigatorService.instance.navigatorKey(false),
                child: child,
              ),
            );
          },
          home: const HomeView(),
        ),
      ),
    );
  }
}

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key, required this.child, this.lightDynamic, this.darkDynamic});

  final Widget child;
  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _AppThemeBuilder(
        darkDynamic: darkDynamic,
        lightDynamic: lightDynamic,
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
  const _AppThemeBuilder({super.key, required this.child, this.lightDynamic, this.darkDynamic});
  final Widget child;
  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;
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
    themeMode =
        _binding.window.platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  void dispose() {
    _binding.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {
      themeMode =
          _binding.window.platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    });
    super.didChangePlatformBrightness();
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
