import 'package:flutter/material.dart';

import '../../app.dart';
import '../../shared/widgets/widgets.dart';
import '../../utils/utils.dart';

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
    String message = exceptionToString(exception);

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
