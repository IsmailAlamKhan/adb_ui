import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// Focus of Launcher's inline palette, so ⌘K focuses it instead of opening a dialog.
class LauncherPaletteFocus {
  static FocusNode? node;
}

/// Launcher: device cards, an always-visible command palette, today's activity.
class LauncherHome extends HookConsumerWidget {
  const LauncherHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final adb = ref.read(adbControllerProvider);
    final devices = ref.watch(connectedDevicesProvider);
    final list = devices.valueOrNull ?? const <AdbDevice>[];
    final selected = ref.watch(selectedDeviceProvider);
    final compact = WindowSize.of(context).isCompact;
    final focus = useFocusNode(debugLabel: 'launcher palette');
    useEffect(() {
      LauncherPaletteFocus.node = focus;
      return () {
        if (LauncherPaletteFocus.node == focus) LauncherPaletteFocus.node = null;
      };
    }, [focus]);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(compact ? 20 : 40, compact ? 20 : 36, compact ? 20 : 40, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('adb ui', style: text.titleMedium!.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: t.textMuted),
                    onPressed: adb.openActivity,
                    child: const Text('Activity'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: t.textMuted),
                    onPressed: adb.openSettings,
                    child: const Text('Settings'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (devices.hasError)
                ErrorPanel(error: devices.error!, onRetry: () async => ref.invalidate(connectedDevicesProvider))
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final d in list)
                      SizedBox(
                        width: compact ? double.infinity : 400,
                        child: _DeviceCard(device: d, selected: d.id == selected?.id),
                      ),
                    SizedBox(
                      width: compact ? double.infinity : 240,
                      child: AppCard(
                        dashed: true,
                        onTap: adb.addDevice,
                        padding: const EdgeInsets.all(20),
                        semanticLabel: 'Add device',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('+ Add device', style: text.headlineSmall!.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('QR code, pairing code or IP', style: TextStyle(color: t.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (selected != null && !selected.isOnline) ...[
                const SizedBox(height: 16),
                DeviceStateBanner(device: selected),
              ],
              if (list.isEmpty && !devices.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  'Plug a phone in with USB and allow USB debugging, or add one over Wi-Fi.',
                  style: TextStyle(color: t.textMuted),
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: CommandPalette(inline: true, focusNode: focus, maxListHeight: 320),
                ),
              ),
              const SizedBox(height: 32),
              const _TodayActivity(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device, required this.selected});
  final AdbDevice device;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      selected: selected,
      padding: const EdgeInsets.all(20),
      semanticLabel: '${device.displayName}, ${device.state.label}',
      onTap: () {
        ref.read(selectedDeviceIdProvider.notifier).state = device.id;
        LauncherPaletteFocus.node?.requestFocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DeviceStatusLine(device: device, upper: true),
          const SizedBox(height: 12),
          Text(
            device.displayName,
            style: text.displaySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(device.id, style: AppThemeFactory.mono(t, size: 12, color: t.textMuted), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _TodayActivity extends ConsumerWidget {
  const _TodayActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final now = DateTime.now();
    final today = ref
        .watch(commandQueueControllerProvider)
        .where((c) => c.startedAt.year == now.year && c.startedAt.month == now.month && c.startedAt.day == now.day)
        .take(12)
        .toList();
    final adb = ref.read(adbControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Today'),
        const SizedBox(height: 8),
        if (today.isEmpty)
          Text('Nothing run yet today.', style: TextStyle(color: t.textMuted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in today)
                _ActivityChip(command: c, onTap: () => adb.openCommandDetails(c.id)),
            ],
          ),
      ],
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.command, required this.onTap});
  final CommandModel command;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final (Color bg, Color fg) = command.isRunning
        ? (t.accentSoft, t.onAccentSoft)
        : command.isError
            ? (t.dangerSoft, t.onDangerSoft)
            : (t.successSoft, t.onSuccessSoft);
    final label = command.isError
        ? '${command.command} · ${command.explainedError?.title ?? 'failed'}'
        : '${command.command} · ${command.durationLabel}';
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (command.isRunning)
                SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              else
                Icon(command.isError ? Icons.close_rounded : Icons.check_rounded, size: 14, color: fg),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(label, style: TextStyle(color: fg, fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
