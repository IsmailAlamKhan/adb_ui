import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// Console: device list │ device with shortcut grid, docked activity terminal below.
class ConsoleHome extends HookConsumerWidget {
  const ConsoleHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = WindowSize.of(context);
    final device = ref.watch(selectedDeviceProvider);
    final t = AppTokens.of(context);
    final dockFraction = useState(size.isCompact ? 0.0 : 0.34);
    final collapsed = dockFraction.value <= 0.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          // Collapse the dock on short windows; keep at least 220 px for the device area.
          final maxDock = (constraints.maxHeight - 52 - 220).clamp(0.0, constraints.maxHeight * 0.6);
          final dockHeight = collapsed ? 0.0 : (constraints.maxHeight * dockFraction.value).clamp(140.0, maxDock);
          return Column(
            children: [
              const _TitleRow(),
              Divider(height: 1, color: t.borderSubtle),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!size.isCompact) ...[
                      SizedBox(width: size.isExpanded ? 240 : 200, child: const _DeviceColumn()),
                      VerticalDivider(width: 1, color: t.borderSubtle),
                    ],
                    Expanded(
                      child: device == null
                          ? const NoDeviceState()
                          : _DeviceCenter(key: ValueKey(device.id), device: device),
                    ),
                  ],
                ),
              ),
              _ActivityDock(
                height: maxDock < 140 ? 0 : dockHeight,
                collapsed: collapsed || maxDock < 140,
                onToggle: () => dockFraction.value = collapsed ? 0.34 : 0.0,
                onDrag: (dy) {
                  final next = (dockHeight - dy) / constraints.maxHeight;
                  dockFraction.value = next.clamp(140 / constraints.maxHeight, 0.6);
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TitleRow extends ConsumerWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final adb = ref.read(adbControllerProvider);
    final compact = WindowSize.of(context).isCompact;
    final devices = ref.watch(connectedDevicesProvider).valueOrNull ?? const <AdbDevice>[];
    final selected = ref.watch(selectedDeviceProvider);
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text('adb', style: AppThemeFactory.mono(t, size: 14, weight: FontWeight.w700, color: t.accent)),
            Text(' ui', style: AppThemeFactory.mono(t, size: 14, weight: FontWeight.w700)),
            const SizedBox(width: 16),
            if (compact && devices.isNotEmpty) ...[
              Flexible(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected?.id,
                    isDense: true,
                    borderRadius: t.borderRadius,
                    items: [
                      for (final d in devices)
                        DropdownMenuItem(value: d.id, child: Text(d.displayName, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (id) => ref.read(selectedDeviceIdProvider.notifier).state = id,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.textMuted,
                      backgroundColor: t.surfaceAlt,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: adb.openPalette,
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Search actions…', overflow: TextOverflow.ellipsis)),
                        KeyHint(shortcutLabel(AppShortcuts.palette)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Add device (${shortcutLabel(AppShortcuts.addDevice)})',
              onPressed: adb.addDevice,
              icon: const Icon(Icons.add_rounded),
            ),
            IconButton(
              tooltip: 'Settings (${shortcutLabel(AppShortcuts.settings)})',
              onPressed: adb.openSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceColumn extends ConsumerWidget {
  const _DeviceColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final adb = ref.read(adbControllerProvider);
    final devices = ref.watch(connectedDevicesProvider).valueOrNull ?? const <AdbDevice>[];
    return Material(
      color: t.surfaceAlt,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          SectionLabel('Devices · ${devices.length}', padding: const EdgeInsets.fromLTRB(8, 6, 8, 6)),
          for (final d in devices) DeviceListTile(device: d, dense: true),
          const SizedBox(height: 6),
          TextButton.icon(
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            onPressed: adb.addDevice,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add device'),
          ),
        ],
      ),
    );
  }
}

class _DeviceCenter extends ConsumerWidget {
  const _DeviceCenter({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final compact = WindowSize.of(context).isCompact;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(device.displayName, style: text.headlineSmall),
              DeviceStatusLine(device: device),
              Text(device.id, style: AppThemeFactory.mono(t, size: 12, color: t.textMuted)),
            ],
          ),
          if (!device.isOnline) ...[const SizedBox(height: 12), DeviceStateBanner(device: device)],
          const SizedBox(height: 16),
          DeviceActionGrid(device: device, showShortcuts: true, minTileWidth: compact ? 150 : 180),
          const SizedBox(height: 20),
          const SectionLabel('Device'),
          const SizedBox(height: 8),
          DeviceDetailsCard(device: device),
        ],
      ),
    );
  }
}

/// Docked activity terminal: list of commands on the left, selected output on the right.
class _ActivityDock extends HookConsumerWidget {
  const _ActivityDock({
    required this.height,
    required this.collapsed,
    required this.onToggle,
    required this.onDrag,
  });
  final double height;
  final bool collapsed;
  final VoidCallback onToggle;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final commands = ref.watch(commandQueueControllerProvider);
    final selectedId = useState<String?>(null);
    final errorsOnly = useState(false);
    final compact = WindowSize.of(context).isCompact;
    CommandModel? selected;
    for (final c in commands) {
      if (c.id == selectedId.value) selected = c;
    }
    selected ??= commands.isEmpty ? null : commands.first;
    final latest = commands.isEmpty ? null : commands.first;
    final muted = t.onTerminalMuted;

    final strip = Material(
      color: t.terminal,
      child: InkWell(
        onTap: onToggle,
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(collapsed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18, color: muted),
                const SizedBox(width: 6),
                Text('ACTIVITY',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: muted, letterSpacing: 0.8)),
                const SizedBox(width: 12),
                if (latest != null) ...[
                  CommandStatusIcon(command: latest, size: 14, onTerminal: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${latest.command} · ${latest.explainedError?.title ?? latest.durationLabel}',
                      style: AppThemeFactory.mono(t, size: 12, color: latest.isError ? const Color(0xFFFFB4B4) : t.onTerminal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Expanded(child: Text('No commands yet', style: TextStyle(color: muted))),
                if (!collapsed) ...[
                  _DockChip(label: 'All', selected: !errorsOnly.value, onTap: () => errorsOnly.value = false),
                  const SizedBox(width: 4),
                  _DockChip(label: 'Errors', selected: errorsOnly.value, onTap: () => errorsOnly.value = true),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Clear finished',
                    color: muted,
                    iconSize: 16,
                    onPressed: ref.read(commandQueueControllerProvider.notifier).clear,
                    icon: const Icon(Icons.clear_all_rounded),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (collapsed) return strip;

    final list = Theme(
      data: Theme.of(context).copyWith(
        extensions: [t.copyWith(canvas: t.terminal)],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: t.onTerminal),
        child: _TerminalList(
          errorsOnly: errorsOnly.value,
          selectedId: selected?.id,
          onSelect: (c) => compact
              ? ref.read(adbControllerProvider).openCommandDetails(c.id)
              : selectedId.value = c.id,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeRow,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
            child: Semantics(
              label: 'Resize activity panel',
              child: Container(height: 5, color: t.borderSubtle),
            ),
          ),
        ),
        strip,
        Container(
          height: height,
          color: t.terminal,
          child: compact || selected == null
              ? list
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 340, child: list),
                    VerticalDivider(width: 1, color: muted.withValues(alpha: 0.2)),
                    Expanded(child: _TerminalOutput(command: selected)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DockChip extends StatelessWidget {
  const _DockChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: selected ? t.terminalAccent.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label,
              style: TextStyle(color: selected ? t.terminalAccent : t.onTerminalMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _TerminalList extends ConsumerWidget {
  const _TerminalList({required this.errorsOnly, required this.selectedId, required this.onSelect});
  final bool errorsOnly;
  final String? selectedId;
  final ValueChanged<CommandModel> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final list = ref
        .watch(commandQueueControllerProvider)
        .where((c) => !errorsOnly || c.isError)
        .toList();
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(errorsOnly ? 'No errors.' : 'Run something: output streams here.',
            style: AppThemeFactory.mono(t, color: t.onTerminalMuted)),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        final selected = c.id == selectedId;
        return Material(
          color: selected ? t.onTerminal.withValues(alpha: 0.08) : Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(c),
            onDoubleTap: () => ref.read(adbControllerProvider).openCommandDetails(c.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  CommandStatusIcon(command: c, size: 14, onTerminal: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.command,
                            style: AppThemeFactory.mono(t, size: 12, color: t.onTerminal),
                            overflow: TextOverflow.ellipsis),
                        if (c.explainedError != null)
                          Text(c.explainedError!.title,
                              style: AppThemeFactory.mono(t, size: 11, color: const Color(0xFFFFB4B4)),
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(c.durationLabel, style: AppThemeFactory.mono(t, size: 11, color: t.onTerminalMuted)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TerminalOutput extends ConsumerWidget {
  const _TerminalOutput({required this.command});
  final CommandModel command;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final adb = ref.read(adbControllerProvider);
    final error = command.explainedError;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '\$ adb ${[command.rawCommand, ...command.arguments].where((e) => e.isNotEmpty).join(' ')}',
              style: AppThemeFactory.mono(t, size: 12, color: t.terminalAccent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (command.isDone)
            IconButton(
              tooltip: 'Run again',
              color: t.onTerminalMuted,
              iconSize: 16,
              onPressed: () => adb.rerunCommand(command),
              icon: const Icon(Icons.replay_rounded),
            ),
          IconButton(
            tooltip: 'Open details',
            color: t.onTerminalMuted,
            iconSize: 16,
            onPressed: () => adb.openCommandDetails(command.id),
            icon: const Icon(Icons.open_in_full_rounded),
          ),
        ],
      ),
    );
    Widget output(String text) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          reverse: command.isRunning,
          child: SizedBox(
            width: double.infinity,
            child: SelectableText(
              text.trim().isEmpty ? (command.isRunning ? 'Waiting for output…' : 'No output') : text.trimRight(),
              style: AppThemeFactory.mono(t, color: t.onTerminal),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Text(
              '✕ ${error.title}${error.hint != null ? ' — ${error.hint}' : ''}',
              style: AppThemeFactory.mono(t, size: 12, color: const Color(0xFFFFB4B4)),
            ),
          ),
        Expanded(
          child: command.isRunning
              ? ValueListenableBuilder<String>(
                  valueListenable: ref.read(commandQueueControllerProvider.notifier).liveOutput(command.id),
                  builder: (_, value, __) => output(value),
                )
              : output(command.outputText),
        ),
      ],
    );
  }
}
