import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as p;

import '../../utils/utils.dart';
import '../errors/errors_model.dart';
import '../logcat/logcat_model.dart';
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

  /// `adb kill-server` then `adb start-server`: fixes stalled mDNS discovery.
  /// Recorded as `kill-server`. See spec/features/restart-adb.md.
  Future<Result> restartServer();

  Future<Result> pair(String pair, String host, int port);

  /// Services currently advertised over mDNS (`adb mdns services`).
  Future<List<AdbMdnsService>> mdnsServices();

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

  Future<Result> uninstallApp(AdbDevice device, String packageName);

  /// Starts a long-running adb process (logcat, screen mirror server) with the user's
  /// environment. Not recorded in Activity; the caller must kill it.
  Future<io.Process> startProcess(List<String> arguments, {AdbDevice? device, String executable = 'adb'});

  /// Pids of [package] (`pidof`), empty when it isn't running.
  Future<Set<int>> pidsOf(AdbDevice device, String package);

  /// Package of the activity in front (`dumpsys activity activities`).
  Future<String?> foregroundPackage(AdbDevice device);

  /// `adb logcat -c`.
  Future<Result> clearLogcat(AdbDevice device);

  /// All `getprop` values of a device.
  Future<DeviceProperties> deviceProperties(AdbDevice device);

  /// Installed package names; third-party only unless [includeSystem].
  Future<List<String>> listPackages(AdbDevice device, {bool includeSystem = false});

  /// Runs `adb -s <id> <arguments…>` and fails on a non-zero exit code. With [summarize],
  /// Activity keeps only the summary (not the output) and the full stdout goes to
  /// [onStdout]. Used by AI agent tools (spec/features/agent-mcp-server.md).
  Future<Result> runArguments(
    AdbDevice device,
    List<String> arguments, {
    String Function(String stdout)? summarize,
    void Function(String stdout)? onStdout,
  });

  /// PNG of the screen (`adb exec-out screencap -p`), handed to [onBytes].
  Future<Result> screenshot(AdbDevice device, void Function(Uint8List png) onBytes);

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
  final chmodResult =
      io.Process.runSync('chmod', ['u+x', 'env.sh'], workingDirectory: supportDir.absolute.path);
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
    // Never log values: the environment holds tokens and passwords, and logs are attached
    // to bug reports. Only PATH matters for finding adb.
    LogFile.instance.dispath(
      'Loaded ${envMap.length} environment variables. PATH=${envMap['PATH'] ?? '(not set)'}',
    );
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

  final _modelCache = <String, String>{};

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
        type: parts.last.trim(),
        id: parts.first.trim(),
        model: '',
      );
      // Models don't change while connected: only ask once per device (06 #6).
      var model = _modelCache[device.id];
      if (model == null && device.isOnline) {
        model = (await (await run(
          'getprop',
          arguments: ['ro.product.model'],
          device: device,
          shell: true,
          addToLogs: false,
        ))
                .stdout)
            .trim();
        if (model.isNotEmpty) _modelCache[device.id] = model;
      }
      devices.add(device.copyWith(model: model ?? ''));
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
        return result.copyWith(
          messege: result.stdout.then((output) {
            if (output.contains('Successfully paired')) {
              return output.trim();
            }
            logError('Failed to pair with $host:$port', error: output);
            throw AppException('Failed to pair cause $output');
          }),
        );
      });

  @override
  Future<List<AdbMdnsService>> mdnsServices() =>
      run('mdns', arguments: ['services'], addToLogs: false).then((result) async {
        final output = await result.stdout;
        final error = (await result.stderr).trim();
        if (error.isNotEmpty && output.trim().isEmpty) {
          throw AdbMdnsUnavailableException(error);
        }
        return AdbMdnsService.parseList(output);
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
          // stderr may hold warnings on success; stdout's "Success" decides.
          if (stdout.contains('Success')) {
            return 'Installed ${basename(path)}';
          }
          logError('Failed to install $path', error: output);
          throw AppException('Failed to install ${basename(path)}\n$stdout\n$stderr'.trim());
        }),
      );
    });
  }

  @override
  Future<List<AdbFileSystem>> ls(AdbDevice device, String? path) => run(
        'ls',
        shell: true,
        // -1 one per line, -p marks directories with '/', -L follows symlinks (e.g. /sdcard).
        arguments: ['-1', '-p', '-L', '"${path ?? '/'}"'],
        device: device,
        addToLogs: false,
      ).then((result) async {
        final stdErr = await result.stderr;
        final out = await result.stdout;
        final combined = '$out\n$stdErr';
        if (out.trim().isEmpty && combined.contains('No such file or directory')) {
          throw NotFoundException(path);
        }
        if (out.trim().isEmpty && combined.contains('Permission denied')) {
          throw PermissionDeniedException();
        }
        if (stdErr.trim().isNotEmpty && out.trim().isEmpty) {
          throw AppException('Failed to list files: $stdErr');
        }
        return parseLsOutput(out, root: path == null || path == '/');
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
      // adb 37+ prints its "1 file pushed" summary to stderr when not on a terminal, so
      // success is the exit code; the output only explains a failure.
      return result.copyWith(
        messege: Future.wait([result.exitCode, result.stdout, result.stderr]).then((v) {
          if (v[0] == 0) return 'Pushed $file';
          final output = '${v[2]}\n${v[1]}'.trim();
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
      // adb 37+ prints its "1 file pulled" summary to stderr when not on a terminal, so
      // success is the exit code; the output only explains a failure.
      return result.copyWith(
        messege: Future.wait([result.exitCode, result.stdout, result.stderr]).then((v) {
          if (v[0] == 0) return 'Pulled $file';
          final output = '${v[2]}\n${v[1]}'.trim();
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
      return result.copyWith(
        messege: Future.wait([result.stdout, result.stderr, result.exitCode]).then((values) {
          final stdout = values[0] as String;
          final stderr = values[1] as String;
          final exitCode = values[2] as int;
          final output = [stdout.trim(), stderr.trim()].where((e) => e.isNotEmpty).join('\n');
          if (exitCode != 0) {
            throw CommandFailedException(exitCode, output);
          }
          return output;
        }),
      );
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
  Future<Result> restartServer() async {
    // kill-server exits 1 when no server is running; only start-server decides.
    final kill = await run('kill-server', addToLogs: false);
    await kill.exitCode;
    final start = await run('start-server');
    return start.copyWith(
      command: 'kill-server',
      arguments: const [],
      messege: Future.wait([start.exitCode, start.stdout, start.stderr]).then((v) {
        if (v[0] == 0) return 'adb restarted';
        final output = '${v[2]}\n${v[1]}'.trim();
        logError('Failed to restart adb', error: output);
        throw AppException('Failed to restart adb cause $output');
      }),
    );
  }

  @override
  Future<Result> inputText(AdbDevice device, String text) {
    text = text.replaceAll('\'', '\\\'').replaceAll('"', '\\"').replaceAll(' ', '%s');
    logInfo('Text: $text');
    return run('shell', device: device, arguments: ['input', 'text', text])
        .then((value) => value.copyWith(
              messege: value.stdout.then((value) {
                if (value.isEmpty) {
                  return 'Text sent';
                }
                logError('Failed to send text', error: value);
                throw AppException('Failed to send text cause $value');
              }),
            ));
  }

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
      case 'pair':
        final address = arguments.first;
        final separator = address.lastIndexOf(':');
        return pair(
          arguments.last,
          address.substring(0, separator),
          address.substring(separator + 1).toInt()!,
        );
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
      case 'kill-server':
        return restartServer();
      case 'logcat':
        assert(device != null, 'Device cannot be null');
        return clearLogcat(device!);

      case 'shell':
        if (arguments.first == 'input' && arguments[1] == 'text') {
          assert(device != null, 'Device cannot be null');
          return inputText(device!, arguments.last);
        } else {
          assert(device != null, 'Device cannot be null');
          return runCustomCommand(device!, arguments.join(' '), executable: executable);
        }
      case 'exec-out':
        if (arguments.isNotEmpty && arguments.first == 'screencap') {
          return screenshot(device!, (_) {});
        }
        return runCustomCommand(device!, [command, ...arguments].join(' '), executable: executable);
      case '':
        return runCustomCommand(device!, arguments.join(' '), executable: executable);
      default:
        throw AppException('Command not found');
    }
  }

  @override
  Future<Result> uninstallApp(AdbDevice device, String packageName) {
    return run(
      'uninstall',
      arguments: [packageName],
      device: device,
    ).then((result) async {
      return result.copyWith(
        messege: result.stdout.then((output) {
          if (output.contains('Success')) {
            return 'Uninstalled $packageName';
          }
          logError('Failed to uninstall $packageName', error: output);
          throw AppException('Failed to uninstall cause $output');
        }),
      );
    });
  }

  @override
  Future<io.Process> startProcess(
    List<String> arguments, {
    AdbDevice? device,
    String executable = 'adb',
  }) async {
    if (io.Platform.isLinux || io.Platform.isMacOS) {
      _unixEnvironmentMap ??= await _loadUnixEnvironment();
    }
    try {
      return await io.Process.start(
        executable,
        [if (device != null) ...['-s', device.id], ...arguments],
        environment: _unixEnvironmentMap,
        runInShell: true,
      );
    } on ProcessException catch (e) {
      if (executable == 'adb') throw AdbNotFoundException();
      throw AppException('ProcessException: ${e.message}', e.errorCode.toString());
    }
  }

  @override
  Future<Set<int>> pidsOf(AdbDevice device, String package) async {
    final result = await run('pidof', shell: true, device: device, arguments: [package], addToLogs: false);
    return parsePids(await result.stdout);
  }

  @override
  Future<String?> foregroundPackage(AdbDevice device) async {
    final result = await run(
      'dumpsys',
      shell: true,
      device: device,
      arguments: ['activity', 'activities'],
      addToLogs: false,
    );
    return parseForegroundPackage(await result.stdout);
  }

  @override
  Future<Result> clearLogcat(AdbDevice device) =>
      run('logcat', arguments: ['-c'], device: device).then((result) => result.copyWith(
            messege: Future.wait([result.exitCode, result.stderr]).then((v) {
              if (v[0] != 0) throw AppException('Failed to clear logcat: ${v[1]}');
              return 'Cleared the device log';
            }),
          ));

  @override
  Future<DeviceProperties> deviceProperties(AdbDevice device) async {
    final result = await run('getprop', shell: true, device: device, addToLogs: false);
    final output = await result.stdout;
    final stderr = (await result.stderr).trim();
    if (await result.exitCode != 0) {
      throw AppException(stderr.isEmpty ? 'getprop failed' : stderr);
    }
    return DeviceProperties.parse(output);
  }

  @override
  Future<Result> runArguments(
    AdbDevice device,
    List<String> arguments, {
    String Function(String stdout)? summarize,
    void Function(String stdout)? onStdout,
  }) async {
    final quiet = summarize != null;
    final result = await run('', arguments: arguments, device: device, addToLogs: !quiet);
    final message = Future.wait([result.stdout, result.stderr, result.exitCode]).then((v) {
      final stdout = v[0] as String;
      final stderr = v[1] as String;
      final exitCode = v[2] as int;
      final output = [stdout.trim(), stderr.trim()].where((e) => e.isNotEmpty).join('\n');
      if (exitCode != 0) throw CommandFailedException(exitCode, output);
      onStdout?.call(stdout);
      if (summarize != null) return summarize(stdout);
      return output.isEmpty ? 'Done' : output;
    });
    if (!quiet) return result.copyWith(messege: message);
    return result.copyWith(
      stdoutStream: const Stream<String>.empty(),
      stderrStream: const Stream<String>.empty(),
      messege: message,
    );
  }

  @override
  Future<Result> screenshot(AdbDevice device, void Function(Uint8List png) onBytes) async {
    final arguments = ['screencap', '-p'];
    final process = await startProcess(['exec-out', ...arguments], device: device);
    final bytes = BytesBuilder(copy: false);
    final read = process.stdout.forEach(bytes.add);
    final stderr = process.stderr.transform(utf8.decoder).join();
    final message = Future.wait([read.then((_) => 0), process.exitCode, stderr]).then((v) {
      final png = bytes.takeBytes();
      final isPng = png.length > 24 && png[1] == 0x50 && png[2] == 0x4E && png[3] == 0x47;
      if (v[1] != 0 || !isPng) {
        throw AppException("Couldn't capture the screen. ${(v[2] as String).trim()}".trim());
      }
      onBytes(png);
      final data = ByteData.sublistView(png);
      return 'Screenshot ${data.getUint32(16)}×${data.getUint32(20)}';
    });
    return Result(
      stdoutStream: const Stream<String>.empty(),
      stderrStream: const Stream<String>.empty(),
      exitCode: process.exitCode,
      stdout: Future.value(''),
      stderr: stderr,
      messege: message,
      device: device,
      command: 'exec-out',
      arguments: arguments,
    );
  }

  @override
  Future<List<String>> listPackages(AdbDevice device, {bool includeSystem = false}) async {
    final result = await run(
      'pm',
      shell: true,
      device: device,
      arguments: ['list', 'packages', if (!includeSystem) '-3'],
      addToLogs: false,
    );
    final output = await result.stdout;
    final stderr = (await result.stderr).trim();
    if (await result.exitCode != 0) {
      throw AppException(stderr.isEmpty ? 'pm list packages failed' : stderr);
    }
    return parsePackageList(output);
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

class AdbMdnsUnavailableException extends AppException {
  AdbMdnsUnavailableException(String details)
      : super(
          "mDNS discovery isn't available in your adb. Update Android platform-tools.\n$details",
        );
}

class ScrcpyNotFoundException extends AppException {
  ScrcpyNotFoundException() : super('Scrcpy not found');
}
