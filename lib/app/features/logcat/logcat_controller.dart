import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

@immutable
class LogcatState {
  const LogcatState({
    this.visible = const [],
    this.total = 0,
    this.filter = const LogcatFilter(),
    this.running = false,
    this.paused = false,
    this.newWhilePaused = 0,
    this.error,
    this.followedPackage,
    this.followedPids = const {},
    this.waitingForApp = false,
  });

  /// Filtered entries, oldest first.
  final List<LogcatEntry> visible;

  /// Entries in the buffer (all, unfiltered).
  final int total;
  final LogcatFilter filter;
  final bool running;
  final bool paused;
  final int newWhilePaused;
  final Object? error;

  /// Package being followed (picked, or the foreground one).
  final String? followedPackage;
  final Set<int> followedPids;

  /// Following an app that isn't running yet.
  final bool waitingForApp;

  LogcatState copyWith({
    List<LogcatEntry>? visible,
    int? total,
    LogcatFilter? filter,
    bool? running,
    bool? paused,
    int? newWhilePaused,
    Object? error,
    bool clearError = false,
    String? followedPackage,
    bool clearFollowed = false,
    Set<int>? followedPids,
    bool? waitingForApp,
  }) =>
      LogcatState(
        visible: visible ?? this.visible,
        total: total ?? this.total,
        filter: filter ?? this.filter,
        running: running ?? this.running,
        paused: paused ?? this.paused,
        newWhilePaused: newWhilePaused ?? this.newWhilePaused,
        error: clearError ? null : (error ?? this.error),
        followedPackage: clearFollowed ? null : (followedPackage ?? this.followedPackage),
        followedPids: followedPids ?? this.followedPids,
        waitingForApp: waitingForApp ?? this.waitingForApp,
      );
}

final logcatControllerProvider =
    StateNotifierProvider.autoDispose.family<LogcatController, LogcatState, AdbDevice>(
  LogcatController.new,
);

/// One logcat session for a device (spec/features/logcat.md).
class LogcatController extends StateNotifier<LogcatState> {
  LogcatController(this.ref, this.device)
      : service = ref.read(adbServiceProvider),
        super(const LogcatState()) {
    start();
  }

  final Ref ref;
  final AdbDevice device;
  final AdbService service;

  static const bufferSize = 20000;
  static const pollInterval = Duration(seconds: 2);
  static const flushInterval = Duration(milliseconds: 150);

  final _buffer = ListQueue<LogcatEntry>();
  final _pending = <LogcatEntry>[];
  final _crashes = CrashTracker();
  Process? _process;
  StreamSubscription<String>? _subscription;
  Timer? _flushTimer;
  Timer? _pollTimer;
  int _seq = 0;
  bool _polling = false;

