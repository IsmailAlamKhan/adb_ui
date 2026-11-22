import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../design/design.dart';
import '../../features.dart';

enum AdbFileExplorerOpenReason { pickFile, pickFolder }

/// Common places on Android storage, shown as shortcuts.
const deviceQuickPlaces = [
  ('Internal storage', '/sdcard', Icons.smartphone_rounded),
  ('Download', '/sdcard/Download', Icons.download_rounded),
  ('DCIM', '/sdcard/DCIM', Icons.photo_camera_outlined),
  ('Pictures', '/sdcard/Pictures', Icons.image_outlined),
  ('Documents', '/sdcard/Documents', Icons.description_outlined),
];

/// Chooses a folder (push destination) or files (pull) on the device.
/// Pops a `String` folder path, or a `List<String>` of file paths; null on cancel.
/// State is local, so selections never leak between openings (spec/08-redesign.md).
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
    final pathController = useTextEditingController(text: initialPath);
    useEffect(() {
      pathController.text = path.value;
      return null;
    }, [path.value]);

    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final pickFolder = openReason == AdbFileExplorerOpenReason.pickFolder;
    final query = (device: device, path: path.value);
    final files = ref.watch(adbFilesProvider(query));
    final screen = MediaQuery.sizeOf(context);
    final compact = WindowSize.of(context).isCompact;

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
    }

    void up() {
      if (path.value == '/') return;
      final parent = path.value.substring(0, path.value.lastIndexOf('/'));
      go(parent.isEmpty ? '/' : parent);
    }

    String child(String name) => path.value == '/' ? '/$name' : '${path.value}/$name';

    final crumbs = path.value.split('/').where((e) => e.isNotEmpty).toList();

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
      error: (e, _) => ErrorPanel(
        error: e,
        compact: true,
        onRetry: () async => ref.invalidate(adbFilesProvider(query)),
      ),
      data: (entries) {
        final visible = pickFolder ? entries.whereType<AdbDirectory>().toList() : entries;
        if (visible.isEmpty) {
          return Center(
            child: Text(
              pickFolder ? 'No folders here. Choose this folder, or go up.' : 'This folder is empty.',
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
              selected: isSelected,
              leading: isDir
                  ? Icon(Icons.folder_rounded, color: t.accent)
                  : Checkbox(value: isSelected, onChanged: (_) => toggle()),
              title: Text(entry.name, overflow: TextOverflow.ellipsis),
              trailing: isDir ? const Icon(Icons.chevron_right_rounded) : null,
              onTap: isDir ? () => go(full) : toggle,
            );
          },
        );
      },
    );

    final count = selected.value.length;
    final primaryLabel = pickFolder
        ? 'Push here'
        : count == 0
            ? 'Pull'
            : 'Pull $count ${count == 1 ? 'file' : 'files'}';
    final primary = FilledButton(
      onPressed: pickFolder
          ? () => Navigator.of(context).pop(path.value)
          : count == 0
              ? null
              : () => Navigator.of(context).pop(selected.value.toList()),
      child: Text(primaryLabel),
    );

    return Dialog(
      insetPadding: compact ? EdgeInsets.zero : const EdgeInsets.all(24),
      child: SizedBox(
        width: compact ? screen.width : (screen.width - 80).clamp(360.0, 720.0),
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
                pickFolder
                    ? 'Open the folder on ${device.displayName} where the files should go.'
                    : 'Tick the files on ${device.displayName} to copy to this computer.',
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
                      TextButton(
                        onPressed: () => go('/${crumbs.sublist(0, i + 1).join('/')}'),
                        child: Text(crumbs[i]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: t.borderRadiusLarge,
                    border: Border.fromBorderSide(t.subtleSide),
                  ),
                  child: ClipRRect(borderRadius: t.borderRadiusLarge, child: list),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pickFolder ? 'Destination: ${path.value}' : (count == 0 ? 'No files selected' : '$count selected'),
                      style: AppThemeFactory.mono(t, size: 12, color: t.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!pickFolder && count > 0)
                    TextButton(onPressed: () => selected.value = {}, child: const Text('Clear')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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
