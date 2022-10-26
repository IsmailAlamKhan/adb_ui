import 'package:flutter/material.dart';

class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child, this.keepAlive = true});
  final Widget child;
  final bool keepAlive;
  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
