import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// One row of the command palette.
class PaletteItem {
  const PaletteItem({
    required this.section,
    required this.label,
    required this.onRun,
    this.detail,
    this.shortcut,
    this.icon,
    this.enabled = true,
    this.keywords = '',
  });
  final String section;
  final String label;
  final String? detail;
  final String? shortcut;
  final IconData? icon;
  final bool enabled;
  final String keywords;
  final VoidCallback onRun;

  /// Every query word must appear in the label, detail or keywords.
  bool matches(String query) {
    if (query.isEmpty) return true;
    final haystack = '$label $detail $keywords'.toLowerCase();
    return query.toLowerCase().split(RegExp(r'\s+')).every(haystack.contains);
  }
}

/// Builds palette items for the current state (selected device, devices, recent commands).
List<PaletteItem> buildPaletteItems(WidgetRef ref, {required VoidCallback close}) {
  final adb = ref.read(adbControllerProvider);
  final device = ref.read(selectedDeviceProvider);
  final devices = ref.read(connectedDevicesProvider).valueOrNull ?? const <AdbDevice>[];
  final scrcpy = ref.read(scrcpyAvailableProvider).valueOrNull ?? false;
  final recent = ref.read(commandQueueControllerProvider).where((c) => c.isDone).take(5);
  final settings = ref.read(settingsControllerProvider.notifier);

  VoidCallback run(VoidCallback action) => () {
        close();
        action();
      };

  return [
    if (device != null)
      for (final action in DeviceAction.values)
        PaletteItem(
          section: 'Actions on ${device.displayName}',
          label: '${action.label}…',
          detail: action.command,
          shortcut: action.shortcutText,
          icon: action.icon,
          enabled: action.unavailableReason(device, scrcpyAvailable: scrcpy) == null,
          onRun: run(() => action.perform(ref, device)),
        ),
    for (final d in devices)
      if (d.id != device?.id)
        PaletteItem(
          section: 'Switch device',
          label: d.displayName,
          detail: d.id,
          icon: Icons.smartphone_rounded,
          keywords: 'device select switch',
          onRun: run(() => ref.read(selectedDeviceIdProvider.notifier).state = d.id),
        ),
    for (final tab in AddDeviceTab.values)
      PaletteItem(
        section: 'Add device',
        label: switch (tab) {
          AddDeviceTab.qr => 'Pair with QR code',
          AddDeviceTab.code => 'Pair with pairing code',
          AddDeviceTab.ip => 'Connect by IP address',
        },
        icon: tab.icon,
        keywords: 'add device wireless wifi connect pair',
        shortcut: tab == AddDeviceTab.qr ? shortcutLabel(AppShortcuts.addDevice) : null,
        onRun: run(() => adb.addDevice(tab)),
      ),
    PaletteItem(
      section: 'App',
      label: 'Activity',
      icon: Icons.history_rounded,
      shortcut: shortcutLabel(AppShortcuts.activity),
      keywords: 'log history queue output',
      onRun: run(adb.openActivity),
    ),
    PaletteItem(
      section: 'App',
      label: 'Settings',
      icon: Icons.settings_outlined,
      shortcut: shortcutLabel(AppShortcuts.settings),
      keywords: 'preferences style theme',
      onRun: run(adb.openSettings),
    ),
    PaletteItem(
      section: 'App',
      label: 'Check for updates',
      icon: Icons.system_update_alt_rounded,
      keywords: 'update upgrade new version download install',
      onRun: run(() => ref.read(updateControllerProvider.notifier).checkAndPrompt(manual: true)),
    ),
    PaletteItem(
      section: 'App',
      label: "What's new",
      icon: Icons.history_edu_rounded,
      keywords: 'changelog release notes changes',
      onRun: run(() => ref.read(updateControllerProvider.notifier).showChangelog()),
    ),
    PaletteItem(
      section: 'App',
      label: 'Restart adb',
      detail: 'adb kill-server, start-server',
      icon: Icons.restart_alt_rounded,
      keywords: 'kill-server reset stuck wifi wireless discovery',
      onRun: run(adb.restartAdb),
    ),
    for (final style in AppStyle.values)
      PaletteItem(
        section: 'App',
        label: 'Switch to ${style.label} style',
        icon: Icons.dashboard_customize_outlined,
        keywords: 'layout look appearance',
        onRun: run(() => settings.setStyle(style)),
      ),
    for (final mode in ThemeMode.values)
      PaletteItem(
        section: 'App',
        label: 'Theme: ${switch (mode) {
          ThemeMode.system => 'match system',
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
        }}',
        icon: Icons.contrast_rounded,
        keywords: 'dark light appearance',
        onRun: run(() => settings.setThemeMode(mode)),
      ),
    for (final c in recent)
      PaletteItem(
        section: 'Recent',
        label: 'Run again: ${c.command}',
        detail: c.startedAt.timeAgoLabel,
        icon: Icons.replay_rounded,
        onRun: run(() => adb.rerunCommand(c)),
      ),
  ];
}

