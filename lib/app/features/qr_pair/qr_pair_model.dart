import 'dart:math';

import 'package:flutter/foundation.dart';

import '../errors/errors_model.dart';

/// The service name + password shown in the QR code (same scheme Android Studio uses).
@immutable
class QrPairCode {
  const QrPairCode({required this.serviceName, required this.password});

  factory QrPairCode.generate([Random? random]) {
    final rng = random ?? Random.secure();
    return QrPairCode(
      serviceName: '$servicePrefix${_randomString(rng, 10)}',
      password: _randomString(rng, 12),
    );
  }

  static const servicePrefix = 'adbui-';
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// mDNS instance name the phone will advertise after scanning.
  final String serviceName;

  /// Password passed to `adb pair`.
  final String password;

  /// Payload understood by Android's "Pair device with QR code" scanner.
  String get qrData => 'WIFI:T:ADB;S:$serviceName;P:$password;;';

  static String _randomString(Random rng, int length) =>
      List.generate(length, (_) => _alphabet[rng.nextInt(_alphabet.length)]).join();

  @override
  bool operator ==(Object other) =>
      other is QrPairCode && other.serviceName == serviceName && other.password == password;

  @override
  int get hashCode => Object.hash(serviceName, password);
}

enum QrPairStatus {
  waitingForScan,
  pairing,
  connecting,
  connected,
  pairedNotConnected,
  failed;

  bool get isWorking =>
      this == QrPairStatus.waitingForScan ||
      this == QrPairStatus.pairing ||
      this == QrPairStatus.connecting;
}

/// Plain class (not freezed) because codegen can't run on the current toolchain;
/// see spec/06-known-issues.md.
@immutable
class QrPairState {
  const QrPairState({
    required this.code,
    this.status = QrPairStatus.waitingForScan,
    this.host,
    this.deviceId,
    this.message,
    this.error,
    this.expiresAt,
  });

  final QrPairCode code;
  final QrPairStatus status;

  /// IP of the phone, once it has been discovered.
  final String? host;

  /// adb device id (serial) once connected.
  final String? deviceId;

  /// Error message for [QrPairStatus.failed].
  final String? message;

  /// Explained error for [QrPairStatus.failed].
  final AppError? error;

  /// When the code stops being looked for.
  final DateTime? expiresAt;

  QrPairState copyWith({
    QrPairStatus? status,
    String? host,
    String? deviceId,
    String? message,
    AppError? error,
    DateTime? expiresAt,
  }) =>
      QrPairState(
        code: code,
        status: status ?? this.status,
        host: host ?? this.host,
        deviceId: deviceId ?? this.deviceId,
        message: message ?? this.message,
        error: error ?? this.error,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  bool operator ==(Object other) =>
      other is QrPairState &&
      other.code == code &&
      other.status == status &&
      other.host == host &&
      other.deviceId == deviceId &&
      other.message == message &&
      other.error == error &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(code, status, host, deviceId, message, error, expiresAt);
}
