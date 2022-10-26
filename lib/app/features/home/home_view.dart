import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double sidebarSize = 250;
    if (MediaQuery.of(context).size.width < 500) {
      sidebarSize = 200;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('ADB')),
      body: Row(
        children: [
          SizedBox(width: sidebarSize, child: const HomeViewSideBar()),
          const VerticalDivider(),
          const Expanded(child: HomeViewContent()),
        ],
      ),
    );
  }
}
