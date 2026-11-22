import 'dart:convert';
import 'dart:typed_data';

/// Events from scrcpy's video socket with `send_stream_meta` and `send_frame_meta` on
/// (scrcpy 4.0 `Streamer.java`): codec id, then session metas and framed packets.
sealed class ScrcpyStreamEvent {}

class ScrcpyCodec extends ScrcpyStreamEvent {
  ScrcpyCodec(this.id);
  final int id;
  static const h264 = 0x68323634; // "h264"
}

/// A new encoding session (start, rotation, resize).
class ScrcpySession extends ScrcpyStreamEvent {
  ScrcpySession(this.width, this.height);
  final int width;
  final int height;
}

/// Codec config (H.264: SPS + PPS in Annex-B).
class ScrcpyConfig extends ScrcpyStreamEvent {
  ScrcpyConfig(this.data);
  final Uint8List data;
}

class ScrcpyFrame extends ScrcpyStreamEvent {
  ScrcpyFrame(this.ptsMicros, this.keyFrame, this.data);
  final int ptsMicros;
  final bool keyFrame;
  final Uint8List data;
}

/// Incremental parser; feed socket chunks with [add].
class ScrcpyStreamParser {
  final _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);
  bool _codecRead = false;

  static const _flagSession = 1 << 63;
  static const _flagConfig = 1 << 62;
  static const _flagKey = 1 << 61;
  static const _ptsMask = (1 << 61) - 1;

  List<ScrcpyStreamEvent> add(Uint8List chunk) {
    _buffer
      ..add(_pending)
      ..add(chunk);
    var data = _buffer.takeBytes();
    final events = <ScrcpyStreamEvent>[];
    var offset = 0;
    final view = ByteData.sublistView(data);
    if (!_codecRead) {
      if (data.length < 4) {
        _pending = data;
        return events;
      }
      events.add(ScrcpyCodec(view.getUint32(0)));
      _codecRead = true;
      offset = 4;
    }
    while (data.length - offset >= 12) {
      final head = view.getUint64(offset);
      if (head & _flagSession != 0) {
        events.add(ScrcpySession(view.getUint32(offset + 4), view.getUint32(offset + 8)));
        offset += 12;
        continue;
      }
      final size = view.getUint32(offset + 8);
      if (data.length - offset - 12 < size) break;
      final payload = Uint8List.sublistView(data, offset + 12, offset + 12 + size);
      if (head & _flagConfig != 0) {
        events.add(ScrcpyConfig(Uint8List.fromList(payload)));
      } else {
        events.add(ScrcpyFrame(head & _ptsMask, head & _flagKey != 0, Uint8List.fromList(payload)));
      }
      offset += 12 + size;
    }
    _pending = Uint8List.fromList(Uint8List.sublistView(data, offset));
    return events;
  }
}

/// Splits Annex-B (00 00 01 / 00 00 00 01 start codes) into NAL units.
List<Uint8List> splitAnnexB(Uint8List data) {
  final nals = <Uint8List>[];
  var start = -1;
  var i = 0;
  while (i + 2 < data.length) {
    if (data[i] == 0 && data[i + 1] == 0 && data[i + 2] == 1) {
      if (start >= 0) {
        var end = i;
        if (end > start && data[end - 1] == 0) end--;
        nals.add(Uint8List.sublistView(data, start, end));
      }
      i += 3;
      start = i;
    } else {
      i++;
    }
  }
  if (start >= 0 && start < data.length) nals.add(Uint8List.sublistView(data, start));
  return nals.where((n) => n.isNotEmpty).toList();
}

/// AVCDecoderConfigurationRecord (avcC) from Annex-B SPS/PPS, or null if they're missing.
Uint8List? avcConfigFromAnnexB(Uint8List config) {
  final nals = splitAnnexB(config);
  final sps = nals.where((n) => n[0] & 0x1f == 7).toList();
  final pps = nals.where((n) => n[0] & 0x1f == 8).toList();
  if (sps.isEmpty || pps.isEmpty || sps.first.length < 4) return null;
  final out = BytesBuilder()
    ..add([1, sps.first[1], sps.first[2], sps.first[3], 0xff, 0xe0 | sps.length]);
  for (final s in sps) {
    out
      ..add([s.length >> 8, s.length & 0xff])
      ..add(s);
  }
  out.add([pps.length]);
  for (final p in pps) {
    out
      ..add([p.length >> 8, p.length & 0xff])
      ..add(p);
  }
  return out.toBytes();
}

