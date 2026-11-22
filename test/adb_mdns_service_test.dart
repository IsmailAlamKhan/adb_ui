import 'package:adb_ui/app/features/adb/adb_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdbMdnsService.parseList', () {
    test('parses connect and pairing services, skipping the header', () {
      const output = 'List of discovered mdns services\n'
          'adb-56261FDCH009VK-IiAuI4\t_adb-tls-connect._tcp\t192.168.68.111:40675\n'
          'adbui-AbC123xYz9\t_adb-tls-pairing._tcp\t192.168.68.111:37099\n';

      final services = AdbMdnsService.parseList(output);

      expect(services, const [
        AdbMdnsService(
          name: 'adb-56261FDCH009VK-IiAuI4',
          type: AdbMdnsService.connectType,
          host: '192.168.68.111',
          port: 40675,
        ),
        AdbMdnsService(
          name: 'adbui-AbC123xYz9',
          type: AdbMdnsService.pairingType,
          host: '192.168.68.111',
          port: 37099,
        ),
      ]);
      expect(services.first.isConnect, isTrue);
      expect(services.last.isPairing, isTrue);
      expect(services.last.address, '192.168.68.111:37099');
    });

    test('strips the trailing dot older adb versions print on the type', () {
      final services = AdbMdnsService.parseList(
        'studio-x\t_adb-tls-pairing._tcp.\t10.0.0.5:5555\n',
      );
      expect(services.single.type, AdbMdnsService.pairingType);
      expect(services.single.isPairing, isTrue);
    });

    test('accepts space-separated columns and CRLF line endings', () {
      final services = AdbMdnsService.parseList(
        'List of discovered mdns services\r\nname   _adb-tls-connect._tcp   10.0.0.5:41000\r\n',
      );
      expect(services.single.port, 41000);
      expect(services.single.host, '10.0.0.5');
    });

    test('skips empty and malformed lines', () {
      final services = AdbMdnsService.parseList(
        '\n'
        'only-two-columns _adb-tls-connect._tcp\n'
        'bad-port _adb-tls-connect._tcp 10.0.0.5:abc\n'
        'no-port _adb-tls-connect._tcp 10.0.0.5\n',
      );
      expect(services, isEmpty);
    });

    test('returns empty list for empty output', () {
      expect(AdbMdnsService.parseList(''), isEmpty);
      expect(AdbMdnsService.parseList('List of discovered mdns services\n'), isEmpty);
    });
  });
}
