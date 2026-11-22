import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

class UpdateChecker extends HookConsumerWidget {
  const UpdateChecker({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfoService = ref.watch(packageInfoServiceProvider);
    final navigator = Navigator.of(context);
    useEffect(() {
      packageInfoService.newVersionAvailable().then((value) {
        if (value == UpdateAvailableState.updateAvailable) {
          navigator.showDialog(
            pageBuilder: (_) => const UpdateAvailableDialog(),
          );
        }
      });
    }, []);
    return child;
  }
}

class UpdateAvailableDialog extends ConsumerWidget {
  const UpdateAvailableDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.system_update_alt_rounded, color: t.accent, size: 28),
              const SizedBox(height: 12),
              Text('A new version of $appName is available', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Download the installer for this computer. Your settings and activity are kept.',
                style: TextStyle(color: t.textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref.read(aboutControllerProvider.notifier).showChangelog(),
                    child: const Text("What's new"),
                  ),
                  const Spacer(),
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ref.read(aboutServiceProvider).downloadUpdates();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Download'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
