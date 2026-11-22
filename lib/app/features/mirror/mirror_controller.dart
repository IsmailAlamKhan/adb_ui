import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

import '../../utils/utils.dart';
import '../features.dart';

enum MirrorMode { live, snapshot }

enum MirrorStatus { starting, running, failed, stopped }

enum MirrorQuality {
  low('Low · 720p', 720, 4000000),
  medium('Medium · 1080p', 1080, 8000000),
  high('High · original', 0, 16000000);

  const MirrorQuality(this.label, this.maxSize, this.bitRate);
  final String label;
  final int maxSize;
  final int bitRate;
}

@immutable
class MirrorState {
  const MirrorState({
    this.mode = MirrorMode.live,
    this.status = MirrorStatus.starting,
    this.width = 0,
    this.height = 0,
    this.snapshot,
    this.error,
    this.quality = MirrorQuality.medium,
    this.maxFps = 60,
    this.recording = false,
    this.fps = 0,
    this.playerGeneration = 0,
  });
  final MirrorMode mode;
  final MirrorStatus status;

  /// Frame size in device pixels (video frame in live mode, PNG in snapshot mode).
  final int width;
  final int height;
  final Uint8List? snapshot;
  final Object? error;
  final MirrorQuality quality;
  final int maxFps;
  final bool recording;

  /// Measured frames per second (snapshot mode) or 0 when unknown.
  final double fps;

  /// Bumped when a new video player is created, so the view mounts its output.
  final int playerGeneration;

  bool get hasFrame => width > 0 && height > 0;

  MirrorState copyWith({
    MirrorMode? mode,
    MirrorStatus? status,
    int? width,
    int? height,
    Uint8List? snapshot,
    Object? error,
    bool clearError = false,
    MirrorQuality? quality,
    int? maxFps,
    bool? recording,
    double? fps,
    int? playerGeneration,
  }) =>
      MirrorState(
        mode: mode ?? this.mode,
        status: status ?? this.status,
        width: width ?? this.width,
        height: height ?? this.height,
        snapshot: snapshot ?? this.snapshot,
        error: clearError ? null : (error ?? this.error),
        quality: quality ?? this.quality,
        maxFps: maxFps ?? this.maxFps,
        recording: recording ?? this.recording,
        fps: fps ?? this.fps,
        playerGeneration: playerGeneration ?? this.playerGeneration,
      );
}

/// The mirror could not start (server, version, decoder).
class MirrorException extends AppException {
  MirrorException(super.message);
}

final mirrorControllerProvider =
    StateNotifierProvider.autoDispose.family<MirrorController, MirrorState, AdbDevice>(MirrorController.new);

/// In-app mirror: scrcpy server + H.264 into media_kit (live), or screencap (snapshot).
class MirrorController extends StateNotifier<MirrorState> {
  MirrorController(this.ref, this.device)
      : service = ref.read(adbServiceProvider),
        super(const MirrorState()) {
    final scrcpy = ref.read(scrcpyAvailableProvider).valueOrNull ?? true;
    start(scrcpy ? MirrorMode.live : MirrorMode.snapshot);
  }

  final Ref ref;
  final AdbDevice device;
  final AdbService service;

  Player? player;
  VideoController? videoController;

  Process? _server;
  Socket? _video;
  Socket? _control;
  ServerSocket? _relay;
  int? _forwardPort;
  String? _scid;
  StreamSubscription<int?>? _widthSub;
  StreamSubscription<int?>? _heightSub;
  bool _snapshotLoop = false;
  Process? _recorder;
  int _session = 0;

  static const _remoteServer = '/data/local/tmp/adbui-scrcpy-server.jar';
  static const _recordPath = '/sdcard/adbui-recording.mp4';

  Future<void> start(MirrorMode mode) async {
    final session = ++_session;
    await _teardown();
    if (!mounted || session != _session) return;
    state = state.copyWith(mode: mode, status: MirrorStatus.starting, clearError: true, width: 0, height: 0);
    try {
      if (mode == MirrorMode.live) {
        await _startLive(session);
      } else {
        _startSnapshots(session);
      }
    } catch (e, s) {
      LogFile.instance.dispath('Mirror failed to start', error: e, stackTrace: s);
      if (mounted && session == _session) {
        await _teardown();
        state = state.copyWith(status: MirrorStatus.failed, error: e);
      }
    }
  }

