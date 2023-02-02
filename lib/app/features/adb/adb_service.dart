import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as p;

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
  final String command;
  final List<String> arguments;

  Result({
    required this.stdoutStream,
    required this.stderrStream,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.messege,
    required this.device,
    required this.command,
    required this.arguments,
  });

  Result copyWith({
    Stream<String>? stdoutStream,
    Stream<String>? stderrStream,
    Future<int>? exitCode,
    Future<String>? stdout,
    Future<String>? stderr,
    Future<String>? messege,
    AdbDevice? device,
    String? command,
    List<String>? arguments,
  }) {
    return Result(
      stdoutStream: stdoutStream ?? this.stdoutStream,
      stderrStream: stderrStream ?? this.stderrStream,
      exitCode: exitCode ?? this.exitCode,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      messege: messege ?? this.messege,
      device: device ?? this.device,
      command: command ?? this.command,
      arguments: arguments ?? this.arguments,
    );
  }
}

abstract class AdbService {
  Future<List<AdbDevice>> getConnectedDevices();

  Stream<List<AdbDevice>> get connectedDevicesStream;

  Future<void> verifyAdb();

  Future<bool> scrcpyAvailable();

  /// commands
  Future<Result> connect(String host, int port);

  Future<Result> tcpip();

  Future<Result> pair(String pair, String host, int port);

  Future<Result> rerunCommand(
    String command,
    AdbDevice? device,
    List<String> arguments, {
    String executable = 'adb',
  });

  /// connnected device commands

  Future<Result> disconnect(AdbDevice device);

  Future<Result> installApk(AdbDevice device, String path);

  Future<Result> scrcpy(AdbDevice device);

  Future<List<AdbFileSystem>> ls(AdbDevice device, String? path);

  Future<Result> pushFile(AdbDevice device, String file, String destinationPath);

  Future<Result> pullFile(AdbDevice device, String file, String destinationPath);

  Future<Result> runCustomCommand(AdbDevice device, String command, {String executable = 'adb'});

  Future<Result> inputText(AdbDevice device, String text);

  /// -connnected device commands-

  /// -commands-
}

const _kFileContentEnvSh = '''#!/bin/sh
set +x

[ -f /etc/profile ] && source /etc/profile;
[ -f /etc/profiles ] && source /etc/profiles; 
[ -f /etc/bashrc ] && source /etc/bashrc;
[ -f /etc/bash.bashrc ] && source /etc/bash.bashrc;
[ -f /etc/zprofile ] && source /etc/zprofile;
[ -f /etc/zshenv ] && source /etc/zshenv; 
[ -f /etc/zshrc ] && source /etc/zshrc;

cd ~/;

 # ZSH
[ -f .zshrc ] && source ./.zshrc ; 
[ -f .zshenv ] && source ./.zshenv ; 
[ -f .zprofile ] && source ./.zprofile ; 

 # Korn Shell (ksh)
[ -f .kshrc ] && source ./.kshrc ; 

[ -f .profile ] && source ./.profile ;
[ -f .profiles ] && source ./.profiles ;
[ -f .bash_login ] && source ./.bash_login ;
[ -f .bashrc ] && source ./.bashrc ;
[ -f .bash_profile ] && source ./.bash_profile ;

# RedHat
[ -f .kshrc ] && source ./.kshrc ; 

# Custom profile
[ -f .adb_ui ] && source ./.adb_ui ;

/usr/bin/env;
''';

Map<String, String>? _unixEnvironmentMap;

Future<Map<String, String>?> _loadUnixEnvironment() async {
  final supportDir = await p.getApplicationSupportDirectory();
  final tempFile = File(join(supportDir.absolute.path, 'env.sh'));
  logInfo('Created temp sh file at ${tempFile.absolute.path}');

  tempFile.createSync(recursive: true);
  tempFile.writeAsStringSync(_kFileContentEnvSh);
  // wait some milliseconds for file to be flushed.
  await Future.delayed(const Duration(milliseconds: 300));

  // execution permissions (no need to get result).
  final chmodResult = io.Process.runSync('chmod', ['u+x', 'env.sh'],
      workingDirectory: supportDir.absolute.path);
  LogFile.instance.dispath(
      "Permission result (${chmodResult.exitCode}) - out=${chmodResult.stdout} - err=${chmodResult.stderr}");

  final result = Process.runSync(
    'bash',
    ['-c', './env.sh'],
    runInShell: true,
    workingDirectory: supportDir.absolute.path,
  );
  final envMap = <String, String>{};
  var stdOut = result.stdout.toString().trim();
  if (stdOut.isNotEmpty) {
    result.stdout.toString().trim().split('\n').forEach((line) {
      final parts = line.split('=');
      final key = parts[0];
      final value = parts.length > 1 ? parts[1] : '';
      envMap[key] = value;
    });
    LogFile.instance.dispath("Source System Environment result:\n$envMap");
  } else {
    logError("ERROR: ${result.stderr} // ${result.exitCode}");
    throw AppException(
      'Error requesting environment: ${result.stderr}',
      result.exitCode.toString(),
    );
  }
  return envMap;
}

