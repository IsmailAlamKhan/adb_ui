// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';

import 'widgets.dart';

typedef ConfirmDialogLayoutBuilder = List<ConfirmDialogAction> Function(
  BuildContext context,
  ConfirmDialogAction confirm,
  ConfirmDialogAction cancel,
  List<ConfirmDialogAction>? extraActions,
);

class ConfirmDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  ConfirmDialogAction({
    required this.text,
    this.onPressed,
    this.textColor,
  });
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.text,
    this.confirmText,
    this.cancelText,
    this.title,
    this.confirmTextColor,
    this.cancelTextColor,
    this.extraActions,
    this.layoutBuilder,
    this.onConfirm,
    this.onCancel,
  }) : assert(
          text is String || text is String Function(BuildContext),
          'text must be a String or a String Function(BuildContext)',
        );
  final Object text;
  final String? confirmText;
  final String? cancelText;
  final String? title;
  final Color? confirmTextColor;
  final Color? cancelTextColor;
  final List<ConfirmDialogAction>? extraActions;
  final ConfirmDialogLayoutBuilder? layoutBuilder;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    // final confirmButton = FilledButton(
    //   onPressed: onConfirm ?? () => navigator.pop(true),
    //   style: ElevatedButton.styleFrom(
    //     foregroundColor: confirmTextColor ?? theme.colorScheme.primary,
    //   ),
    //   child: Text(confirmText ?? "Yes"),
    // );
    // final cancelButton = ElevatedButton(
    //   onPressed: onCancel ?? () => navigator.pop(false),
    //   style: ElevatedButton.styleFrom(
    //     foregroundColor: cancelTextColor ?? theme.colorScheme.error,
    //   ).filled(context),
    //   child: Text(cancelText ?? "No"),
    // );
    final confirmButton = ConfirmDialogAction(
      text: confirmText ?? "Yes",
      onPressed: onConfirm ?? () => navigator.pop(true),
      textColor: confirmTextColor ?? Colors.green,
    );

    final cancelButton = ConfirmDialogAction(
      text: cancelText ?? "No",
      onPressed: onCancel ?? () => navigator.pop(false),
      textColor: cancelTextColor ?? theme.colorScheme.error,
    );
    final actions = layoutBuilder?.call(
          context,
          confirmButton,
          cancelButton,
          extraActions,
        ) ??
        [
          ...?extraActions,
          if (Platform.isWindows) ...[
            cancelButton,
            confirmButton,
          ] else ...[
            confirmButton,
            cancelButton,
          ],
        ];
    final _text = this.text;
    String text;
    if (_text is String) {
      text = _text;
    } else if (_text is String Function(BuildContext)) {
      text = _text(context);
    } else {
      throw Exception('text must be a String or a String Function(BuildContext)');
    }
    return ConstrainedDialog(
      child: WillPopScope(
        onWillPop: () => Future.value(false),
        child: AlertDialog(
          title: Center(
            child: Text(title ?? "Confirm"),
          ),
          content: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: actions
              .map((e) => TextButton(
                    onPressed: e.onPressed,
                    style: TextButton.styleFrom(foregroundColor: e.textColor),
                    child: Text(e.text),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
