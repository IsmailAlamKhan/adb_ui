import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';

class FilePickerView extends HookConsumerWidget {
  const FilePickerView({
    super.key,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.allowMultiple = true,
  });

  const factory FilePickerView.apk() = _FilePickerViewApk;
  final FileType fileType;
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDragging = useState(false);
    final pickedFiles = useState<List<XFile>>([]);
    final errorMsg = useState<String?>(null);
    return AlertDialog(
      content: DropTarget(
        onDragDone: (details) {
          errorMsg.value = null;
          if (!allowMultiple) {
            pickedFiles.value = [];
          }
          if (!allowMultiple && details.files.length > 1) {
            errorMsg.value = 'Only one file can be selected';
            return;
          }
          final files = <XFile>[];

          for (var file in details.files) {
            bool validFile = false;
            final fileExtension = file.name.split('.').last;
            switch (fileType) {
              case FileType.any:
                validFile = true;
                break;
              case FileType.media:
                validFile =
                    ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'].contains(fileExtension);
                break;
              case FileType.image:
                validFile = ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension);
                break;
              case FileType.video:
                validFile = ['mp4', 'mov', 'avi'].contains(fileExtension);
                break;
              case FileType.audio:
                validFile = ['mp3', 'wav', 'aac', 'ogg'].contains(fileExtension);
                break;
              case FileType.custom:
                validFile = allowedExtensions!.contains(fileExtension);
                break;
            }
            if (validFile) {
              // pickedFiles.value = details.files.first;
              files.add(file);
            } else {
              errorMsg.value = 'Invalid file type';
            }
          }
          pickedFiles.value = [...pickedFiles.value, ...files];
        },
        onDragEntered: (details) {
          isDragging.value = true;
          errorMsg.value = null;
        },
        onDragExited: (details) {
          isDragging.value = false;
          errorMsg.value = null;
        },
        child: _FilePicker(
          isDragging: isDragging.value,
          files: pickedFiles.value,
          errorMsg: errorMsg.value,
          onFileSelected: () async {
            final result = await FilePicker.platform.pickFiles(
              type: fileType,
              allowedExtensions: allowedExtensions,
              allowMultiple: allowMultiple,
            );

            if (result != null) {
              pickedFiles.value = [
                ...pickedFiles.value,
                ...result.files.map((e) => XFile(e.path!))
              ];

              errorMsg.value = null;
            }
          },
        ),
      ),
      actions: [
        if (pickedFiles.value.isNotEmpty)
          TextButton(
            onPressed: () {
              if (allowMultiple) {
                Navigator.of(context).pop(pickedFiles.value.map((e) => e.path).toList());
              } else {
                Navigator.of(context).pop(pickedFiles.value.first.path);
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

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    super.key,
    required this.files,
    required this.isDragging,
    required this.errorMsg,
    required this.onFileSelected,
  });
  final List<XFile> files;
  final bool isDragging;
  final String? errorMsg;
  final VoidCallback onFileSelected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDragging = this.isDragging;
    Color? background;
    if (isDragging) {
      background = surfaceTintColor(context: context, opacity: .2);
    } else if (errorMsg != null) {
      background = theme.colorScheme.error;
    }

    return AnimatedTheme(
      data: AppTheme.themeDataFrom(
        colorScheme: theme.colorScheme.copyWith(
          background: background,
          onBackground: background?.contrastColor(),
        ),
      ),
      child: SizedBox(
        height: 300,
        width: 300,
        child: Material(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onFileSelected,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Builder(
                  builder: (context) {
                    Widget child;
                    if (files.isEmpty) {
                      child = Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 50),
                            if (errorMsg != null)
                              Text(errorMsg!)
                            else
                              const Text('Drag and drop a file here or click to pick one'),
                          ],
                        ),
                      );
                    } else {
                      child = Center(
                        child: _FilePicked(files: files),
                      );
                    }
                    return child;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilePicked extends StatelessWidget {
  const _FilePicked({
    super.key,
    required this.files,
  });

  final List<XFile> files;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 50),
        const SizedBox(height: 10),
        if (files.length == 1) Text(files.first.name) else Text('${files.length} files selected'),
      ],
    );
  }
}

class _FilePickerViewApk extends FilePickerView {
  const _FilePickerViewApk({super.key})
      : super(
          allowedExtensions: const ['apk'],
          fileType: FileType.custom,
          allowMultiple: false,
        );
}
