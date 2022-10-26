import 'package:flutter/material.dart';

import '../../utils/utils.dart';

typedef ConfirmDialogLayoutBuilder = List<Widget> Function(
  BuildContext context,
  Widget confirm,
  Widget cancel,
  List<Widget>? extraActions,
);

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
  final List<Widget>? extraActions;
  final ConfirmDialogLayoutBuilder? layoutBuilder;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    final confirmButton = ElevatedButton(
      onPressed: onConfirm ?? () => navigator.pop(true),
      style: ElevatedButton.styleFrom(
        foregroundColor: confirmTextColor ?? theme.colorScheme.primary,
      ).filled(context),
      child: Text(confirmText ?? "Yes"),
    );
    final cancelButton = ElevatedButton(
      onPressed: onCancel ?? () => navigator.pop(false),
      style: ElevatedButton.styleFrom(
        foregroundColor: cancelTextColor ?? theme.colorScheme.error,
      ).filled(context),
      child: Text(confirmText ?? "No"),
    );
    final actions = layoutBuilder?.call(
          context,
          confirmButton,
          cancelButton,
          extraActions,
        ) ??
        [...?extraActions, cancelButton, confirmButton];
    final _text = this.text;
    String text;
    if (_text is String) {
      text = _text;
    } else if (_text is String Function(BuildContext)) {
      text = _text(context);
    } else {
      throw Exception('text must be a String or a String Function(BuildContext)');
    }
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: AlertDialog(
        title: Center(
          child: Text(title ?? "Confirm"),
        ),
        content: Text(
          text,
          style: Theme.of(context).textTheme.bodyText2,
        ),
        actions: actions,
      ),
    );
  }
}
