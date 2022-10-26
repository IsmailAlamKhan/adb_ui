import 'dart:async';

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

  Future<void> run(Future<Result> Function() function, String command) async {
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
          _commandOutputCloseTimer = Timer(const Duration(seconds: 2), closeCurrentCommandOutput);
        }
      });
    } on AppException catch (e) {
      showSnackbar(text: e.message);
    }
  }

  Future<void> connect() async {
    final ip = await showDialog<Map<String, String>>(
      pageBuilder: (_) => AdbInputDialog.single(
        title: 'Please Enter your ip and port',
        label: 'port',
        inputKey: 'ip:port',
      ),
    );
    if (ip == null) {
      return;
    }
    final parts = ip['ip:port']!.split(':');
    if (parts.isEmpty) {
      return;
    }
    final host = parts[0];
    final port = parts[1];
    return run(
      () => service.connect(host, int.parse(port)),
      'Connect to $host:$port',
    );
  }

  Future<void> disconnect(AdbDevice device) {
    return run(
      () => service.disconnect(device.id),
      'Disconnect from ${device.id}',
    );
  }

  Future<void> installApk(AdbDevice device) => run(
        () async {
          final apkPath = await showDialog<String>(pageBuilder: (_) => const FilePickerView.apk());
          if (apkPath != null) {
            return service.installApk(device.id, apkPath);
          }
          throw AppException('No apk selected to install');
        },
        'Install apk on ${device.id}',
      );

  Future<void> pushFile(AdbDevice device) async {
    final destinationPath = await showDialog<String>(
      pageBuilder: (_) => AdbFileExplorerView(
        device: device,
        openReason: AdbFileExplorerOpenReason.pickFolder,
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
      () => service.pushFile(device.id, file, destinationPath),
      'Push file to ${device.id}',
    );
  }
}
