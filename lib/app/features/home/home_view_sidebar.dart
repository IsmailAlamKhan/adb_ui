import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

class HomeViewSideBar extends ConsumerWidget {
  const HomeViewSideBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adb = ref.read(adbControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onTap: adb.connect,
          title: const Text('Connect wireless'),
          leading: const Icon(Icons.wifi),
        ),
        ListTile(
          onTap: adb.pair,
          title: const Text('Pair'),
          leading: const Icon(Icons.wifi_find),
        ),
      ],
    );
  }
}
