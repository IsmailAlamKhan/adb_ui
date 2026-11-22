import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_style.dart';
import 'app_tokens.dart';
import 'style_tokens.dart';

/// Builds the Material theme of a style from its [AppTokens]. The tokens are attached as a
/// theme extension, so widgets can read them with `AppTokens.of(context)`.
class AppThemeFactory {
  const AppThemeFactory._();

  static ThemeData build(AppStyle style, Brightness brightness) =>
      fromTokens(tokensFor(style, brightness));

  static ThemeData fromTokens(AppTokens t) {
    final scheme = ColorScheme(
      brightness: t.brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      primaryContainer: t.accentSoft,
      onPrimaryContainer: t.onAccentSoft,
      secondary: t.accent,
      onSecondary: t.onAccent,
      secondaryContainer: t.accentSoft,
      onSecondaryContainer: t.onAccentSoft,
      tertiary: t.success,
      onTertiary: t.isDark ? t.successSoft : Colors.white,
      tertiaryContainer: t.successSoft,
      onTertiaryContainer: t.onSuccessSoft,
      error: t.danger,
      onError: t.isDark ? t.dangerSoft : Colors.white,
      errorContainer: t.dangerSoft,
      onErrorContainer: t.onDangerSoft,
      surface: t.surface,
      onSurface: t.text,
      onSurfaceVariant: t.textMuted,
      surfaceContainerLowest: t.surface,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surfaceAlt,
      surfaceContainerHigh: t.surfaceAlt,
      surfaceContainerHighest: t.surfaceAlt,
      outline: t.borderSubtle,
      outlineVariant: t.borderSubtle,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: t.terminal,
      onInverseSurface: t.onTerminal,
      inversePrimary: t.accentSoft,
      surfaceTint: Colors.transparent,
    );

    final launcher = t.style == AppStyle.launcher;
    final body = launcher ? 14.0 : 13.0;
    TextStyle b(double size, [FontWeight weight = FontWeight.w400, double? height]) =>
        GoogleFonts.getFont(t.bodyFont,
            fontSize: size, fontWeight: weight, height: height, color: t.text);
    TextStyle h(double size, [FontWeight weight = FontWeight.w600, double spacing = 0]) =>
        GoogleFonts.getFont(t.headingFont,
            fontSize: size, fontWeight: weight, letterSpacing: spacing, color: t.text);

    final textTheme = TextTheme(
      displayLarge: h(56, FontWeight.w700, -1.5),
      displayMedium: h(40, FontWeight.w700, -1),
      displaySmall: h(28, FontWeight.w700, -0.5),
      headlineLarge: h(26, FontWeight.w600, -0.3),
      headlineMedium: h(22, FontWeight.w600, -0.2),
      headlineSmall: h(20),
      titleLarge: h(17),
      titleMedium: b(15, FontWeight.w600),
      titleSmall: b(13, FontWeight.w600),
      bodyLarge: b(body + 1, FontWeight.w400, 1.45),
      bodyMedium: b(body, FontWeight.w400, 1.45),
      bodySmall: b(12, FontWeight.w400, 1.4).copyWith(color: t.textMuted),
      labelLarge: b(body, FontWeight.w500),
      labelMedium: b(12, FontWeight.w500),
      labelSmall: b(11, FontWeight.w600).copyWith(letterSpacing: 0.6, color: t.textMuted),
    );

    final radius = t.borderRadius;
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final buttonHeight = switch (t.style) {
      AppStyle.console => 32.0,
      AppStyle.workbench => 36.0,
      AppStyle.launcher => 44.0,
    };
    final buttonPadding = EdgeInsets.symmetric(horizontal: launcher ? 18 : 14);
    final buttonText = textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w600);
    final hover = t.text.withValues(alpha: 0.06);
    final focus = t.accent.withValues(alpha: 0.18);
    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.getFont(t.bodyFont).fontFamily,
      visualDensity: t.density,
      scaffoldBackgroundColor: t.canvas,
      canvasColor: t.canvas,
      cardColor: t.surface,
      dividerColor: t.borderSubtle,
      hoverColor: hover,
      focusColor: focus,
      highlightColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
      extensions: [t],
      iconTheme: IconThemeData(color: t.text, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: t.canvas,
        foregroundColor: t.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: t.borderSubtle, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: t.borderRadiusLarge, side: t.borderSide),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: t.borderRadiusLarge,
          side: launcher ? t.borderSide : BorderSide.none,
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          minimumSize: Size(64, buttonHeight),
          padding: buttonPadding,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          elevation: 0,
          minimumSize: Size(64, buttonHeight),
          padding: buttonPadding,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.text,
          backgroundColor: launcher ? Colors.transparent : t.surface,
          minimumSize: Size(64, buttonHeight),
          padding: buttonPadding,
          shape: shape,
          side: BorderSide(color: launcher ? t.border : t.borderSubtle, width: t.strokeWidth),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accent,
          minimumSize: Size(48, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.textMuted,
          shape: shape,
          minimumSize: Size(buttonHeight, buttonHeight),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: t.text,
          selectedForegroundColor: t.onAccentSoft,
          selectedBackgroundColor: t.accentSoft,
          side: BorderSide(color: t.borderSubtle),
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: launcher ? 14 : 11),
        border: inputBorder(t.borderSubtle),
        enabledBorder: inputBorder(t.borderSubtle),
        focusedBorder: inputBorder(t.accent, 2),
        errorBorder: inputBorder(t.danger),
        focusedErrorBorder: inputBorder(t.danger, 2),
        labelStyle: textTheme.bodyMedium!.copyWith(color: t.textMuted),
        floatingLabelStyle: textTheme.bodyMedium!.copyWith(color: t.accent),
        hintStyle: textTheme.bodyMedium!.copyWith(color: t.textMuted),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall!.copyWith(color: t.danger),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.text,
        unselectedLabelColor: t.textMuted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicatorColor: t.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: t.borderSubtle,
        overlayColor: WidgetStatePropertyAll(hover),
        tabAlignment: TabAlignment.start,
      ),
      listTileTheme: ListTileThemeData(
        dense: t.style == AppStyle.console,
        selectedTileColor: t.accentSoft,
        selectedColor: t.onAccentSoft,
        iconColor: t.textMuted,
        textColor: t.text,
        shape: shape,
        visualDensity: t.density,
        horizontalTitleGap: 10,
        minLeadingWidth: 20,
        titleTextStyle: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: textTheme.bodySmall,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        contentTextStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: t.terminal, borderRadius: BorderRadius.circular(6)),
        textStyle: textTheme.bodySmall!.copyWith(color: t.onTerminal),
        waitDuration: const Duration(milliseconds: 500),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius, side: t.subtleSide),
        textStyle: textTheme.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius, side: t.subtleSide),
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: t.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.accentSoft,
        circularTrackColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(t.onAccent),
        side: BorderSide(color: t.textMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius / 2)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.textMuted,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.onAccent : t.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.surfaceAlt,
        ),
        trackOutlineColor: WidgetStatePropertyAll(t.borderSubtle),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(t.textMuted.withValues(alpha: 0.4)),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceAlt,
        selectedColor: t.accentSoft,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: t.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(t.radiusLarge)),
        ),
      ),
    );
  }

  /// Monospace text style for output, commands and shortcuts.
  static TextStyle mono(AppTokens t, {double size = 12.5, Color? color, FontWeight? weight}) =>
      GoogleFonts.getFont(
        t.monoFont,
        fontSize: size,
        height: 1.5,
        color: color ?? t.text,
        fontWeight: weight,
      );
}
