import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/design.dart';
import '../../shared/widgets/widgets.dart';
import '../ai/ai.dart';
import 'setup_controller.dart';
import 'setup_model.dart';
import 'tool_paths.dart';

/// Setup & requirements: what ADB UI needs, and installing it with the user's OK.
/// First run (after the style picker), adb missing at startup, or from Settings / palette.
/// See spec/features/onboarding.md.
class SetupView extends HookConsumerWidget {
  const SetupView({super.key, this.mode = SetupMode.manual});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final compact = WindowSize.of(context).isCompact;

    useEffect(() {
      Future.microtask(controller.refresh);
      return null;
    }, const []);

    final host = state.host;
    final requirements = host?.requirements ?? const [Requirement.adb, Requirement.scrcpy, Requirement.aiModel];
    final busy = state.running != null;
    final requiredMissing = requirements.any((r) => r.required && state.statusOf(r).checked && !state.statusOf(r).found);

    final list = ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 20, compact ? 16 : 28, 24),
      children: [
        if (mode != SetupMode.manual) ...[
          const Row(children: [AppLogo(size: 28)]),
          const SizedBox(height: 16),
        ],
        Text('Set up ADB UI', style: compact ? text.headlineSmall : text.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'ADB UI checks what it needs on this computer. Nothing is installed without your OK.',
          style: TextStyle(color: t.textMuted),
        ),
        const SizedBox(height: 8),
        if (host != null) _InstallerLine(host: host),
        if (mode == SetupMode.adbMissing) ...[
          const SizedBox(height: 16),
          const AppBanner(
            tone: BannerTone.warning,
            title: "adb wasn't found",
            message: 'ADB UI needs it to talk to your devices. Install it below, or install '
                'Android SDK Platform-Tools yourself and click Check again.',
          ),
        ],
        const SizedBox(height: 24),
        const SectionLabel('Required'),
        const SizedBox(height: 8),
        for (final r in requirements.where((r) => r.required)) ...[
          RequirementRow(requirement: r),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        const SectionLabel('Optional'),
        const SizedBox(height: 8),
        for (final r in requirements.where((r) => !r.required)) ...[
          RequirementRow(requirement: r),
          const SizedBox(height: 8),
        ],
        if (state.log.isNotEmpty || busy) ...[
          const SizedBox(height: 16),
          SectionLabel(busy ? 'Installing ${state.running!.shortName}…' : 'Last install'),
          const SizedBox(height: 8),
          if (state.progress != null) ...[
            LinearProgressIndicator(value: state.progress),
            const SizedBox(height: 8),
          ],
          TerminalBlock(text: state.log.join('\n'), maxHeight: 220, placeholder: 'Starting…'),
        ],
      ],
    );

    final footer = Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, 8, compact ? 16 : 28, 16),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: busy ? null : controller.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Check again'),
          ),
          if (requiredMissing)
            OutlinedButton.icon(
              onPressed: busy ? null : controller.installRequired,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Install required'),
            ),
          if (mode == SetupMode.manual)
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Done'),
            )
          else
            Tooltip(
              message: state.requiredReady ? '' : 'Install adb first',
              child: FilledButton.icon(
                onPressed: state.requiredReady && !busy ? controller.finish : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Continue'),
              ),
            ),
        ],
      ),
    );

    final body = Column(
      children: [
        Expanded(child: list),
        Divider(height: 1, color: t.borderSubtle),
        footer,
      ],
    );

    if (mode == SetupMode.manual) {
      return AdaptiveDialog(
        child: Scaffold(
          appBar: AppBar(title: const Text('Setup & requirements')),
          body: body,
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: body),
        ),
      ),
    );
  }
}

