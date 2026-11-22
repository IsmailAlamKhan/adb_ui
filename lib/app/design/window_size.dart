import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Width classes from spec/08-redesign.md (U14).
enum WindowSize {
  compact,
  medium,
  expanded;

  static const compactMax = 720.0;
  static const expandedMin = 1200.0;

  /// Smallest window the layouts are designed for.
  static const minimum = Size(480, 560);

  static WindowSize fromWidth(double width) {
    if (width < compactMax) return WindowSize.compact;
    if (width < expandedMin) return WindowSize.medium;
    return WindowSize.expanded;
  }

  static WindowSize of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == WindowSize.compact;
  bool get isExpanded => this == WindowSize.expanded;
}

/// ⌘ on macOS, Ctrl elsewhere.
bool get usesMeta => Platform.isMacOS;

SingleActivator platformShortcut(LogicalKeyboardKey key, {bool shift = false}) =>
    SingleActivator(key, meta: usesMeta, control: !usesMeta, shift: shift);

/// Human label for a [platformShortcut], e.g. `⌘I` or `Ctrl+I`.
String shortcutLabel(SingleActivator activator) {
  final key = switch (activator.trigger) {
    LogicalKeyboardKey.comma => ',',
    LogicalKeyboardKey.backspace => '⌫',
    LogicalKeyboardKey.enter => '↵',
    _ => activator.trigger.keyLabel.toUpperCase(),
  };
  if (usesMeta) {
    return '${activator.shift ? '⇧' : ''}⌘$key';
  }
  return '${activator.shift ? 'Shift+' : ''}Ctrl+$key';
}
