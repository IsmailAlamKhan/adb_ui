import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/design.dart';
import '../../shared/widgets/widgets.dart';
import '../ai/ai.dart';
import 'onboarding_frame.dart';
import 'setup_controller.dart';
import 'setup_model.dart';
import 'tool_paths.dart';

/// Setup & requirements: what ADB UI needs, and installing it with the user's OK.
/// First run (step 2 after the style picker), adb missing at startup, or from Settings /
/// palette. See spec/features/onboarding.md.
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
    final manual = mode == SetupMode.manual;

    useEffect(() {
      Future.microtask(controller.refresh);
      return null;
    }, const []);

    final host = state.host;
    final requirements = host?.requirements ?? const [Requirement.adb, Requirement.scrcpy, Requirement.aiModel];
    final busy = state.running != null;

    var delay = 0;
    Widget enter(Widget child, [Object? id]) {
      final d = Duration(milliseconds: 60 * delay++);
      return manual ? child : FadeSlideIn(key: id == null ? null : ValueKey(id), delay: d, child: child);
    }

    final hPad = compact ? 16.0 : 32.0;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(hPad, manual ? 20 : (compact ? 20 : 36), hPad, 24),
      children: [
        enter(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode == SetupMode.firstRun ? 'Get your tools ready' : 'Set up ADB UI',
                style: manual
                    ? (compact ? text.headlineSmall : text.headlineMedium)
                    : (compact ? text.headlineMedium : text.displaySmall),
              ),
              const SizedBox(height: 8),
              Text(
                'ADB UI checks what it needs on this computer. Nothing is installed without your OK.',
                style: text.bodyLarge!.copyWith(color: t.textMuted),
              ),
              if (host != null) ...[const SizedBox(height: 12), _InstallerLine(host: host)],
            ],
          ),
        ),
        if (mode == SetupMode.adbMissing) ...[
          const SizedBox(height: 16),
          enter(
            const AppBanner(
              tone: BannerTone.warning,
              title: "adb wasn't found",
              message:
                  'ADB UI needs it to talk to your devices. Install it below, or install '
                  'Android SDK Platform-Tools yourself and click Check again.',
            ),
          ),
        ],
        const SizedBox(height: 24),
        enter(_ReadinessCard(requirements: requirements)),
        const SizedBox(height: 28),
        enter(const SectionLabel('Required')),
        const SizedBox(height: 10),
        for (final r in requirements.where((r) => r.required)) ...[
          enter(RequirementRow(requirement: r), r),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        enter(const SectionLabel('Optional')),
        const SizedBox(height: 10),
        for (final r in requirements.where((r) => !r.required)) ...[
          enter(RequirementRow(requirement: r), r),
          const SizedBox(height: 10),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: state.log.isNotEmpty || busy
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    SectionLabel(busy ? 'Installing ${state.running!.shortName}…' : 'Last install'),
                    const SizedBox(height: 8),
                    if (state.progress != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: state.progress, minHeight: 6),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TerminalBlock(text: state.log.join('\n'), maxHeight: 220, placeholder: 'Starting…'),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );

    final checkAgain = OutlinedButton.icon(
      onPressed: busy ? null : controller.refresh,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Check again'),
    );

    if (manual) {
      return AdaptiveDialog(
        child: Scaffold(
          appBar: AppBar(title: const Text('Setup & requirements')),
          body: Column(
            children: [
              Expanded(child: list),
              Divider(height: 1, color: t.borderSubtle),
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    checkAgain,
                    FilledButton(
                      autofocus: true,
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return OnboardingFrame(
      step: mode == SetupMode.firstRun ? 2 : null,
      maxWidth: 760,
      actions: [
        checkAgain,
        Tooltip(
          message: state.requiredReady ? '' : 'Install adb first',
          child: FilledButton.icon(
            onPressed: state.requiredReady && !busy ? controller.finish : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Continue'),
          ),
        ),
      ],
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: list),
      ),
    );
  }
}

/// Ring of found tools plus one line about what's still needed, and Install required.
class _ReadinessCard extends ConsumerWidget {
  const _ReadinessCard({required this.requirements});
  final List<Requirement> requirements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final tools = requirements.where((r) => r != Requirement.aiModel).toList();
    final checking = tools.any((r) => !state.statusOf(r).checked);
    final found = tools.where((r) => state.statusOf(r).found).length;
    final missingRequired = tools
        .where((r) => r.required && state.statusOf(r).checked && !state.statusOf(r).found)
        .length;
    final ready = !checking && missingRequired == 0;
    final busy = state.running != null;

    final (Color ring, Color tint, String title, String detail) = switch (()) {
      _ when checking => (t.accent, t.accentSoft, 'Checking this computer…', 'Looking for adb and the other tools.'),
      _ when ready => (
        t.success,
        t.successSoft,
        'Everything ADB UI needs is ready',
        found == tools.length
            ? (found == 2 ? 'Both tools were found.' : 'All $found tools were found.')
            : '$found of ${tools.length} tools found. The optional ones can wait.',
      ),
      _ => (
        t.danger,
        t.dangerSoft,
        missingRequired == 1 ? '1 required tool is missing' : '$missingRequired required tools are missing',
        'Install it below, or click Install required to do it in one go.',
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: t.borderRadiusLarge,
        color: Color.alphaBlend(tint.withValues(alpha: 0.55), t.surface),
        border: Border.all(color: ring.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: tools.isEmpty ? 0 : found / tools.length),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: checking ? null : v,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      color: ring,
                      backgroundColor: ring.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: ready
                      ? Icon(Icons.check_rounded, key: const ValueKey('ok'), color: ring, size: 26)
                      : Text(
                          checking ? '' : '$found/${tools.length}',
                          key: ValueKey('$found${tools.length}$checking'),
                          style: TextStyle(fontWeight: FontWeight.w700, color: t.text, fontSize: 13),
                        ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(color: t.textMuted)),
              ],
            ),
          ),
          if (missingRequired > 0)
            FilledButton.icon(
              onPressed: busy ? null : controller.installRequired,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Install required'),
            ),
        ],
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
      runSpacing: 4,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 15, color: t.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(line, style: TextStyle(color: t.textMuted, fontSize: 13)),
              ),
            ],
          ),
        ),
        if (link != null) TextButton(onPressed: () => launchUrl(Uri.parse(link)), child: Text(linkLabel!)),
      ],
    );
  }
}

