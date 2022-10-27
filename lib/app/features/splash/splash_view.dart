import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromWindow(
      child: Builder(builder: (context) {
        final mq = MediaQuery.of(context);
        final theme = mq.platformBrightness == Brightness.dark
            ? AppTheme.darkThemeData()
            : AppTheme.lightThemeData();
        return Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedTheme(
            data: theme,
            child: const Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
        );
      }),
    );
  }
}