class _InstallerLine extends StatelessWidget {
  const _InstallerLine({required this.host});
  final HostInfo host;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final manager = host.manager;
    final (String line, String? linkLabel, String? link) = switch (manager) {
      PackageManager.brew => ('Installs use Homebrew.', null, null),
      PackageManager.winget => ('Installs use winget.', null, null),
      final PackageManager m => ('Installs use ${m.label} (needs your administrator password).', null, null),
      null => switch (host.os) {
          HostOs.macos => (
              "No package manager found. Installs download from the official site into ADB UI's own folder.",
              'Get Homebrew',
              'https://brew.sh',
            ),
          HostOs.windows => (
              "winget wasn't found. Installs download from the official site into ADB UI's own folder.",
              'About winget',
              'https://learn.microsoft.com/windows/package-manager/winget/',
            ),
          HostOs.linux => (
              "No package manager found. Installs download from the official site into ADB UI's own folder.",
              null,
              null,
            ),
        },
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Icon(Icons.inventory_2_outlined, size: 16, color: t.textMuted),
        Text(line, style: TextStyle(color: t.textMuted)),
        if (link != null)
          TextButton(onPressed: () => launchUrl(Uri.parse(link)), child: Text(linkLabel!)),
      ],
    );
  }
}

/// One requirement: status, how it would be installed, and Install buttons.
class RequirementRow extends ConsumerWidget {
  const RequirementRow({super.key, required this.requirement});
  final Requirement requirement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = requirement;
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final mono = TextStyle(fontFamily: t.monoFont, fontSize: 12.5, color: t.textMuted);

    if (r == Requirement.aiModel) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.label, style: text.titleSmall),
            const SizedBox(height: 2),
            Text(r.purpose, style: TextStyle(color: t.textMuted)),
            const SizedBox(height: 12),
            const AiModelSetupCard(compact: true),
          ],
        ),
      );
    }

    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final status = state.statusOf(r);
    final error = state.errors[r];
    final running = state.running == r;
    final busy = state.running != null;
    final plans = controller.plansFor(r);

    final (Color dot, String statusText) = switch (status) {
      _ when running => (t.accent, 'Installing…'),
      ToolStatus(checked: false) => (t.textMuted, 'Checking…'),
      ToolStatus(found: true, managedByApp: true) => (t.success, 'Installed by ADB UI${_v(status)}'),
      ToolStatus(found: true) => (t.success, 'Found${_v(status)}'),
      _ when error != null => (t.danger, 'Install failed: ${error.title}'),
      _ => (r.required ? t.danger : t.warning, 'Not found'),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 6), child: StatusDot(color: dot, label: statusText)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(r.purpose, style: TextStyle(color: t.textMuted)),
                    const SizedBox(height: 6),
                    Text(statusText, style: TextStyle(color: dot == t.textMuted ? t.textMuted : t.text)),
                    if (status.found && status.path != null) SelectableText(status.path!, style: mono),
                  ],
                ),
              ),
            ],
          ),
          if (status.checked && !status.found && plans.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText('↳ ${describeMethod(plans.first)}', style: mono),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, m) in plans.indexed)
                        if (m is! ManualInstall)
                          i == 0
                              ? FilledButton.icon(
                                  onPressed: busy ? null : () => controller.install(r, m),
                                  icon: const Icon(Icons.download_rounded, size: 18),
                                  label: Text(m is PackageManagerInstall && m.needsRoot ? 'Install…' : 'Install'),
                                )
                              : OutlinedButton(
                                  onPressed: busy ? null : () => controller.install(r, m),
                                  child: Text(m is DownloadInstall ? 'Download instead' : 'Other way'),
                                ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _v(ToolStatus s) => s.version == null ? '' : ' · ${s.version}';
}

/// One-line description of a method, shown under a missing item.
String describeMethod(InstallMethod m) => switch (m) {
      PackageManagerInstall() => m.needsRoot ? 'sudo ${m.command}' : m.command,
      DownloadInstall(source: DownloadSource.googlePlatformTools) =>
        "download Platform-Tools from dl.google.com (Google) into ADB UI's folder",
      DownloadInstall(source: DownloadSource.scrcpyGithub) =>
        "download scrcpy from github.com/Genymobile/scrcpy into ADB UI's folder",
      ManualInstall(:final text) => text,
    };

