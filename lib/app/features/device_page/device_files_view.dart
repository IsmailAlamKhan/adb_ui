import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// Workbench "Files" tab: browse, select, pull, push, drop to push.
/// State is local, so selections don't leak between devices or folders (06 #5).
class DeviceFilesView extends HookConsumerWidget {
  const DeviceFilesView({super.key, required this.device});
  final AdbDevice device;

  static const _start = ['sdcard'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segments = useState<List<String>>(_start);
    final selected = useState<Set<String>>({});
    final dragging = useState(false);
    final pathController = useTextEditingController();
    final path = '/${segments.value.join('/')}';
    useEffect(() {
      pathController.text = path;
      return null;
    }, [path]);
    useEffect(() {
      segments.value = _start;
      selected.value = {};
      return null;
    }, [device.id]);

    final query = (device: device, path: path);
    final files = ref.watch(adbFilesProvider(query));
    final adb = ref.read(adbControllerProvider);
    final t = AppTokens.of(context);

    void open(List<String> next) {
      segments.value = next;
      selected.value = {};
    }

    return DropTarget(
      onDragEntered: (_) => dragging.value = true,
      onDragExited: (_) => dragging.value = false,
      onDragDone: (details) {
        dragging.value = false;
        final paths = details.files.map((f) => f.path).toList();
        if (paths.isNotEmpty) adb.pushFile(device, files: paths, destination: path);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Up one folder',
                onPressed: segments.value.isEmpty
                    ? null
                    : () => open(segments.value.sublist(0, segments.value.length - 1)),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: pathController,
                  style: AppThemeFactory.mono(t, size: 13),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.folder_open_rounded, size: 18),
                    hintText: '/sdcard',
                  ),
                  onSubmitted: (value) =>
                      open(value.split('/').where((e) => e.trim().isNotEmpty).toList()),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(adbFilesProvider(query)),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: selected.value.isEmpty
                    ? null
                    : () => adb.pullFile(device, files: selected.value.toList()),
                icon: const Icon(Icons.file_download_rounded, size: 18),
                label: Text(selected.value.isEmpty ? 'Pull selected' : 'Pull ${selected.value.length} selected…'),
              ),
              OutlinedButton.icon(
                onPressed: () => adb.pushFile(device, destination: path),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Push files here…'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: dragging.value ? t.accentSoft : t.surface,
                borderRadius: t.borderRadiusLarge,
                border: Border.all(
                  color: dragging.value ? t.accent : t.borderSubtle,
                  width: dragging.value ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: t.borderRadiusLarge,
                child: files.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorPanel(
                    error: e,
                    compact: true,
                    onRetry: () async => ref.invalidate(adbFilesProvider(query)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'This folder is empty. Drop files here to push them.',
                          style: TextStyle(color: t.textMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final entry = list[index];
                        final isDir = entry is AdbDirectory;
                        final full = '$path/${entry.name}';
                        final isSelected = selected.value.contains(full);
                        return ListTile(
                          selected: isSelected,
                          leading: isDir
                              ? Icon(Icons.folder_rounded, color: t.accent)
                              : Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggle(selected, full),
                                ),
                          title: Text(entry.name),
                          trailing: isDir ? const Icon(Icons.chevron_right_rounded) : null,
                          onTap: () => isDir
                              ? open([...segments.value, entry.name])
                              : _toggle(selected, full),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dragging.value ? 'Drop to push into $path' : 'Tip: drop files from your computer here to push them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _toggle(ValueNotifier<Set<String>> selected, String path) {
    final next = {...selected.value};
    if (!next.remove(path)) next.add(path);
    selected.value = next;
  }
}
