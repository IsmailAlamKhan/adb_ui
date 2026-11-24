import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../errors/errors.dart';
import '../package_info/package_info.dart';
import 'update_model.dart';
import 'update_service.dart';
import 'update_view.dart';

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// Checks for updates, downloads and installs them. See spec/features/updates.md.
class UpdateController extends StateNotifier<UpdateState> with NavigationController {
  UpdateController(Ref ref)
      : service = ref.read(updateServiceProvider),
        packageInfo = ref.read(packageInfoServiceProvider),
        eventBus = ref.read(eventBusProvider),
        super(const UpdateState());

  final UpdateService service;
  final PackageInfoService packageInfo;
  @override
  final EventBus eventBus;

  static const checkEvery = Duration(hours: 6);

  Timer? _timer;
  Completer<void>? _cancel;
  List<AppRelease> _releases = const [];
  UpdatePrefs _prefs = UpdatePrefs.initial;

  /// Debug builds only: `--dart-define=ADB_UI_FAKE_VERSION=0.0.17` to test updating.
  static const _fakeVersion = String.fromEnvironment('ADB_UI_FAKE_VERSION');

  Future<AppVersion> _current() async {
    final current = state.current ??
        (kDebugMode && _fakeVersion.isNotEmpty ? AppVersion.tryParse(_fakeVersion) : null) ??
        AppVersion.tryParse((await packageInfo.getPackageInfo()).version);
    return current ?? const AppVersion([0]);
  }

  bool _started = false;

