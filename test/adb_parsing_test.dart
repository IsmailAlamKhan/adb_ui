import 'package:adb_ui/app/design/app_style.dart';
import 'package:adb_ui/app/design/window_size.dart';
import 'package:adb_ui/app/features/adb/adb_model.dart';
import 'package:adb_ui/app/features/settings/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHostPort / validateHostPort', () {
    test('valid addresses', () {
      expect(parseHostPort('192.168.1.20:37099'), (host: '192.168.1.20', port: 37099));
      expect(parseHostPort(' 10.0.0.2:5555 '), (host: '10.0.0.2', port: 5555));
      expect(parseHostPort('[fe80::1]:5555'), (host: 'fe80::1', port: 5555));
      expect(validateHostPort('192.168.1.20:37099'), isNull);
    });

    test('invalid addresses give a message instead of crashing (06 #10)', () {
      expect(parseHostPort('192.168.1.20'), isNull);
      expect(parseHostPort('192.168.1.20:'), isNull);
      expect(parseHostPort('192.168.1.20:abc'), isNull);
      expect(parseHostPort('192.168.1.20:70000'), isNull);
      expect(validateHostPort(''), contains('Enter'));
      expect(validateHostPort('192.168.1.20'), contains('port'));
      expect(validateHostPort('host:port'), isNotNull);
    });

    test('pairing code', () {
      expect(validatePairingCode('123456'), isNull);
      expect(validatePairingCode('123 456'), isNull);
      expect(validatePairingCode('12345'), isNotNull);
      expect(validatePairingCode(''), isNotNull);
    });
  });

  test('DeviceProperties.parse', () {
    final props = DeviceProperties.parse('''
[ro.build.version.release]: [16]
[ro.build.version.sdk]: [36]
[ro.product.cpu.abi]: [arm64-v8a]
[ro.product.manufacturer]: [Google]
[ro.product.model]: [Pixel 10 Pro]
garbage line
''');
    expect(props.androidVersion, '16');
    expect(props.sdk, '36');
    expect(props.abi, 'arm64-v8a');
    expect(props.manufacturer, 'Google');
    expect(props.model, 'Pixel 10 Pro');
  });

  test('parsePackageList strips prefix, dedupes and sorts', () {
    expect(
      parsePackageList('package:com.b.app\npackage:com.a.app\n\npackage:com.b.app\nnoise'),
      ['com.a.app', 'com.b.app'],
    );
  });

  test('AdbDevice state and wireless detection', () {
    const usb = AdbDevice(id: '56261FDCH009VK', type: 'device', model: 'Pixel 10 Pro');
    const wifi = AdbDevice(id: 'adb-56261FDCH009VK-IiAuI4._adb-tls-connect._tcp', type: 'device', model: '');
    const unauthorized = AdbDevice(id: 'R5CT', type: 'unauthorized', model: '');
    expect(usb.isOnline, isTrue);
    expect(usb.isWireless, isFalse);
    expect(wifi.isWireless, isTrue);
    expect(wifi.displayName, wifi.id);
    expect(unauthorized.state, AdbDeviceState.unauthorized);
    expect(const AdbDevice(id: '1.2.3.4:5555', type: 'offline', model: 'X').state, AdbDeviceState.offline);
  });

  group('SettingsModel.style', () {
    test('old settings without style read as null (shows the picker)', () {
      final model = SettingsModel.fromJson({'themeMode': ThemeMode.dark.index});
      expect(model.style, isNull);
      expect(model.themeMode, ThemeMode.dark);
    });

    test('round-trips the style by name; unknown names read as null', () {
      const model = SettingsModel(themeMode: ThemeMode.system, style: AppStyle.console);
      final json = model.toJson();
      expect(json['style'], 'console');
      expect(SettingsModel.fromJson(json).style, AppStyle.console);
      expect(SettingsModel.fromJson({'themeMode': 0, 'style': 'retro'}).style, isNull);
    });
  });

  test('WindowSize classes', () {
    expect(WindowSize.fromWidth(480), WindowSize.compact);
    expect(WindowSize.fromWidth(719), WindowSize.compact);
    expect(WindowSize.fromWidth(720), WindowSize.medium);
    expect(WindowSize.fromWidth(1199), WindowSize.medium);
    expect(WindowSize.fromWidth(1200), WindowSize.expanded);
  });
}