extension on DateTime {
  String get timeAgoLabel {
    final d = DateTime.now().difference(this);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}

/// The palette: a search field and the matching items. ↑/↓ move, ↵ runs, Esc clears/closes.
class CommandPalette extends HookConsumerWidget {
  const CommandPalette({super.key, this.inline = false, this.onClose, this.focusNode, this.maxListHeight = 360});

  /// Inline (Launcher home) shows a limited list until something is typed.
  final bool inline;
  final VoidCallback? onClose;
  final FocusNode? focusNode;
  final double maxListHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useValueListenable(controller).text.trim();
    final highlighted = useState(0);
    final ownFocus = useFocusNode();
    final focus = focusNode ?? ownFocus;
    final scroll = useScrollController();
    // Rebuild when state the items depend on changes.
    ref.watch(selectedDeviceProvider);
    ref.watch(connectedDevicesProvider);
    ref.watch(commandQueueControllerProvider.select((l) => l.where((c) => c.isDone).take(5).length));
    final t = AppTokens.of(context);

    void close() {
      controller.clear();
      onClose?.call();
    }

    var items = buildPaletteItems(ref, close: close).where((i) => i.matches(query)).toList();
    if (inline && query.isEmpty) {
      items = items.where((i) => i.section.startsWith('Actions') || i.section == 'Recent').toList();
      if (items.isEmpty) {
        items = buildPaletteItems(ref, close: close).where((i) => i.section == 'Add device').toList();
      }
    }
    final index = items.isEmpty ? 0 : highlighted.value.clamp(0, items.length - 1);

    KeyEventResult onKey(FocusNode node, KeyEvent event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        highlighted.value = items.isEmpty ? 0 : (index + 1) % items.length;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        highlighted.value = items.isEmpty ? 0 : (index - 1 + items.length) % items.length;
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (items.isNotEmpty && items[index].enabled) items[index].onRun();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (controller.text.isNotEmpty && inline) {
          controller.clear();
        } else {
          onClose?.call();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final fg = t.onTerminal;
    final muted = t.onTerminalMuted;
    final rows = <Widget>[];
    String? section;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.section != section) {
        section = item.section;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          child: Text(
            section.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: muted, letterSpacing: 0.8),
          ),
        ));
      }
      final selected = i == index;
      rows.add(Opacity(
        opacity: item.enabled ? 1 : 0.45,
        child: Material(
          color: selected ? fg.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: t.borderRadius,
          child: InkWell(
            borderRadius: t.borderRadius,
            onTap: item.enabled ? item.onRun : null,
            onHover: (h) {
              if (h) highlighted.value = i;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 18, color: muted),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(item.label, style: TextStyle(color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (item.detail != null) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: Text(
                        item.detail!,
                        textAlign: TextAlign.right,
                        style: AppThemeFactory.mono(t, size: 12, color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Fixed-width column so shortcuts line up.
                  SizedBox(
                    width: 64,
                    child: item.shortcut == null
                        ? null
                        : Align(alignment: Alignment.centerRight, child: KeyHint(item.shortcut!, onTerminal: true)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }

    return Material(
      color: t.terminal,
      shape: RoundedRectangleBorder(
        borderRadius: t.borderRadiusLarge,
        // Outline so the dark palette stays visible on dark grounds.
        side: t.isDark ? BorderSide(color: t.borderSubtle) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      elevation: inline ? 0 : 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Text('›', style: AppThemeFactory.mono(t, size: 18, color: t.terminalAccent)),
                const SizedBox(width: 12),
                Expanded(
                  child: Focus(
                    onKeyEvent: onKey,
                    skipTraversal: true,
                    child: TextField(
                      controller: controller,
                      focusNode: focus,
                      autofocus: !inline,
                      onChanged: (_) => highlighted.value = 0,
                      cursorColor: t.terminalAccent,
                      style: TextStyle(color: fg, fontSize: 17),
                      decoration: InputDecoration(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: inline ? 'Type a command' : 'Search actions, devices, settings…',
                        hintStyle: TextStyle(color: muted, fontSize: 17),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                KeyHint(inline ? shortcutLabel(AppShortcuts.palette) : 'esc', onTerminal: true),
              ],
            ),
          ),
          Divider(height: 1, color: muted.withValues(alpha: 0.25)),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('Nothing matches "$query".', style: TextStyle(color: muted)),
                  )
                : ListView(
                    controller: scroll,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    children: rows,
                  ),
          ),
        ],
      ),
    );
  }
}

/// ⌘K palette as a dialog (Workbench, Console; Launcher focuses its inline palette instead).
class CommandPaletteDialog extends StatelessWidget {
  const CommandPaletteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Align(
      alignment: const Alignment(0, -0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 680, maxHeight: size.height * 0.8),
          child: CommandPalette(
            onClose: () => Navigator.of(context).pop(),
            maxListHeight: (size.height * 0.6).clamp(200, 440),
          ),
        ),
      ),
    );
  }
}
