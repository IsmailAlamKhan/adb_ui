import 'package:freezed_annotation/freezed_annotation.dart';

part 'adb_model.freezed.dart';
part 'adb_model.g.dart';

@freezed
abstract class AdbDevice with _$AdbDevice {
  const AdbDevice._();
  const factory AdbDevice({
    required String id,
    required String type,
    required String model,
  }) = _AdbDevice;

  bool get isOffline => type.trim().toLowerCase() == 'offline';

  /// Connection state from the `adb devices` state column.
  AdbDeviceState get state => AdbDeviceState.parse(type);

  bool get isOnline => state == AdbDeviceState.online;

  /// Connected over Wi-Fi (`ip:port` or an mDNS `_adb-tls-connect` id).
  bool get isWireless => id.contains(':') || id.contains('._adb-tls-connect.');

  /// Model, or the id when the model isn't known (e.g. unauthorized devices).
  String get displayName => model.trim().isNotEmpty ? model.trim() : id;

  factory AdbDevice.fromJson(Map<String, dynamic> json) => _$AdbDeviceFromJson(json);
}

/// State column of `adb devices`.
enum AdbDeviceState {
  online,
  offline,
  unauthorized,
  other;

  static AdbDeviceState parse(String value) => switch (value.trim().toLowerCase()) {
        'device' => AdbDeviceState.online,
        'offline' => AdbDeviceState.offline,
        'unauthorized' => AdbDeviceState.unauthorized,
        _ => AdbDeviceState.other,
      };

  String get label => switch (this) {
        AdbDeviceState.online => 'Online',
        AdbDeviceState.offline => 'Offline',
        AdbDeviceState.unauthorized => 'Unauthorized',
        AdbDeviceState.other => 'Unavailable',
      };
}

/// One entry of `adb mdns services`: `<instance>\t<type>\t<ip>:<port>`.
///
/// Plain class (not freezed) because codegen can't run on the current toolchain;
/// see spec/06-known-issues.md.
@immutable
class AdbMdnsService {
  const AdbMdnsService({
    required this.name,
    required this.type,
    required this.host,
    required this.port,
  });

  /// mDNS instance name, e.g. `adb-SERIAL-xxxxxx` or the QR service name.
  final String name;

  /// Service type without trailing dot, e.g. `_adb-tls-connect._tcp`.
  final String type;
  final String host;
  final int port;

  @override
  bool operator ==(Object other) =>
      other is AdbMdnsService &&
      other.name == name &&
      other.type == type &&
      other.host == host &&
      other.port == port;

  @override
  int get hashCode => Object.hash(name, type, host, port);

  @override
  String toString() => 'AdbMdnsService($name, $type, $host:$port)';

  static const pairingType = '_adb-tls-pairing._tcp';
  static const connectType = '_adb-tls-connect._tcp';

  bool get isPairing => type == pairingType;
  bool get isConnect => type == connectType;

  String get address => '$host:$port';

  /// Parses the stdout of `adb mdns services`. Malformed lines are skipped.
  static List<AdbMdnsService> parseList(String output) {
    final services = <AdbMdnsService>[];
    for (final rawLine in output.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.toLowerCase().startsWith('list of discovered')) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) continue;
      var type = parts[1];
      if (type.endsWith('.')) type = type.substring(0, type.length - 1);
      final address = parts.last;
      final separator = address.lastIndexOf(':');
      if (separator <= 0) continue;
      final port = int.tryParse(address.substring(separator + 1));
      if (port == null) continue;
      services.add(AdbMdnsService(
        name: parts.first,
        type: type,
        host: address.substring(0, separator),
        port: port,
      ));
    }
    return services;
  }
}

mixin AdbFileSystem {
  abstract final String name;
}

@freezed
abstract class AdbFile with _$AdbFile, AdbFileSystem {
  const AdbFile._();
  const factory AdbFile(String name) = _AdbFile;
}

@freezed
abstract class AdbDirectory with _$AdbDirectory, AdbFileSystem {
  const AdbDirectory._();
  const factory AdbDirectory(String name) = _AdbDirectory;
}

/// Values from `adb shell getprop`, parsed from `[key]: [value]` lines.
@immutable
class DeviceProperties {
  const DeviceProperties(this.raw);
  final Map<String, String> raw;

  String? get model => raw['ro.product.model'];
  String? get manufacturer => raw['ro.product.manufacturer'];
  String? get androidVersion => raw['ro.build.version.release'];
  String? get sdk => raw['ro.build.version.sdk'];
  String? get abi => raw['ro.product.cpu.abi'];
  String? get device => raw['ro.product.device'];

  static final _line = RegExp(r'^\[(.+?)\]:\s*\[(.*)\]\s*$');

  static DeviceProperties parse(String output) {
    final map = <String, String>{};
    for (final line in output.split('\n')) {
      final match = _line.firstMatch(line.trim());
      if (match != null) map[match.group(1)!] = match.group(2)!;
    }
    return DeviceProperties(map);
  }
}

/// Package names from `pm list packages` output (`package:<name>` lines), sorted.
List<String> parsePackageList(String output) {
  final packages = <String>{};
  for (final line in output.split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('package:')) continue;
    final name = trimmed.substring('package:'.length).trim();
    if (name.isNotEmpty) packages.add(name);
  }
  return packages.toList()..sort();
}

/// A parsed `host:port`. IPv6 hosts may be written in brackets: `[fe80::1]:5555`.
typedef HostPort = ({String host, int port});

/// Parses `host:port`; returns null when it isn't valid.
HostPort? parseHostPort(String input) {
  final value = input.trim();
  final separator = value.lastIndexOf(':');
  if (separator <= 0 || separator == value.length - 1) return null;
  var host = value.substring(0, separator).trim();
  if (host.startsWith('[') && host.endsWith(']')) host = host.substring(1, host.length - 1);
  final port = int.tryParse(value.substring(separator + 1));
  if (host.isEmpty || host.contains(' ') || port == null || port < 1 || port > 65535) return null;
  return (host: host, port: port);
}

/// Error message for a `host:port` field, or null when valid.
String? validateHostPort(String? input) {
  final value = input?.trim() ?? '';
  if (value.isEmpty) return 'Enter the IP address and port, e.g. 192.168.1.20:37099';
  if (!value.contains(':')) {
    return 'Add the port after a colon, e.g. $value:37099 (use :5555 for Android 10 or older)';
  }
  if (parseHostPort(value) == null) {
    return "That isn't a valid address. Use IP:PORT with a port from 1 to 65535";
  }
  return null;
}

/// Error message for a Wireless debugging pairing code, or null when valid.
String? validatePairingCode(String? input) {
  final value = input?.replaceAll(' ', '') ?? '';
  if (value.isEmpty) return 'Enter the 6-digit code shown on your phone';
  if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'The pairing code is 6 digits';
  return null;
}
