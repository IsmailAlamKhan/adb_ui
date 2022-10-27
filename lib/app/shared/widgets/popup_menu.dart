import 'package:flutter/material.dart';

class PopupMenu<T> extends StatelessWidget {
  const PopupMenu({
    super.key,
    required this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
  });
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final T? initialValue;
  final PopupMenuCanceled? onCanceled;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: Theme.of(context).copyWith(useMaterial3: false),
      child: PopupMenuButton<T>(
        itemBuilder: itemBuilder,
        initialValue: initialValue,
        onSelected: onSelected,
        onCanceled: onCanceled,
        tooltip: tooltip,
      ),
    );
  }
}