  /// Called once when the home screen shows: "What's new" after an update, then the first
  /// check, then a check every [checkEvery].
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final whatsNew = await _firstStartOfVersion();
    if (whatsNew != null) await showWhatsNew(whatsNew);
    _timer?.cancel();
    _timer = Timer.periodic(checkEvery, (_) => checkAndPrompt());
    await checkAndPrompt();
  }

  /// Checks and shows the update dialog when there's one to offer. [manual] (palette, About)
  /// also reports "up to date" and errors.
  Future<void> checkAndPrompt({bool manual = false}) async {
    final show = await check(manual: manual);
    if (!mounted) return;
    if (show) {
      await showDialog<void>(pageBuilder: (_) => const UpdateDialog());
    } else if (manual && state.status == UpdateStatus.upToDate) {
      showSuccess("You're up to date", message: 'ADB UI ${state.current} is the latest version.');
    } else if (manual && state.status == UpdateStatus.failed && state.error != null) {
      showError(state.error!, onRetry: () => checkAndPrompt(manual: true));
    }
  }

  Future<void> showWhatsNew(AppVersion version) async {
    final entries = await changelog();
    final entry = entries.where((e) => e.version == version).firstOrNull;
    if (entry == null || !mounted) return;
    await showDialog<void>(pageBuilder: (_) => WhatsNewDialog(entry: entry));
  }

  Future<void> showChangelog() => showDialog<void>(pageBuilder: (_) => const ChangelogDialog());

  /// Stores the running version; returns it when it's newer than the last one seen (the
  /// first start after an update), else null. A fresh install returns null.
  Future<AppVersion?> _firstStartOfVersion() async {
    final current = await _current();
    state = state.copyWith(current: current);
    _prefs = await service.loadPrefs();
    final lastSeen = AppVersion.tryParse(_prefs.lastSeenVersion);
    AppVersion? whatsNew;
    if (lastSeen == null || lastSeen != current) {
      if (lastSeen != null && current > lastSeen) {
        whatsNew = current;
        unawaited(service.clearDownloads().catchError((_) {}));
      }
      _prefs = _prefs.copyWith(lastSeenVersion: '$current');
      await service.savePrefs(_prefs);
    }
    return whatsNew;
  }

  /// Looks for an update. Returns true when one is offered and should be shown (not skipped,
  /// or [manual]). Errors only surface for [manual] checks.
  Future<bool> check({bool manual = false}) async {
    if (state.status == UpdateStatus.checking ||
        state.status == UpdateStatus.downloading ||
        state.status == UpdateStatus.installing) {
      return false;
    }
    final current = await _current();
    final previous = state;
    state = UpdateState(status: UpdateStatus.checking, current: current);
    try {
      _releases = await service.releases();
      final release = pickUpdate(_releases, current, Platform.operatingSystem);
      if (!mounted) return false;
      if (release == null) {
        state = UpdateState(status: UpdateStatus.upToDate, current: current);
        return false;
      }
      final keepDownload = previous.release?.version == release.version ? previous.file : null;
      state = UpdateState(
        status: keepDownload != null ? UpdateStatus.ready : UpdateStatus.available,
        current: current,
        release: release,
        notes: releasesBetween(_releases, current, release.version),
        file: keepDownload,
      );
      return manual || _prefs.skippedVersion != '${release.version}';
    } catch (e, s) {
      LogFile.instance.dispath('Update check failed', error: e, stackTrace: s);
      if (!mounted) return false;
      state = manual
          ? UpdateState(status: UpdateStatus.failed, current: current, error: ErrorCatalogue.explain(e))
          : previous.copyWith(status: previous.release != null ? previous.status : UpdateStatus.idle);
      return false;
    }
  }

  /// Hides [UpdateState.release] until a newer version comes out.
  Future<void> skip() async {
    final release = state.release;
    if (release == null) return;
    _prefs = _prefs.copyWith(skippedVersion: '${release.version}');
    await service.savePrefs(_prefs);
  }

  Future<void> download() async {
    final release = state.release;
    final asset = release?.installerFor(Platform.operatingSystem);
    if (release == null || asset == null || state.status == UpdateStatus.downloading) return;
    final cancel = _cancel = Completer<void>();
    state = UpdateState(
      status: UpdateStatus.downloading,
      current: state.current,
      release: release,
      notes: state.notes,
      total: asset.size,
    );
    try {
      final file = await service.download(
        asset,
        cancel: cancel,
        onProgress: (received, total) {
          if (mounted && state.status == UpdateStatus.downloading) {
            state = state.copyWith(received: received, total: total);
          }
        },
      );
      if (!mounted || cancel.isCompleted) return;
      state = state.copyWith(status: UpdateStatus.ready, file: file.path);
    } catch (e, s) {
      if (!mounted) return;
      if (cancel.isCompleted) {
        state = _back(UpdateStatus.available);
        return;
      }
      LogFile.instance.dispath('Update download failed', error: e, stackTrace: s);
      state = _back(UpdateStatus.failed, error: ErrorCatalogue.explain(e));
    } finally {
      _cancel = null;
    }
  }

  void cancelDownload() {
    final cancel = _cancel;
    if (cancel != null && !cancel.isCompleted) cancel.complete();
  }

  /// Installs the downloaded update and quits. Returns false when the installer was only
  /// opened for the user (the app can't replace itself here); the app keeps running then.
  Future<bool> installAndRestart() async {
    final path = state.file;
    if (path == null) return false;
    state = state.copyWith(status: UpdateStatus.installing);
    try {
      final replaced = await service.install(File(path));
      if (!replaced) {
        state = state.copyWith(status: UpdateStatus.ready);
        return false;
      }
      // Cancelable so the app's exit handlers run (the AI model is freed first).
      final response = await ServicesBinding.instance.exitApplication(AppExitType.cancelable);
      if (response == AppExitResponse.cancel) exit(0);
      return true;
    } catch (e, s) {
      LogFile.instance.dispath('Update install failed', error: e, stackTrace: s);
      if (mounted) state = _back(UpdateStatus.failed, error: ErrorCatalogue.explain(e));
      return false;
    }
  }

  UpdateState _back(UpdateStatus status, {AppError? error}) => UpdateState(
        status: status,
        current: state.current,
        release: state.release,
        notes: state.notes,
        error: error,
      );

  /// Every version's notes, from the bundled changelog.
  Future<List<ChangelogEntry>> changelog() async =>
      parseChangelog(await service.bundledChangelog()).where((e) => e.version != null).toList();

  @override
  void dispose() {
    _timer?.cancel();
    cancelDownload();
    super.dispose();
  }
}
