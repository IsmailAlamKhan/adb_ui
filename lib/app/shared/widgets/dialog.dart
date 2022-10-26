import 'package:flutter/material.dart';

class DialogWrapper extends StatelessWidget {
  const DialogWrapper({
    super.key,
    required this.child,
  });
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800), child: child),
    );
  }
}