  // ── Live (scrcpy) ─────────────────────────────────────────────────────────

  Future<(String, String)> _scrcpyServer() async {
    final env = Platform.environment['SCRCPY_SERVER_PATH'];
    final which = await Process.run('/bin/sh', ['-lc', 'command -v scrcpy'], runInShell: false);
    final bin = (which.stdout as String).trim();
    final candidates = [
      if (env != null) env,
      if (bin.isNotEmpty) p.normalize(p.join(p.dirname(File(bin).resolveSymbolicLinksSync()), '..', 'share', 'scrcpy', 'scrcpy-server')),
      '/opt/homebrew/share/scrcpy/scrcpy-server',
      '/usr/local/share/scrcpy/scrcpy-server',
      '/usr/share/scrcpy/scrcpy-server',
      if (bin.isNotEmpty) p.join(p.dirname(bin), 'scrcpy-server'),
    ];
    final server = candidates.firstWhere((c) => File(c).existsSync(), orElse: () => '');
    if (server.isEmpty) {
      throw MirrorException("Couldn't find scrcpy-server next to scrcpy. Set SCRCPY_SERVER_PATH, or use snapshot mode.");
    }
    final version = await Process.run('/bin/sh', ['-lc', 'scrcpy --version']);
    final match = RegExp(r'scrcpy\s+(\S+)').firstMatch(version.stdout as String);
    if (match == null) throw MirrorException("Couldn't read the scrcpy version.");
    return (server, match.group(1)!);
  }

  Future<void> _adb(List<String> args) async {
    final process = await service.startProcess(args, device: device);
    final err = process.stderr.transform(utf8.decoder).join();
    await process.stdout.drain<void>();
    final code = await process.exitCode;
    if (code != 0) throw MirrorException('adb ${args.join(' ')} failed: ${await err}');
  }

