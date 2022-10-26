import 'dart:math' as math;

import 'package:flutter/material.dart';

class PersistentHeader extends StatelessWidget {
  const PersistentHeader({
    super.key,
    this.pinned = false,
    this.floating = false,
    this.collapsedHeight,
    required this.child,
  });
  final bool pinned;
  final bool floating;
  final double? collapsedHeight;
  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      delegate: _PersistentHeader(
        pinned: pinned,
        floating: floating,
        collapsedHeight: collapsedHeight,
        child: child,
      ),
      pinned: pinned,
      floating: floating,
    );
  }
}

class _PersistentHeader extends SliverPersistentHeaderDelegate {
  final bool pinned;
  final bool floating;
  final double? collapsedHeight;
  final PreferredSizeWidget child;
  _PersistentHeader({
    required this.pinned,
    required this.floating,
    required this.collapsedHeight,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isScrolledUnder =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()?.isScrolledUnder ??
            (overlapsContent || (pinned && shrinkOffset > maxExtent - minExtent));

    return FlexibleSpaceBar.createSettings(
      currentExtent: math.max(minExtent, maxExtent - shrinkOffset),
      isScrolledUnder: isScrolledUnder,
      minExtent: minExtent,
      maxExtent: maxExtent,
      child: child,
    );
  }

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  double get minExtent => pinned ? child.preferredSize.height : (collapsedHeight ?? 0);

  @override
  bool shouldRebuild(_PersistentHeader oldDelegate) =>
      oldDelegate.floating != floating ||
      oldDelegate.pinned != pinned ||
      oldDelegate.collapsedHeight != collapsedHeight ||
      oldDelegate.child != child;
}
