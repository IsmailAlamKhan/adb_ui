import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../design/design.dart';
import '../adb/adb_dialogs.dart';
import 'update_controller.dart';
import 'update_model.dart';

/// Starts update checks once the home screen is up. See spec/features/updates.md.
class UpdateChecker extends HookConsumerWidget {
  const UpdateChecker({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // After the first frame so dialogs have a navigator.
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(updateControllerProvider.notifier).start());
      return null;
    }, const []);
    return child;
  }
}

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

/// "ADB UI x is available": notes since your version, then download → install.
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final release = state.release;
    final asset = release?.installerFor(Platform.operatingSystem);
    void close() => Navigator.of(context).pop();

    final List<Widget> actions;
    Widget? status;
    switch (state.status) {
      case UpdateStatus.downloading:
        final progress = state.total > 0 ? state.received / state.total : null;
        status = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 6),
            Text(
              state.total > 0
                  ? 'Downloading ${_mb(state.received)} of ${_mb(state.total)} MB'
                  : 'Downloading ${_mb(state.received)} MB',
              style: TextStyle(color: t.textMuted),
            ),
          ],
        );
        actions = [OutlinedButton(onPressed: controller.cancelDownload, child: const Text('Cancel'))];
      case UpdateStatus.ready:
        status = const AppBanner(
          tone: BannerTone.success,
          title: 'Ready to install',
          message: 'ADB UI will close, update and reopen. Your settings and activity are kept.',
        );
        actions = [
          OutlinedButton(onPressed: close, child: const Text('Later')),
          FilledButton(
            onPressed: () async {
              final replaced = await controller.installAndRestart();
              if (!replaced && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Install and restart'),
          ),
        ];
      case UpdateStatus.installing:
        status = const Row(
          children: [
            SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Installing…'),
          ],
        );
        actions = const [];
      case UpdateStatus.failed:
        status = AppBanner(
          tone: BannerTone.danger,
          title: state.error?.title ?? "Couldn't update",
          message: state.error?.message,
        );
        actions = [
          if (asset != null)
            TextButton(onPressed: () => launchUrlString(asset.url), child: const Text('Download in browser')),
          OutlinedButton(onPressed: close, child: const Text('Close')),
          FilledButton(onPressed: controller.download, child: const Text('Try again')),
        ];
      default:
        actions = [
          TextButton(
            onPressed: () async {
              await controller.skip();
              close();
            },
            child: const Text('Skip this version'),
          ),
          OutlinedButton(onPressed: close, child: const Text('Later')),
          FilledButton(onPressed: controller.download, child: const Text('Update')),
        ];
    }

    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.system_update_alt_rounded, color: t.accent, size: 28),
              const SizedBox(height: 12),
              Text(
                release == null ? 'ADB UI is up to date' : 'ADB UI ${release.version} is available',
                style: text.headlineSmall,
              ),
              if (state.current != null) ...[
                const SizedBox(height: 4),
                Text('You have ${state.current}.', style: TextStyle(color: t.textMuted)),
              ],
              if (state.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(t.borderSide),
                      borderRadius: t.borderRadius,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final r in state.notes) ...[
                            Text('${r.version}', style: text.titleMedium),
                            const SizedBox(height: 6),
                            ReleaseNotesView(lines: releaseNoteLines(r.notes)),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (status != null) ...[const SizedBox(height: 16), status],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown once on the first start after an update.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({required this.entry, super.key});
  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: t.accent, size: 28),
              const SizedBox(height: 12),
              Text("What's new in ${entry.title}", style: text.headlineSmall),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: ReleaseNotesView(lines: entry.lines))),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every version's notes from the bundled CHANGELOG-ALL.md; works offline.
class ChangelogDialog extends HookConsumerWidget {
  const ChangelogDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(updateControllerProvider.notifier);
    final current = ref.watch(updateControllerProvider.select((s) => s.current));
    final entries = useFuture(useMemoized(controller.changelog));
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Changelog', style: text.headlineSmall)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: switch (entries) {
                AsyncSnapshot(hasError: true) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text("Couldn't read the changelog.", style: TextStyle(color: t.textMuted)),
                  ),
                AsyncSnapshot(:final data?) => ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    children: [
                      for (final e in data) ...[
                        Row(
                          children: [
                            Text(e.title, style: text.titleMedium),
                            if (current != null && e.version == current) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: t.accentSoft, borderRadius: t.borderRadius),
                                child: Text('Installed', style: TextStyle(color: t.onAccentSoft, fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        ReleaseNotesView(lines: e.lines),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                _ => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders changelog lines: `- ` bullets, `### ` subheadings, other text as paragraphs.
/// `**bold**` and `` `code` `` are shown plainly (markers removed).
class ReleaseNotesView extends StatelessWidget {
  const ReleaseNotesView({required this.lines, super.key});
  final List<String> lines;

  static String _plain(String s) => s.replaceAll('**', '').replaceAll('`', '');

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final children = <Widget>[];
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 6));
        continue;
      }
      final bullet = RegExp(r'^(\s*)[-*]\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        final indent = bullet.group(1)!.length >= 2 ? 16.0 : 0.0;
        children.add(Padding(
          padding: EdgeInsets.only(left: indent, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: t.textMuted, shape: BoxShape.circle),
                ),
              ),
              Expanded(child: SelectableText(_plain(bullet.group(2)!))),
            ],
          ),
        ));
      } else if (line.startsWith('#')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(_plain(line.replaceFirst(RegExp(r'^#+\s*'), '')), style: text.titleSmall),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SelectableText(_plain(line)),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
