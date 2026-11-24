import 'dart:math';

import 'package:adb_ui/app/features/qr_pair/qr_pair_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrPairCode', () {
    test('qrData uses the Android Studio WIFI:T:ADB payload format', () {
      const code = QrPairCode(serviceName: 'adbui-abc', password: 'secret123');
      expect(code.qrData, 'WIFI:T:ADB;S:adbui-abc;P:secret123;;');
    });

    test('generate() makes a prefixed alphanumeric name and 12-char password', () {
      final code = QrPairCode.generate(Random(42));
      expect(code.serviceName, startsWith(QrPairCode.servicePrefix));
      expect(code.serviceName.length, QrPairCode.servicePrefix.length + 10);
      expect(code.password.length, 12);
      final alnum = RegExp(r'^[A-Za-z0-9]+$');
      expect(alnum.hasMatch(code.serviceName.substring(QrPairCode.servicePrefix.length)), isTrue);
      expect(alnum.hasMatch(code.password), isTrue);
    });

    test('generate() returns a different code each time', () {
      expect(QrPairCode.generate(), isNot(QrPairCode.generate()));
    });
  });

  group('QrPairState', () {
    test('copyWith keeps the code and unspecified fields', () {
      const code = QrPairCode(serviceName: 'adbui-a', password: 'p');
      const state = QrPairState(code: code, host: '10.0.0.5');
      final next = state.copyWith(status: QrPairStatus.connecting);
      expect(next.code, code);
      expect(next.host, '10.0.0.5');
      expect(next.status, QrPairStatus.connecting);
      expect(next.status.isWorking, isTrue);
      expect(QrPairStatus.failed.isWorking, isFalse);
    });

    test('restart hint flags default off and survive copyWith', () {
      const state = QrPairState(code: QrPairCode(serviceName: 'adbui-a', password: 'p'));
      expect(state.adbMaybeStuck, isFalse);
      expect(state.restartingAdb, isFalse);
      final stuck = state.copyWith(adbMaybeStuck: true);
      expect(stuck.copyWith(status: QrPairStatus.connecting).adbMaybeStuck, isTrue);
      expect(stuck == state, isFalse);
    });

    test('stuck thresholds: 15 s waiting for the scan, 10 s connecting, none otherwise', () {
      expect(QrPairState.stuckAfter(QrPairStatus.waitingForScan), const Duration(seconds: 15));
      expect(QrPairState.stuckAfter(QrPairStatus.connecting), const Duration(seconds: 10));
      for (final s in [
        QrPairStatus.pairing,
        QrPairStatus.connected,
        QrPairStatus.pairedNotConnected,
        QrPairStatus.failed,
      ]) {
        expect(QrPairState.stuckAfter(s), isNull);
      }
    });
  });
}
