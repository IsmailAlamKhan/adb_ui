import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class AdaptiveDialog extends StatelessWidget {
  const AdaptiveDialog({
    super.key,
    required this.child,
  });
  final Widget child;
  @override
  Widget build(BuildContext context) {
    Widget child = this.child;
    if (isTabletOrLarger(context)) {
      child = Center(
        child: ConstrainedDialog(
          forceSize: true,
          child: Dialog(clipBehavior: Clip.antiAlias, child: child),
        ),
      );
    }
    return child;
  }
}

class ConstrainedDialog extends StatelessWidget {
  const ConstrainedDialog({
    super.key,
    bool? forceSize,
    this.forceHeight = true,
    this.forceWidth = true,
    required this.child,
  }) : forceSize = forceSize ?? (forceHeight || forceWidth);

  static const defaultConstraints = BoxConstraints(maxWidth: 800, maxHeight: 600);
  final bool forceSize;
  final bool forceHeight;
  final bool forceWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget child = this.child;
    if (forceSize) {
      child = Center(
        child: SizedBox(
          width: forceWidth ? defaultConstraints.maxWidth : null,
          height: forceHeight ? defaultConstraints.maxHeight : null,
          child: child,
        ),
      );
    } else {
      child = Center(child: ConstrainedBox(constraints: defaultConstraints, child: child));
    }

    return child;
  }
}
