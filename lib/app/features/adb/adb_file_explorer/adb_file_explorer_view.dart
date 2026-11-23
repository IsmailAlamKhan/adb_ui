import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../design/design.dart';
import '../../features.dart';

/// `pickFile` chooses files to pull; `push` browses to a folder and pushes into it.
enum AdbFileExplorerOpenReason { pickFile, push }

/// Common places on Android storage, shown as shortcuts.
const deviceQuickPlaces = [
  ('Internal storage', '/sdcard', Icons.smartphone_rounded),
  ('Download', '/sdcard/Download', Icons.download_rounded),
  ('DCIM', '/sdcard/DCIM', Icons.photo_camera_outlined),
  ('Pictures', '/sdcard/Pictures', Icons.image_outlined),
  ('Documents', '/sdcard/Documents', Icons.description_outlined),
];

/// Browses the device's files (spec/features/file-explorer-transfer.md).
/// `pickFile` pops a `List<String>` of files to pull (null on cancel); `push` pushes into the
/// open folder (computer's file picker or drop) and stays open until Done.
/// Files are previewed in a side pane (spec/features/file-preview.md).
/// State is local, so selections never leak between openings.
class AdbFileExplorerView extends HookConsumerWidget {
  const AdbFileExplorerView({
    super.key,
    this.title = 'Choose files',
    required this.device,
    this.openReason = AdbFileExplorerOpenReason.pickFile,
    this.initialPath = '/sdcard',
  });
  final AdbDevice device;
  final String title;
  final AdbFileExplorerOpenReason openReason;
  final String initialPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = useState(initialPath);
    final history = useState<List<String>>([]);
    final selected = useState<Set<String>>({});
    final previewed = useState<String?>(null);
    final dragging = useState(false);
    final pushing = useState(false);
    final listFocus = useFocusNode(debugLabel: 'device files');
    // Drops on this browser push here, so the window-wide APK drop zone must ignore them.
    final dropKey = useMemoized(GlobalKey.new);
    useEffect(() {
      if (openReason != AdbFileExplorerOpenReason.push) return null;
      ApkDropZone.exclude(dropKey);
      return () => ApkDropZone.include(dropKey);
    }, const []);
    final pathController = useTextEditingController(text: initialPath);
    useEffect(() {
      pathController.text = path.value;
      return null;
    }, [path.value]);

    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final pushMode = openReason == AdbFileExplorerOpenReason.push;
    final query = (device: device, path: path.value);
    final files = ref.watch(adbFilesProvider(query));
    final screen = MediaQuery.sizeOf(context);
    final compact = WindowSize.of(context).isCompact;
    final adb = ref.read(adbControllerProvider);

    // A remembered push folder may be gone: fall back to /sdcard.
    final missing = files.hasError && path.value == initialPath && initialPath != '/sdcard';
    useEffect(() {
      if (missing) path.value = '/sdcard';
      return null;
    }, [missing]);