/// Annex-B → 4-byte length-prefixed NAL units (what Matroska's V_MPEG4/ISO/AVC expects).
Uint8List annexBToLengthPrefixed(Uint8List data) {
  final out = BytesBuilder(copy: false);
  for (final nal in splitAnnexB(data)) {
    final len = ByteData(4)..setUint32(0, nal.length);
    out
      ..add(len.buffer.asUint8List())
      ..add(nal);
  }
  return out.toBytes();
}

/// Minimal live Matroska writer for one H.264 track (mpv demuxes it natively).
class LiveMatroska {
  const LiveMatroska._();

  static Uint8List _id(int id) {
    final bytes = <int>[];
    var v = id;
    while (v > 0) {
      bytes.insert(0, v & 0xff);
      v >>= 8;
    }
    return Uint8List.fromList(bytes);
  }

  /// 8-byte EBML size (always valid, keeps the writer simple).
  static Uint8List _size(int size) {
    final b = ByteData(8)..setUint64(0, size);
    final out = b.buffer.asUint8List();
    out[0] = 0x01;
    return out;
  }

  static Uint8List _uint(int v) {
    final bytes = <int>[];
    do {
      bytes.insert(0, v & 0xff);
      v >>= 8;
    } while (v > 0);
    return Uint8List.fromList(bytes);
  }

  static Uint8List element(int id, List<int> payload) =>
      (BytesBuilder(copy: false)
            ..add(_id(id))
            ..add(_size(payload.length))
            ..add(payload))
          .toBytes();

  static Uint8List _uintEl(int id, int v) => element(id, _uint(v));
  static Uint8List _strEl(int id, String s) => element(id, utf8.encode(s));
  static Uint8List _cat(List<List<int>> parts) {
    final b = BytesBuilder(copy: false);
    for (final p in parts) {
      b.add(p);
    }
    return b.toBytes();
  }

  /// EBML header + Segment (unknown size) + Info + Tracks.
  static Uint8List header({required int width, required int height, required Uint8List avcC}) {
    final ebml = element(0x1A45DFA3, _cat([
      _uintEl(0x4286, 1),
      _uintEl(0x42F7, 1),
      _uintEl(0x42F2, 4),
      _uintEl(0x42F3, 8),
      _strEl(0x4282, 'matroska'),
      _uintEl(0x4287, 4),
      _uintEl(0x4285, 2),
    ]));
    final info = element(0x1549A966, _cat([
      _uintEl(0x2AD7B1, 1000000),
      _strEl(0x4D80, 'adb_ui'),
      _strEl(0x5741, 'adb_ui'),
    ]));
    final track = element(0xAE, _cat([
      _uintEl(0xD7, 1),
      _uintEl(0x73C5, 1),
      _uintEl(0x83, 1),
      _uintEl(0x9C, 0),
      _strEl(0x86, 'V_MPEG4/ISO/AVC'),
      element(0x63A2, avcC),
      element(0xE0, _cat([_uintEl(0xB0, width), _uintEl(0xBA, height)])),
    ]));
    final tracks = element(0x1654AE6B, track);
    return _cat([
      ebml,
      _id(0x18538067),
      [0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff],
      info,
      tracks,
    ]);
  }

  /// One Cluster holding one SimpleBlock.
  static Uint8List frame({required int timecodeMs, required bool keyFrame, required Uint8List lengthPrefixed}) {
    final block = _cat([
      [0x81, 0x00, 0x00, keyFrame ? 0x80 : 0x00],
      lengthPrefixed,
    ]);
    return element(0x1F43B675, _cat([_uintEl(0xE7, timecodeMs), element(0xA3, block)]));
  }
}
