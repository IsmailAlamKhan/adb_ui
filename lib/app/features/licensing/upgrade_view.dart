import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../auth/auth_providers.dart';
import 'license_model.dart';
import 'license_providers.dart';

class UpgradeView extends ConsumerWidget {
  const UpgradeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final license = ref.watch(licenseControllerProvider);
    final licenseNotifier = ref.read(licenseControllerProvider.notifier);
    final user = ref.watch(currentUserProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final configured = SupabaseConfig.isConfigured;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Plan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(license.statusLabel, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (user != null) Text('Signed in as ${user.email ?? user.id}'),
        if (user == null)
          const Text('Sign in to start a trial or upgrade. You can keep using free features without an account.'),
        const SizedBox(height: 24),
        if (!configured)
          const Text(
            'Cloud licensing is not configured in this build. Set Supabase URL and anon key in '
            'lib/app/utils/supabase_config.dart to enable sign-in and checkout.',
          ),
        if (configured && user != null) ...[
          license.maybeWhen(
            pro: (purchasedAt, deviceIds, maxDevices) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Devices registered: ${deviceIds.length} of $maxDevices',
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          if (!license.isPro && !license.isTrialActive)
            FilledButton(
              onPressed: () async {
                try {
                  await licenseNotifier.startTrial();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trial started — enjoy Pro features for 14 days.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Start free trial'),
            ),
          const SizedBox(height: 12),
          if (!license.isPro)
            OutlinedButton(
              onPressed: () async {
                try {
                  await licenseNotifier.purchasePro();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('If checkout completed, your plan will update shortly.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Upgrade to Pro'),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await authNotifier.signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ],
    );
  }
}
