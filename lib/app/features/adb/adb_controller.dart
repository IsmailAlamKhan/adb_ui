import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

final adbControllerProvider = Provider<AdbController>(AdbController.new);

class AdbController with NavigationController {
  @override
  final EventBus eventBus;
  final AdbService service;
  final NetworkInfoService networkInfoService;
  final CommandQueueController commandQueueController;

  AdbController(Ref ref)
      : eventBus = ref.read(eventBusProvider),
        service = ref.read(adbServiceProvider),
        networkInfoService = ref.read(networkInfoServiceProvider),
        commandQueueController = ref.read(commandQueueControllerProvider.notifier);

  Timer? _commandOutputCloseTimer;
  static const _commandOutputCloseTimerDuration = Duration(seconds: 2);
  void closeCurrentCommandOutput() {
    popUntil((route) => route.settings != CurrentCommandOutput.routeSettings);
  }

  Future<void> run({
    required Future<Result> Function() function,
    required String command,
    bool autoCloseOutput = true,
    bool isRerun = false,
    bool showOutput = true,
  }) async {
    String id = const Uuid().v4();
    if (isRerun) {
      id = 'rerun-$id';
    }
    _commandOutputCloseTimer?.cancel();
    closeCurrentCommandOutput();
    try {
      return await function().then((value) async {
        final _command = CommandModel.adding(
          id: id,
          command: command,
          device: value.device,
          stdout: value.stdoutStream,
          stderr: value.stderrStream,
          rawCommand: value.command,
          arguments: value.arguments,
        );
        commandQueueController.addCommand(_command);
        if (showOutput) {
          showDialog(
            pageBuilder: (context) => CurrentCommandOutput(commandId: id),
            barrierDismissible: false,
            barrierLabel: 'adb',
            routeSettings: CurrentCommandOutput.routeSettings,
          );
        }
        try {
          await value.messege;
        } catch (e, s) {
          String msg = exceptionToString(e);

          commandQueueController.updateCommand(
            CommandModel.error(
              id: id,
              command: command,
              device: value.device,
              error: msg,
              rawCommand: value.command,
              arguments: value.arguments,
            ),
          );
          LogFile.instance.dispath(
            'Error while running command: $command',
            error: e,
            stackTrace: s,
          );
        } finally {
          if (autoCloseOutput && showOutput) {
            _commandOutputCloseTimer =
                Timer(_commandOutputCloseTimerDuration, closeCurrentCommandOutput);
          }
        }
      });
    } on AppException catch (e) {
      showSnackbar(text: e.message);
    }
  }

  Future<void> connect() async {
    final nativeWirelessDebugSupported = await confirmDialog(
      (context) => 'Do you have android 11 or higher?',
      title: 'Android 11 or higher required',
    );
    if (nativeWirelessDebugSupported == null) {
      return;
    }
    if (!nativeWirelessDebugSupported) {
      final connectedUsb = await confirmDialog(
        (context) => 'Please connect your device via USB and confirm',
        title: 'USB cable required',
        confirmText: 'Ok',
        cancelText: 'Cancel',
      );
      if (connectedUsb == null) {
        return;
      }
      if (!connectedUsb) {
        showSnackbar(
          text:
              'For older android versions you need to first connect your device via USB and then wirelessly',
        );
        return;
      }

      await run(
        function: () => service.tcpip(),
        command: 'adb tcpip 5555',
      );
      if (_commandOutputCloseTimer != null) {
        await Future.delayed(_commandOutputCloseTimerDuration);
      }
      final ready = await confirmDialog(
        (context) =>
            'Please connect your device to the same wifi network as your computer and confirm.',
        title: 'Take out the usb cable',
        confirmText: 'Ok',
        cancelText: 'Cancel',
      );
      if (ready == false) {
        return;
      }
    }

    final ip = await showDialog<String>(
      pageBuilder: (_) => AdbInputDialog.single(
        title: nativeWirelessDebugSupported ? 'Enter your ip and port' : 'Enter your ip',
        label: nativeWirelessDebugSupported ? 'IP:PORT' : 'IP',
      ),
    );
    if (ip == null) {
      return;
    }
    String host;
    String port;
    if (nativeWirelessDebugSupported) {
      final split = ip.split(':');
      if (split.length != 2) {
        showSnackbar(text: 'Invalid ip');
        return;
      }
      host = split[0];
      port = split[1];
    } else {
      host = ip;
      port = '5555';
    }

    // final parts = ip.split(':');
    // if (parts.isEmpty) {
    //   return;
    // }
    // if (parts.length == 1) {
    //   parts.add('5555');
    // }
    // host = parts[0];
    // port = parts[1];
    return run(
      function: () => service.connect(host, int.parse(port)),
      command: 'Connect to $host:$port',
    );
  }

