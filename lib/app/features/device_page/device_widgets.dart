import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

extension AdbDeviceStateUi on AdbDeviceState {
  Color color(AppTokens t) => switch (this) {
        AdbDeviceState.online => t.success,
        AdbDeviceState.offline || AdbDeviceState.unauthorized => t.warning,
        AdbDeviceState.other => t.textMuted,
      };
}

/// "● Online · Wi-Fi" line.
class DeviceStatusLine extends StatelessWidget {
  const DeviceStatusLine({super.key, required this.device, this.upper = false});
  final AdbDevice device;
  final bool upper;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final color = device.state.color(t);
    var label = '${device.state.label} · ${device.isWireless ? 'Wi-Fi' : 'USB'}';
    if (upper) label = label.toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, label: device.state.label),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: device.isOnline ? t.onSuccessSoft : t.onWarningSoft,
                  fontWeight: FontWeight.w600,
                  letterSpacing: upper ? 0.6 : 0,
                ),
          ),
        ),
      ],
    );
  }
}

/// Device row for sidebars and lists.
class DeviceListTile extends ConsumerWidget {
  const DeviceListTile({super.key, required this.device, this.dense = false});
  final AdbDevice device;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDeviceProvider)?.id == device.id;
    final t = AppTokens.of(context);
    return Semantics(
      selected: selected,
      child: ListTile(
        selected: selected,
        dense: dense,
        leading: Icon(
          device.isWireless ? Icons.wifi_rounded : Icons.smartphone_rounded,
          size: 18,
          color: selected ? t.onAccentSoft : t.textMuted,
        ),
        title: Text(device.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: dense
            ? null
            : Text(device.id, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: StatusDot(color: device.state.color(t), label: device.state.label),
        onTap: () => ref.read(selectedDeviceIdProvider.notifier).state = device.id,
      ),
    );
  }
}

/// Warning for unauthorized / offline devices, with the steps from the error catalogue.
class DeviceStateBanner extends StatelessWidget {
  const DeviceStateBanner({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context) {
    if (device.isOnline) return const SizedBox.shrink();
    final error = ErrorCatalogue.explain(null, output: switch (device.state) {
      AdbDeviceState.unauthorized => 'unauthorized',
      AdbDeviceState.offline => 'device offline',
      _ => 'device ${device.type}',
    });
    return AppBanner(
      tone: BannerTone.warning,
      title: error.kind == ErrorKind.unknown ? 'The device is ${device.type}' : error.title,
      message: error.kind == ErrorKind.unknown ? null : error.message,
      steps: error.kind == ErrorKind.unknown ? const [] : error.steps,
    );
  }
}

/// Key/value facts about a device (Overview).
class DeviceDetailsCard extends ConsumerWidget {
  const DeviceDetailsCard({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final props = device.isOnline ? ref.watch(devicePropertiesProvider(device)).valueOrNull : null;
    final rows = <(String, String)>[
      ('Model', [props?.manufacturer, props?.model ?? device.displayName].whereType<String>().join(' ')),
      if (props?.androidVersion != null) ('Android', '${props!.androidVersion} (API ${props.sdk})'),
      if (props?.abi != null) ('Processor (ABI)', props!.abi!),
      ('Connection', device.isWireless ? 'Wi-Fi (wireless debugging)' : 'USB'),
      ('Serial', device.id),
    ];
    return AppCard(
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 130, child: Text(label, style: TextStyle(color: t.textMuted))),
                  Expanded(
                    child: SelectableText(
                      value,
                      style: label == 'Serial' ? AppThemeFactory.mono(t, size: 12) : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Grid of action tiles for a device (Workbench Overview, Console center).
class DeviceActionGrid extends ConsumerWidget {
  const DeviceActionGrid({
    super.key,
    required this.device,
    this.showShortcuts = false,
    this.minTileWidth = 150,
    this.exclude = const {},
  });
  final AdbDevice device;
  final bool showShortcuts;
  final double minTileWidth;
  final Set<DeviceAction> exclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrcpy = ref.watch(scrcpyAvailableProvider).valueOrNull ?? false;
    final actions = DeviceAction.values.where((a) => !exclude.contains(a)).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.maxWidth / minTileWidth).floor().clamp(1, 6);
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final action in actions)
            SizedBox(
              width: width,
              child: DeviceActionTile(
                action: action,
                showShortcut: showShortcuts,
                disabledReason: action.unavailableReason(device, scrcpyAvailable: scrcpy),
                onTap: () => action.perform(ref, device),
              ),
            ),
        ],
      );
    });
  }
}

