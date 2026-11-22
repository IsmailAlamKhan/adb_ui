import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_style.dart';
import '../app_theme_factory.dart';
import '../app_tokens.dart';

/// Small coloured dot with a label for screen readers.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, required this.label, this.size = 8});
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

/// Keyboard shortcut chip, e.g. `⌘I`.
class KeyHint extends StatelessWidget {
  const KeyHint(this.label, {super.key, this.onTerminal = false});
  final String label;
  final bool onTerminal;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final fg = onTerminal ? t.onTerminalMuted : t.textMuted;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: onTerminal ? t.onTerminalMuted.withValues(alpha: 0.4) : t.borderSubtle),
        ),
        child: Text(label, style: AppThemeFactory.mono(t, size: 11, color: fg)),
      ),
    );
  }
}

/// Section heading. Launcher and Console use upper-case tracking; Workbench sentence case.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.padding = EdgeInsets.zero});
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final upper = t.style != AppStyle.workbench;
    final style = Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: upper ? 11 : 12,
          letterSpacing: upper ? 0.8 : 0,
          color: t.textMuted,
        );
    return Padding(
      padding: padding,
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(child: Text(upper ? text.toUpperCase() : text, style: style)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// A bordered surface that can be tapped, selected and focused.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.dashed = false,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool dashed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final side = selected
        ? BorderSide(color: t.accent, width: t.strokeWidth + 1)
        : t.style == AppStyle.launcher
            ? t.borderSide
            : t.subtleSide;
    final shape = RoundedRectangleBorder(borderRadius: t.borderRadiusLarge, side: side);
    Widget content = Padding(padding: padding, child: child);
    if (dashed) {
      content = CustomPaint(
        painter: _DashedBorderPainter(color: t.borderSubtle, radius: t.radiusLarge, width: t.strokeWidth),
        child: content,
      );
    }
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: color ?? (dashed ? Colors.transparent : t.surface),
        shape: dashed ? RoundedRectangleBorder(borderRadius: t.borderRadiusLarge) : shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius, required this.width});
  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset(width / 2, width / 2) & Size(size.width - width, size.height - width),
        Radius.circular(radius),
      ));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius || old.width != width;
}

/// Empty / first-run state: icon, title, message and actions.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
  });
  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: t.accentSoft, borderRadius: t.borderRadiusLarge),
                child: Icon(icon, color: t.onAccentSoft, size: 28),
              ),
              const SizedBox(height: 16),
              Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: text.bodyMedium!.copyWith(color: t.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Selectable monospace output on the terminal colours, with a copy button.
class TerminalBlock extends StatelessWidget {
  const TerminalBlock({
    super.key,
    required this.text,
    this.maxHeight,
    this.placeholder = 'No output',
    this.showCopy = true,
  });
  final String text;
  final double? maxHeight;
  final String placeholder;
  final bool showCopy;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final empty = text.trim().isEmpty;
    Widget body = SelectableText(
      empty ? placeholder : text.trimRight(),
      style: AppThemeFactory.mono(t, color: empty ? t.onTerminalMuted : t.onTerminal),
    );
    body = SingleChildScrollView(padding: const EdgeInsets.fromLTRB(14, 12, 44, 12), child: body);
    if (maxHeight != null) {
      body = ConstrainedBox(constraints: BoxConstraints(maxHeight: maxHeight!), child: body);
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: t.terminal, borderRadius: t.borderRadius),
      child: Stack(
        children: [
          body,
          if (showCopy && !empty)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Copy output',
                iconSize: 16,
                color: t.onTerminalMuted,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => Clipboard.setData(ClipboardData(text: text)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Inline banner: info (accent), warning, error or success.
enum BannerTone { info, warning, danger, success }

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.steps = const [],
    this.actions = const [],
    this.icon,
  });
  final BannerTone tone;
  final String title;
  final String? message;
  final List<String> steps;
  final List<Widget> actions;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final (Color bg, Color fg, IconData defaultIcon) = switch (tone) {
      BannerTone.info => (t.accentSoft, t.onAccentSoft, Icons.info_outline_rounded),
      BannerTone.warning => (t.warningSoft, t.onWarningSoft, Icons.warning_amber_rounded),
      BannerTone.danger => (t.dangerSoft, t.onDangerSoft, Icons.error_outline_rounded),
      BannerTone.success => (t.successSoft, t.onSuccessSoft, Icons.check_circle_outline_rounded),
    };
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: t.borderRadius),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall!.copyWith(color: fg)),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(message!, style: text.bodyMedium!.copyWith(color: fg)),
                  ],
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    for (var i = 0; i < steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('${i + 1}. ${steps[i]}', style: text.bodyMedium!.copyWith(color: fg)),
                      ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toast shown through the app's snackbar channel.
enum ToastTone { success, error, info }

class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.actions = const [],
    this.onDismiss,
  });
  final ToastTone tone;
  final String title;
  final String? message;

  /// (label, callback). The toast closes before the callback runs.
  final List<(String, VoidCallback)> actions;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final (Color fg, IconData icon) = switch (tone) {
      ToastTone.success => (t.success, Icons.check_circle_rounded),
      ToastTone.error => (t.danger, Icons.error_rounded),
      ToastTone.info => (t.accent, Icons.info_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Material(
        color: t.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: t.borderRadiusLarge,
          side: t.style == AppStyle.launcher ? t.borderSide : t.subtleSide,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleSmall),
                    if (message != null && message!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message!,
                        style: text.bodyMedium!.copyWith(color: t.textMuted),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (final (label, onPressed) in actions)
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 30),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: () {
                                onDismiss?.call();
                                onPressed();
                              },
                              child: Text(label),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                iconSize: 16,
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
