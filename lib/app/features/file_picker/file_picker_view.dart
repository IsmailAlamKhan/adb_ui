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
  });

  const factory FilePickerView.apk() = _FilePickerViewApk;
  final FileType fileType;
  final List<String>? allowedExtensions;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDragging = useState(false);
    final pickedFile = useState<XFile?>(null);
    final errorMsg = useState<String?>(null);
    return AlertDialog(
      content: InkWell(
        onTap: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['apk'],
          );

          if (result != null) {
            pickedFile.value = XFile(result.files.single.path!);
            errorMsg.value = null;
          }
        },
        child: DropTarget(
          onDragDone: (details) {
            errorMsg.value = null;
            if (details.files.length > 1) {
              errorMsg.value = 'You can only drop one file at a time';
              return;
            }

            final file = details.files.first;
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
              pickedFile.value = details.files.first;
            } else {
              errorMsg.value = 'Invalid file type';
            }
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
            file: pickedFile.value,
            errorMsg: errorMsg.value,
          ),
        ),
      ),
      actions: [
        if (pickedFile.value != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(pickedFile.value!.path),
            child: const Text('OK'),
          ),
      ],
    );
  }
}

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    super.key,
    this.file,
    required this.isDragging,
    required this.errorMsg,
  });
  final XFile? file;
  final bool isDragging;
  final String? errorMsg;
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Builder(
                builder: (context) {
                  Widget child;
                  if (file == null) {
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
                    child = Center(child: Text(file!.name));
                  }
                  return child;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilePickerViewApk extends FilePickerView {
  const _FilePickerViewApk({super.key})
      : super(allowedExtensions: const ['apk'], fileType: FileType.custom);
}
