import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import '../features.dart';

class AdbInputDialog extends HookWidget {
  const AdbInputDialog({
    super.key,
    required this.title,
    this.info,
    required this.inputs,
  });

  factory AdbInputDialog.single({
    Key? key,
    required String title,
    required String label,
    String? info,
  }) {
    return AdbInputDialog(
      key: key,
      title: title,
      info: info,
      inputs: {
        'input': (controller) => AdbInputDialogInput(
              controller: controller,
              label: label,
            ),
      },
    );
  }
  final String title;
  final String? info;

  final Map<String, Widget Function(TextEditingController)> inputs;
  @override
  Widget build(BuildContext context) {
    final inputs = this.inputs.values.toList();
    final tec = inputs.map((_) => useTextEditingController()).toList();
    return AlertDialog(
      title: Text.rich(
        TextSpan(
          text: title,
          children: [
            if (info != null)
              WidgetSpan(
                child: Tooltip(
                  message: info!,
                  child: const Icon(Icons.info_outline),
                ),
              ),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < inputs.length; i++) ...[
            inputs[i](tec[i]),
            if (i < inputs.length - 1) const Gap(10),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (inputs.length == 1) {
              Navigator.of(context).pop(tec[0].text);
            } else {
              final map = <String, String>{
                for (var i = 0; i < this.inputs.keys.length; i++)
                  if (tec[i].text.isNotEmpty) this.inputs.keys.elementAt(i): tec[i].text,
              };
              Navigator.of(context).pop(map);
            }
          },
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class AdbInputDialogInput extends StatelessWidget {
  const AdbInputDialogInput({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class AdbDeviceDialog extends ConsumerWidget {
  const AdbDeviceDialog({super.key, required this.device});
  final AdbDevice device;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(adbControllerProvider);
    final scrcpyAvailable = ref.watch(scrcpyAvailableProvider).whenOrNull<bool>(
              data: (value) => value,
            ) ??
        false;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          clipBehavior: Clip.antiAlias,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Copy id'),
                onTap: () {
                  Navigator.of(context).pop();
                  Clipboard.setData(ClipboardData(text: device.id));
                },
              ),
              ListTile(
                title: const Text('Disconnect'),
                subtitle: const Text('Only available for WIFI devices'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.disconnect(device);
                },
              ),
              if (!device.isOffline) ...[
                ListTile(
                  title: const Text('Install apk'),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.installApk(device);
                  },
                ),
                ListTile(
                  title: const Text('Push file'),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.pushFile(device);
                  },
                ),
                ListTile(
                  title: const Text('Pull file'),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.pullFile(device);
                  },
                ),
                ListTile(
                  title: const Text('Run command'),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.runCommand(device);
                  },
                ),
                ListTile(
                  title: const Text('Input text'),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.inputText(device);
                  },
                ),
                ListTile(
                  title: const Text('Scrcpy'),
                  enabled: scrcpyAvailable,
                  subtitle: ref.watch(scrcpyAvailableProvider).when(
                        data: (available) => available ? null : const Text('Not available'),
                        loading: () => const Text('Loading...'),
                        error: (e, s) => Text('Error: $e'),
                      ),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.runScrcpy(device);
                  },
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
