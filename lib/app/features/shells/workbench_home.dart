import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../../shared/shared.dart';
import '../features.dart';

/// Workbench: sidebar of devices, each device a page with tabs (spec/08-redesign.md).
class WorkbenchHome extends ConsumerWidget {
  const WorkbenchHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = WindowSize.of(context);
    final device = ref.watch(selectedDeviceProvider);
    final adb = ref.read(adbControllerProvider);
    final t = AppTokens.of(context);
    final body = device == null
        ? const NoDeviceState()
        : _DevicePage(key: ValueKey(device.id), device: device, sideActivity: size.isExpanded);

    if (size.isCompact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(device?.displayName ?? 'ADB UI'),
          actions: [
            IconButton(
              tooltip: 'Search actions',
              onPressed: adb.openPalette,
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: 'Activity',
              onPressed: adb.openActivity,
              icon: const Icon(Icons.history_rounded),
            ),
          ],
        ),
        drawer: const Drawer(child: _Sidebar(inDrawer: true)),
        body: body,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: size.isExpanded ? 240 : 220, child: const _Sidebar()),
          VerticalDivider(width: 1, color: t.borderSubtle),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({this.inDrawer = false});
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final adb = ref.read(adbControllerProvider);
    final devices = ref.watch(connectedDevicesProvider).valueOrNull ?? const <AdbDevice>[];
    final counts = ref.watch(activityCountsProvider);
    void close() {
      if (inDrawer) Navigator.of(context).maybePop();
    }

    Widget item(IconData icon, String label, VoidCallback onTap, {Widget? trailing}) => ListTile(
      dense: true,
      leading: Icon(icon, size: 18),
      title: Text(label),
      trailing: trailing,
      onTap: () {
        close();
        onTap();
      },
    );

    return Material(
      color: t.surfaceAlt,
      child: SafeArea(
        right: false,
        child: Padding(
          // The drawer drops the top inset, so leave room for the macOS window buttons.
          padding: EdgeInsets.fromLTRB(8, inDrawer && Platform.isMacOS ? 34 : 12, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Row(
                  children: [
                    const AppLogo(size: 22),
                    const SizedBox(width: 8),
                    Expanded(child: Text('ADB UI', style: Theme.of(context).textTheme.titleMedium)),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: t.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () {
                  close();
                  adb.openPalette();
                },
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Search actions')),
                    KeyHint(shortcutLabel(AppShortcuts.palette)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    const SectionLabel('Devices', padding: EdgeInsets.fromLTRB(10, 10, 10, 4)),
                    if (devices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                        child: Text('No devices yet', style: TextStyle(color: t.textMuted)),
                      ),
                    for (final d in devices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: DeviceListTile(device: d),
                      ),
                    const SectionLabel('Add device', padding: EdgeInsets.fromLTRB(10, 14, 10, 4)),
                    item(Icons.qr_code_2_rounded, 'Pair with QR code', () => adb.addDevice()),
                    item(Icons.pin_outlined, 'Pair with code', () => adb.addDevice(AddDeviceTab.code)),
                    item(Icons.lan_outlined, 'Connect by IP', () => adb.addDevice(AddDeviceTab.ip)),
                  ],
                ),
              ),
              item(
                Icons.history_rounded,
                'Activity',
                adb.openActivity,
                trailing: counts.running > 0
                    ? SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
                      )
                    : counts.errors > 0
                    ? Tooltip(
                        message: '${counts.errors} failed',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: t.dangerSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${counts.errors}',
                            style: TextStyle(
                              color: t.onDangerSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              item(Icons.settings_outlined, 'Settings', adb.openSettings),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevicePage extends ConsumerWidget {
  const _DevicePage({super.key, required this.device, required this.sideActivity});
  final AdbDevice device;
  final bool sideActivity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final adb = ref.read(adbControllerProvider);
    final scrcpy = ref.watch(scrcpyAvailableProvider).valueOrNull ?? false;
    final compact = WindowSize.of(context).isCompact;
    final pad = compact ? 16.0 : 32.0;
    final tabs = device.isOnline
        ? const ['Overview', 'Screen', 'Logcat', 'Apps', 'Files', 'Shell', 'Type text']
        : const ['Overview'];
    final mirrorReason = DeviceAction.mirror.unavailableReason(device, scrcpyAvailable: scrcpy);

    final header = Padding(
      padding: EdgeInsets.fromLTRB(pad, compact ? 12 : 28, pad, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact) Text(device.displayName, style: text.headlineLarge),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DeviceStatusLine(device: device),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      device.id,
                      style: AppThemeFactory.mono(t, size: 12, color: t.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              Builder(
                builder: (tabContext) => Tooltip(
                  message: mirrorReason ?? 'Show the Screen tab',
                  child: OutlinedButton.icon(
                    onPressed: mirrorReason == null
                        ? () => DefaultTabController.of(tabContext).animateTo(1)
                        : null,
                    icon: const Icon(Icons.cast_rounded, size: 18),
                    label: const Text('Mirror screen'),
                  ),
                ),
              ),
              if (device.isWireless)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: t.danger),
                  onPressed: () => adb.disconnect(device),
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text('Disconnect'),
                ),
            ],
          ),
        ],
      ),
    );

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (!device.isOnline)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
              child: DeviceStateBanner(device: device),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad - 12),
            child: TabBar(
              isScrollable: true,
              dividerColor: Colors.transparent,
              tabs: [for (final tab in tabs) Tab(text: tab, height: 38)],
            ),
          ),
          Divider(height: 1, color: t.borderSubtle),
          Expanded(
            child: TabBarView(
              // Desktop: tabs change by click/keyboard; swiping would fight with lists and selection.
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Overview(device: device, sideActivity: sideActivity, pad: pad),
                if (device.isOnline) ...[
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: MirrorView(device: device),
                  ),
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: LogcatView(device: device),
                  ),
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: DeviceAppsView(device: device),
                  ),
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: _ExcludedFromApkDrop(child: DeviceFilesView(device: device)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(pad),
                    child: DeviceShellView(device: device),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.all(pad),
                    child: DeviceTypeTextView(device: device),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Files tab takes drops itself (push), so the window-wide APK drop skips it.
class _ExcludedFromApkDrop extends StatefulWidget {
  const _ExcludedFromApkDrop({required this.child});
  final Widget child;

  @override
  State<_ExcludedFromApkDrop> createState() => _ExcludedFromApkDropState();
}

class _ExcludedFromApkDropState extends State<_ExcludedFromApkDrop> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    ApkDropZone.exclude(_key);
  }

  @override
  void dispose() {
    ApkDropZone.include(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

class _Overview extends ConsumerWidget {
  const _Overview({required this.device, required this.sideActivity, required this.pad});
  final AdbDevice device;
  final bool sideActivity;
  final double pad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adb = ref.read(adbControllerProvider);
    final activity = AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActivityList(deviceId: device.id, limit: 6, dense: true, shrinkWrap: true),
          Divider(height: 1, color: AppTokens.of(context).borderSubtle),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: adb.openActivity, child: const Text('Show all activity')),
          ),
        ],
      ),
    );
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Quick actions'),
        const SizedBox(height: 10),
        DeviceActionGrid(
          device: device,
          exclude: const {DeviceAction.mirror, DeviceAction.disconnect, DeviceAction.logcat},
        ),
        const SizedBox(height: 24),
        const SectionLabel('Device'),
        const SizedBox(height: 10),
        DeviceDetailsCard(device: device),
        if (!sideActivity) ...[
          const SizedBox(height: 24),
          const SectionLabel('Recent activity'),
          const SizedBox(height: 10),
          activity,
        ],
      ],
    );
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: sideActivity
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 24),
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [const SectionLabel('Recent activity'), const SizedBox(height: 10), activity],
                  ),
                ),
              ],
            )
          : main,
    );
  }
}
