import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

final adbControllerProvider = Provider<AdbController>(AdbController.new);

class AdbController with NavigationController {
  @override
  final EventBus eventBus;
  final AdbService service;
  final NetworkInfoService networkInfoService;

  AdbController(Ref ref)
      : eventBus = ref.read(eventBusProvider),
        service = ref.read(adbServiceProvider),
        networkInfoService = ref.read(networkInfoServiceProvider);

  Timer? _commandOutputCloseTimer;
  void closeCurrentCommandOutput() {
    popUntil((route) => route.settings != CurrentCommandOutput.routeSettings);
  }

  Future<void> run({
    required Future<Result> Function() function,
    required String command,
    bool autoCloseOutput = true,
  }) async {
    _commandOutputCloseTimer?.cancel();
    closeCurrentCommandOutput();
    try {
      return await function().then((value) async {
        showDialog(
          pageBuilder: (context) => CurrentCommandOutput(
            stderrStream: value.sterrStream,
            stdoutStream: value.stoutStream,
            command: command,
          ),
          barrierDismissible: false,
          barrierLabel: 'adb',
          routeSettings: CurrentCommandOutput.routeSettings,
        );
        try {
          await value.messege;
        } on AppException catch (e) {
          showSnackbar(text: e.message);
        } finally {
          if (autoCloseOutput) {
            _commandOutputCloseTimer = Timer(const Duration(seconds: 2), closeCurrentCommandOutput);
          }
        }
      });
    } on AppException catch (e) {
      showSnackbar(text: e.message);
    }
  }

  Future<void> connect() async {
    final ip = await showDialog<String>(
      pageBuilder: (_) =>
          AdbInputDialog.single(title: 'Enter your ip and port', label: 'host:port'),
    );
    if (ip == null) {
      return;
    }

    final parts = ip.split(':');
    if (parts.isEmpty) {
      return;
    }
    final host = parts[0];
    final port = parts[1];
    return run(
      function: () => service.connect(host, int.parse(port)),
      command: 'Connect to $host:$port',
    );
  }

  Future<void> disconnect(AdbDevice device) async {
    return run(
      function: () => service.disconnect(device.id),
      command: 'Disconnect from ${device.id}',
    );
  }

  Future<void> installApk(AdbDevice device) => run(
        function: () async {
          final apkPath = await showDialog<String>(pageBuilder: (_) => const FilePickerView.apk());
          if (apkPath != null) {
            return service.installApk(device.id, apkPath);
          }
          throw AppException('No apk selected to install');
        },
        command: 'Install apk on ${device.id}',
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

    final file = await showDialog<String>(pageBuilder: (_) => const FilePickerView());
    if (file == null) {
      showSnackbar(text: 'No file selected');
      return;
    }

    run(
      function: () => service.pushFile(device.id, file, destinationPath),
      command: 'Push file to ${device.id}',
    );
  }

  Future<void> pullFile(AdbDevice device) async {
    final file = await showDialog<String>(
      pageBuilder: (_) => AdbFileExplorerView(
        device: device,
        title: 'Select file to pull',
      ),
    );
    if (file == null) {
      return;
    }
    final destinationPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Pick a folder to save the file',
      fileName: file.split('/').last,
    );
    if (destinationPath == null) {
      showSnackbar(text: 'No destination path selected');
      return;
    }
    run(
      function: () => service.pullFile(device.id, file, destinationPath),
      command: 'Pull file from ${device.id}',
    );
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
      function: () => service.runCustomCommand(device.id, command),
      command: 'Run command on ${device.id}',
      autoCloseOutput: false,
    );
  }
}
