import 'package:flutter/material.dart';

import '../../app.dart';
import '../../shared/widgets/widgets.dart';
import '../../utils/utils.dart';
import '../adb/adb.dart';

class AppInitErrorView extends StatelessWidget {
  const AppInitErrorView({
    super.key,
    required this.exception,
  });
  final AppInitializationException exception;
  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      builder: (context, themeMode, light, dark, builder) => MaterialApp(
        title: appName,
        navigatorKey: NavigatorService.instance.navigatorKey(false),
        themeMode: themeMode,
        darkTheme: dark,
        theme: light,
        builder: builder,
        home: _AppInitErrorView(exception: exception),
      ),
    );
  }
}

class _AppInitErrorView extends StatelessWidget {
  const _AppInitErrorView({
    super.key,
    required this.exception,
  });

  final AppInitializationException exception;

  @override
  Widget build(BuildContext context) {
    String message;
    final exception = this.exception.exception;
    if (exception is AdbNotFoundException) {
      message = 'Adb not found please install android platform tools';
    } else {
      message = exception.message;
    }
    return Scaffold(
      body: Center(
        child: AppExceptionIndicator(
          title: 'App Initialization Error',
          message: message,
        ),
      ),
    );
  }
}
