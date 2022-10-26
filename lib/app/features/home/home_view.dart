import 'package:flutter/material.dart';

import '../features.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADB'),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.of(context).pushBuilder((_) => const TerminalOutputsView());
        //     },
        //     icon: const Icon(Icons.terminal),
        //   ),
        // ],
      ),
      body: Row(
        children: const [
          SizedBox(
            width: 200,
            child: HomeViewSidebar(),
          ),
          VerticalDivider(),
          Expanded(child: HomeViewContent()),
        ],
      ),
    );
  }
}
