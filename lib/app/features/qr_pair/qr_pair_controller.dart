import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

final qrPairControllerProvider =
    StateNotifierProvider.autoDispose<QrPairController, QrPairState>(QrPairController.new);

/// Drives the QR pairing flow: wait for the phone's mDNS pairing service, `adb pair`,
/// then wait for (or trigger) the connection. See spec/features/qr-pairing.md.
class QrPairController extends StateNotifier<QrPairState> {
  QrPairController(Ref ref)
      : service = ref.read(adbServiceProvider),
        adbController = ref.read(adbControllerProvider),
        super(QrPairState(code: QrPairCode.generate())) {
    _start();
  }

  final AdbService service;
  final AdbController adbController;

  static const scanTimeout = Duration(minutes: 2);
  static const connectTimeout = Duration(seconds: 30);

  /// How long to let adb's own mDNS auto-connect happen before running `adb connect`
  /// ourselves (otherwise the device can end up connected twice).
  static const autoConnectGrace = Duration(seconds: 5);
  static const pollInterval = Duration(seconds: 1);

  /// Bumped on every restart so loops from an older code stop.
  int _session = 0;

  bool _isActive(int session) => mounted && session == _session;

  /// While a Restart adb runs, polling waits (adb's errors meanwhile aren't failures).
  bool _restarting = false;

  /// When the current wait counts as possibly stuck (see [QrPairState.stuckAfter]).
  DateTime? _stuckAt;

  /// Guid from `adb pair`, kept so a restart from "paired, not connected" can retry.
  String? _guid;

  void _startStuckClock(QrPairStatus status) {
    final after = QrPairState.stuckAfter(status);
    _stuckAt = after == null ? null : DateTime.now().add(after);
  }

  void _checkStuck() {
    final at = _stuckAt;
    if (at != null && !state.adbMaybeStuck && DateTime.now().isAfter(at)) {
      state = state.copyWith(adbMaybeStuck: true);
    }
  }

  /// Restarts adb from the pairing flow and carries on with the same code.
  Future<void> restartAdb() async {
    if (state.restartingAdb) return;
    final session = _session;
    _restarting = true;
    state = state.copyWith(restartingAdb: true);
    try {
      await adbController.restartAdb();
    } finally {
      _restarting = false;
      if (_isActive(session)) {
        state = state.copyWith(restartingAdb: false, adbMaybeStuck: false);
        _startStuckClock(state.status);
        if (state.status == QrPairStatus.pairedNotConnected && state.host != null) {
          _connect(session, state.host!, _guid).catchError((Object e) => _fail(session, e));
        }
      }
    }
  }

  /// Generates a new code and starts over.
  void restart() {
    state = QrPairState(code: QrPairCode.generate());
    _start();
  }

  Future<void> _start() async {
    final session = ++_session;
    final code = state.code;
    final deadline = DateTime.now().add(scanTimeout);
    state = state.copyWith(expiresAt: deadline);
    _startStuckClock(QrPairStatus.waitingForScan);
    try {
      while (_isActive(session)) {
        if (_restarting) {
          await Future.delayed(pollInterval);
          continue;
        }
        _checkStuck();
        if (DateTime.now().isAfter(deadline)) {
          _fail(
            session,
            const AppError(
              kind: ErrorKind.pairing,
              title: 'The code expired',
              message: 'Nothing scanned it within 2 minutes.',
              steps: [
                'On the phone open Developer options → Wireless debugging → Pair device with QR code.',
                'Click New code and scan it.',
              ],
            ),
          );
          return;
        }
        final services = await service.mdnsServices();
        if (!_isActive(session)) return;
        final pairing = services.firstWhereOrNull(
          (s) => s.isPairing && s.name == code.serviceName,
        );
        if (pairing != null) {
          await _pair(session, code, pairing);
          return;
        }
        await Future.delayed(pollInterval);
      }
    } catch (e, s) {
      if (e is! AppException) LogFile.instance.dispath('QR pairing failed', error: e, stackTrace: s);
      _fail(session, e);
    }
  }

  Future<void> _pair(int session, QrPairCode code, AdbMdnsService pairing) async {
    state = state.copyWith(status: QrPairStatus.pairing, host: pairing.host);
    final output = await adbController.runForResult(
      function: () => service.pair(code.password, pairing.host, pairing.port),
      command: 'QR pair with ${pairing.address}',
      showOutput: false,
    );
    if (!_isActive(session)) return;
    if (output == null) {
      _fail(session, AppException('Failed to pair'));
      return;
    }
    final guid = _guid = RegExp(r'guid=([^\]\s]+)').firstMatch(output)?.group(1);
    await _connect(session, pairing.host, guid);
  }

  Future<void> _connect(int session, String host, String? guid) async {
    state = state.copyWith(status: QrPairStatus.connecting);
    _startStuckClock(QrPairStatus.connecting);
    final startedAt = DateTime.now();
    final deadline = startedAt.add(connectTimeout);
    final manualConnectAfter = startedAt.add(autoConnectGrace);
    var triedConnect = false;
    while (_isActive(session)) {
      if (_restarting) {
        await Future.delayed(pollInterval);
        continue;
      }
      _checkStuck();
      if (DateTime.now().isAfter(deadline)) {
        _stuckAt = null;
        state = state.copyWith(status: QrPairStatus.pairedNotConnected, adbMaybeStuck: true);
        return;
      }

      // adb usually auto-connects to freshly paired devices.
      final devices = await service.getConnectedDevices();
      if (!_isActive(session)) return;
      final connected = devices.firstWhereOrNull(
        (d) => !d.isOffline && ((guid != null && d.id.contains(guid)) || d.id.startsWith('$host:')),
      );
      if (connected != null) {
        state = state.copyWith(status: QrPairStatus.connected, deviceId: connected.id);
        return;
      }

      if (!triedConnect && DateTime.now().isAfter(manualConnectAfter)) {
        final services = await service.mdnsServices();
        if (!_isActive(session)) return;
        final connectService = services.firstWhereOrNull(
          (s) => s.isConnect && (guid != null ? s.name == guid : s.host == host),
        );
        if (connectService != null) {
          triedConnect = true;
          final result = await adbController.runForResult(
            function: () => service.connect(connectService.host, connectService.port),
            command: 'Connect to ${connectService.address}',
            showOutput: false,
          );
          if (!_isActive(session)) return;
          if (result != null) {
            state = state.copyWith(
              status: QrPairStatus.connected,
              deviceId: connectService.address,
            );
            return;
          }
        }
      }
      await Future.delayed(pollInterval);
    }
  }

  void _fail(int session, Object error) {
    if (!_isActive(session)) return;
    final explained = error is AppError ? error : ErrorCatalogue.explain(error);
    state = state.copyWith(status: QrPairStatus.failed, message: explained.title, error: explained);
  }

  @override
  void dispose() {
    _session++;
    super.dispose();
  }
}
