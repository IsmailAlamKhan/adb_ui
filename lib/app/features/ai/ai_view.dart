import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../design/design.dart';
import '../features.dart';

/// "Describe what you want to see…" above logcat. Runs the on-device model.
class AiLogFilterField extends HookConsumerWidget {
  const AiLogFilterField({super.key, required this.device, required this.current, required this.onFilter});
  final AdbDevice device;
  final LogcatFilter current;
  final ValueChanged<LogcatFilter> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = ref.watch(aiControllerProvider);
    final controller = ref.read(aiControllerProvider.notifier);
    final input = useTextEditingController();
    final error = useState<Object?>(null);
    final t = AppTokens.of(context);

    if (!ai.downloaded) return const AiModelSetupCard(compact: true);

    Future<void> run() async {
      final request = input.text.trim();
      if (request.isEmpty || ai.thinking) return;
      error.value = null;
      try {
        final packages = await ref.read(installedPackagesProvider((device: device, includeSystem: false)).future)
            .catchError((_) => <String>[]);
        final filter = await controller.filterFor(request, packages: packages, current: current);
        onFilter(filter);
      } catch (e) {
        error.value = e;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: input,
          enabled: !ai.thinking,
          onSubmitted: (_) => run(),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.auto_awesome, size: 18, color: t.accent),
            hintText: 'Describe what you want to see, e.g. "network errors from Slack"',
            suffixIcon: ai.thinking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(tooltip: 'Apply', onPressed: run, icon: const Icon(Icons.arrow_forward_rounded)),
            helperText: ai.thinking
                ? (ai.status == AiModelStatus.loading ? 'Loading the model…' : 'Thinking…')
                : current.aiExplanation ?? 'Runs on this computer. Your logs are never sent anywhere.',
          ),
        ),
        if (error.value != null) ...[
          const SizedBox(height: 8),
          AppBanner(
            tone: BannerTone.danger,
            title: ErrorCatalogue.explain(error.value).title,
            message: ErrorCatalogue.explain(error.value).message,
            steps: ErrorCatalogue.explain(error.value).steps,
          ),
        ],
      ],
    );
  }
}

/// Download / choose the on-device model. Used in logcat (compact) and Settings.
class AiModelSetupCard extends ConsumerWidget {
  const AiModelSetupCard({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = ref.watch(aiControllerProvider);
    final controller = ref.read(aiControllerProvider.notifier);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;

    String mb(int bytes) => bytes >= 1e9 ? '${(bytes / 1e9).toStringAsFixed(1)} GB' : '${(bytes / 1e6).round()} MB';

    final status = switch (ai.status) {
      AiModelStatus.unknown => 'Checking…',
      AiModelStatus.notDownloaded => 'Not downloaded',
      AiModelStatus.downloading =>
        ai.progress == null ? 'Downloading…' : 'Downloading ${(ai.progress! * 100).toStringAsFixed(0)}%',
      AiModelStatus.ready => 'Downloaded',
      AiModelStatus.loading => 'Loading…',
      AiModelStatus.loaded => 'Ready',
      AiModelStatus.failed => 'Failed',
    };

    final chooser = SegmentedButton<AiModelChoice>(
      showSelectedIcon: false,
      segments: [
        for (final c in AiModelChoice.values)
          ButtonSegment(value: c, label: Text('${c.label} · ${mb(c.bytes)}')),
      ],
      selected: {ai.choice},
      onSelectionChanged: ai.status == AiModelStatus.downloading ? null : (s) => controller.setChoice(s.first),
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (ai.status == AiModelStatus.downloading)
          OutlinedButton(onPressed: controller.cancelDownload, child: const Text('Cancel'))
        else if (!ai.downloaded)
          FilledButton.icon(
            onPressed: controller.download,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text('Download ${mb(ai.choice.bytes)}'),
          )
        else if (!compact)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: t.danger),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => ConfirmActionDialog(
                  title: 'Delete the ${ai.choice.label} model?',
                  message: 'Frees ${mb(ai.choice.bytes)}. You can download it again later.',
                  confirmLabel: 'Delete',
                  destructive: true,
                ),
              );
              if (ok == true) controller.deleteModel();
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete model'),
          ),
        Text(status, style: text.bodySmall),
      ],
    );

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: t.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('AI log filters', style: text.titleSmall)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Describe what you want to see in plain words. A small AI model runs on this computer, '
            'so logs never leave it. Download it once.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          chooser,
          if (ai.status == AiModelStatus.downloading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: ai.progress),
          ],
          const SizedBox(height: 10),
          actions,
          if (ai.error != null) ...[
            const SizedBox(height: 10),
            AppBanner(
              tone: BannerTone.danger,
              title: ErrorCatalogue.explain(ai.error).title,
              message: ErrorCatalogue.explain(ai.error).message,
            ),
          ],
        ],
      ),
    );
  }
}
