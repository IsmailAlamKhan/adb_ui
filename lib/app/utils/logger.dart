import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../features/features.dart';
import 'utils.dart';

final appLogger = AppLogger.root();

void logError(Object? messege, {Object? error, StackTrace? stackTrace}) {
  appLogger.error(messege, error: error, stackTrace: stackTrace);
}

void logWarning(Object? messege, {Object? warning, StackTrace? stackTrace}) {
  appLogger.warning(messege, warning: warning, stackTrace: stackTrace);
}

void logInfo(Object? messege) => appLogger.info(messege);

class AppLogger {
  factory AppLogger.root() => _root;
  static final _root = AppLogger('App Logger');

  AppLogger(this.name) : logger = Logger(name);

  final String name;
  final Logger logger;

  void error(Object? message, {Object? error, StackTrace? stackTrace}) =>
      logger.shout(message, error, stackTrace);

  void warning(Object? message, {Object? warning, StackTrace? stackTrace}) =>
      logger.warning(message, warning, stackTrace);

  void info(Object? message) => logger.info(message);
  static void init() {
    if (kDebugMode) {
      Logger.root.level = Level.ALL;
    } else {
      Logger.root.level = Level.WARNING;
    }
    Logger.root.onRecord.listen((data) => _printLog(data));
  }

  static void _printLog(LogRecord record) {
    final level = record.level;
    final recordMessege = record.message;
    final error = record.error;
    final stack = record.stackTrace;
    final name = record.loggerName;

    final isError = level.value.between(1000, 1300);
    final isWarning = level.value == 900;
    final isNormal = level.value.between(0, 900);

    final output =
        "[$name] $recordMessege${error != null ? '\n$error' : ''}${stack != null ? '\n$stack' : ''}";
    var messege = "";
    if (isError) {
      messege = '🛑 \x1B[31m$output\x1B[0m ';
    }
    if (isWarning) {
      messege = '⚠️ \x1B[33m$output\x1B[0m ⚠️';
    }
    if (isNormal) {
      messege = '\x1B[34m ℹ️ $output ℹ️ \x1B[0m';
    }

    // ignore: avoid_print
    print(messege);
  }
}

class LogFile {
  static LogFile? _instance;

  static LogFile get instance {
    assert(
      _instance != null,
      'LogFile.instance has not been initialized. Call LogFile.init() first.',
    );
    return _instance!;
  }

  File? _logFile;
  File? _flutterErrorLogFile;
  File? _stdoutLogFile;
  File? _stderrLogFile;

  File? get logFile => _logFile;
  File? get flutterErrorLogFile => _flutterErrorLogFile;
  File? get stdoutLogFile => _stdoutLogFile;
  File? get stderrLogFile => _stderrLogFile;
  bool get fileExists {
    if (kIsWeb) return false;

    return (logFile?.existsSync() ?? false) &&
        (flutterErrorLogFile?.existsSync() ?? false) &&
        (stdoutLogFile?.existsSync() ?? false) &&
        (stderrLogFile?.existsSync() ?? false);
  }

  Future<void> dispath(
    String messege, {
    bool isError = true,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!fileExists) {
      await _init(false);
    }

    String value;
    if (stackTrace != null) {
      value = 'Messege: $messege ${error ?? ''}\nStackTrace=$stackTrace\n';
    } else {
      value = 'Messege: $messege${error == null ? '' : '\nError: $error'}\n';
    }
    if (isError) {
      logError(messege, error: error, stackTrace: stackTrace);
    } else {
      logInfo(messege);
    }
    _logFile?.writeAsStringSync(value.toString(), mode: FileMode.append);
  }

  Future<void> dispatchFlutterErrorLogs(FlutterErrorDetails details) async {
    if (!fileExists) {
      await _init(false);
    }
    final messege = details.exception;
    final stackTrace = details.stack;

    logError('Flutter Error', error: details.exception, stackTrace: stackTrace);

    _flutterErrorLogFile?.writeAsStringSync(
      'Messege: $messege\nStackTrace=$stackTrace\n',
      mode: FileMode.append,
    );
  }

  Future<void> dispatchStdoutLogs(String messege) async {
    if (!fileExists) {
      await _init(false);
    }
    _stdoutLogFile?.writeAsStringSync(messege, mode: FileMode.append);
  }

  Future<void> dispatchStderrLogs(String messege) async {
    if (!fileExists) {
      await _init(false);
    }
    _stderrLogFile?.writeAsStringSync(messege, mode: FileMode.append);
  }

  Future<File?> getAllLogsAndReset({Device? device}) async {
    if (_logFile == null) return Future.value();
    final now = DateTime.now();
    final month = DateFormat.MMM().format(now);
    final name = 'logs-$month-${now.day}';
    final pathToStoreZip = await FilePicker.platform.getDirectoryPath();
    if (pathToStoreZip == null) {
      throw AppException('No Directory Selected', 'no-dir-selected');
    }
    var encoder = ZipFileEncoder();
    File? deviceInfoFile;
    if (device != null) {
      deviceInfoFile = File(p.join(pathToStoreZip, 'device_info.json'));
    }
    final zipFilePath = p.join(pathToStoreZip, '$name.zip');
    final zipFile = File(zipFilePath);
    final logsDir = await _localPath;

    await compute((_) async {
      encoder.create(zipFilePath);
      final dirs = <Directory>[];
      await for (var item in logsDir.list(recursive: true)) {
        if (item.statSync().type == FileSystemEntityType.directory && !dirs.contains(item.parent)) {
          final path = item.parent.path;
          if (path.split(p.separator).last != 'logs') {
            await encoder.addDirectory(item.parent);
            dirs.add(item.parent);
          }
        }
      }
      final deviceInfo = device;
      deviceInfoFile?.writeAsStringSync(jsonEncode(deviceInfo));
      if (deviceInfoFile != null) {
        await encoder.addFile(deviceInfoFile);
      }
      encoder.close();
    }, null);
    deviceInfoFile?.deleteSync();
    await logsDir.delete(recursive: true);
    _init(false);
    return zipFile;
  }

  Future<Directory> get _localPath async {
    Directory directory = await getExternalDir();
    return Directory(p.join(directory.path, 'logs'));
  }

  Future<String> get _todayLogDir async {
    Directory directory = await _localPath;
    return p.join(directory.path, getTodayDir);
  }

  String get getTodayDir {
    final now = DateTime.now();
    final month = DateFormat.MMM().format(now);
    return p.join('${now.year}', month);
  }

  Future<void> _init(bool firstInit) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final dir = await _todayLogDir;
    _logFile = File(p.join(dir, 'log-${now.day}.txt'));
    _flutterErrorLogFile = File(p.join(dir, 'flutter-error-log-${now.day}.txt'));
    _stdoutLogFile = File(p.join(dir, 'stdout-log-${now.day}.txt'));
    _stderrLogFile = File(p.join(dir, 'stderr-log-${now.day}.txt'));
    if (!fileExists) {
      _logFile?.createSync(recursive: true);
      _flutterErrorLogFile?.createSync(recursive: true);
      _stdoutLogFile?.createSync(recursive: true);
      _stderrLogFile?.createSync(recursive: true);

      logInfo('Log files created');
      if (firstInit) dispath('App Started', isError: false);
    } else {
      logInfo('Log files already exist');
      if (firstInit) dispath('App Started', isError: false);
    }
  }

  static Future<void> init() {
    _instance = LogFile();
    return _instance!._init(true);
  }
}
