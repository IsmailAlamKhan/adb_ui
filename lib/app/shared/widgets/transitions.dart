import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../utils/utils.dart';

abstract class AppAnimatedWidget extends AnimatedWidget {
  final Animation<double> animation;
  final bool isReverse;
  const AppAnimatedWidget({super.key, required this.animation, this.isReverse = false})
      : super(listenable: animation);

  Animation<double> get progress {
    final animation = listenable as Animation<double>;
    if (isReverse) {
      return ReverseAnimation(animation);
    }
    return animation;
  }

  Animation<double> get opacity => CurvedAnimation(
        parent: progress,
        curve: const Interval(
          0.0,
          0.7,
          curve: Curves.easeInOut,
        ),
      );

  @override
  Widget build(BuildContext context);
}

class FadeSlideTransition extends AppAnimatedWidget {
  const FadeSlideTransition({
    super.key,
    required super.animation,
    super.isReverse,
    required this.slide,
    required this.child,
  });
  const FadeSlideTransition.reverse({
    super.key,
    required super.animation,
    required this.slide,
    required this.child,
  }) : super(isReverse: true);

  final Tween<Offset> slide;

  final Widget child;

  Animation<Offset> get _position => slide.animate(
        CurvedAnimation(
          parent: progress,
          curve: const Interval(
            0.0,
            0.8,
            curve: Curves.easeInOut,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: _position,
        child: child,
      ),
    );
  }
}

class FadeSizeTransition extends AppAnimatedWidget {
  const FadeSizeTransition({
    super.key,
    required super.animation,
    required this.child,
    this.axisAlignment = 0.0,
    super.isReverse,
    this.axis = Axis.vertical,
  });
  const FadeSizeTransition.reverse({
    super.key,
    required super.animation,
    required this.child,
    this.axisAlignment = 0.0,
    this.axis = Axis.vertical,
  }) : super(isReverse: true);

  final Widget child;

  final double axisAlignment;

  final Axis axis;

  Animation<double> get _sizeFactor => CurvedAnimation(
        parent: progress,
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SizeTransition(
        axis: axis,
        axisAlignment: axisAlignment,
        sizeFactor: _sizeFactor,
        child: child,
      ),
    );
  }
}

class AppFadeScaleTransition extends AppAnimatedWidget {
  const AppFadeScaleTransition({
    super.key,
    required super.animation,
    required this.child,
    super.isReverse,
    this.alignment = Alignment.center,
    this.minScale = 0.0,
  });
  const AppFadeScaleTransition.reverse({
    super.key,
    required super.animation,
    required this.child,
    this.alignment = Alignment.center,
    this.minScale = 0.0,
  }) : super(isReverse: true);

  final Widget child;

  final Alignment alignment;
  final double minScale;

  Animation<double> get _scale => Tween(
        begin: minScale,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: progress,
        curve: Curves.easeInOut,
      ));

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        alignment: alignment,
        scale: _scale,
        child: child,
      ),
    );
  }
}

class SharedAxisSwitcher extends StatelessWidget {
  const SharedAxisSwitcher({
    super.key,
    this.reverse = false,
    required this.child,
    this.transitionType = SharedAxisTransitionType.horizontal,
    this.duration = AppTheme.defaultDuration,
    this.layoutBuilder = SharedAxisSwitcher.defaultLayoutBuilder,
  });
  final bool reverse;
  final Widget? child;
  final SharedAxisTransitionType transitionType;
  final Duration duration;
  final PageTransitionSwitcherLayoutBuilder layoutBuilder;
  static Widget defaultLayoutBuilder(List<Widget> entries) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: entries,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      reverse: reverse,
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: animation,
          fillColor: Colors.transparent,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        );
      },
      duration: duration,
      layoutBuilder: layoutBuilder,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
