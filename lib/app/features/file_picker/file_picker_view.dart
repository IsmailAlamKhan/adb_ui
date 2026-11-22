import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../adb/adb_dialogs.dart';

/// Pick or drop local files. Pops a `List<String>` of paths (or one `String` for [allowMultiple]
/// false), or null on cancel.
class FilePickerView extends HookConsumerWidget {
  const FilePickerView({
    super.key,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.allowMultiple = true,
    this.title = 'Choose files to push',
  });

  const factory FilePickerView.apk() = _FilePickerViewApk;
  final FileType fileType;
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  final String title;

  bool _accepts(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (fileType) {
      FileType.any => true,
      FileType.media => ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'].contains(ext),
      FileType.image => ['jpg', 'jpeg', 'png', 'gif'].contains(ext),
      FileType.video => ['mp4', 'mov', 'avi'].contains(ext),
      FileType.audio => ['mp3', 'wav', 'aac', 'ogg'].contains(ext),
      FileType.custom => allowedExtensions!.contains(ext),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDragging = useState(false);
    final picked = useState<List<XFile>>([]);
    final error = useState<String?>(null);
    final t = AppTokens.of(context);
    final wanted = allowedExtensions?.map((e) => '.$e').join(', ');

    void add(List<XFile> files) {
      error.value = null;
      if (!allowMultiple && files.length > 1) {
        error.value = 'Choose one file';
        return;
      }
      final valid = files.where((f) => _accepts(f.name)).toList();
      if (valid.length < files.length) {
        error.value = wanted == null ? "Some files can't be used" : 'Only $wanted files can be used here';
      }
      picked.value = allowMultiple ? [...picked.value, ...valid] : valid.take(1).toList();
    }

    Future<void> browse() async {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );
      if (result != null) add(result.files.where((f) => f.path != null).map((e) => XFile(e.path!)).toList());
    }

    final hasFiles = picked.value.isNotEmpty;
    final zoneColor = isDragging.value
        ? t.accentSoft
        : error.value != null
            ? t.dangerSoft
            : t.surfaceAlt;
    final zoneBorder = isDragging.value ? t.accent : (error.value != null ? t.danger : t.borderSubtle);

    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fileType == FileType.custom ? 'Choose an APK to install' : title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              DropTarget(
                onDragEntered: (_) {
                  isDragging.value = true;
                  error.value = null;
                },
                onDragExited: (_) => isDragging.value = false,
                onDragDone: (details) {
                  isDragging.value = false;
                  add(details.files);
                },
                child: Semantics(
                  button: true,
                  label: 'Drop files here or choose from your computer',
                  child: Material(
                    color: zoneColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: t.borderRadiusLarge,
                      side: BorderSide(color: zoneBorder, width: isDragging.value ? 2 : 1),
                    ),
                    child: InkWell(
                      borderRadius: t.borderRadiusLarge,
                      onTap: browse,
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasFiles ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                              size: 40,
                              color: hasFiles ? t.success : t.textMuted,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              hasFiles
                                  ? (picked.value.length == 1
                                      ? picked.value.first.name
                                      : '${picked.value.length} files selected')
                                  : 'Drop ${allowMultiple ? 'files' : 'a file'} here, or click to choose',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (wanted != null) ...[
                              const SizedBox(height: 4),
                              Text(wanted, style: TextStyle(color: t.textMuted)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (error.value != null) ...[
                const SizedBox(height: 8),
                Text(error.value!, style: TextStyle(color: t.danger)),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasFiles)
                    TextButton(onPressed: () => picked.value = [], child: const Text('Clear')),
                  const Spacer(),
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: !hasFiles
                        ? null
                        : () => Navigator.of(context).pop(
                              allowMultiple
                                  ? picked.value.map((e) => e.path).toList()
                                  : picked.value.first.path,
                            ),
                    child: Text(fileType == FileType.custom ? 'Install' : 'Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePickerViewApk extends FilePickerView {
  const _FilePickerViewApk()
      : super(allowedExtensions: const ['apk'], fileType: FileType.custom, allowMultiple: false);
}
