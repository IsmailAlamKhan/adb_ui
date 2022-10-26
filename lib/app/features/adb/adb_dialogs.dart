import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

class AdbInputDialog extends HookWidget {
  const AdbInputDialog({
    super.key,
    required this.title,
    required this.inputs,
  });

  factory AdbInputDialog.single({
    Key? key,
    required String title,
    required String label,
    required String inputKey,
  }) {
    return AdbInputDialog(
      key: key,
      title: title,
      inputs: {
        inputKey: (controller) => AdbInputDialogInput(
              controller: controller,
              label: label,
            ),
      },
    );
  }
  final String title;
  final Map<String, Widget Function(TextEditingController)> inputs;
  @override
  Widget build(BuildContext context) {
    final inputs = this.inputs.values.toList();
    final tec = inputs.map((_) => useTextEditingController()).toList();
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < inputs.length; i++) inputs[i](tec[i])],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final map = <String, String>{
              for (var i = 0; i < this.inputs.keys.length; i++)
                this.inputs.keys.elementAt(i): tec[i].text,
            };
            Navigator.of(context).pop(map);
          },
          child: const Text('OK'),
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
              ]
            ],
          ),
        ),
      ),
    );
  }
}