/// Asks before anything is installed: shows the exact command, or the URL and checksum.
class InstallConsentDialog extends StatelessWidget {
  const InstallConsentDialog({
    super.key,
    required this.requirement,
    required this.method,
    this.target,
    this.hasPkexec = false,
  });

  final Requirement requirement;
  final InstallMethod method;
  final DownloadTarget? target;
  final bool hasPkexec;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);
    final m = method;
    final needsRoot = m is PackageManagerInstall && m.needsRoot;
    final shown = switch (m) {
      PackageManagerInstall() => m.command,
      _ => target?.url ?? '',
    };

    void close(InstallConsent c) => Navigator.of(context).pop(c);
    void copy() => Clipboard.setData(ClipboardData(text: needsRoot ? 'sudo $shown' : shown));

    final details = <Widget>[
      if (m is PackageManagerInstall) ...[
        Text(needsRoot ? 'This command installs it:' : 'ADB UI will run this command:'),
        const SizedBox(height: 8),
        TerminalBlock(text: needsRoot ? 'sudo $shown' : shown),
        if (m.manager == PackageManager.winget) ...[
          const SizedBox(height: 8),
          Text("This accepts the package's licence agreement.", style: TextStyle(color: t.textMuted)),
        ],
        if (needsRoot) ...[
          const SizedBox(height: 12),
          AppBanner(
            tone: BannerTone.info,
            title: 'This needs administrator rights',
            message: hasPkexec
                ? 'Run it with pkexec and your system will ask for your password, or copy it and run it in a terminal.'
                : 'Copy it, run it in a terminal, then click Check again.',
          ),
        ],
      ],
      if (m is DownloadInstall && target != null) ...[
        const Text('ADB UI will download:'),
        const SizedBox(height: 8),
        TerminalBlock(text: target!.url),
        const SizedBox(height: 12),
        _Fact(
          'Checks',
          target!.algorithm == 'sha1'
              ? "SHA-1 ${target!.checksum} from Google's repository index"
              : "SHA-256 ${target!.checksum} from the release's SHA256SUMS.txt",
        ),
        if (target!.version != null) _Fact('Version', target!.version!),
        if (target!.size != null) _Fact('Size', '${(target!.size! / 1e6).toStringAsFixed(1)} MB'),
        _Fact(
          'Unpacks into',
          requirement == Requirement.adb
              ? ToolPaths.maybeInstance?.platformToolsDir ?? "ADB UI's tools folder"
              : ToolPaths.maybeInstance?.scrcpyDir ?? "ADB UI's tools folder",
        ),
        const SizedBox(height: 4),
        Text('No administrator rights needed. ADB UI finds it there without changing your PATH.',
            style: TextStyle(color: t.textMuted)),
      ],
    ];

    return Dialog(
      insetPadding: EdgeInsets.all(size.width < WindowSize.compactMax ? 12 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Install ${requirement.shortName}?', style: text.titleLarge),
                    const SizedBox(height: 12),
                    ...details,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(onPressed: () => close(InstallConsent.cancel), child: const Text('Cancel')),
                  if (m is PackageManagerInstall)
                    OutlinedButton.icon(
                      onPressed: () {
                        copy();
                        if (needsRoot) close(InstallConsent.cancel);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(needsRoot ? 'Copy command' : 'Copy'),
                    ),
                  if (!needsRoot || hasPkexec)
                    FilledButton(
                      autofocus: true,
                      onPressed: () => close(InstallConsent.install),
                      child: Text(needsRoot ? 'Run with pkexec' : (m is DownloadInstall ? 'Download' : 'Install')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: t.textMuted))),
          Expanded(child: SelectableText(value, style: TextStyle(fontFamily: t.monoFont, fontSize: 12.5))),
        ],
      ),
    );
  }
}