class ProccessAdbServiceImpl implements AdbService {
  final Ref ref;

  ProccessAdbServiceImpl(this.ref);

  Future<Result> run(
    String command, {
    bool shell = false,
    List<String> arguments = const [],
    String executable = 'adb',
    AdbDevice? device,
    bool addToLogs = true,
  }) async {
    // Unix exception.
    if (io.Platform.isLinux || io.Platform.isMacOS) {
      _unixEnvironmentMap ??= await _loadUnixEnvironment();
    }

    // logWarning(arguments);
    Process process;
    final _command = [
      if (device != null) ...['-s', device.id],
      if (shell) 'shell',
      if (command != '') command,
      ...arguments,
    ];
    try {
      process = await io.Process.start(
        executable,
        _command,
        environment: _unixEnvironmentMap,
        runInShell: true,
      );
    } on ProcessException catch (e) {
      if (e.message == 'No such file or directory') {
        if (executable == 'adb') {
          throw AdbNotFoundException();
        } else {
          throw ScrcpyNotFoundException();
        }
      }
      throw AppException(
        'ProcessException: ${e.message} while running: $executable ${e.arguments.join(' ')}',
        e.errorCode.toString(),
      );
    }
    final stdout = process.stdout.asBroadcastStream();
    final stderr = process.stderr.asBroadcastStream();

    final _stdout = stdout.transform(utf8.decoder);
    final _stderr = stderr.transform(utf8.decoder);
    if (addToLogs) {
      _stdout.listen(LogFile.instance.dispatchStdoutLogs);
      _stderr.listen(LogFile.instance.dispatchStdoutLogs);
    }

    final result = Result(
      device: device,
      exitCode: process.exitCode,
      stdoutStream: _stdout,
      stderrStream: _stderr,
      stdout: _stdout.join(),
      stderr: _stderr.join(),
      messege: Future.value(''),
      command: executable != 'adb' ? executable : command,
      arguments: arguments,
    );
    return result;
  }

