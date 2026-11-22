import 'package:flutter/material.dart';

import 'app_style.dart';

/// Design tokens of the current style and brightness. Widgets read colours, shape and fonts
/// from here instead of hard-coding them. Values live in `style_tokens.dart`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.style,
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderSubtle,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.success,
    required this.successSoft,
    required this.onSuccessSoft,
    required this.danger,
    required this.dangerSoft,
    required this.onDangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.onWarningSoft,
    required this.terminal,
    required this.onTerminal,
    required this.onTerminalMuted,
    required this.terminalAccent,
    required this.radius,
    required this.radiusLarge,
    required this.strokeWidth,
    required this.bodyFont,
    required this.headingFont,
    required this.monoFont,
    required this.density,
  });

  final AppStyle style;
  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  /// Dividers and input outlines. Same as [border] except in Launcher, whose cards use a
  /// heavy ink [border] but whose dividers stay light.
  final Color borderSubtle;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color success;
  final Color successSoft;
  final Color onSuccessSoft;
  final Color danger;
  final Color dangerSoft;
  final Color onDangerSoft;
  final Color warning;
  final Color warningSoft;
  final Color onWarningSoft;
  final Color terminal;
  final Color onTerminal;
  final Color onTerminalMuted;

  /// Accent that stays readable on [terminal] in light and dark themes.
  final Color terminalAccent;
  final double radius;
  final double radiusLarge;
  final double strokeWidth;
  final String bodyFont;
  final String headingFont;
  final String monoFont;
  final VisualDensity density;

  bool get isDark => brightness == Brightness.dark;

  BorderRadius get borderRadius => BorderRadius.circular(radius);
  BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  BorderSide get borderSide => BorderSide(color: border, width: strokeWidth);
  BorderSide get subtleSide => BorderSide(color: borderSubtle);

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ??
      (throw FlutterError('AppTokens missing: build the theme with AppThemeFactory.'));

  @override
  AppTokens copyWith({Color? accent, Color? canvas}) => AppTokens(
        style: style,
        brightness: brightness,
        canvas: canvas ?? this.canvas,
        surface: surface,
        surfaceAlt: surfaceAlt,
        border: border,
        borderSubtle: borderSubtle,
        text: text,
        textMuted: textMuted,
        accent: accent ?? this.accent,
        onAccent: onAccent,
        accentSoft: accentSoft,
        onAccentSoft: onAccentSoft,
        success: success,
        successSoft: successSoft,
        onSuccessSoft: onSuccessSoft,
        danger: danger,
        dangerSoft: dangerSoft,
        onDangerSoft: onDangerSoft,
        warning: warning,
        warningSoft: warningSoft,
        onWarningSoft: onWarningSoft,
        terminal: terminal,
        onTerminal: onTerminal,
        onTerminalMuted: onTerminalMuted,
        terminalAccent: terminalAccent,
        radius: radius,
        radiusLarge: radiusLarge,
        strokeWidth: strokeWidth,
        bodyFont: bodyFont,
        headingFont: headingFont,
        monoFont: monoFont,
        density: density,
      );

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    final pick = t < 0.5 ? this : other;
    return AppTokens(
      style: pick.style,
      brightness: pick.brightness,
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      border: c(border, other.border),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      text: c(text, other.text),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccentSoft: c(onAccentSoft, other.onAccentSoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      onSuccessSoft: c(onSuccessSoft, other.onSuccessSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      onDangerSoft: c(onDangerSoft, other.onDangerSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      onWarningSoft: c(onWarningSoft, other.onWarningSoft),
      terminal: c(terminal, other.terminal),
      onTerminal: c(onTerminal, other.onTerminal),
      onTerminalMuted: c(onTerminalMuted, other.onTerminalMuted),
      terminalAccent: c(terminalAccent, other.terminalAccent),
      radius: pick.radius,
      radiusLarge: pick.radiusLarge,
      strokeWidth: pick.strokeWidth,
      bodyFont: pick.bodyFont,
      headingFont: pick.headingFont,
      monoFont: pick.monoFont,
      density: pick.density,
    );
  }
}
