import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../shared/widgets/logo.dart';

/// Shown while the app starts. Settings aren't loaded yet, so it uses Workbench tokens.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(builder: (context) {
        final theme = AppThemeFactory.build(AppStyle.workbench, MediaQuery.platformBrightnessOf(context));
        final t = theme.extension<AppTokens>()!;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: theme,
            child: ColoredBox(
              color: t.canvas,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 48),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(minHeight: 3, color: t.accent, backgroundColor: t.accentSoft),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Starting adb…',
                      style: TextStyle(color: t.textMuted, fontSize: 13, decoration: TextDecoration.none),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
