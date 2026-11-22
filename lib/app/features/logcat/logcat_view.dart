import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

extension LogLevelUi on LogLevel? {
  (Color bg, Color fg) colors(AppTokens t) => switch (this) {
        LogLevel.fatal || LogLevel.error => (t.dangerSoft, t.onDangerSoft),
        LogLevel.warn => (t.warningSoft, t.onWarningSoft),
        LogLevel.info => (t.successSoft, t.onSuccessSoft),
        LogLevel.debug => (t.accentSoft, t.onAccentSoft),
        _ => (t.surfaceAlt, t.textMuted),
      };
}

/// Full page (Console, Launcher, palette, ⌘L).
class LogcatPage extends StatelessWidget {
  const LogcatPage({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Logcat · ${device.displayName}')),
        body: Padding(
          padding: EdgeInsets.all(WindowSize.of(context).isCompact ? 12 : 20),
          child: LogcatView(device: device),
        ),
      );
}

/// Logcat stream with presets, follow app/foreground, search and the AI filter.
class LogcatView extends HookConsumerWidget {
  const LogcatView({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = logcatControllerProvider(device);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final adb = ref.read(adbControllerProvider);
    final t = AppTokens.of(context);
    final filter = state.filter;
    final search = useTextEditingController(text: filter.text);
    final scroll = useScrollController();
    final compact = WindowSize.of(context).isCompact;

    // Scrolling away from the newest line pauses the view; scrolling back resumes it.
    useEffect(() {
      void onScroll() {
        if (!scroll.hasClients) return;
        final away = scroll.offset > 48;
        if (away && !controller.state.paused) controller.pause();
      }

      scroll.addListener(onScroll);
      return () => scroll.removeListener(onScroll);
    }, [scroll]);

    void jumpToLatest() {
      controller.resume();
      if (scroll.hasClients) scroll.jumpTo(0);
    }

    Future<void> followApp() async {
      final package = await showDialog<String>(
        context: context,
        builder: (_) => _PackagePickerDialog(device: device),
      );
      if (package != null) controller.setFilter(filter.copyWith(package: package, followForeground: false));
    }

    Future<void> save() async {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save visible log lines',
        fileName: 'logcat-${device.displayName.replaceAll(' ', '-')}.txt',
      );
      if (path == null) return;
      await File(path).writeAsString(controller.visibleText());
      adb.showSuccess('Saved ${state.visible.length} lines', message: path);
    }

    final followLabel = filter.followForeground
        ? 'Following foreground${state.followedPackage != null ? ': ${state.followedPackage}' : ''}'
        : filter.package != null
            ? 'Following ${filter.package}'
            : 'Follow app…';

    final toolbar = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<LogPreset>(
          showSelectedIcon: false,
          segments: [
            for (final p in LogPreset.values)
              ButtonSegment(
                value: p,
                label: Text(p.label),
                icon: p == LogPreset.crashes ? const Icon(Icons.bug_report_outlined, size: 16) : null,
              ),
          ],
          selected: {filter.preset},
          onSelectionChanged: (s) => controller.setFilter(filter.copyWith(preset: s.first)),
        ),
        OutlinedButton.icon(
          onPressed: followApp,
          icon: const Icon(Icons.apps_rounded, size: 18),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(followLabel, overflow: TextOverflow.ellipsis),
          ),
        ),
        FilterChip(
          avatar: const Icon(Icons.center_focus_strong_rounded, size: 16),
          label: const Text('Follow foreground app'),
          selected: filter.followForeground,
          onSelected: (v) => controller.setFilter(filter.copyWith(followForeground: v, clearPackage: true)),
        ),
        PopupMenuButton<LogLevel?>(
          tooltip: 'Minimum level',
          initialValue: filter.minLevel,
          onSelected: (l) => controller.setFilter(
            l == null ? filter.copyWith(clearMinLevel: true) : filter.copyWith(minLevel: l),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(value: null, child: Text('Any level')),
            for (final l in LogLevel.values) PopupMenuItem(value: l, child: Text('${l.label} and above')),
          ],
          child: Chip(
            avatar: const Icon(Icons.filter_list_rounded, size: 16),
            label: Text(filter.minLevel == null ? 'Any level' : '${filter.minLevel!.label}+'),
          ),
        ),
      ],
    );

    final searchRow = Row(
      children: [
        Expanded(
          child: TextField(
            controller: search,
            onChanged: (v) {
              final isRegex = v.length > 2 && v.startsWith('/') && v.endsWith('/');
              controller.setFilter(filter.copyWith(
                text: isRegex ? v.substring(1, v.length - 1) : v,
                regex: isRegex,
              ));
            },
            style: AppThemeFactory.mono(t, size: 13),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              hintText: 'Search messages and tags  ·  /regex/',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: state.paused ? 'Resume' : 'Pause',
          onPressed: state.paused ? jumpToLatest : controller.pause,
          icon: Icon(state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
        ),
        IconButton(
          tooltip: 'Copy visible lines',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: controller.visibleText()));
            adb.showSuccess('Copied ${state.visible.length} lines');
          },
          icon: const Icon(Icons.copy_all_rounded),
        ),
        IconButton(tooltip: 'Save visible lines…', onPressed: save, icon: const Icon(Icons.save_alt_rounded)),
        IconButton(
          tooltip: 'Clear',
          onPressed: () async {
            final onDevice = await showDialog<bool>(
              context: context,
              builder: (_) => const ConfirmActionDialog(
                title: 'Clear the log?',
                message: 'This empties the view and the device\'s log buffer (adb logcat -c).',
                confirmLabel: 'Clear',
                destructive: true,
              ),
            );
            if (onDevice == true) controller.clear(onDevice: true);
          },
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    );

    final chips = _ActiveFilterChips(filter: filter, onChange: controller.setFilter, onClear: controller.clearFilters);

    Widget body;
    if (state.error != null && !state.running) {
      body = ErrorPanel(error: state.error!, onRetry: controller.start);
    } else if (state.visible.isEmpty) {
      body = Center(
        child: Text(
          state.waitingForApp
              ? 'Waiting for ${state.followedPackage} to start…'
              : state.total == 0
                  ? (state.running ? 'Waiting for log lines…' : 'Logcat stopped.')
                  : 'No lines match these filters.',
          style: TextStyle(color: t.textMuted),
        ),
      );
    } else {
      final items = state.visible;
      body = SelectionArea(
        child: ListView.builder(
          controller: scroll,
          reverse: true,
          itemCount: items.length,
          itemBuilder: (context, i) => _LogRow(entry: items[items.length - 1 - i], compact: compact),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiLogFilterField(device: device, current: filter, onFilter: controller.setFilter),
        const SizedBox(height: 10),
        toolbar,
        const SizedBox(height: 10),
        searchRow,
        if (!filter.isEmpty) ...[const SizedBox(height: 8), chips],
        const SizedBox(height: 10),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: t.terminal, borderRadius: t.borderRadius),
                  child: ClipRRect(borderRadius: t.borderRadius, child: body),
                ),
              ),
              if (state.paused)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FilledButton.icon(
                    onPressed: jumpToLatest,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                    label: Text(state.newWhilePaused > 0 ? '${state.newWhilePaused} new · Jump to latest' : 'Jump to latest'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${state.visible.length} shown · ${state.total} in buffer${state.running ? ' · live' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.filter, required this.onChange, required this.onClear});
  final LogcatFilter filter;
  final ValueChanged<LogcatFilter> onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    Widget chip(String field, String label, LogcatFilter Function() without) => InputChip(
          avatar: filter.aiFields.contains(field) ? const Icon(Icons.auto_awesome, size: 14) : null,
          label: Text(label),
          onDeleted: () => onChange(without()),
        );
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (filter.preset != LogPreset.all)
          chip('preset', filter.preset.label, () => filter.copyWith(preset: LogPreset.all)),
        if (filter.package != null) chip('package', 'App: ${filter.package}', () => filter.copyWith(clearPackage: true)),
        if (filter.followForeground)
          chip('foreground', 'Foreground app', () => filter.copyWith(followForeground: false)),
        if (filter.minLevel != null)
          chip('minLevel', '${filter.minLevel!.label}+', () => filter.copyWith(clearMinLevel: true)),
        for (final tag in filter.includeTags)
          chip('includeTags', 'Tag: $tag',
              () => filter.copyWith(includeTags: [...filter.includeTags]..remove(tag))),
        for (final tag in filter.excludeTags)
          chip('excludeTags', 'Hide: $tag',
              () => filter.copyWith(excludeTags: [...filter.excludeTags]..remove(tag))),
        if (filter.text.isNotEmpty)
          chip('text', filter.regex ? 'Regex: ${filter.text}' : 'Text: ${filter.text}', () => filter.copyWith(text: '')),
        TextButton(onPressed: onClear, child: const Text('Clear filters')),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.compact});
  final LogcatEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final mono = AppThemeFactory.mono(t, size: 12, color: t.onTerminal);
    if (entry.isMarker) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Expanded(child: Divider(color: t.terminalAccent.withValues(alpha: 0.4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(entry.message, style: mono.copyWith(color: t.terminalAccent)),
          ),
          Expanded(child: Divider(color: t.terminalAccent.withValues(alpha: 0.4))),
        ]),
      );
    }
    if (!entry.parsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Text(entry.raw, style: mono.copyWith(color: t.onTerminalMuted)),
      );
    }
    final (bg, fg) = entry.level.colors(t);
    final crash = entry.crash != CrashMark.none;
    const crashColor = Color(0xFFFFB4B4);
    return Container(
      decoration: BoxDecoration(
        color: crash ? crashColor.withValues(alpha: 0.08) : null,
        border: crash ? const Border(left: BorderSide(color: crashColor, width: 3)) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            SizedBox(width: 96, child: Text(entry.time.split(' ').last, style: mono.copyWith(color: t.onTerminalMuted))),
            SizedBox(width: 52, child: Text('${entry.pid}', style: mono.copyWith(color: t.onTerminalMuted))),
          ],
          Container(
            width: 18,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 8, top: 1),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
            child: Text(entry.level!.letter, style: mono.copyWith(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: compact ? 90 : 150,
            child: Text(entry.tag, style: mono.copyWith(color: t.terminalAccent), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.crash == CrashMark.start ? 'CRASH · ${entry.message}' : entry.message,
              style: mono.copyWith(color: crash ? crashColor : t.onTerminal),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackagePickerDialog extends StatelessWidget {
  const _PackagePickerDialog({required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: dialogInset(context),
      child: SizedBox(
        width: 620,
        height: (size.height * 0.8).clamp(360, 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: PackagesList(
            device: device,
            onTap: (p) => Navigator.of(context).pop(p),
            trailing: (_) => const Icon(Icons.chevron_right_rounded),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text('Follow an app\'s logs', style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
        ),
      ),
    );
  }
}
