import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../shared/shared.dart';
import '../../../shared/widgets/async_value_builder.dart';
import '../../../utils/utils.dart';
import '../../features.dart';

enum AdbFileExplorerOpenReason { pickFile, pickFolder }

class AdbFileExplorerView extends HookConsumerWidget {
  const AdbFileExplorerView({
    super.key,
    required this.device,
    this.openReason = AdbFileExplorerOpenReason.pickFile,
  });
  final AdbDevice device;
  final AdbFileExplorerOpenReason openReason;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(() => AdbFileExplorerController(
          openReason: openReason,
          eventBus: ref.watch(eventBusProvider),
        ));
    useListenable(controller);

    final files = ref.watch(adbFilesProvider(device: device, path: controller.currentPath));
    return Center(
      child: SizedBox(
        height: 700,
        width: 500,
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('File Explorer'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: controller.goBack,
                      child: const Text('Back'),
                    ),
                    const Gap(10),
                    Text('/${controller.history.join('/')}'),
                  ],
                ),
              ),
            ),
            body: AsyncValueBuilder(
              value: files,
              onTryAgain: () async =>
                  ref.invalidate(adbFilesProvider(device: device, path: controller.currentPath)),
              builder: (_, files) => ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return ListTile(
                    title: Text(file.name),
                    leading: file is AdbFile ? const Icon(Icons.insert_drive_file) : null,
                    onTap: () => controller.onTap(file),
                    // onLongPress: () => controller.onLongPress(file),
                  );
                },
              ),
            ),
            bottomNavigationBar: openReason == AdbFileExplorerOpenReason.pickFolder
                ? SizedBox(
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: controller.selectPath,
                          style: ElevatedButton.styleFrom().filled(context),
                          child: const Text('Select'),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
