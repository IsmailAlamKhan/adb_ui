import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
        WidgetsFlutterBinding.ensureInitialized();
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
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        theme: AppTheme.themeDataFrom(colorScheme: lightDynamic, brightness: Brightness.light),
        darkTheme: AppTheme.themeDataFrom(colorScheme: darkDynamic, brightness: Brightness.dark),
        navigatorKey: NavigatorService.instance.navigatorKey(false),
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: NavigationEventListener(
              navigator: NavigatorService.instance.navigatorKey(false),
              child: child ?? const SizedBox(),
            ),
          );
        },
        home: const HomeView(),
      ),
    );
  }
}
