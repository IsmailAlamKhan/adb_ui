import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../shared/widgets/async_value_builder.dart';
import '../../utils/extensions.dart';
import '../features.dart';

class HomeViewContent extends ConsumerWidget {
  const HomeViewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectedDevices = ref.watch(connectedDevicesProvider);
    return AsyncValueBuilder(
      value: connectedDevices,
      builder: (context, connectedDevices) {
        if (connectedDevices.isEmpty) {
          return const Center(child: Text('No connected devices'));
        }
        return CustomScrollView(
          slivers: [
            SliverPinnedHeader(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${connectedDevices.length} Connected device(s)',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: connectedDevices.length,
                (context, index) {
                  final device = connectedDevices[index];
                  return ListTile(
                    title: Text.rich(
                      TextSpan(
                        text: device.model,
                        children: [
                          if (device.isOffline)
                            TextSpan(
                              text: ' (Offline)',
                              style: Theme.of(context).textTheme.caption,
                            ),
                        ],
                      ),
                    ),
                    subtitle: Text(device.id),
                    onTap: () => Navigator.of(context).showDialog(
                      pageBuilder: (context) => AdbDeviceDialog(device: device),
                    ),
                  );
                },
              ),
            )
          ],
        );
      },
    );
  }
}
