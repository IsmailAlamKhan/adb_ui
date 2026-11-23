import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/design.dart';
import '../adb/adb.dart';
import '../errors/errors.dart';
import 'file_preview_model.dart';
import 'file_preview_service.dart';

/// Opens the large preview ("Quick Look") for [files] at [index] (spec/features/file-preview.md).
Future<void> showFilePreview(
  BuildContext context, {
  required AdbDevice device,
  required List<String> files,
  required int index,
}) => showDialog<void>(
  context: context,
  builder: (_) => FilePreviewDialog(device: device, files: files, initialIndex: index),
);

/// Side pane: preview, file info and actions for one device file.
class FilePreviewPane extends ConsumerWidget {
  const FilePreviewPane({super.key, required this.device, required this.path, this.onExpand});
  final AdbDevice device;
  final String? path;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final decoration = BoxDecoration(
      color: t.surface,
      borderRadius: t.borderRadiusLarge,
      border: Border.fromBorderSide(t.subtleSide),
    );
    if (path == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.preview_outlined, size: 36, color: t.textMuted),
                const SizedBox(height: 10),
                Text(
                  'Select a file to preview it',
                  style: TextStyle(color: t.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final query = (device: device, path: path!);
    final preview = ref.watch(filePreviewProvider(query));
    final info = preview.valueOrNull?.info;
    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: t.borderRadius,
                child: preview.when(
                  skipLoadingOnReload: false,
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorPanel(
                    error: e,
                    compact: true,
                    onRetry: () async => ref.invalidate(filePreviewProvider(query)),
                  ),
                  data: (data) => FilePreviewContent(data: data, compact: true),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(path!.split('/').last, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              info == null ? '…' : '${formatFileSize(info.size)} · ${_date(info.modified)}',
              style: TextStyle(color: t.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              path!,
              style: AppThemeFactory.mono(t, size: 11, color: t.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            _PreviewActions(device: device, path: path!, onExpand: onExpand),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

class _PreviewActions extends HookConsumerWidget {
  const _PreviewActions({required this.device, required this.path, this.onExpand});
  final AdbDevice device;
  final String path;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opening = useState(false);
    final adb = ref.read(adbControllerProvider);

    Future<void> open() async {
      opening.value = true;
      try {
        final service = ref.read(filePreviewServiceProvider);
        final info = await service.stat(device, path);
        final file = await service.pullToCache(device, info);
        if (!await launchUrl(Uri.file(file.path))) {
          adb.showToast(tone: ToastTone.info, title: 'No app on this computer opens this file', message: file.path);
        }
      } catch (e) {
        adb.showError(e);
      } finally {
        opening.value = false;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonalIcon(
          onPressed: () => adb.pullFile(device, files: [path]),
          icon: const Icon(Icons.file_download_rounded, size: 18),
          label: const Text('Pull…'),
        ),
        OutlinedButton.icon(
          onPressed: opening.value ? null : open,
          icon: opening.value
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Open'),
        ),
        if (onExpand != null)
          IconButton(
            tooltip: 'Large preview (Space)',
            onPressed: onExpand,
            icon: const Icon(Icons.open_in_full_rounded, size: 18),
          ),
      ],
    );
  }
}

/// The preview itself: image, player, text, or a "no preview" note.
class FilePreviewContent extends StatelessWidget {
  const FilePreviewContent({super.key, required this.data, this.compact = false});
  final FilePreviewData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    if (data.tooBig) {
      return _Note(
        icon: Icons.inventory_2_outlined,
        title: 'Too big to preview here',
        message: '${formatFileSize(data.info.size)}. Use Pull… or Open.',
      );
    }
    switch (data.kind) {
      case FilePreviewKind.image:
        return ColoredBox(
          color: t.surfaceAlt,
          child: Image.file(
            data.file!,
            fit: BoxFit.scaleDown, // small images at their real size, big ones fitted
            errorBuilder: (_, __, ___) => const _Note(
              icon: Icons.broken_image_outlined,
              title: "Couldn't show this image",
              message: 'Try Open to view it in another app.',
            ),
          ),
        );
      case FilePreviewKind.video:
      case FilePreviewKind.audio:
        return _MediaPreview(
          key: ValueKey(data.file!.path),
          path: data.file!.path,
          audio: data.kind == FilePreviewKind.audio,
        );
      case FilePreviewKind.text:
        return ColoredBox(
          color: t.terminal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    data.text!.isEmpty ? '(empty file)' : data.text!,
                    style: AppThemeFactory.mono(t, size: compact ? 11.5 : 13, color: t.onTerminal),
                  ),
                ),
              ),
              if (data.truncated)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Text(
                    'Showing the first 256 KB of ${formatFileSize(data.info.size)}.',
                    style: TextStyle(color: t.onTerminalMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      case FilePreviewKind.other:
        return const _Note(
          icon: Icons.insert_drive_file_outlined,
          title: 'No preview for this kind of file',
          message: 'Use Open to view it in an app on this computer.',
        );
    }
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return ColoredBox(
      color: t.surfaceAlt,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: t.textMuted),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(color: t.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plays a pulled video or audio file with desktop controls; paused until the user plays.
class _MediaPreview extends HookWidget {
  const _MediaPreview({super.key, required this.path, required this.audio});
  final String path;
  final bool audio;

  @override
  Widget build(BuildContext context) {
    final player = useMemoized(Player.new);
    final controller = useMemoized(() => VideoController(player));
    useEffect(() {
      player.open(Media(Uri.file(path).toString()), play: false);
      return player.dispose;
    }, const []);
    final t = AppTokens.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: audio ? Center(child: Icon(Icons.music_note_rounded, size: 48, color: t.onTerminalMuted)) : null,
        ),
        Video(
          controller: controller,
          controls: MaterialDesktopVideoControls,
          fill: audio ? Colors.transparent : Colors.black,
        ),
      ],
    );
  }
}

/// Large preview with ← / → between the folder's files; Esc or Space closes.
class FilePreviewDialog extends HookConsumerWidget {
  const FilePreviewDialog({super.key, required this.device, required this.files, required this.initialIndex});
  final AdbDevice device;
  final List<String> files;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = useState(initialIndex.clamp(0, files.length - 1));
    final path = files[index.value];
    final query = (device: device, path: path);
    final preview = ref.watch(filePreviewProvider(query));
    final size = MediaQuery.sizeOf(context);
    final compact = WindowSize.of(context).isCompact;
    final t = AppTokens.of(context);
    final info = preview.valueOrNull?.info;

    void move(int delta) {
      final next = index.value + delta;
      if (next >= 0 && next < files.length) index.value = next;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => move(1),
        const SingleActivator(LogicalKeyboardKey.space): () => Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          insetPadding: compact ? EdgeInsets.zero : const EdgeInsets.all(32),
          child: SizedBox(
            width: compact ? size.width : size.width - 64,
            height: compact ? size.height : size.height - 64,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              path.split('/').last,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              [
                                '${index.value + 1} of ${files.length}',
                                if (info != null) formatFileSize(info.size),
                                if (info != null) _date(info.modified),
                              ].join(' · '),
                              style: TextStyle(color: t.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Previous (←)',
                        onPressed: index.value > 0 ? () => move(-1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        tooltip: 'Next (→)',
                        onPressed: index.value < files.length - 1 ? () => move(1) : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                      IconButton(
                        tooltip: 'Close (Esc)',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: t.borderRadiusLarge,
                      child: preview.when(
                        skipLoadingOnReload: false,
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            ErrorPanel(error: e, onRetry: () async => ref.invalidate(filePreviewProvider(query))),
                        data: (data) => FilePreviewContent(data: data),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PreviewActions(device: device, path: path),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
