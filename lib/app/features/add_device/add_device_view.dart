import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

enum AddDeviceTab {
  qr('QR code', Icons.qr_code_2_rounded),
  code('Pairing code', Icons.pin_outlined),
  ip('IP address', Icons.lan_outlined);

  const AddDeviceTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The three ways to add a device, side by side (spec/08-redesign.md, surface 7–9).
class AddDeviceDialog extends HookWidget {
  const AddDeviceDialog({super.key, this.initialTab = AddDeviceTab.qr});
  final AddDeviceTab initialTab;

  @override
  Widget build(BuildContext context) {
    final tab = useState(initialTab);
    final t = AppTokens.of(context);
    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Add a device', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Wireless debugging needs Android 11 or newer. Android 10 or older: use IP address.',
                style: TextStyle(color: t.textMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<AddDeviceTab>(
                  showSelectedIcon: false,
                  segments: [
                    for (final tab in AddDeviceTab.values)
                      ButtonSegment(value: tab, label: Text(tab.label), icon: Icon(tab.icon, size: 18)),
                  ],
                  selected: {tab.value},
                  onSelectionChanged: (s) => tab.value = s.first,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                child: switch (tab.value) {
                  AddDeviceTab.qr => const QrPairPanel(key: ValueKey('qr')),
                  AddDeviceTab.code => const _PairCodeForm(key: ValueKey('code')),
                  AddDeviceTab.ip => const _ConnectIpForm(key: ValueKey('ip')),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PairCodeForm extends HookConsumerWidget {
  const _PairCodeForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = useTextEditingController();
    final code = useTextEditingController();
    final addressError = useState<String?>(null);
    final codeError = useState<String?>(null);
    final busy = useState(false);
    final paired = useState(false);
    final t = AppTokens.of(context);

    Future<void> submit() async {
      addressError.value = validateHostPort(address.text);
      codeError.value = validatePairingCode(code.text);
      if (addressError.value != null || codeError.value != null) return;
      busy.value = true;
      final ok = await ref.read(adbControllerProvider).pair(address.text, code.text);
      if (!context.mounted) return;
      busy.value = false;
      paired.value = ok;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'On the phone: Wireless debugging → Pair device with pairing code. Enter what it shows.',
          style: TextStyle(color: t.textMuted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: address,
          autofocus: true,
          enabled: !busy.value,
          onChanged: (_) => addressError.value = null,
          decoration: InputDecoration(
            labelText: 'IP address & port',
            hintText: '192.168.1.20:37099',
            errorText: addressError.value,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: code,
          enabled: !busy.value,
          keyboardType: TextInputType.number,
          onChanged: (_) => codeError.value = null,
          onSubmitted: (_) => submit(),
          decoration: InputDecoration(
            labelText: 'Wi-Fi pairing code',
            hintText: '6 digits',
            errorText: codeError.value,
          ),
        ),
        const SizedBox(height: 16),
        if (paired.value) ...[
          const AppBanner(
            tone: BannerTone.success,
            title: 'Paired',
            message: 'The phone usually connects on its own within a few seconds. If it '
                "doesn't, use IP address with the address under \"IP address & Port\".",
          ),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: busy.value ? null : submit,
            child: busy.value ? const _ButtonProgress('Pairing…') : const Text('Pair'),
          ),
        ),
      ],
    );
  }
}

class _ConnectIpForm extends HookConsumerWidget {
  const _ConnectIpForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = useTextEditingController();
    final addressError = useState<String?>(null);
    final busy = useState(false);
    final legacyOpen = useState(false);
    final t = AppTokens.of(context);
    final adb = ref.read(adbControllerProvider);

    Future<void> submit() async {
      addressError.value = validateHostPort(address.text);
      if (addressError.value != null) return;
      busy.value = true;
      final ok = await adb.connect(address.text);
      if (!context.mounted) return;
      busy.value = false;
      if (ok) Navigator.of(context).pop();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Use the IP address & port from Wireless debugging. The port changes each time it restarts.',
          style: TextStyle(color: t.textMuted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: address,
          autofocus: true,
          enabled: !busy.value,
          onChanged: (_) => addressError.value = null,
          onSubmitted: (_) => submit(),
          decoration: InputDecoration(
            labelText: 'IP address & port',
            hintText: '192.168.1.20:37099',
            errorText: addressError.value,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: t.surfaceAlt,
          borderRadius: t.borderRadius,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            initiallyExpanded: legacyOpen.value,
            onExpansionChanged: (v) => legacyOpen.value = v,
            shape: const RoundedRectangleBorder(),
            collapsedShape: const RoundedRectangleBorder(),
            title: const Text('Android 10 or older?'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Connect the phone with a USB cable and allow USB debugging.\n'
                '2. Click Enable Wi-Fi debugging below.\n'
                "3. Unplug the cable and enter the phone's IP with :5555 above "
                '(Settings → About phone → Status → IP address).',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy.value
                    ? null
                    : () async {
                        busy.value = true;
                        await adb.enableTcpip();
                        busy.value = false;
                      },
                icon: const Icon(Icons.usb_rounded, size: 18),
                label: const Text('Enable Wi-Fi debugging (adb tcpip 5555)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: busy.value ? null : submit,
            child: busy.value ? const _ButtonProgress('Connecting…') : const Text('Connect'),
          ),
        ),
      ],
    );
  }
}

class _ButtonProgress extends StatelessWidget {
  const _ButtonProgress(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
}
