import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADB')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final adb = ref.read(adbControllerProvider);
          adb.connect();
        },
        tooltip: 'Connect wireless',
        child: const Icon(Icons.wifi),
      ),
      body: const HomeViewContent(),
    );
  }
}
