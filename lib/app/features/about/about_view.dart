import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

/// About ADB UI: version, update status, links, report a bug.
class AboutView extends ConsumerWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aboutControllerProvider.notifier);
    final version = ref.watch(packageInfoControllerProvider)?.version ?? '';
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    return AdaptiveDialog(
      child: Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Row(
              children: [
                const AppLogo(size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appName, style: text.headlineMedium),
                      const SizedBox(height: 2),
                      Text('Version $version', style: AppThemeFactory.mono(t, size: 13, color: t.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _UpdateStatus(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.showChangelog,
                  icon: const Icon(Icons.history_edu_rounded, size: 18),
                  label: const Text('Changelog'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showLicensePage(context: context, applicationName: appName),
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: const Text('Licenses'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.openGitHub,
                  icon: const Icon(Icons.code_rounded, size: 18),
                  label: const Text('GitHub'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              onTap: controller.reportBugOrFeatureRequest,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: t.accentSoft, borderRadius: t.borderRadius),
                    child: Icon(Icons.bug_report_outlined, color: t.onAccentSoft, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Report a bug or request a feature', style: text.titleSmall),
                        Text('Opens an issue on GitHub. For bugs, a log file is saved for you to attach.',
                            style: text.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('If ADB UI helps you, a star on GitHub helps others find it.', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _UpdateStatus extends ConsumerWidget {
  const _UpdateStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    void openDialog() => Navigator.of(context).push(DialogRoute(context: context, builder: (_) => const UpdateDialog()));
    final checkAgain = TextButton(
      onPressed: () => controller.checkAndPrompt(manual: true),
      child: const Text('Check for updates'),
    );
    return switch (state.status) {
      UpdateStatus.checking => const AppBanner(tone: BannerTone.info, title: 'Checking for updates…'),
      UpdateStatus.failed when state.release == null => AppBanner(
          tone: BannerTone.warning,
          title: "Couldn't check for updates",
          message: state.error?.message,
          actions: [checkAgain],
        ),
      _ when state.release != null => AppBanner(
          tone: BannerTone.info,
          icon: Icons.system_update_alt_rounded,
          title: 'ADB UI ${state.release!.version} is available',
          message: switch (state.status) {
            UpdateStatus.downloading => 'Downloading…',
            UpdateStatus.ready => 'Downloaded and ready to install.',
            _ => null,
          },
          actions: [FilledButton(onPressed: openDialog, child: const Text('See update'))],
        ),
      UpdateStatus.upToDate => AppBanner(
          tone: BannerTone.success,
          title: "You're on the latest version",
          actions: [checkAgain],
        ),
      _ => AppBanner(tone: BannerTone.info, title: 'Updates are checked automatically', actions: [checkAgain]),
    };
  }
}

/// Pops `{is_bug_report, add_device_details}` or null.
class FeatureRequestOrBugReportDialog extends HookWidget {
  const FeatureRequestOrBugReportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isBugReport = useState(true);
    final addDeviceDetails = useState(true);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;

    Widget choice(bool bug, IconData icon, String title, String subtitle) => Expanded(
          child: Semantics(
            inMutuallyExclusiveGroup: true,
            checked: isBugReport.value == bug,
            child: AppCard(
              selected: isBugReport.value == bug,
              onTap: () => isBugReport.value = bug,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: t.accent),
                  const SizedBox(height: 8),
                  Text(title, style: text.titleSmall),
                  Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
          ),
        );

    return Dialog(
      insetPadding: dialogInset(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report a bug or request a feature', style: text.headlineSmall),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  choice(true, Icons.bug_report_outlined, 'Bug report', 'Something is broken'),
                  const SizedBox(width: 12),
                  choice(false, Icons.lightbulb_outline_rounded, 'Feature request', 'Something is missing'),
                ],
              ),
              if (isBugReport.value) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include device details in the log file'),
                  subtitle: const Text('Computer model and OS. Helps reproduce the bug.'),
                  value: addDeviceDetails.value,
                  onChanged: (v) => addDeviceDetails.value = v,
                ),
                Text(
                  'A zip of the app logs is saved to your computer, then GitHub opens. Attach the zip to the issue.',
                  style: text.bodySmall,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop({
                      'is_bug_report': isBugReport.value,
                      'add_device_details': addDeviceDetails.value,
                    }),
                    child: Text(isBugReport.value ? 'Save logs and open GitHub' : 'Open GitHub'),
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