  Future<void> disconnect(AdbDevice device) async {
    return run(
      function: () => service.disconnect(device),
      command: 'Disconnect',
    );
  }

  Future<void> installApk(AdbDevice device) => run(
        function: () async {
          final apkPath = await showDialog<String>(pageBuilder: (_) => const FilePickerView.apk());
          if (apkPath != null) {
            return service.installApk(device, apkPath);
          }
          throw AppException('No apk selected to install');
        },
        command: 'Install apk',
      );

  Future<void> pushFile(AdbDevice device) async {
    final destinationPath = await showDialog<String>(
      pageBuilder: (_) => AdbFileExplorerView(
        device: device,
        openReason: AdbFileExplorerOpenReason.pickFolder,
        title: 'Select destination folder',
      ),
    );

    if (destinationPath == null) {
      showSnackbar(text: 'No destination path selected');
      return;
    }

    final files = await showDialog<List<String>>(pageBuilder: (_) => const FilePickerView());
    if (files == null) {
      showSnackbar(text: 'No file selected');
      return;
    }
    showSnackbar(text: 'Your files are being pushed check the command queue');
    for (var file in files) {
      await run(
        function: () => service.pushFile(device, file, destinationPath),
        command: 'Push file',
        showOutput: false,
      );
      if (_commandOutputCloseTimer != null) {
        await Future.delayed(_commandOutputCloseTimerDuration);
      }
    }
  }

  Future<void> pullFile(AdbDevice device) async {
    final files = await showDialog<List<String>>(
      pageBuilder: (_) => AdbFileExplorerView(device: device, title: 'Select files to pull'),
    );
    if (files == null) {
      return;
    }
    String? fileName;
    if (files.length == 1) {
      fileName = files.first.split('/').last;
    }

    String? destinationPath;
    if (fileName != null) {
      destinationPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Pick a folder to save the file',
        fileName: fileName,
      );
    } else {
      destinationPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pick a folder to save the files',
      );
    }
    if (destinationPath == null) {
      showSnackbar(text: 'No destination path selected');
      return;
    }
    showSnackbar(text: 'Your files are being pulled check the command queue');
    final _files = files.toList();
    for (var file in _files) {
      await run(
        function: () => service.pullFile(device, file, destinationPath!),
        command: 'Pull file',
        showOutput: false,
      );
      if (_commandOutputCloseTimer != null) {
        await Future.delayed(_commandOutputCloseTimerDuration);
      }
    }
  }

  Future<void> pair() async {
    final pairCodeAndIp = await showDialog<Map<String, String>>(
      pageBuilder: (_) => AdbInputDialog(
        title: 'Enter your pair code and ip',
        inputs: {
          'pair_code': (controller) => AdbInputDialogInput(
                controller: controller,
                label: 'Pair code',
              ),
          'host_port': (controller) => AdbInputDialogInput(
                controller: controller,
                label: 'host:port',
              ),
        },
      ),
    );
    if (pairCodeAndIp == null) return;
    final pairCode = pairCodeAndIp['pair_code'];
    final ip = pairCodeAndIp['host_port'];
    if (pairCode == null || ip == null) return;

    final parts = ip.split(':');
    if (parts.isEmpty) {
      return;
    }
    final host = parts[0];
    final port = parts[1];
    return run(
      function: () => service.pair(pairCode, host, int.parse(port)),
      command: 'Pair to $host:$port',
    );
  }

  Future<void> runCommand(AdbDevice device) async {
    final command = await showDialog<String>(
      pageBuilder: (_) => AdbInputDialog.single(
        title: 'Enter your command',
        label: 'command',
      ),
    );
    if (command == null) return;
    return run(
      function: () => service.runCustomCommand(device, command),
      command: 'Run command',
      autoCloseOutput: false,
    );
  }

  Future<void> runScrcpy(AdbDevice device) => run(
        function: () => service.scrcpy(device),
        command: 'Run scrcpy',
      );

  Future<void> rerunCommand(CommandModel command) {
    return run(
      function: () => service.rerunCommand(command.rawCommand, command.device, command.arguments),
      command: command.command,
      autoCloseOutput: false,
      isRerun: true,
    );
  }

  Future<void> inputText(AdbDevice device) async {
    final text = await showDialog<String>(
      pageBuilder: (_) => AdbInputDialog.single(
        title: 'Enter your text',
        label: 'text',
      ),
    );
    if (text == null) return;
    return run(
      function: () => service.inputText(device, text),
      command: 'Input text',
    );
  }
}
