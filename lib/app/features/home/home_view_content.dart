import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
        return ListView.builder(
          itemCount: connectedDevices.length,
          itemBuilder: (context, index) {
            final device = connectedDevices[index];
            return ListTile(
              title: Text(device.type),
              subtitle: Text(device.id),
              onTap: () => Navigator.of(context).showDialog(
                pageBuilder: (context) => AdbDeviceDialog(device: device),
              ),
            );
          },
        );
      },
    );
  }
}