/// Icon shown in a requirement's tile.
IconData requirementIcon(Requirement r) => switch (r) {
  Requirement.adb => Icons.usb_rounded,
  Requirement.scrcpy => Icons.cast_rounded,
  Requirement.libmpv => Icons.movie_rounded,
  Requirement.aiModel => Icons.auto_awesome_rounded,
};

/// One requirement: icon tile, name, purpose, status pill, and the Install buttons.
class RequirementRow extends ConsumerWidget {
  const RequirementRow({super.key, required this.requirement});
  final Requirement requirement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = requirement;
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final mono = TextStyle(fontFamily: t.monoFont, fontSize: 12.5, color: t.textMuted);
    final compact = WindowSize.of(context).isCompact;

    Widget heading({Widget? pill, required Color tile, required Color onTile}) {
      final titleBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(r.label, style: text.titleSmall),
              _Tag(r.required ? 'Required' : 'Optional', strong: r.required),
            ],
          ),
          const SizedBox(height: 3),
          Text(r.purpose, style: TextStyle(color: t.textMuted)),
        ],
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(t.radius + 4)),
            child: Icon(requirementIcon(r), color: onTile, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: compact && pill != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleBlock, const SizedBox(height: 8), pill],
                  )
                : titleBlock,
          ),
          if (!compact && pill != null) ...[const SizedBox(width: 12), pill],
        ],
      );
    }

    if (r == Requirement.aiModel) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading(tile: t.accentSoft, onTile: t.onAccentSoft),
            const SizedBox(height: 14),
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

    final tone = switch (status) {
      _ when running => _Tone.busy,
      ToolStatus(checked: false) => _Tone.checking,
      ToolStatus(found: true) => _Tone.ok,
      _ when error != null => _Tone.bad,
      _ => r.required ? _Tone.bad : _Tone.warn,
    };
    final statusText = switch (status) {
      _ when running => 'Installing…',
      ToolStatus(checked: false) => 'Checking…',
      ToolStatus(found: true, managedByApp: true) => 'Installed by ADB UI${_v(status)}',
      ToolStatus(found: true) => 'Found${_v(status)}',
      _ when error != null => 'Install failed: ${error.title}',
      _ => 'Not found',
    };
    final (tile, onTile) = switch (tone) {
      _Tone.ok => (t.successSoft, t.onSuccessSoft),
      _Tone.bad => (t.dangerSoft, t.onDangerSoft),
      _Tone.warn => (t.warningSoft, t.onWarningSoft),
      _ => (t.accentSoft, t.onAccentSoft),
    };
    final showInstall = status.checked && !status.found && plans.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading(
              tile: tile,
              onTile: onTile,
              pill: _StatusPill(tone: tone, label: statusText, progress: running ? state.progress : null),
            ),
            if (status.found && status.path != null)
              Padding(
                padding: const EdgeInsets.only(left: 58, top: 8),
                child: SelectableText(status.path!, style: mono),
              ),
            if (showInstall)
              Padding(
                padding: EdgeInsets.only(left: compact ? 0 : 58, top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: t.surfaceAlt,
                        borderRadius: t.borderRadius,
                        border: Border.all(color: t.borderSubtle),
                      ),
                      child: SelectableText('↳ ${describeMethod(plans.first)}', style: mono),
                    ),
                    const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  static String _v(ToolStatus s) => s.version == null ? '' : ' · ${s.version}';
}

enum _Tone { checking, busy, ok, warn, bad }

/// Rounded status label that cross-fades when the status changes.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.tone, required this.label, this.progress});
  final _Tone tone;
  final String label;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final (bg, fg) = switch (tone) {
      _Tone.ok => (t.successSoft, t.onSuccessSoft),
      _Tone.bad => (t.dangerSoft, t.onDangerSoft),
      _Tone.warn => (t.warningSoft, t.onWarningSoft),
      _Tone.busy => (t.accentSoft, t.onAccentSoft),
      _Tone.checking => (t.surfaceAlt, t.textMuted),
    };
    final lead = switch (tone) {
      _Tone.checking || _Tone.busy => SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2, value: progress, color: fg),
      ),
      _Tone.ok => Icon(Icons.check_circle_rounded, size: 15, color: fg),
      _Tone.warn => Icon(Icons.info_rounded, size: 15, color: fg),
      _Tone.bad => Icon(Icons.error_rounded, size: 15, color: fg),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
      ),
      child: Container(
        key: ValueKey('$tone$label'),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(label: label, child: lead),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.strong = false});
  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: strong ? t.accentSoft : Colors.transparent,
        border: strong ? null : Border.all(color: t.borderSubtle),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: strong ? t.onAccentSoft : t.textMuted),
      ),
    );
  }
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
