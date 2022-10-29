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
    this.forceSize = false,
    required this.child,
  });
  final bool forceSize;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    Widget child = this.child;
    if (forceSize) {
      child = Center(
        child: SizedBox(
          width: 800,
          height: 600,
          child: child,
        ),
      );
    } else {
      child = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
            maxHeight: 600,
          ),
          child: child,
        ),
      );
    }

    return child;
  }
}
