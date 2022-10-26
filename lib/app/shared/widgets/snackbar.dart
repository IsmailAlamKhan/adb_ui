import 'package:flutter/material.dart';

class AppSnackbar extends SnackBar {
  const AppSnackbar({
    super.key,
    required super.content,
    super.action,
    super.animation,
    super.backgroundColor,
    SnackBarBehavior super.behavior = SnackBarBehavior.floating,
    super.dismissDirection,
    super.duration,
    super.elevation,
    super.margin,
    super.padding,
    super.onVisible,
    super.shape,
    super.width = 400,
  });

  factory AppSnackbar.text(
    String text, {
    Color? bg,
    TextStyle? textStyle,
  }) =>
      AppSnackbar(
        content: Text(text, style: textStyle),
        backgroundColor: bg,
      );

  factory AppSnackbar.action(
    String text,
    SnackBarAction action, {
    Color? bg,
    TextStyle? textStyle,
  }) =>
      AppSnackbar(
        content: Text(text, style: textStyle),
        action: action,
        backgroundColor: bg,
      );
}
