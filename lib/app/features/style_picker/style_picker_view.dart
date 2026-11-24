import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../../shared/shared.dart';
import '../features.dart';

/// Light/dark the app will actually use for [mode].
Brightness resolveBrightness(BuildContext context, ThemeMode mode) => switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };

/// A miniature of a style's layout, drawn with that style's tokens.
class StylePreview extends StatelessWidget {
  const StylePreview({super.key, required this.style, required this.brightness, this.height = 132});
  final AppStyle style;
  final Brightness brightness;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = tokensFor(style, brightness);
    Widget box(Color color, {double? w, double? h, double r = 3, Border? border}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r), border: border),
        );
    Widget line(double w, [Color? c]) => box(c ?? t.textMuted.withValues(alpha: 0.5), w: w, h: 4, r: 2);
    final card = Border.all(color: style == AppStyle.launcher ? t.border : t.borderSubtle, width: style == AppStyle.launcher ? 1.5 : 1);

    final body = switch (style) {
      AppStyle.workbench => Row(
          children: [
            Container(
              width: 46,
              color: t.surfaceAlt,
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(t.surface, h: 10, border: card),
                  const SizedBox(height: 6),
                  line(28),
                  const SizedBox(height: 4),
                  line(22),
                  const SizedBox(height: 4),
                  line(26),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(60, t.text),
                    const SizedBox(height: 6),
                    Row(children: [
                      box(t.accent, w: 18, h: 3, r: 1),
                      const SizedBox(width: 4),
                      line(14),
                      const SizedBox(width: 4),
                      line(14),
                      const SizedBox(width: 4),
                      line(14),
                    ]),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            Expanded(child: box(t.surface, border: card)),
                            if (i < 2) const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      AppStyle.console => Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    color: t.surfaceAlt,
                    padding: const EdgeInsets.all(6),
                    child: Column(children: [
                      box(t.accentSoft, h: 8),
                      const SizedBox(height: 4),
                      line(28),
                      const SizedBox(height: 4),
                      line(24),
                    ]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 3,
                        crossAxisSpacing: 3,
                        childAspectRatio: 2,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [for (var i = 0; i < 6; i++) box(t.surface, border: card)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 34,
              color: t.terminal,
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(70, t.accent),
                  const SizedBox(height: 4),
                  line(50, t.onTerminalMuted),
                ],
              ),
            ),
          ],
        ),
      AppStyle.launcher => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: box(t.surface, h: 30, r: 5, border: card)),
                const SizedBox(width: 6),
                box(Colors.transparent, w: 34, h: 30, r: 5, border: Border.all(color: t.borderSubtle)),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Container(
                      decoration: BoxDecoration(color: t.terminal, borderRadius: BorderRadius.circular(5)),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          line(30, t.accent),
                          const SizedBox(height: 5),
                          line(60, t.onTerminalMuted),
                          const SizedBox(height: 4),
                          line(48, t.onTerminalMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    };
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(height: height, color: t.canvas, child: body),
      ),
    );
  }
}

/// Selectable card for one style (radio semantics).
class StyleChoiceCard extends StatelessWidget {
  const StyleChoiceCard({
    super.key,
    required this.style,
    required this.selected,
    required this.brightness,
    required this.onSelect,
    this.compact = false,
  });
  final AppStyle style;
  final bool selected;
  final Brightness brightness;
  final VoidCallback onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '${style.label} style. ${style.tagline}',
      child: AppCard(
        selected: selected,
        onTap: onSelect,
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            StylePreview(style: style, brightness: brightness, height: compact ? 92 : 132),
            SizedBox(height: compact ? 8 : 12),
            Row(
              children: [
                Expanded(child: Text(style.label, style: text.titleMedium)),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? t.accent : t.textMuted,
                  size: 20,
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(style.tagline, style: text.bodyMedium!.copyWith(color: t.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row/column of the three style cards, with arrow-key selection.
class StyleChooser extends StatelessWidget {
  const StyleChooser({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.brightness,
    this.compact = false,
  });
  final AppStyle selected;
  final ValueChanged<AppStyle> onChanged;
  final Brightness brightness;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    void move(int delta) {
      const values = AppStyle.values;
      onChanged(values[(selected.index + delta + values.length) % values.length]);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => move(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => move(1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => move(-1),
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final stacked = constraints.maxWidth < 600;
        final cards = [
          for (final style in AppStyle.values)
            StyleChoiceCard(
              style: style,
              selected: style == selected,
              brightness: brightness,
              compact: compact,
              onSelect: () => onChanged(style),
            ),
        ];
        if (stacked) {
          return Column(
            children: [
              for (final card in cards) ...[card, const SizedBox(height: 12)],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      }),
    );
  }
}

class ThemeModeChooser extends StatelessWidget {
  const ThemeModeChooser({super.key, required this.value, required this.onChanged});
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded, size: 18)),
          ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded, size: 18)),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded, size: 18)),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      );
}

/// First-run picker (spec/features/app-styles.md). Re-themes live to the highlighted choice.
class StylePickerView extends HookConsumerWidget {
  const StylePickerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsControllerProvider);
    final style = useState(settings.style ?? AppStyle.workbench);
    final mode = useState(settings.themeMode);
    final brightness = resolveBrightness(context, mode.value);
    final theme = AppThemeFactory.build(style.value, brightness);
    final compact = WindowSize.of(context).isCompact;

    return AnimatedTheme(
      data: theme,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
      child: Builder(builder: (context) {
        final t = AppTokens.of(context);
        final text = Theme.of(context).textTheme;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 20 : 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 28),
                          const SizedBox(width: 10),
                          Text('ADB UI', style: text.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('Choose how ADB UI looks', style: compact ? text.headlineMedium : text.displaySmall),
                      const SizedBox(height: 8),
                      Text(
                        'You can change this any time in Settings.',
                        style: text.bodyLarge!.copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: 28),
                      StyleChooser(
                        selected: style.value,
                        brightness: brightness,
                        onChanged: (s) => style.value = s,
                      ),
                      const SizedBox(height: 28),
                      const SectionLabel('Theme'),
                      const SizedBox(height: 8),
                      ThemeModeChooser(value: mode.value, onChanged: (m) => mode.value = m),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          autofocus: true,
                          onPressed: () {
                            // Setup (requirements) comes next, before home.
                            ref.read(setupGateProvider.notifier).state = SetupMode.firstRun;
                            ref.read(settingsControllerProvider.notifier).completeOnboarding(style.value, mode.value);
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text('Continue with ${style.value.label}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
