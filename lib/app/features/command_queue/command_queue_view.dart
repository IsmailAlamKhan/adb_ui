import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

enum ActivityFilter {
  all('All'),
  running('Running'),
  errors('Errors');

  const ActivityFilter(this.label);
  final String label;

  bool matches(CommandModel c) => switch (this) {
        ActivityFilter.all => true,
        ActivityFilter.running => !c.isDone,
        ActivityFilter.errors => c is CommandModelError,
      };
}

/// Visual state of one activity entry.
extension CommandModelUi on CommandModel {
  bool get isError => this is CommandModelError;
  bool get isRunning => !isDone;

  /// Explained error for failed commands.
  AppError? get explainedError => whenError((c) => ErrorCatalogue.explain(c.error));

  String get durationLabel {
    final ms = finishedIn;
    if (ms == null) return 'running';
    if (ms < 1000) return '$ms ms';
    return '${(ms / 1000).toStringAsFixed(1)} s';
  }

  String get outputText =>
      whenDone((c) => c.output) ?? whenError((c) => c.error) ?? '';
}

/// Status icon for an activity entry.
class CommandStatusIcon extends StatelessWidget {
  const CommandStatusIcon({super.key, required this.command, this.size = 18, this.onTerminal = false});
  final CommandModel command;
  final double size;

  /// Drawn on the always-dark terminal colours (Console dock).
  final bool onTerminal;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    if (command.isRunning) {
      return Semantics(
        label: 'Running',
        child: SizedBox.square(
          dimension: size - 2,
          child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
        ),
      );
    }
    final error = command.isError;
    // The terminal is dark in every theme, so it uses fixed light-on-dark status colours.
    final Color bg;
    final Color fg;
    if (onTerminal) {
      fg = error ? const Color(0xFFFFB4B4) : const Color(0xFF6BE3A8);
      bg = fg.withValues(alpha: 0.18);
    } else {
      bg = error ? t.dangerSoft : t.successSoft;
      fg = error ? t.onDangerSoft : t.onSuccessSoft;
    }
    return Semantics(
      label: error ? 'Failed' : 'Done',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(
          error ? Icons.priority_high_rounded : Icons.check_rounded,
          size: size - 4,
          color: fg,
        ),
      ),
    );
  }
}

/// Shared activity list, used by every style.
class ActivityList extends HookConsumerWidget {
  const ActivityList({
    super.key,
    this.filter = ActivityFilter.all,
    this.deviceId,
    this.limit,
    this.dense = false,
    this.onTap,
    this.selectedId,
    this.shrinkWrap = false,
    this.emptyMessage = 'Commands you run show up here.',
  });
  final ActivityFilter filter;
  final String? deviceId;
  final int? limit;
  final bool dense;
  final void Function(CommandModel command)? onTap;
  final String? selectedId;
  final bool shrinkWrap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(commandQueueControllerProvider);
    var items = all.where(filter.matches);
    if (deviceId != null) items = items.where((c) => c.device == null || c.device!.id == deviceId);
    var list = items.toList();
    if (limit != null && list.length > limit!) list = list.sublist(0, limit);
    final t = AppTokens.of(context);

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          filter == ActivityFilter.errors ? 'No errors. Nice.' : emptyMessage,
          style: TextStyle(color: t.textMuted),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: t.borderSubtle),
      itemBuilder: (context, index) => ActivityTile(
        command: list[index],
        dense: dense,
        selected: list[index].id == selectedId,
        onTap: onTap == null ? null : () => onTap!(list[index]),
      ),
    );
  }
}

class ActivityTile extends ConsumerWidget {
  const ActivityTile({
    super.key,
    required this.command,
    this.dense = false,
    this.selected = false,
    this.onTap,
  });
  final CommandModel command;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final adb = ref.read(adbControllerProvider);
    final error = command.explainedError;
    final meta = [
      if (command.device != null) command.device!.displayName,
      command.startedAt.timeAgoSinceNow(),
      if (command.isDone) command.durationLabel,
      if (command.isRerun) 're-run',
    ].join(' · ');
    return Material(
      color: selected ? t.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => adb.openCommandDetails(command.id),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 8 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: CommandStatusIcon(command: command),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.command,
                      style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        error.title,
                        style: text.bodySmall!.copyWith(color: t.danger, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(meta, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (command.isDone)
                IconButton(
                  tooltip: 'Run again',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.replay_rounded),
                  onPressed: () => adb.rerunCommand(command),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full Activity page with filters (Workbench sidebar, Launcher header, ⇧⌘A).
class ActivityView extends HookConsumerWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = useState(ActivityFilter.all);
    final controller = ref.read(commandQueueControllerProvider.notifier);
    final count = ref.watch(commandQueueControllerProvider.select((v) => v.length));
    return AdaptiveDialog(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity'),
          actions: [
            TextButton.icon(
              onPressed: count == 0 ? null : controller.clear,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear finished'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SegmentedButton<ActivityFilter>(
                showSelectedIcon: false,
                segments: [
                  for (final f in ActivityFilter.values) ButtonSegment(value: f, label: Text(f.label)),
                ],
                selected: {filter.value},
                onSelectionChanged: (s) => filter.value = s.first,
              ),
            ),
            const Divider(),
            Expanded(child: ActivityList(filter: filter.value)),
          ],
        ),
      ),
    );
  }
}

/// Details of one command: status, explained error, live or final output, Copy, Re-run.
class CommandDetailsDialog extends ConsumerWidget {
  const CommandDetailsDialog({super.key, required this.commandId});
  final String commandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final command = ref.watch(commandQueueControllerProvider.select((list) {
      for (final c in list) {
        if (c.id == commandId) return c;
      }
      return null;
    }));
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    if (command == null) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('This command was removed from Activity.', style: TextStyle(color: t.textMuted)),
        ),
      );
    }
    final error = command.explainedError;
    final adb = ref.read(adbControllerProvider);
    final status = command.isRunning ? 'Running' : (command.isError ? 'Failed' : 'Done');
    final meta = [
      status,
      if (command.device != null) command.device!.displayName,
      if (command.isDone) command.durationLabel,
      command.startedAt.timeAgoSinceNow(),
    ].join(' · ');

    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CommandStatusIcon(command: command, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(command.command, style: text.headlineSmall),
                        const SizedBox(height: 2),
                        Text(meta, style: text.bodySmall),
                        const SizedBox(height: 4),
                        SelectableText(
                          [
                            command.rawCommand == '' ? 'adb' : 'adb ${command.rawCommand}',
                            ...command.arguments,
                          ].join(' '),
                          style: AppThemeFactory.mono(t, size: 12, color: t.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error != null) ...[
                      ErrorExplanation(error: error, showDetails: false),
                      const SizedBox(height: 16),
                    ],
                    const SectionLabel('Output'),
                    const SizedBox(height: 6),
                    if (command.isRunning)
                      ValueListenableBuilder<String>(
                        valueListenable:
                            ref.read(commandQueueControllerProvider.notifier).liveOutput(command.id),
                        builder: (_, value, __) =>
                            TerminalBlock(text: value, placeholder: 'Waiting for output…', maxHeight: 360),
                      )
                    else
                      TerminalBlock(text: command.outputText, maxHeight: 360),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (command.isDone)
                    OutlinedButton.icon(
                      onPressed: () => Clipboard.setData(ClipboardData(text: command.outputText)),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy output'),
                    ),
                  if (command.isDone)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        adb.rerunCommand(command);
                      },
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('Run again'),
                    ),
                  FilledButton(
                    autofocus: true,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