  @override
  Future<List<AdbDevice>> getConnectedDevices() async {
    final process = await run('devices', addToLogs: false);
    final devices = <AdbDevice>[];
    final output = (await process.stdout).split('\n').toList()
      ..removeWhere((element) =>
          element.trim().toLowerCase().contains('devices attached') || element.trim().isEmpty);

    for (var element in output) {
      final parts = element.split('	');
      if (parts.isEmpty) {
        break;
      }
      var device = AdbDevice(
        type: parts.last,
        id: parts.first,
        model: '',
      );
      final model = await (await run(
        'getprop',
        arguments: ['ro.product.model'],
        device: device,
        shell: true,
      ))
          .stdout;
      devices.add(device.copyWith(model: model.trim()));
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
  Future<Result> connect(String host, int port) async {
    return run(
      'connect',
      arguments: ['$host:$port'],
    ).then((result) async {
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
  }

  @override
  Future<Result> pair(String pairCode, String host, int port) => run(
        'pair',
        arguments: ['$host:$port', pairCode],
      ).then((result) async {
        return result.copyWith(messege: result.stdout);
      });

  @override
  Future<Result> disconnect(AdbDevice device) {
    final id = device.id;
    return run(
      'disconnect',
      arguments: [id],
      device: device,
    ).then((result) async {
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
    return run(
      'install',
      arguments: [path],
      device: device,
    ).then((result) async {
      return result.copyWith(
        messege: Future.wait([result.stdout, result.stderr]).then((output) {
          final stdout = output.first;
          final stderr = output.last;
          if (stderr != '') {
            throw AppException("Failed to install cause $stderr");
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
  Future<List<AdbFileSystem>> ls(AdbDevice device, String? path) => run(
        'ls',
        shell: true,
        arguments: ['-i', '"${path ?? '/'}"'],
        device: device,
      ).then((result) async {
        final stdErr = await result.stderr;
        if (stdErr != '') {
          throw AppException("Failed to list files $stdErr");
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
    return run(
      'push',
      arguments: [file, destinationPath],
      device: device,
    ).then((result) async {
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
    return run(
      'pull',
      arguments: [file, destinationPath],
      device: device,
    ).then((result) async {
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
  Future<Result> runCustomCommand(AdbDevice device, String command, {String executable = 'adb'}) {
    return run(
      '',
      arguments: [...command.split(' ')],
      device: device,
      executable: executable,
    ).then((result) {
      return result.copyWith(messege: result.stdout);
    });
  }

  @override
  Future<void> verifyAdb() {
    return run('version').then((result) async {
      final stdErr = await result.stderr;
      if (stdErr != '') {
        throw AppException(stdErr);
      }
      final stdOut = await result.stdout;
      if (stdOut.contains('Android Debug Bridge version')) {
        return;
      }
      throw AdbNotFoundException();
    });
  }

  @override
  Future<bool> scrcpyAvailable() async {
    try {
      return await run('', arguments: ['--version'], executable: 'scrcpy').then((result) async {
        final exitCode = await result.exitCode;
        if (exitCode == 0) {
          return true;
        }
        return false;
      });
    } on AppException catch (e) {
      LogFile.instance.dispath('Scrcpy not found', error: e);
      return Future.value(false);
    }
  }

  @override
  Future<Result> scrcpy(AdbDevice device) =>
      run('', device: device, executable: 'scrcpy').then((result) async {
        return result.copyWith(
          messege: result.stdout.then((output) {
            if (output.contains('INFO: Device')) {
              return 'Scrcpy started';
            }
            logError('Failed to start scrcpy', error: output);
            throw AppException('Failed to start scrcpy cause $output');
          }),
        );
      });

  @override
  Future<Result> tcpip() => run('tcpip', arguments: ['5555']).then((value) {
        return value.copyWith(
          messege: value.stdout.then((output) {
            if (output.contains('restarting in TCP mode port: 5555')) {
              return 'Restarted in TCP mode';
            }
            logError('Failed to restart in TCP mode', error: output);
            throw AppException('Failed to restart in TCP mode cause $output');
          }),
        );
      });

  @override
  Future<Result> inputText(AdbDevice device, String text) =>
      run('shell', device: device, arguments: ['input', 'text', text])
          .then((value) => value.copyWith(
                messege: value.stdout.then((value) {
                  if (value.isEmpty) {
                    return 'Text sent';
                  }
                  logError('Failed to send text', error: value);
                  throw AppException('Failed to send text cause $value');
                }),
              ));
  @override
  Future<Result> rerunCommand(
    String command,
    AdbDevice? device,
    List<String> arguments, {
    String executable = 'adb',
  }) {
    switch (command) {
      case 'connect':
        final ip = arguments.first.split(':');
        final host = ip.first;
        final port = ip.last.toInt()!;
        return connect(host, port);
      case 'disconnect':
        assert(device != null, 'Device cannot be null');
        return disconnect(device!);
      case 'install':
        assert(device != null, 'Device cannot be null');
        return installApk(device!, arguments.first);
      case 'push':
        assert(device != null, 'Device cannot be null');
        return pushFile(device!, arguments.first, arguments.last);
      case 'pull':
        assert(device != null, 'Device cannot be null');
        return pullFile(device!, arguments.first, arguments.last);
      case 'scrcpy':
        assert(device != null, 'Device cannot be null');
        return scrcpy(device!);

      case 'tcpip':
        return tcpip();

      case 'shell':
        if (arguments.first == 'input' && arguments[1] == 'text') {
          assert(device != null, 'Device cannot be null');
          return inputText(device!, arguments.last);
        } else {
          assert(device != null, 'Device cannot be null');
          return runCustomCommand(device!, arguments.join(' '), executable: executable);
        }
      case '':
        return runCustomCommand(device!, arguments.join(' '), executable: executable);
      default:
        throw AppException('Command not found');
    }
  }
}

class PermissionDeniedException extends AppException {
  PermissionDeniedException() : super('Permission denied');
}

class NotDirException extends AppException {
  NotDirException() : super('Not a directory');
}

class AdbNotFoundException extends AppException {
  AdbNotFoundException()
      : super('Adb not found please install it, Adb is required for this app to run');
}

class ScrcpyNotFoundException extends AppException {
  ScrcpyNotFoundException() : super('Scrcpy not found');
}
