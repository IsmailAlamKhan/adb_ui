import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';

class RunAnimation extends HookConsumerWidget {
  const RunAnimation({
    super.key,
    required this.builder,
    required this.run,
  });
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
