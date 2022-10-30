import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
    return ConstrainedDialog(
      child: AlertDialog(
        title: const Text('Update Available'),
        content:
            const Text('A new version of the app is available. Would you like to download it now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              ref.read(aboutServiceProvider).downloadUpdates();
              Navigator.of(context).pop();
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
