import 'dart:convert';
import 'dart:typed_data';

/// Encoders for scrcpy's control protocol (scrcpy 4.0, `app/src/control_msg.c`).
/// All integers are big-endian. See spec/features/screen-mirror.md.
class ScrcpyControl {
  const ScrcpyControl._();

  static const typeInjectKeycode = 0;
  static const typeInjectText = 1;
  static const typeInjectTouch = 2;
  static const typeInjectScroll = 3;
  static const typeBackOrScreenOn = 4;
  static const typeExpandNotifications = 5;
  static const typeCollapsePanels = 7;
  static const typeSetClipboard = 9;
  static const typeSetDisplayPower = 10;
  static const typeRotateDevice = 11;

  /// Android MotionEvent / KeyEvent actions.
  static const actionDown = 0;
  static const actionUp = 1;
  static const actionMove = 2;

  /// scrcpy's "generic finger" pointer id (-2 as uint64): injected as a touch.
  static const pointerFinger = -2;

  /// Android keycodes used by the control bar and keyboard.
  static const keyHome = 3;
  static const keyBack = 4;
  static const keyDpadUp = 19;
  static const keyDpadDown = 20;
  static const keyDpadLeft = 21;
  static const keyDpadRight = 22;
  static const keyVolumeUp = 24;
  static const keyVolumeDown = 25;
  static const keyPower = 26;
  static const keyTab = 61;
  static const keyEnter = 66;
  static const keyDel = 67;
  static const keyForwardDel = 112;
  static const keyAppSwitch = 187;

  static Uint8List keycode({required int action, required int keycode, int repeat = 0, int metaState = 0}) {
    final b = ByteData(14)
      ..setUint8(0, typeInjectKeycode)
      ..setUint8(1, action)
      ..setInt32(2, keycode)
      ..setInt32(6, repeat)
      ..setInt32(10, metaState);
    return b.buffer.asUint8List();
  }

  static Uint8List text(String text) {
    final utf8Bytes = utf8.encode(text);
    final len = utf8Bytes.length.clamp(0, 300);
    final b = ByteData(5 + len)
      ..setUint8(0, typeInjectText)
      ..setUint32(1, len);
    final out = b.buffer.asUint8List();
    out.setRange(5, 5 + len, utf8Bytes);
    return out;
  }

  static void _position(ByteData b, int offset, int x, int y, int width, int height) {
    b
      ..setInt32(offset, x)
      ..setInt32(offset + 4, y)
      ..setUint16(offset + 8, width)
      ..setUint16(offset + 10, height);
  }

  /// Touch at frame pixel ([x], [y]) on a [width]×[height] video frame.
  static Uint8List touch({
    required int action,
    required int x,
    required int y,
    required int width,
    required int height,
    int pointerId = pointerFinger,
    double pressure = 1,
    int actionButton = 0,
    int buttons = 0,
  }) {
    final b = ByteData(32)
      ..setUint8(0, typeInjectTouch)
      ..setUint8(1, action)
      ..setInt64(2, pointerId);
    _position(b, 10, x, y, width, height);
    b
      ..setUint16(22, _u16fp(pressure))
      ..setInt32(24, actionButton)
      ..setInt32(28, buttons);
    return b.buffer.asUint8List();
  }

  /// Scroll; [hscroll]/[vscroll] in [-16, 16] (scrcpy normalises by 16).
  static Uint8List scroll({
    required int x,
    required int y,
    required int width,
    required int height,
    double hscroll = 0,
    double vscroll = 0,
  }) {
    final b = ByteData(21)..setUint8(0, typeInjectScroll);
    _position(b, 1, x, y, width, height);
    b
      ..setInt16(13, _i16fp((hscroll / 16).clamp(-1.0, 1.0)))
      ..setInt16(15, _i16fp((vscroll / 16).clamp(-1.0, 1.0)))
      ..setInt32(17, 0);
    return b.buffer.asUint8List();
  }

  static Uint8List backOrScreenOn(int action) =>
      Uint8List.fromList([typeBackOrScreenOn, action]);

  static Uint8List expandNotifications() => Uint8List.fromList([typeExpandNotifications]);

  static Uint8List collapsePanels() => Uint8List.fromList([typeCollapsePanels]);

  static Uint8List rotate() => Uint8List.fromList([typeRotateDevice]);

  static Uint8List displayPower(bool on) => Uint8List.fromList([typeSetDisplayPower, on ? 1 : 0]);

  /// Sets the device clipboard; with [paste] it is also pasted into the focused field.
  static Uint8List setClipboard(String text, {int sequence = 0, bool paste = true}) {
    final bytes = utf8.encode(text);
    final len = bytes.length.clamp(0, 256 * 1024);
    final b = ByteData(14 + len)
      ..setUint8(0, typeSetClipboard)
      ..setInt64(1, sequence)
      ..setUint8(9, paste ? 1 : 0)
      ..setUint32(10, len);
    final out = b.buffer.asUint8List();
    out.setRange(14, 14 + len, bytes);
    return out;
  }

  /// Float in [0, 1] → u16 fixed point (1.0 → 0xffff), as `sc_float_to_u16fp`.
  static int _u16fp(double f) {
    final v = (f.clamp(0.0, 1.0) * 0x10000).round();
    return v >= 0xffff ? 0xffff : v;
  }

  /// Float in [-1, 1] → i16 fixed point, as `sc_float_to_i16fp`.
  static int _i16fp(double f) {
    var v = (f * 0x8000).round();
    if (v >= 0x7fff) v = 0x7fff;
    if (v < -0x8000) v = -0x8000;
    return v;
  }
}
