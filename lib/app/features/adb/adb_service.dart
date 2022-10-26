import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import 'adb_model.dart';

final adbServiceProvider = Provider<AdbService>(ProccessAdbServiceImpl.new);

class Result {
  final Stream<String> stoutStream;
  final Stream<String> sterrStream;
  final Future<int> exitCode;
  final Future<String> stdout;
  final Future<String> stderr;
  final Future<String> messege;
  Result({
    required this.stoutStream,
    required this.sterrStream,
    required this.stderr,
    required this.exitCode,
    required this.stdout,
    required this.messege,
  });

  Result copyWith({
    Stream<String>? stoutStream,
    Stream<String>? sterrStream,
    Future<int>? exitCode,
    Future<String>? stdout,
    Future<String>? stderr,
    Future<String>? messege,
  }) {
    return Result(
      stoutStream: stoutStream ?? this.stoutStream,
      sterrStream: sterrStream ?? this.sterrStream,
      exitCode: exitCode ?? this.exitCode,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      messege: messege ?? this.messege,
    );
  }
}

abstract class AdbService {
  Future<List<AdbDevice>> getConnectedDevices();

  Stream<List<AdbDevice>> get connectedDevicesStream;
  Stream<String> get terminalOutputs;

  /// commands
  Future<Result> connect(String host, int port);
  Future<Result> disconnect(String id);
  Future<Result> installApk(String id, String path);

  Future<List<AdbFileSystem>> ls(AdbDevice device, String? path);

  Future<Result> pushFile(String id, String file, String destinationPath);
}

class ProccessAdbServiceImpl implements AdbService {
  final Ref ref;
  ProccessAdbServiceImpl(this.ref);

  final terminalOutputsController = StreamController<String>();

  Future<Result> run(List<String> arguments, [bool addStdout = true]) async {
    // logWarning(arguments);
    final process = await io.Process.start('adb', arguments);
    final stdout = process.stdout.asBroadcastStream();
    final stderr = process.stderr.asBroadcastStream();
    if (addStdout) {
      io.stdout.addStream(stdout);
      io.stderr.addStream(stderr);
    }
    final _stdout = stdout.transform(utf8.decoder);
    final _stderr = stderr.transform(utf8.decoder);

    final result = Result(
      exitCode: process.exitCode,
      stoutStream: _stdout,
      sterrStream: _stderr,
      stdout: _stdout.join(),
      stderr: _stderr.join(),
      messege: Future.value(''),
    );
    return result;
  }

  @override
  Future<List<AdbDevice>> getConnectedDevices() async {
    final process = await run(['devices'], false);
    final devices = <AdbDevice>[];
    final output = (await process.stdout).split('\n').toList()
      ..removeWhere((element) =>
          element.trim().toLowerCase().contains('devices attached') || element.trim().isEmpty);

    for (var element in output) {
      final parts = element.split('	');
      if (parts.isEmpty) {
        break;
      }
      devices.add(AdbDevice(type: parts.last, id: parts.first));
    }
    return devices;
  }

  @override
  Stream<List<AdbDevice>> get connectedDevicesStream {
    final future = getConnectedDevices;
    // return Stream.fromFuture(future());
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) => future());
  }

  @override
  Stream<String> get terminalOutputs => terminalOutputsController.stream;
  @override
  Future<Result> connect(String host, int port) =>
      run(['connect', '$host:$port']).then((result) async {
        return result.copyWith(
          messege: result.stdout.then((output) {
            if (output.contains('connected to')) {
              return 'Connected to $host:$port';
            }
            logError('Failed to connect to $host:$port', error: output);
            throw AppException('Failed to connect');
          }),
        );
      });

  @override
  Future<Result> disconnect(String id) => run(['disconnect', id]).then((result) async {
        return result.copyWith(
          messege: result.stdout.then((output) {
            if (output.contains('disconnected')) {
              return 'Disconnected from $id';
            }
            logError('Failed to disconnect $id', error: output);
            throw AppException('Failed to disconnect');
          }),
        );
      });
  @override
  Future<Result> installApk(String id, String path) =>
      run(['-s', id, 'install', path]).then((result) async {
        return result.copyWith(
          messege: Future.wait([result.stdout, result.stderr]).then((output) {
            final stdout = output.first;
            final stderr = output.last;
            if (stderr != '') {
              throw AppException("Failed to install");
            }
            if (stdout.contains('Success')) {
              return 'Installed $path';
            }
            logError('Failed to install $path', error: output);
            throw AppException('Failed to install');
          }),
        );
      });

  @override
  Future<List<AdbFileSystem>> ls(AdbDevice device, String? path) =>
      run(['-s', device.id, 'shell', 'ls', '-i', '"${path ?? '/'}"']).then((result) async {
        final stdErr = await result.stderr;
        if (stdErr != '') {
          throw AppException("Failed to list files");
        }

        return result.stdout.then((output) async {
          if (output.contains('Permission denied')) {
            throw PermissionDeniedException();
          }
          if (output.contains('No such file or directory')) {
            throw PermissionDeniedException();
          }
          final files = output.split('\n').toList().map((e) => e.trim()).toList();
          files.forEach(logInfo);
          final result = <AdbFileSystem>[];
          for (var element in files) {
            if (element == '') {
              continue;
            }
            List<String> parts = element.split(' ')..removeWhere((element) => element.isEmpty);

            final inode = parts.first;

            if (inode == '?') {
              continue;
            }
            parts.removeAt(0);
            final name = parts.join(' ').trim();
            // result.add(name);
            AdbFileSystem file;
            if (name.contains('.')) {
              file = AdbFile(name);
            } else {
              file = AdbDirectory(name);
            }
            result.add(file);
          }
          //TODO: have to find a better way to remove the unneccery files
          result.removeWhere(
            (element) =>
                element.name == 'metadata' ||
                element.name == 'oem' ||
                element.name == 'odm' ||
                element.name == 'lost+found' ||
                element.name == 'bugreports' ||
                element.name == 'data' ||
                element.name == 'sys' ||
                element.name == 'system' ||
                element.name == 'apex' ||
                element.name == 'vendor' ||
                element.name == 'bin' ||
                element.name == 'acct' ||
                element.name == 'config' ||
                element.name == 'debug_ramdisk' ||
                element.name == 'default.prop' ||
                element.name == 'd' ||
                element.name == 'cache' ||
                element.name == 'system_ext',
          );
          return result.toList()
            ..sort((a, b) {
              if (a is AdbDirectory) {
                return -1;
              }
              return 1;
            });
        });
      });

  @override
  Future<Result> pushFile(
    String id,
    String file,
    String destinationPath,
  ) =>
      run(['-s', id, 'push', file, destinationPath]).then((result) async {
        return result.copyWith(
          messege: result.stdout.then((output) {
            if (output.contains('pushed')) {
              return 'Pushed $file';
            }
            logError('Failed to push $file', error: output);
            throw AppException('Failed to push');
          }),
        );
      });
}

class PermissionDeniedException extends AppException {
  PermissionDeniedException() : super('Permission denied');
}

class NotDirException extends AppException {
  NotDirException() : super('Not a directory');
}