    void go(String next) {
      var normalized = next.trim().replaceAll(RegExp(r'/+'), '/');
      if (normalized.isEmpty) normalized = '/';
      if (!normalized.startsWith('/')) normalized = '/$normalized';
      if (normalized.length > 1 && normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      if (normalized == path.value) return;
      history.value = [...history.value, path.value];
      path.value = normalized;
      previewed.value = null;
    }

    void up() {
      if (path.value == '/') return;
      final parent = path.value.substring(0, path.value.lastIndexOf('/'));
      go(parent.isEmpty ? '/' : parent);
    }

    String child(String name) => path.value == '/' ? '/$name' : '${path.value}/$name';

    final crumbs = path.value.split('/').where((e) => e.isNotEmpty).toList();

    void openLarge(String file, List<AdbFileSystem> entries) {
      final names = [
        for (final e in entries)
          if (e is AdbFile) child(e.name),
      ];
      showFilePreview(context, device: device, files: names, index: names.indexOf(file).clamp(0, names.length - 1));
    }

    Future<void> pushInto(List<String>? local) async {
      pushing.value = true;
      try {
        await adb.pushFile(device, files: local, destination: path.value);
      } finally {
        if (context.mounted) pushing.value = false;
      }
    }

    final places = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, target, icon) in deviceQuickPlaces)
          ChoiceChip(
            avatar: Icon(icon, size: 16),
            label: Text(label),
            selected: path.value == target,
            showCheckmark: false,
            onSelected: (_) => go(target),
          ),
      ],
    );

    final list = files.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          ErrorPanel(error: e, compact: true, onRetry: () async => ref.invalidate(adbFilesProvider(query))),
      data: (entries) {
        final visible = entries;
        if (visible.isEmpty) {
          return Center(
            child: Text(
              pushMode ? 'This folder is empty. Push files here, or drop them.' : 'This folder is empty.',
              style: TextStyle(color: t.textMuted),
            ),
          );
        }
        return ListView.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final entry = visible[index];
            final isDir = entry is AdbDirectory;
            final full = child(entry.name);
            final isSelected = selected.value.contains(full);
            void toggle() {
              final next = {...selected.value};
              if (!next.remove(full)) next.add(full);
              selected.value = next;
            }

            return ListTile(
              selected: isSelected || previewed.value == full,
              leading: isDir
                  ? Icon(Icons.folder_rounded, color: t.accent)
                  : pushMode
                  ? Icon(fileKindIcon(full), color: t.textMuted)
                  : Checkbox(value: isSelected, onChanged: (_) => toggle()),
              title: Text(entry.name, overflow: TextOverflow.ellipsis),
              trailing: isDir ? const Icon(Icons.chevron_right_rounded) : null,
              onTap: isDir
                  ? () => go(full)
                  : () {
                      if (!pushMode) toggle();
                      listFocus.requestFocus();
                      if (compact) {
                        openLarge(full, entries);
                      } else {
                        previewed.value = full;
                      }
                    },
            );
          },
        );
      },
    );

    final count = selected.value.length;
    final primary = pushMode
        ? FilledButton.icon(
            onPressed: pushing.value ? null : () => pushInto(null),
            icon: pushing.value
                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Push files here…'),
          )
        : FilledButton(
            onPressed: count == 0 ? null : () => Navigator.of(context).pop(selected.value.toList()),
            child: Text(count == 0 ? 'Pull' : 'Pull $count ${count == 1 ? 'file' : 'files'}'),
          );

    return Dialog(
      insetPadding: compact ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: SizedBox(
        width: compact ? screen.width : (screen.width - 80).clamp(360.0, 1100.0),
        height: compact ? screen.height : (screen.height - 80).clamp(420.0, 780.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: text.headlineSmall)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                pushMode
                    ? 'Open the folder where the files should go, then push files from your computer or drop them here.'
                    : 'Tick the files on ${device.displayName} to copy to this computer. Click a file to preview it.',
                style: TextStyle(color: t.textMuted),
              ),
              const SizedBox(height: 14),
              places,
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: history.value.isEmpty
                        ? null
                        : () {
                            final h = [...history.value];
                            path.value = h.removeLast();
                            history.value = h;
                          },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  IconButton(
                    tooltip: 'Up one folder',
                    onPressed: path.value == '/' ? null : up,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: pathController,
                      style: AppThemeFactory.mono(t, size: 13),
                      onSubmitted: go,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.folder_open_rounded, size: 18),
                        hintText: '/sdcard',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => ref.invalidate(adbFilesProvider(query)),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Breadcrumbs: click any part to jump there.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TextButton(onPressed: () => go('/'), child: const Text('/')),
                    for (var i = 0; i < crumbs.length; i++) ...[
                      Icon(Icons.chevron_right_rounded, size: 16, color: t.textMuted),
                      TextButton(onPressed: () => go('/${crumbs.sublist(0, i + 1).join('/')}'), child: Text(crumbs[i])),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.space): () {
                      final current = previewed.value;
                      final entries = files.valueOrNull;
                      if (current != null && entries != null) openLarge(current, entries);
                    },
                  },
                  child: Focus(
                    focusNode: listFocus,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 11,
                          child: DropTarget(
                            key: dropKey,
                            enable: pushMode,
                            onDragEntered: (_) => dragging.value = true,
                            onDragExited: (_) => dragging.value = false,
                            onDragDone: (details) {
                              dragging.value = false;
                              final local = details.files.map((f) => f.path).toList();
                              if (local.isNotEmpty) pushInto(local);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: dragging.value ? t.accentSoft : t.surface,
                                borderRadius: t.borderRadiusLarge,
                                border: dragging.value
                                    ? Border.all(color: t.accent, width: 2)
                                    : Border.fromBorderSide(t.subtleSide),
                              ),
                              child: ClipRRect(
                                borderRadius: t.borderRadiusLarge,
                                child: dragging.value
                                    ? Center(
                                        child: Text(
                                          'Drop to push into ${path.value}',
                                          style: TextStyle(color: t.onAccentSoft, fontWeight: FontWeight.w600),
                                        ),
                                      )
                                    : list,
                              ),
                            ),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 9,
                            child: FilePreviewPane(
                              device: device,
                              path: previewed.value,
                              onExpand: previewed.value == null || files.valueOrNull == null
                                  ? null
                                  : () => openLarge(previewed.value!, files.valueOrNull!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pushMode ? 'Pushing into ${path.value}' : (count == 0 ? 'No files selected' : '$count selected'),
                      style: AppThemeFactory.mono(t, size: 12, color: t.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!pushMode && count > 0)
                    TextButton(onPressed: () => selected.value = {}, child: const Text('Clear')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(pushMode ? 'Done' : 'Cancel'),
                  ),
                  const SizedBox(width: 8),
                  primary,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon for a file by its preview kind.
IconData fileKindIcon(String path) => switch (FilePreviewKind.of(path)) {
  FilePreviewKind.image => Icons.image_outlined,
  FilePreviewKind.video => Icons.movie_outlined,
  FilePreviewKind.audio => Icons.music_note_outlined,
  FilePreviewKind.text => Icons.description_outlined,
  FilePreviewKind.other => Icons.insert_drive_file_outlined,
};