class DeviceActionTile extends StatelessWidget {
  const DeviceActionTile({
    super.key,
    required this.action,
    required this.onTap,
    this.showShortcut = false,
    this.disabledReason,
  });
  final DeviceAction action;
  final VoidCallback onTap;
  final bool showShortcut;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final enabled = disabledReason == null;
    final console = t.style == AppStyle.console;
    final fg = action.destructive ? t.danger : t.text;
    final tile = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: AppCard(
        padding: EdgeInsets.all(console ? 12 : 14),
        onTap: enabled ? onTap : null,
        semanticLabel: '${action.label}${enabled ? '' : ', unavailable: $disabledReason'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: action.destructive ? t.dangerSoft : t.accentSoft,
                    borderRadius: BorderRadius.circular(t.radius),
                  ),
                  child: Icon(
                    action.icon,
                    size: 16,
                    color: action.destructive ? t.onDangerSoft : t.onAccentSoft,
                  ),
                ),
                const Spacer(),
                if (showShortcut) KeyHint(action.shortcutText),
              ],
            ),
            SizedBox(height: console ? 10 : 14),
            Text(action.label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
            if (console) ...[
              const SizedBox(height: 2),
              Text(action.command, style: AppThemeFactory.mono(t, size: 11, color: t.textMuted)),
            ],
          ],
        ),
      ),
    );
    return Tooltip(
      message: disabledReason ?? (showShortcut ? '' : action.shortcutText),
      child: tile,
    );
  }
}

/// "Shell" tab: run adb commands on this device and read their output.
class DeviceShellView extends HookConsumerWidget {
  const DeviceShellView({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final t = AppTokens.of(context);
    final adb = ref.read(adbControllerProvider);
    final commands = ref
        .watch(commandQueueControllerProvider)
        .where((c) => c.device?.id == device.id && c.command.startsWith('adb '))
        .toList();
    final latest = commands.isEmpty ? null : commands.first;

    void submit() {
      final value = controller.text.trim();
      if (value.isEmpty) return;
      adb.runCommand(device, value);
      controller.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onSubmitted: (_) => submit(),
                style: AppThemeFactory.mono(t, size: 13),
                decoration: InputDecoration(
                  prefixText: 'adb ',
                  prefixStyle: AppThemeFactory.mono(t, size: 13, color: t.textMuted),
                  hintText: 'shell getprop ro.build.version.release',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: submit, child: const Text('Run')),
          ],
        ),
        const SizedBox(height: 6),
        Text('Runs on ${device.displayName}. Arguments are split on spaces. Output appears below and in Activity.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        if (latest == null)
          Text('No commands run on this device yet.', style: TextStyle(color: t.textMuted))
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CommandStatusIcon(command: latest),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(latest.command, style: AppThemeFactory.mono(t)),
                    ),
                    Text(latest.durationLabel, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                if (latest.explainedError != null) ...[
                  AppBanner(
                    tone: BannerTone.danger,
                    title: latest.explainedError!.title,
                    message: latest.explainedError!.message,
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: latest.isRunning
                      ? ValueListenableBuilder<String>(
                          valueListenable:
                              ref.read(commandQueueControllerProvider.notifier).liveOutput(latest.id),
                          builder: (_, value, __) => TerminalBlock(text: value, placeholder: 'Running…'),
                        )
                      : TerminalBlock(text: latest.outputText),
                ),
                if (commands.length > 1) ...[
                  const SizedBox(height: 12),
                  const SectionLabel('Earlier'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 140,
                    child: ActivityList(deviceId: device.id, dense: true, limit: 20),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// "Type text" tab.
class DeviceTypeTextView extends HookConsumerWidget {
  const DeviceTypeTextView({super.key, required this.device});
  final AdbDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final error = useState<String?>(null);
    final t = AppTokens.of(context);

    Future<void> send() async {
      if (controller.text.isEmpty) {
        error.value = 'Type something to send';
        return;
      }
      await ref.read(adbControllerProvider).inputText(device, controller.text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap a text field on ${device.displayName} first. The text is typed into it as if on the keyboard.',
          style: TextStyle(color: t.textMuted),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            onChanged: (_) => error.value = null,
            decoration: InputDecoration(
              labelText: 'Text to type',
              alignLabelWithHint: true,
              errorText: error.value,
              helperText: 'Letters, numbers and spaces work best. Emoji are not supported by Android.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: send,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send to device'),
            ),
            OutlinedButton(onPressed: controller.clear, child: const Text('Clear')),
          ],
        ),
      ],
    );
  }
}

/// No device connected: explains how and offers the three ways to add one.
class NoDeviceState extends ConsumerWidget {
  const NoDeviceState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adb = ref.read(adbControllerProvider);
    final devices = ref.watch(connectedDevicesProvider);
    if (!devices.hasValue && !devices.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(height: 12),
            Text('Looking for devices…', style: TextStyle(color: AppTokens.of(context).textMuted)),
          ],
        ),
      );
    }
    if (devices.hasError) {
      return ErrorPanel(
        error: devices.error!,
        onRetry: () async => ref.invalidate(connectedDevicesProvider),
      );
    }
    return EmptyState(
      icon: Icons.phonelink_rounded,
      title: 'Connect an Android device',
      message: 'Plug one in with USB and allow USB debugging, or pair over Wi-Fi '
          '(Android 11+: Developer options → Wireless debugging).',
      actions: [
        FilledButton.icon(
          onPressed: () => adb.addDevice(),
          icon: const Icon(Icons.qr_code_2_rounded, size: 18),
          label: const Text('Pair with QR code'),
        ),
        OutlinedButton(onPressed: () => adb.addDevice(AddDeviceTab.code), child: const Text('Pairing code')),
        OutlinedButton(onPressed: () => adb.addDevice(AddDeviceTab.ip), child: const Text('IP address')),
      ],
    );
  }
}
