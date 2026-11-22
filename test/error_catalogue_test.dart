import 'dart:io';

import 'package:adb_ui/app/features/adb/adb_service.dart';
import 'package:adb_ui/app/features/errors/errors.dart';
import 'package:adb_ui/app/utils/exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ErrorKind kindOf(Object? error, [String? output]) => ErrorCatalogue.explain(error, output: output).kind;

  group('ErrorCatalogue', () {
    test('adb missing', () {
      expect(kindOf(AdbNotFoundException()), ErrorKind.adbMissing);
      expect(kindOf(const ProcessException('adb', ['version'], 'No such file or directory', 2)),
          ErrorKind.adbMissing);
    });

    test('unauthorized and offline devices', () {
      expect(kindOf(AppException('error: device unauthorized.\nThis adb server\'s \$ADB_VENDOR_KEYS is not set')),
          ErrorKind.unauthorized);
      expect(kindOf(null, 'error: device offline'), ErrorKind.offline);
    });

    test('device gone', () {
      expect(kindOf(AppException("adb: device 'R5CT1234' not found")), ErrorKind.noDevice);
      expect(kindOf(null, 'adb: no devices/emulators found'), ErrorKind.noDevice);
    });

    test('connection failures', () {
      expect(
        kindOf(AppException('Failed to connect cause failed to connect to 192.168.1.20:5555: Connection refused')),
        ErrorKind.connection,
      );
      expect(kindOf(null, 'cannot connect to 10.0.0.2:37099: Operation timed out (60)'), ErrorKind.connection);
    });

    test('pairing failures', () {
      expect(kindOf(AppException('Failed to pair cause Failed: Wrong password or connection was dropped.')),
          ErrorKind.pairing);
    });

    test('install failures map to specific kinds', () {
      AppException install(String code) =>
          AppException('Failed to install app.apk\nPerforming Streamed Install\nadb: failed to install app.apk: Failure [$code: details]');
      expect(kindOf(install('INSTALL_FAILED_VERSION_DOWNGRADE')), ErrorKind.installDowngrade);
      expect(kindOf(install('INSTALL_FAILED_UPDATE_INCOMPATIBLE')), ErrorKind.installSignature);
      expect(kindOf(install('INSTALL_FAILED_INSUFFICIENT_STORAGE')), ErrorKind.installStorage);
      expect(kindOf(install('INSTALL_FAILED_NO_MATCHING_ABIS')), ErrorKind.installAbi);
      expect(kindOf(install('INSTALL_PARSE_FAILED_NOT_APK')), ErrorKind.installInvalid);
      expect(kindOf(install('INSTALL_FAILED_USER_RESTRICTED')), ErrorKind.installOther);
    });

    test('file errors', () {
      expect(kindOf(NotFoundException('/sdcard/missing.jpg')), ErrorKind.notFound);
      expect(kindOf(null, "adb: error: remote object '/sdcard/x' does not exist: No such file or directory"),
          ErrorKind.notFound);
      expect(kindOf(PermissionDeniedException()), ErrorKind.permission);
    });

    test('uninstall, scrcpy, mdns, input, command failures', () {
      expect(kindOf(AppException('Failed to uninstall cause Failure [DELETE_FAILED_INTERNAL_ERROR]')),
          ErrorKind.uninstall);
      expect(kindOf(ScrcpyNotFoundException()), ErrorKind.scrcpyMissing);
      expect(kindOf(AdbMdnsUnavailableException('unknown command')), ErrorKind.mdns);
      final input = ErrorCatalogue.explain(InvalidInputException('Add the port'));
      expect(input.kind, ErrorKind.invalidInput);
      expect(input.title, 'Add the port');
      expect(kindOf(CommandFailedException(1, '/system/bin/sh: foo: inaccessible or not found')),
          ErrorKind.commandFailed);
    });

    test('unknown keeps the raw text as details and never throws', () {
      final error = ErrorCatalogue.explain(AppException('something odd'), output: 'raw output');
      expect(error.kind, ErrorKind.unknown);
      expect(error.details, contains('something odd'));
      expect(error.details, contains('raw output'));
      expect(ErrorCatalogue.explain(null).kind, ErrorKind.unknown);
      expect(ErrorCatalogue.explain(StateError('x')).kind, ErrorKind.unknown);
    });

    test('every kind has a title and message', () {
      final error = ErrorCatalogue.explain(AdbNotFoundException());
      expect(error.title, isNotEmpty);
      expect(error.message, isNotEmpty);
      expect(error.steps, isNotEmpty);
    });
  });

  test('AppException keeps its code', () {
    expect(AppException('x', 'E42').code, 'E42');
  });
}