  Future<void> _startLive(int session) async {
    final (server, version) = await _scrcpyServer();
    logInfo('[mirror] server $server version $version');
    await _adb(['push', server, _remoteServer]);
    logInfo('[mirror] pushed');
    final scid = _scid = Random().nextInt(0x7fffffff).toRadixString(16).padLeft(8, '0');
    final port = await _freePort();
    _forwardPort = port;
    await _adb(['forward', 'tcp:$port', 'localabstract:scrcpy_$scid']);

    final process = _server = await service.startProcess([
      'shell',
      'CLASSPATH=$_remoteServer',
      'app_process',
      '/',
      'com.genymobile.scrcpy.Server',
      version,
      'scid=$scid',
      'log_level=info',
      'tunnel_forward=true',
      'audio=false',
      'control=true',
      'send_device_meta=false',
      'send_frame_meta=true',
      'send_stream_meta=true',
      'send_dummy_byte=true',
      'stay_awake=true',
      'max_fps=${state.maxFps}',
      'video_bit_rate=${state.quality.bitRate}',
      if (state.quality.maxSize > 0) 'max_size=${state.quality.maxSize}',
    ], device: device);
    final serverLog = StringBuffer();
    process.stdout.transform(utf8.decoder).listen(serverLog.write);
    process.stderr.transform(utf8.decoder).listen(serverLog.write);
    unawaited(process.exitCode.then((code) {
      if (!mounted || session != _session || _server != process) return;
      state = state.copyWith(
        status: MirrorStatus.failed,
        error: MirrorException('The scrcpy server stopped (exit $code).\n$serverLog'.trim()),
      );
    }));

    // Video socket: retry until the server listens (it sends one dummy byte when ready).
    _pending.clear();
    _parser = ScrcpyStreamParser();
    _header = null;
    _headerSent = false;
    _gop.clear();
    _firstPts = null;
    _sessionWidth = 0;
    _sessionHeight = 0;
    Socket? video;
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (video == null) {
      if (session != _session || !mounted) return;
      if (DateTime.now().isAfter(deadline)) {
        throw MirrorException("The scrcpy server didn't answer.\n$serverLog".trim());
      }
      try {
        final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
        final first = Completer<bool>();
        socket.listen(
          (data) {
            if (!first.isCompleted) {
              first.complete(true);
              if (data.length > 1) _onVideo(Uint8List.sublistView(data, 1));
            } else {
              _onVideo(data);
            }
          },
          onDone: () {
            if (!first.isCompleted) first.complete(false);
          },
          onError: (_) {
            if (!first.isCompleted) first.complete(false);
          },
        );
        final ready = await first.future.timeout(const Duration(seconds: 2), onTimeout: () => false);
        if (ready) {
          video = socket;
        } else {
          socket.destroy();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    _video = video;
    logInfo('[mirror] video socket ready, ${_pending.length} chunks buffered');

    // Control socket (server accepts it second). Device messages are read and dropped.
    final control = _control = await Socket.connect(InternetAddress.loopbackIPv4, port);
    control.listen((_) {}, onError: (_) {}, cancelOnError: true);

    // Relay the H.264 stream to a loopback port that libmpv reads.
    final relay = _relay = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    logInfo('[mirror] relay on ${relay.port}');
    relay.listen((client) {
      logInfo('[mirror] player connected to relay');
      client.setOption(SocketOption.tcpNoDelay, true);
      _videoSink = client;
      _headerSent = false;
      _sendHeaderAndGop();
      client.done.catchError((_) {});
    });

    final player = this.player = Player(configuration: const PlayerConfiguration(bufferSize: 2 * 1024 * 1024));
    videoController = VideoController(player);
    state = state.copyWith(playerGeneration: state.playerGeneration + 1);
    final native = player.platform;
    if (native is NativePlayer) {
      // media_kit opens media through a playlist; mpv blocks tcp:// there unless allowed.
      // The URL is our own loopback relay.
      await native.setProperty('load-unsafe-playlists', 'yes');
      await native.setProperty('cache', 'no');
      await native.setProperty('untimed', 'yes');
      await native.setProperty('profile', 'low-latency');
      await native.setProperty('video-sync', 'desync');
      await native.setProperty('hwdec', 'auto-safe');
    }
    player.stream.error.listen((e) => logInfo('[mirror] player error: $e'));
    player.stream.log.listen((l) => logInfo('[mirror] mpv ${l.prefix} ${l.level}: ${l.text}'.trim()));
    await player.open(Media('tcp://127.0.0.1:${relay.port}'), play: true);
    logInfo('[mirror] player opened');
  }

  IOSink? _videoSink;
  final _pending = <Uint8List>[];
  ScrcpyStreamParser _parser = ScrcpyStreamParser();
  Uint8List? _header;
  bool _headerSent = false;
  final _gop = <Uint8List>[];
  int? _firstPts;
  int _sessionWidth = 0;
  int _sessionHeight = 0;

  /// Bytes from the device: parsed into packets and re-muxed as live Matroska for mpv
  /// (media_kit's ffmpeg has no raw H.264 demuxer; mpv reads Matroska natively).
  void _onVideo(Uint8List data) {
    for (final event in _parser.add(data)) {
      switch (event) {
        case ScrcpyCodec(:final id):
          if (id != ScrcpyCodec.h264) {
            _failLive(MirrorException('Unsupported video codec from the device.'));
          }
        case ScrcpySession(:final width, :final height):
          _sessionWidth = width;
          _sessionHeight = height;
        case ScrcpyConfig(:final data):
          final avc = avcConfigFromAnnexB(data);
          if (avc == null || _sessionWidth == 0) continue;
          final hadHeader = _header != null;
          _header = LiveMatroska.header(width: _sessionWidth, height: _sessionHeight, avcC: avc);
          _gop.clear();
          _firstPts = null;
          if (mounted) state = state.copyWith(width: _sessionWidth, height: _sessionHeight);
          // New session (e.g. rotation): reconnect the player so it reads the new header.
          if (hadHeader) {
            _reopenPlayer();
          } else {
            _sendHeaderAndGop();
          }
        case ScrcpyFrame(:final ptsMicros, :final keyFrame, :final data):
          if (_header == null) continue;
          _firstPts ??= ptsMicros;
          final block = LiveMatroska.frame(
            timecodeMs: ((ptsMicros - _firstPts!) ~/ 1000).clamp(0, 1 << 40),
            keyFrame: keyFrame,
            lengthPrefixed: annexBToLengthPrefixed(data),
          );
          if (keyFrame) _gop.clear();
          if (_gop.length < 600) _gop.add(block);
          if (_headerSent) _write(block);
          if (mounted && state.status != MirrorStatus.running) {
            state = state.copyWith(status: MirrorStatus.running);
          }
      }
    }
  }

  void _write(Uint8List bytes) {
    try {
      _videoSink?.add(bytes);
    } catch (_) {}
  }

  /// A newly connected player gets the header and the frames since the last keyframe.
  void _sendHeaderAndGop() {
    if (_videoSink == null || _header == null || _headerSent) return;
    _write(_header!);
    for (final block in _gop) {
      _write(block);
    }
    _headerSent = true;
  }

  Future<void> _reopenPlayer() async {
    final player = this.player;
    final relay = _relay;
    if (player == null || relay == null) return;
    final old = _videoSink;
    _videoSink = null;
    _headerSent = false;
    try {
      await old?.close();
    } catch (_) {}
    await player.open(Media('tcp://127.0.0.1:${relay.port}'), play: true);
  }

  void _failLive(Object error) {
    if (mounted) state = state.copyWith(status: MirrorStatus.failed, error: error);
  }

  Future<int> _freePort() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = s.port;
    await s.close();
    return port;
  }

  void _send(Uint8List bytes) {
    if (state.mode == MirrorMode.live) {
      try {
        _control?.add(bytes);
      } catch (_) {}
    }
  }

  // ── Snapshot (adb only) ──────────────────────────────────────────────────

  void _startSnapshots(int session) {
    _snapshotLoop = true;
    () async {
      var frames = 0;
      var since = DateTime.now();
      while (_snapshotLoop && mounted && session == _session) {
        try {
          final png = await _screencap();
          if (!mounted || session != _session) return;
          final (w, h) = await _pngSize(png);
          frames++;
          final elapsed = DateTime.now().difference(since).inMilliseconds;
          double? fps;
          if (elapsed > 2000) {
            fps = frames * 1000 / elapsed;
            frames = 0;
            since = DateTime.now();
          }
          state = state.copyWith(snapshot: png, width: w, height: h, status: MirrorStatus.running, fps: fps);
        } catch (e) {
          if (mounted && session == _session) state = state.copyWith(status: MirrorStatus.failed, error: e);
          return;
        }
      }
    }();
  }

  Future<Uint8List> _screencap() async {
    final process = await service.startProcess(['exec-out', 'screencap', '-p'], device: device);
    final builder = BytesBuilder(copy: false);
    await process.stdout.forEach(builder.add);
    final code = await process.exitCode;
    final bytes = builder.takeBytes();
    if (code != 0 || bytes.length < 8) throw MirrorException("Couldn't capture the screen.");
    return bytes;
  }

  static Future<(int, int)> _pngSize(Uint8List png) async {
    // Width/height from the PNG IHDR chunk (bytes 16..24).
    final data = ByteData.sublistView(png);
    return (data.getUint32(16), data.getUint32(20));
  }

  Future<void> _shell(List<String> args) => service.startProcess(['shell', ...args], device: device).then((pr) async {
        await pr.stdout.drain<void>();
        await pr.exitCode;
      });

  // ── Input (both modes) ───────────────────────────────────────────────────

  Offset? _down;
  DateTime? _downAt;

  /// Pointer events in frame pixels.
  void pointer(int action, double x, double y) {
    if (!state.hasFrame) return;
    final px = x.round().clamp(0, state.width - 1);
    final py = y.round().clamp(0, state.height - 1);
    if (state.mode == MirrorMode.live) {
      _send(ScrcpyControl.touch(
        action: action,
        x: px,
        y: py,
        width: state.width,
        height: state.height,
        pressure: action == ScrcpyControl.actionUp ? 0 : 1,
      ));
      return;
    }
    // Snapshot mode: tap or swipe on release.
    if (action == ScrcpyControl.actionDown) {
      _down = Offset(px.toDouble(), py.toDouble());
      _downAt = DateTime.now();
    } else if (action == ScrcpyControl.actionUp && _down != null) {
      final start = _down!;
      final ms = DateTime.now().difference(_downAt!).inMilliseconds.clamp(50, 2000);
      _down = null;
      if ((start - Offset(px.toDouble(), py.toDouble())).distance < 12) {
        _shell(['input', 'tap', '$px', '$py']);
      } else {
        _shell(['input', 'swipe', '${start.dx.round()}', '${start.dy.round()}', '$px', '$py', '$ms']);
      }
    }
  }

  void scroll(double x, double y, double dy) {
    if (!state.hasFrame) return;
    if (state.mode == MirrorMode.live) {
      _send(ScrcpyControl.scroll(
        x: x.round(),
        y: y.round(),
        width: state.width,
        height: state.height,
        vscroll: (-dy / 40).clamp(-16.0, 16.0),
      ));
    } else {
      final to = (y - dy * 2).clamp(0, state.height - 1).round();
      _shell(['input', 'swipe', '${x.round()}', '${y.round()}', '${x.round()}', '$to', '150']);
    }
  }

  void key(int keycode) {
    if (state.mode == MirrorMode.live) {
      _send(ScrcpyControl.keycode(action: ScrcpyControl.actionDown, keycode: keycode));
      _send(ScrcpyControl.keycode(action: ScrcpyControl.actionUp, keycode: keycode));
    } else {
      _shell(['input', 'keyevent', '$keycode']);
    }
  }

  void back() {
    if (state.mode == MirrorMode.live) {
      _send(ScrcpyControl.backOrScreenOn(ScrcpyControl.actionDown));
      _send(ScrcpyControl.backOrScreenOn(ScrcpyControl.actionUp));
    } else {
      key(ScrcpyControl.keyBack);
    }
  }

  void typeText(String text) {
    if (text.isEmpty) return;
    if (state.mode == MirrorMode.live) {
      _send(ScrcpyControl.text(text));
    } else {
      _shell(['input', 'text', text.replaceAll(' ', '%s').replaceAll("'", "\\'")]);
    }
  }

  void rotate() => state.mode == MirrorMode.live
      ? _send(ScrcpyControl.rotate())
      : _shell(['settings', 'put', 'system', 'user_rotation', '1']);

  void notifications() =>
      state.mode == MirrorMode.live ? _send(ScrcpyControl.expandNotifications()) : _shell(['cmd', 'statusbar', 'expand-notifications']);

  void pasteText(String text) =>
      state.mode == MirrorMode.live ? _send(ScrcpyControl.setClipboard(text)) : typeText(text);

  Future<String> screenshot(String folder) async {
    final png = await _screencap();
    final file = File(p.join(folder, 'screenshot-${DateTime.now().toIso8601String().replaceAll(':', '-')}.png'));
    await file.writeAsBytes(png);
    return file.path;
  }

  Future<void> startRecording() async {
    if (state.recording) return;
    _recorder = await service.startProcess(['shell', 'screenrecord', _recordPath], device: device);
    state = state.copyWith(recording: true);
  }

  /// Stops recording and pulls the MP4 into [folder]; returns the file path.
  Future<String> stopRecording(String folder) async {
    await _shell(['pkill', '-INT', 'screenrecord']);
    await _recorder?.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => 0);
    _recorder = null;
    state = state.copyWith(recording: false);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final target = p.join(folder, 'recording-${DateTime.now().toIso8601String().replaceAll(':', '-')}.mp4');
    await _adb(['pull', _recordPath, target]);
    await _shell(['rm', _recordPath]);
    return target;
  }

  void setQuality(MirrorQuality quality) {
    state = state.copyWith(quality: quality);
    start(state.mode);
  }

  void setMaxFps(int fps) {
    state = state.copyWith(maxFps: fps);
    start(state.mode);
  }

  Future<void> _teardown() async {
    _snapshotLoop = false;
    await _widthSub?.cancel();
    await _heightSub?.cancel();
    _widthSub = null;
    _heightSub = null;
    final player = this.player;
    this.player = null;
    videoController = null;
    await player?.dispose();
    _videoSink = null;
    _pending.clear();
    await _relay?.close();
    _relay = null;
    _video?.destroy();
    _video = null;
    _control?.destroy();
    _control = null;
    _server?.kill();
    _server = null;
    final port = _forwardPort;
    _forwardPort = null;
    if (port != null) {
      try {
        await _adb(['forward', '--remove', 'tcp:$port']);
      } catch (_) {}
    }
    if (_scid != null) {
      // The adb client is killed above; also stop the server process on the device.
      unawaited(_shell(['pkill', '-f', 'scid=$_scid']).catchError((_) {}));
      _scid = null;
    }
  }

  @override
  void dispose() {
    _session++;
    if (state.recording) unawaited(_shell(['pkill', '-INT', 'screenrecord']).catchError((_) {}));
    unawaited(_teardown());
    super.dispose();
  }
}
