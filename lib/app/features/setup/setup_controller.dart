import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../adb/adb_providers.dart';
import '../adb/adb_service.dart' show refreshProcessEnvironment;
import '../errors/errors.dart';
import 'install_planner.dart';
import 'setup_model.dart';
import 'setup_service.dart';
import 'setup_view.dart';

/// Non-null: show Setup before home (first run, or adb missing at startup).
final setupGateProvider = StateProvider<SetupMode?>((ref) => null);

final setupControllerProvider = StateNotifierProvider<SetupController, SetupState>(SetupController.new);

/// What the user chose in [InstallConsentDialog].
enum InstallConsent { install, cancel }

class SetupController extends StateNotifier<SetupState> with NavigationController {
  SetupController(this.ref)
      : service = ref.read(setupServiceProvider),
        eventBus = ref.read(eventBusProvider),
        super(const SetupState());

  final Ref ref;
  final SetupService service;
  @override
  final EventBus eventBus;

  bool _refreshing = false;

  List<InstallMethod> plansFor(Requirement r) {
    final host = state.host;
    return host == null ? const [] : InstallPlanner.plansFor(r, host);
  }

  /// Detects the host and every requirement again.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    refreshProcessEnvironment();
    try {
      state = state.copyWith(statuses: {
        for (final r in Requirement.values)
          if (r != Requirement.aiModel) r: const ToolStatus.checking(),
      });
      final host = await service.host();
      if (!mounted) return;
      state = state.copyWith(host: host);
      final statuses = <Requirement, ToolStatus>{};
      for (final r in host.requirements) {
        if (r == Requirement.aiModel) continue;
        statuses[r] = await service.detect(r);
      }
      if (mounted) state = state.copyWith(statuses: statuses);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _redetect(Requirement r) async {
    refreshProcessEnvironment();
    final status = await service.detect(r);
    if (mounted) state = state.copyWith(statuses: {...state.statuses, r: status});
  }

  void _log(String line) {
    if (!mounted) return;
    final log = [...state.log, line];
    state = state.copyWith(log: log.length > 400 ? log.sublist(log.length - 400) : log);
  }

  /// Installs every missing required item, one after another, each with its own consent.
  Future<void> installRequired() async {
    for (final r in Requirement.values.where((r) => r.required)) {
      if (state.statusOf(r).found) continue;
      final plans = plansFor(r);
      if (plans.isEmpty) continue;
      final ok = await install(r, plans.first);
      if (!ok) return;
    }
  }

  /// Asks for consent, then installs [r] with [method]. Returns whether it ended up found.
  Future<bool> install(Requirement r, InstallMethod method) async {
    final host = state.host;
    if (state.running != null || host == null) return false;
    final errors = {...state.errors}..remove(r);
    state = state.copyWith(running: r, errors: errors, log: const [], clearProgress: true);
    try {
      switch (method) {
        case ManualInstall():
          return false;
        case PackageManagerInstall():
          final consent = await showDialog<InstallConsent>(
            pageBuilder: (_) => InstallConsentDialog(
              requirement: r,
              method: method,
              hasPkexec: host.hasPkexec,
            ),
          );
          if (consent != InstallConsent.install) return false;
          await service.runPackageManager(r, method, onOutput: _log);
        case DownloadInstall():
          _log('Looking up the latest official download…');
          final target = await service.resolveDownload(r, method.source, host);
          final consent = await showDialog<InstallConsent>(
            pageBuilder: (_) => InstallConsentDialog(
              requirement: r,
              method: method,
              target: target,
            ),
          );
          if (consent != InstallConsent.install) {
            _log('Cancelled.');
            return false;
          }
          await service.download(
            r,
            target,
            onOutput: _log,
            onProgress: (p) {
              if (mounted) state = p == null ? state.copyWith(clearProgress: true) : state.copyWith(progress: p);
            },
          );
      }
      await _redetect(r);
      if (r == Requirement.scrcpy) ref.invalidate(scrcpyAvailableProvider);
      if (!state.statusOf(r).found) {
        throw InstallFailedException(
          r,
          0,
          'The install finished, but ADB UI still can\'t find ${r.shortName}. Click Check again, or restart ADB UI.',
        );
      }
      showSuccess('${r.label} is installed');
      return true;
    } on Object catch (e, s) {
      LogFile.instance.dispath('[setup] installing $r failed', error: e, stackTrace: s);
      final explained = ErrorCatalogue.explain(e);
      if (mounted) state = state.copyWith(errors: {...state.errors, r: explained});
      showError(explained);
      return false;
    } finally {
      if (mounted) state = state.copyWith(clearRunning: true, clearProgress: true);
    }
  }

  /// Leaves the first-run / adb-missing page for home.
  void finish() => ref.read(setupGateProvider.notifier).state = null;
}
