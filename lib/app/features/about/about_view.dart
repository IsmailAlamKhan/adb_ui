import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

class AboutView extends ConsumerWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aboutControllerProvider.notifier);

    return ConstrainedDialog(
      child: Center(
        child: SizedBox(
          width: 600,
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(title: const Text('About $appName'), toolbarHeight: 40),
                  const Gap(8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(size: 100),
                      const Gap(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _UpdateChecker(),
                            const Gap(8),
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  _CurrentVersion(),
                                  Gap(8),
                                  _ReportBug(),
                                  Gap(8),
                                  _Actions(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text.rich(
                    TextSpan(
                      text: 'Please star the repo on ',
                      children: [
                        TextSpan(
                          text: 'GitHub',
                          style: AppTheme.linkTextStyle,
                          recognizer: TapGestureRecognizer()..onTap = () => controller.openGitHub(),
                        ),
                        const TextSpan(text: ' if you like this app.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aboutControllerProvider.notifier);
    return ButtonBar(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      layoutBehavior: ButtonBarLayoutBehavior.padded,
      overflowButtonSpacing: 8,
      alignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => showLicensePage(context: context),
          child: const Text('Show licenses'),
        ),
        ElevatedButton(
          onPressed: () => controller.showChangelog(),
          child: const Text('Show changelog'),
        ),
      ],
    );
  }
}

class _ReportBug extends ConsumerWidget {
  const _ReportBug({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aboutControllerProvider.notifier);
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Please report any bugs or feature requests on '),
          TextSpan(
            text: 'GitHub',
            style: AppTheme.linkTextStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => controller.reportBugOrFeatureRequest(),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

class FeatureRequestOrBugReportDialog extends HookWidget {
  const FeatureRequestOrBugReportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isBugReport = useState(true);
    final addDeviceDetails = useState(true);
    return ConstrainedDialog(
      child: AlertDialog(
        title: const Text('Report a bug or feature request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: isBugReport.value,
                  onChanged: (value) => isBugReport.value = value!,
                ),
                GestureDetector(
                  onTap: () => isBugReport.value = true,
                  child: const Text('Bug report'),
                ),
                Radio<bool>(
                  value: false,
                  groupValue: isBugReport.value,
                  onChanged: (value) => isBugReport.value = value!,
                ),
                GestureDetector(
                  onTap: () => isBugReport.value = false,
                  child: const Text('Feature request'),
                ),
              ],
            ),
            const Gap(8),
            RunAnimation.sizeTransition(
              show: isBugReport.value,
              axisAlignment: 1,
              child: SwitchListTile(
                title: const Text('Include device details to logs'),
                value: addDeviceDetails.value,
                onChanged: (value) => addDeviceDetails.value = value,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'is_bug_report': isBugReport.value,
              'add_device_details': addDeviceDetails.value,
            }),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CurrentVersion extends ConsumerWidget {
  const _CurrentVersion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVersion = ref.watch(packageInfoControllerProvider)!.version;
    return Text('Current version: $currentVersion');
  }
}

class _UpdateChecker extends ConsumerWidget {
  const _UpdateChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aboutControllerProvider.notifier);
    final state = ref.watch(aboutControllerProvider);

    bool isLoading = false;
    IconData? icon;
    Color? iconColor;
    late InlineSpan text;

    state.when(
      data: (about) {
        if (!about.updateAvailable) {
          icon = Icons.check_circle;
          iconColor = Colors.green;
          text = const TextSpan(text: 'You are using the latest version of $appName');
        } else {
          icon = Icons.warning;
          iconColor = Colors.red;
          text = TextSpan(
            text: 'A new version of $appName is available ',
            children: [
              TextSpan(
                text: 'Download',
                style: AppTheme.linkTextStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    controller.downloadUpdates();
                  },
              ),
            ],
          );
        }
      },
      error: (error, stack) {
        icon = Icons.error;
        iconColor = Colors.red;
        text = const TextSpan(text: 'Error while checking for updates');
      },
      loading: () {
        isLoading = true;
        text = const TextSpan(text: 'Checking for updates...');
      },
    );
    Widget iconWidget;
    Widget textWidget;
    if (isLoading) {
      iconWidget = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      iconWidget = Icon(icon, color: iconColor);
    }
    textWidget = Text.rich(text);

    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        const Gap(10),
        Flexible(child: textWidget),
      ],
    );

    return child;
  }
}
