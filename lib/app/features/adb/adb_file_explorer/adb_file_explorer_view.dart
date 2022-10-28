import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../shared/widgets/async_value_builder.dart';
import '../../../utils/utils.dart';
import '../../features.dart';

enum AdbFileExplorerOpenReason { pickFile, pickFolder }

class AdbFileExplorerView extends HookConsumerWidget {
  const AdbFileExplorerView({
    super.key,
    this.title = 'File Explorer',
    required this.device,
    this.openReason = AdbFileExplorerOpenReason.pickFile,
  });
  final AdbDevice device;
  final String title;
  final AdbFileExplorerOpenReason openReason;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(adbFileExplorerControllerProvider);

    final files = ref.watch(adbFilesProvider(device: device, path: controller.currentPath));
    useEffect(() {
      controller.open(openReason);
    }, [openReason]);
    useEffect(() {
      return controller.clearSelectedFiles;
    }, []);
    return Center(
      child: SizedBox(
        height: 700,
        width: 500,
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: ListTile(
                  leading: controller.history.isNotEmpty
                      ? BackButton(onPressed: controller.goBack)
                      : null,
                  title: Text('/${controller.history.join('/')}'),
                ),
              ),
              actions: [
                if (openReason == AdbFileExplorerOpenReason.pickFile)
                  IconButton(
                    icon: Text('Selected (${controller.selectedFiles.length})'),
                    onPressed: null,
                  ),
              ],
            ),
            body: AsyncValueBuilder(
              value: files,
              onTryAgain: () async =>
                  ref.invalidate(adbFilesProvider(device: device, path: controller.currentPath)),
              builder: (_, files) {
                if (files.isEmpty) {
                  return const Center(child: Text('Empty'));
                }
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final fileSelected = controller.selectedFiles.firstWhereOrNull(
                          (element) => element.endsWith(file.name),
                        ) !=
                        null;
                    return ListTile(
                      title: Text(file.name),
                      selected: fileSelected,
                      leading: file is AdbFile ? const Icon(Icons.insert_drive_file) : null,
                      onTap: () => controller.onTap(file),
                      // onLongPress: () => controller.onLongPress(file),
                    );
                  },
                );
              },
            ),
            bottomNavigationBar: SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: controller.selectPath(),
                    style: ElevatedButton.styleFrom().filled(context),
                    child: const Text('Select'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