  /// Starts (or restarts) the stream.
  Future<void> start() async {
    await _stopProcess();
    state = state.copyWith(running: true, clearError: true);
    try {
      final process = await service.startProcess(
        ['logcat', '-v', 'threadtime', '-T', '1000'],
        device: device,
      );
      if (!mounted) {
        process.kill();
        return;
      }
      _process = process;
      _subscription = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_onLine, onDone: _onEnded);
      final stderr = StringBuffer();
      process.stderr.transform(utf8.decoder).listen(stderr.write);
      process.exitCode.then((code) {
        if (!mounted || _process != process) return;
        if (code != 0 && code != -15 && code != 143) {
          state = state.copyWith(running: false, error: AppException('logcat stopped: $stderr'));
        }
      });
      _flushTimer = Timer.periodic(flushInterval, (_) => _flush());
      _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
    } catch (e) {
      if (mounted) state = state.copyWith(running: false, error: e);
    }
  }

  void _onEnded() {
    if (!mounted) return;
    _flush();
    state = state.copyWith(running: false);
  }

  void _onLine(String line) {
    final entry = _crashes.mark(LogcatEntry.parse(line, _seq++));
    _pending.add(entry);
  }

  void _addMarker(String message, {int? pid}) {
    _pending.add(LogcatEntry(seq: _seq++, raw: message, message: message, pid: pid, isMarker: true));
  }

  void _flush() {
    if (!mounted || _pending.isEmpty) return;
    final batch = List<LogcatEntry>.of(_pending);
    _pending.clear();
    _buffer.addAll(batch);
    var trimmed = false;
    while (_buffer.length > bufferSize) {
      _buffer.removeFirst();
      trimmed = true;
    }
    if (state.paused) {
      final added = batch.where(_matches).length;
      state = state.copyWith(total: _buffer.length, newWhilePaused: state.newWhilePaused + added);
      return;
    }
    if (trimmed) {
      _recompute();
      return;
    }
    final pattern = state.filter.textPattern;
    final pids = _pidFilter;
    final added = batch.where((e) => state.filter.matches(e, pids: pids, pattern: pattern));
    if (added.isEmpty) {
      state = state.copyWith(total: _buffer.length);
    } else {
      state = state.copyWith(visible: [...state.visible, ...added], total: _buffer.length);
    }
  }

  Set<int>? get _pidFilter => state.followedPackage == null ? null : state.followedPids;

  bool _matches(LogcatEntry e) => state.filter.matches(e, pids: _pidFilter);

  void _recompute() {
    final pattern = state.filter.textPattern;
    final pids = _pidFilter;
    state = state.copyWith(
      visible: _buffer.where((e) => state.filter.matches(e, pids: pids, pattern: pattern)).toList(),
      total: _buffer.length,
      newWhilePaused: 0,
    );
  }

  /// Polls pidof / foreground app while following.
  Future<void> _poll() async {
    if (_polling || !mounted) return;
    final filter = state.filter;
    if (filter.package == null && !filter.followForeground) return;
    _polling = true;
    try {
      var package = filter.package;
      if (filter.followForeground) {
        final fg = await service.foregroundPackage(device);
        if (fg != null && fg != state.followedPackage) {
          package = fg;
          _addMarker('Now following $fg (foreground app)');
          state = state.copyWith(followedPackage: fg, followedPids: {});
        } else {
          package = state.followedPackage;
        }
      }
      if (package == null || !mounted) return;
      final pids = await service.pidsOf(device, package);
      if (!mounted) return;
      final fresh = pids.difference(state.followedPids);
      if (fresh.isNotEmpty) {
        if (state.followedPids.isNotEmpty) {
          for (final pid in fresh) {
            _addMarker('Process restarted (pid $pid)', pid: pid);
          }
        }
        state = state.copyWith(
          followedPackage: package,
          followedPids: {...state.followedPids, ...pids},
          waitingForApp: false,
        );
        _flush();
        _recompute();
      } else if (pids.isEmpty && state.followedPids.isEmpty) {
        state = state.copyWith(followedPackage: package, waitingForApp: true);
      }
    } catch (e) {
      LogFile.instance.dispath('logcat poll failed', error: e);
    } finally {
      _polling = false;
    }
  }

  void setFilter(LogcatFilter filter) {
    final packageChanged =
        filter.package != state.filter.package || filter.followForeground != state.filter.followForeground;
    state = state.copyWith(
      filter: filter,
      clearFollowed: packageChanged,
      followedPids: packageChanged ? <int>{} : null,
      waitingForApp: packageChanged ? false : null,
    );
    if (packageChanged && filter.package != null) {
      state = state.copyWith(followedPackage: filter.package, waitingForApp: true);
    }
    _recompute();
    if (packageChanged) _poll();
  }

  void clearFilters() => setFilter(const LogcatFilter());

  void pause() => state = state.copyWith(paused: true, newWhilePaused: 0);

  void resume() {
    state = state.copyWith(paused: false);
    _recompute();
  }

  /// Empties the view, and the device buffer when [device] is true.
  Future<void> clear({bool onDevice = false}) async {
    _buffer.clear();
    _pending.clear();
    state = state.copyWith(visible: const [], total: 0, newWhilePaused: 0);
    if (onDevice) {
      await ref.read(adbControllerProvider).run(
            function: () => service.clearLogcat(device),
            command: 'Clear logcat on ${device.displayName}',
          );
    }
  }

  String visibleText() => state.visible.map((e) => e.raw).join('\n');

  Future<void> _stopProcess() async {
    _flushTimer?.cancel();
    _pollTimer?.cancel();
    await _subscription?.cancel();
    _process?.kill();
    _process = null;
  }

  @override
  void dispose() {
    _stopProcess();
    super.dispose();
  }
}
