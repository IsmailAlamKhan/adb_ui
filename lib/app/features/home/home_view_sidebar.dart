import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

class HomeViewSidebar extends ConsumerWidget {
  const HomeViewSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          title: const Text('Connect'),
          onTap: () {
            final adb = ref.read(adbControllerProvider);
            adb.connect();
          },
        ),
      ],
    );
  }
}
