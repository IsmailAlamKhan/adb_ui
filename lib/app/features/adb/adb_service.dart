import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import 'adb_model.dart';

final adbServiceProvider = Provider<AdbService>(ProccessAdbServiceImpl.new);

class Result {
  final Stream<String> stdoutStream;
  final Stream<String> stderrStream;
  final Future<int> exitCode;
  final Future<String> stdout;
  final Future<String> stderr;
  final Future<String> messege;
  final AdbDevice? device;
  Result({
    required this.stdoutStream,
    required this.stderrStream,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.messege,
    required this.device,
  });

  Result copyWith({
    Stream<String>? stdoutStream,
    Stream<String>? stderrStream,
    Future<int>? exitCode,
    Future<String>? stdout,
    Future<String>? stderr,
    Future<String>? messege,
    AdbDevice? device,
  }) {
    return Result(
      stdoutStream: stdoutStream ?? this.stdoutStream,
      stderrStream: stderrStream ?? this.stderrStream,
      exitCode: exitCode ?? this.exitCode,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      messege: messege ?? this.messege,
      device: device ?? this.device,
    );
  }
}

abstract class AdbService {
  Future<List<AdbDevice>> getConnectedDevices();

  Stream<List<AdbDevice>> get connectedDevicesStream;

  Future<void> verifyAdb();

  /// commands
  Future<Result> connect(String host, int port);
  Future<Result> pair(String pair, String host, int port);

  /// connnected device commands

  Future<Result> disconnect(AdbDevice device);
  Future<Result> installApk(AdbDevice device, String path);

  Future<List<AdbFileSystem>> ls(AdbDevice device, String? path);

  Future<Result> pushFile(AdbDevice device, String file, String destinationPath);

  Future<Result> pullFile(AdbDevice device, String file, String destinationPath);

  Future<Result> runCustomCommand(AdbDevice device, String command);

  /// -connnected device commands-

  /// -commands-
}

class ProccessAdbServiceImpl implements AdbService {
  final Ref ref;
  ProccessAdbServiceImpl(this.ref);

  Future<Result> run(
    List<String> arguments, {
    AdbDevice? device,
    bool addStdout = true,
  }) async {
    // logWarning(arguments);
    final process = await io.Process.start('adb', arguments);
    final stdout = process.stdout.asBroadcastStream();
    final stderr = process.stderr.asBroadcastStream();
    // if (addStdout && kDebugMode) {
    //   io.stdout.addStream(stdout);
    //   io.stderr.addStream(stderr);
    // }
    final _stdout = stdout.transform(utf8.decoder);
    final _stderr = stderr.transform(utf8.decoder);
    _stdout.listen(LogFile.instance.dispatchStdoutLogs);
    _stderr.listen(LogFile.instance.dispatchStdoutLogs);

    final result = Result(
      device: device,
      exitCode: process.exitCode,
      stdoutStream: _stdout,
      stderrStream: _stderr,
      stdout: _stdout.join(),
      stderr: _stderr.join(),
      messege: Future.value(''),
    );
    return result;
  }

  @override
  Future<List<AdbDevice>> getConnectedDevices() async {
    final process = await run(['devices'], addStdout: false);
    final devices = <AdbDevice>[];
    final output = (await process.stdout).split('\n').toList()
      ..removeWhere((element) =>
          element.trim().toLowerCase().contains('devices attached') || element.trim().isEmpty);

    for (var element in output) {
      final parts = element.split('	');
      if (parts.isEmpty) {
        break;
      }
      final model = await run(['-s', parts[0], 'shell', 'getprop', 'ro.product.model']);
      devices.add(AdbDevice(
        type: parts.last,
        id: parts.first,
        model: (await model.stdout).trim(),
      ));
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
  Future<Result> connect(String host, int port) =>
      run(['connect', '$host:$port']).then((result) async {
        return result.copyWith(
          messege: result.stdout.then((output) {
            if (output.contains('connected to')) {
              return 'Connected to $host:$port';
            }
            logError('Failed to connect to $host:$port', error: output);
            throw AppException('Failed to connect cause $output');
          }),
        );
      });
  @override
  Future<Result> pair(String pairCode, String host, int port) =>
      run(['pair', '$host:$port', pairCode]).then((result) async {
        return result.copyWith(messege: result.stdout);
      });

  @override
  Future<Result> disconnect(AdbDevice device) {
    final id = device.id;
    return run(['disconnect', id]).then((result) async {
      return result.copyWith(
        messege: result.stdout.then((output) {
          if (output.contains('disconnected')) {
            return 'Disconnected from $id';
          }
          logError('Failed to disconnect $id', error: output);
          throw AppException('Failed to disconnect cause $output');
        }),
      );
    });
  }

  @override
  Future<Result> installApk(AdbDevice device, String path) {
    final id = device.id;

    return run(['-s', id, 'install', path]).then((result) async {
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
          throw AppException('Failed to install cause $output');
        }),
      );
    });
  }

  @override
  Future<List<AdbFileSystem>> ls(AdbDevice device, String? path) =>
      run(['-s', device.id, 'shell', 'ls', '-i', '"${path ?? '/'}"']).then((result) async {
        final stdErr = await result.stderr;
        if (stdErr != '') {
          throw AppException("Failed to list files ");
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
    AdbDevice device,
    String file,
    String destinationPath,
  ) {
    final id = device.id;
    return run(['-s', id, 'push', file, destinationPath]).then((result) async {
      return result.copyWith(
        messege: result.stdout.then((output) {
          if (output.contains('pushed')) {
            return 'Pushed $file';
          }
          logError('Failed to push $file', error: output);
          throw AppException('Failed to push cause $output');
        }),
      );
    });
  }

  @override
  Future<Result> pullFile(AdbDevice device, String file, String destinationPath) {
    final id = device.id;
    return run(['-s', id, 'pull', file, destinationPath]).then((result) async {
      return result.copyWith(
        messege: result.stdout.then((output) {
          if (output.contains('pulled')) {
            return 'Pulled $file';
          }
          logError('Failed to pull $file', error: output);
          throw AppException('Failed to pull cause $output');
        }),
      );
    });
  }

  @override
  Future<Result> runCustomCommand(AdbDevice device, String command) {
    final id = device.id;
    return run(['-s', id, ...command.split(' ')]).then((result) {
      return result.copyWith(messege: result.stdout);
    });
  }

  @override
  Future<void> verifyAdb() => run(['version']).then((result) async {
        final stdErr = await result.stderr;
        if (stdErr != '') {
          throw AppException("Failed to verify adb");
        }
        final stdOut = await result.stdout;
        if (stdOut.contains('Android Debug Bridge version')) {
          return;
        }
        throw AppException("Failed to verify adb");
      });
}

class PermissionDeniedException extends AppException {
  PermissionDeniedException() : super('Permission denied');
}

class NotDirException extends AppException {
  NotDirException() : super('Not a directory');
}
