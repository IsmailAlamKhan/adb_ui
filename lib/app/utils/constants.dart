import 'package:flutter/material.dart';

Color tintColor({
  required Color color,
  required Color tint,
  required double opacity,
}) {
  return Color.alphaBlend(tint.withOpacity(opacity), color);
}

Color surfaceTintColor({
  required BuildContext context,
  double opacity = .5,
}) {
  return tintColor(
    color: Theme.of(context).colorScheme.surface,
    tint: Theme.of(context).colorScheme.surfaceTint,
    opacity: opacity,
  );
}

typedef FutureCallback<T> = Future<T> Function();
