import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class CardWithoutElevation extends StatelessWidget {
  const CardWithoutElevation({
    super.key,
    required this.child,
    this.color,
    this.surfaceTint,
    this.margin,
    this.shape,
    this.clipBehavior,
  });

  /// this will remove the default margin and make the card without any shape
  factory CardWithoutElevation.flat({
    Key? key,
    required Widget child,
    Color? color,
    Color? surfaceTint,
    Clip? clipBehavior,
  }) =>
      CardWithoutElevation(
        key: key,
        color: color,
        surfaceTint: surfaceTint,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        clipBehavior: clipBehavior,
        child: child,
      );
  final Widget child;
  final Color? color;
  final Color? surfaceTint;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: shape,
      color: tintColor(
        tint: surfaceTint ?? Theme.of(context).colorScheme.surfaceTint,
        color: color ?? Theme.of(context).colorScheme.surface,
        opacity: .1,
      ),
      elevation: 0,
      margin: margin ?? const EdgeInsets.all(0),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
