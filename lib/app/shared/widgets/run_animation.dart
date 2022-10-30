import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../shared.dart';

class RunAnimation extends HookConsumerWidget {
  const RunAnimation({
    super.key,
    required this.builder,
    required this.run,
  });

  static Widget sizeTransition({
    required Widget child,
    required bool show,
    Axis axis = Axis.vertical,
    double axisAlignment = 0.0,
  }) =>
      RunAnimation(
        run: show,
        builder: (context, animation) => FadeSizeTransition(
          animation: animation,
          axis: axis,
          axisAlignment: axisAlignment,
          child: child,
        ),
      );

  static Widget fadeTransition({
    required Widget child,
    required bool show,
  }) =>
      RunAnimation(
        run: show,
        builder: (context, animation) => FadeTransition(opacity: animation, child: child),
      );

  static Widget scaleTransition({
    required Widget child,
    required bool show,
  }) =>
      RunAnimation(
        run: show,
        builder: (context, animation) => FadeScaleTransition(animation: animation, child: child),
      );

  final Widget Function(BuildContext context, Animation<double> animation) builder;
  final bool run;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(
      duration: AppTheme.defaultDuration,
      initialValue: run ? 1 : 0,
    );
    useEffect(() {
      if (run) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }, [run]);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => builder(context, controller),
    );
  }
}
