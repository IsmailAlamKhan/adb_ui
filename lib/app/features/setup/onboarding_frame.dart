import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../shared/widgets/widgets.dart';

/// Shared chrome for the first-run flow (style picker, then Setup): glow background, top bar
/// with the step indicator, and a pinned footer. See spec/features/onboarding.md "Look".
class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({super.key, required this.child, required this.actions, this.step, this.maxWidth = 880});

  final Widget child;

  /// Footer buttons, right-aligned.
  final List<Widget> actions;

  /// 1 (Look) or 2 (Tools); null hides the step indicator.
  final int? step;
  final double maxWidth;

  static const steps = ['Look', 'Tools'];

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final compact = WindowSize.of(context).isCompact;
    final pad = compact ? 16.0 : 32.0;

    Widget constrained(Widget w) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: w,
      ),
    );

    return Scaffold(
      backgroundColor: t.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: OnboardingGlow()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, compact ? 12 : 20, pad, 0),
                  child: constrained(
                    Row(
                      children: [
                        const AppLogo(size: 28),
                        const SizedBox(width: 10),
                        Text('ADB UI', style: text.titleMedium),
                        const Spacer(),
                        if (step != null) OnboardingStepper(step: step!, compact: compact),
                      ],
                    ),
                  ),
                ),
                Expanded(child: child),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.surface.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: t.borderSubtle)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 12, pad, 12),
                    child: constrained(
                      Row(
                        children: [
                          if (step != null && !compact)
                            Text('Step $step of ${steps.length}', style: TextStyle(color: t.textMuted)),
                          const Spacer(),
                          Flexible(
                            flex: 0,
                            child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Two soft accent glows over the canvas, from the active style's tokens.
class OnboardingGlow extends StatelessWidget {
  const OnboardingGlow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final strength = dark ? 0.30 : 0.16;
    Widget glow(Alignment at, double radius, double alpha) => DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: at,
          radius: radius,
          colors: [
            t.accent.withValues(alpha: alpha),
            t.accent.withValues(alpha: 0),
          ],
        ),
      ),
    );
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          glow(const Alignment(-1.1, -1.2), 1.1, strength),
          glow(const Alignment(1.2, 1.3), 0.9, strength * 0.6),
        ],
      ),
    );
  }
}

/// "1 Look — 2 Tools": the current step filled, finished steps checked.
class OnboardingStepper extends StatelessWidget {
  const OnboardingStepper({super.key, required this.step, this.compact = false});
  final int step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final items = <Widget>[];
    for (var i = 0; i < OnboardingFrame.steps.length; i++) {
      final n = i + 1;
      final done = n < step;
      final current = n == step;
      if (i > 0) {
        items.add(
          Container(
            width: compact ? 14 : 28,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: done || current ? t.accent : t.borderSubtle,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current || done ? t.accent : Colors.transparent,
                border: Border.all(color: current || done ? t.accent : t.border, width: 1.5),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 15, color: t.onAccent)
                  : Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: current ? t.onAccent : t.textMuted,
                      ),
                    ),
            ),
            if (!compact || current) ...[
              const SizedBox(width: 8),
              Text(
                OnboardingFrame.steps[i],
                style: TextStyle(
                  fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                  color: current ? t.text : t.textMuted,
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Semantics(
      label: 'Step $step of ${OnboardingFrame.steps.length}: ${OnboardingFrame.steps[step - 1]}',
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );
  }
}

/// Fades and slides [child] up on first build, after [delay]. Instant with reduced motion.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null || _c.isAnimating || _c.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _timer ??= Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(_curve),
      child: widget.child,
    ),
  );
}
