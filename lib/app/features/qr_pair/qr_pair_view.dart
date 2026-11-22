import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../design/design.dart';
import '../features.dart';

/// Closes the surrounding route 2 s after the QR flow connects (spec/features/qr-pairing.md).
void useCloseWhenConnected(BuildContext context, WidgetRef ref) {
  ref.listen(qrPairControllerProvider.select((s) => s.status), (previous, next) {
    if (next != QrPairStatus.connected) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        Navigator.of(context).pop();
      }
    });
  });
}

/// The QR code on a white tile (codes must be dark on light to scan, even in dark theme).
class QrCodeTile extends ConsumerWidget {
  const QrCodeTile({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrPairControllerProvider);
    final t = AppTokens.of(context);
    return Semantics(
      image: true,
      label: 'QR code for pairing. Scan it from Wireless debugging on your phone.',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: state.status == QrPairStatus.waitingForScan ? 1 : 0.35,
        child: Container(
          padding: EdgeInsets.all(size / 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: t.borderRadiusLarge,
            border: Border.fromBorderSide(
              t.style == AppStyle.launcher ? t.borderSide : t.subtleSide,
            ),
          ),
          // Fixed size: dialogs may ask for intrinsic sizes, which QrImageView can't give.
          child: SizedBox.square(
            dimension: size,
            child: QrImageView(
              key: ValueKey(state.code.qrData),
              data: state.code.qrData,
              size: size,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Current step of the QR flow, including explained errors.
class QrPairStatusView extends ConsumerWidget {
  const QrPairStatusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qrPairControllerProvider);
    final host = state.host ?? 'your phone';
    return switch (state.status) {
      QrPairStatus.waitingForScan => const _Working('Waiting for your phone to scan the code…'),
      QrPairStatus.pairing => _Working('Pairing with $host… (step 2 of 3)'),
      QrPairStatus.connecting => _Working('Paired. Connecting to $host… (step 3 of 3)'),
      QrPairStatus.connected => AppBanner(
          tone: BannerTone.success,
          title: 'Connected',
          message: '${state.deviceId} is ready. This closes in a moment.',
        ),
      QrPairStatus.pairedNotConnected => const AppBanner(
          tone: BannerTone.warning,
          title: "Paired, but it didn't connect automatically",
          steps: [
            'On the phone, Wireless debugging shows "IP address & Port".',
            'Use Add device → IP address with that address.',
          ],
        ),
      QrPairStatus.failed => AppBanner(
          tone: BannerTone.danger,
          title: state.error?.title ?? state.message ?? 'Pairing failed',
          message: state.error?.message,
          steps: state.error?.steps ?? const [],
        ),
    };
  }
}

class _Working extends StatelessWidget {
  const _Working(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: t.accentSoft, borderRadius: t.borderRadius),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: t.onAccentSoft),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: t.onAccentSoft))),
          ],
        ),
      ),
    );
  }
}

const qrSteps = [
  ('Open Wireless debugging', 'Settings → Developer options → Wireless debugging (Android 11+).'),
  ('Tap “Pair device with QR code”', 'Point the camera at this code. Use the same Wi-Fi network as this computer.'),
  ("That's it", 'It pairs and connects automatically, then this closes.'),
];

/// QR tab of the add-device dialog (Workbench, Console).
class QrPairPanel extends HookConsumerWidget {
  const QrPairPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useCloseWhenConnected(context, ref);
    final t = AppTokens.of(context);
    final compact = WindowSize.of(context).isCompact;
    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < qrSteps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text('${i + 1}.', style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(qrSteps[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(qrSteps[i].$2, style: TextStyle(color: t.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact) ...[
          const Center(child: QrCodeTile(size: 180)),
          const SizedBox(height: 16),
          steps,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QrCodeTile(size: 180),
              const SizedBox(width: 24),
              Expanded(child: steps),
            ],
          ),
        const SizedBox(height: 8),
        const QrPairStatusView(),
      ],
    );
  }
}

/// Launcher's full-page "Scan to pair." screen.
class QrPairPage extends HookConsumerWidget {
  const QrPairPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useCloseWhenConnected(context, ref);
    final state = ref.watch(qrPairControllerProvider);
    final controller = ref.read(qrPairControllerProvider.notifier);
    final adb = ref.read(adbControllerProvider);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final compact = WindowSize.of(context).isCompact;
    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) => now.value = DateTime.now());
      return timer.cancel;
    }, const []);
    final left = state.expiresAt?.difference(now.value);
    final leftLabel = left == null || left.isNegative
        ? ''
        : ' · ${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')} left';
    final statusLabel = switch (state.status) {
      QrPairStatus.waitingForScan => 'waiting for phone · ${state.code.serviceName}$leftLabel',
      QrPairStatus.pairing => 'pairing with ${state.host}…',
      QrPairStatus.connecting => 'connecting to ${state.host}…',
      QrPairStatus.connected => 'connected · ${state.deviceId}',
      QrPairStatus.pairedNotConnected => 'paired · not connected',
      QrPairStatus.failed => 'failed · ${state.message ?? ''}',
    };

    final steps = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < qrSteps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '${i + 1}',
                    style: text.displayMedium!.copyWith(
                      color: i < 2 ? t.accent : t.textMuted,
                      height: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(qrSteps[i].$1, style: text.headlineSmall),
                      const SizedBox(height: 4),
                      Text(qrSteps[i].$2, style: text.bodyLarge!.copyWith(color: t.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop()},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(compact ? 20 : 40, 24, compact ? 20 : 40, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: t.textMuted),
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: const Text('Back'),
                            ),
                            const Spacer(),
                            Text('esc to cancel', style: AppThemeFactory.mono(t, size: 12, color: t.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Scan to pair.',
                          style: (compact ? text.displayMedium : text.displayLarge)!.copyWith(height: 1),
                        ),
                        const SizedBox(height: 32),
                        if (compact) ...[
                          const QrCodeTile(size: 220),
                          const SizedBox(height: 32),
                          steps,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const QrCodeTile(size: 260),
                              const SizedBox(width: 48),
                              Expanded(child: steps),
                            ],
                          ),
                        if (state.status == QrPairStatus.failed ||
                            state.status == QrPairStatus.pairedNotConnected ||
                            state.status == QrPairStatus.connected) ...[
                          const SizedBox(height: 8),
                          const QrPairStatusView(),
                        ],
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(border: Border(top: t.borderSide)),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Semantics(
                                liveRegion: true,
                                child: Text(statusLabel, style: AppThemeFactory.mono(t, size: 13)),
                              ),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      adb.addDevice(AddDeviceTab.code);
                                    },
                                    child: const Text('Use a pairing code instead'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      adb.addDevice(AddDeviceTab.ip);
                                    },
                                    child: const Text('Connect by IP'),
                                  ),
                                  FilledButton(onPressed: controller.restart, child: const Text('New code')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
