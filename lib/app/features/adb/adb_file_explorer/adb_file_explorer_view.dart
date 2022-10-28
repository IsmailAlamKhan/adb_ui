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
    }, [openReason, device]);
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
                  title: _DirTextField(
                    value: '/${controller.history.join('/')}',
                    onSubmit: controller.goToPath,
                  ),
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
                      leading: SizedBox(
                        width: 30,
                        child: AnimatedSwitcher(
                          duration: AppTheme.defaultDuration,
                          child: Icon(
                            fileSelected
                                ? Icons.check_box
                                : file is AdbFile
                                    ? Icons.insert_drive_file
                                    : Icons.folder,
                            key: ValueKey(fileSelected),
                          ),
                        ),
                      ),
                      onTap: () => controller.onTap(file),
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

class _DirTextField extends HookConsumerWidget {
  const _DirTextField({
    super.key,
    required this.value,
    required this.onSubmit,
  });
  final String value;
  final ValueChanged<String> onSubmit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tec = useTextEditingController(text: value);
    useEffect(() {
      tec.text = value;
    }, [value]);
    return AnimatedTheme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
              border: InputBorder.none,
              disabledBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorBorder: InputBorder.none,
            ),
      ),
      child: TextField(
        controller: tec,
        decoration: const InputDecoration.collapsed(
          hintText: 'Enter directory',
        ),
        onSubmitted: onSubmit,
      ),
    );
  }
}
