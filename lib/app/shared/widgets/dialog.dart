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
    if (isTabletSize(context)) {
      child = Center(
        child: SizedBox(
          width: 500,
          height: 500,
          child: Dialog(clipBehavior: Clip.antiAlias, child: child),
        ),
      );
    }
    return child;
  }
}
