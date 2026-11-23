import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../design/design.dart';
import '../../utils/utils.dart';
import '../features.dart';

final adbControllerProvider = Provider<AdbController>(AdbController.new);

/// UI entry point for every adb command. Each command goes through [runForResult] so it
/// appears in Activity, and its result is shown as a toast (spec/02-adb-layer.md).
class AdbController with NavigationController {
  @override
  final EventBus eventBus;
  final Ref ref;
  final AdbService service;
  final CommandQueueController commandQueueController;

  AdbController(this.ref)
      : eventBus = ref.read(eventBusProvider),
        service = ref.read(adbServiceProvider),
        commandQueueController = ref.read(commandQueueControllerProvider.notifier);

  AppStyle get _style => ref.read(settingsControllerProvider).style ?? AppStyle.workbench;

  Future<void> run({
    required Future<Result> Function() function,
    required String command,
    bool isRerun = false,
    bool showOutput = true,
  }) =>
      runForResult(function: function, command: command, isRerun: isRerun, showOutput: showOutput);

  /// Runs a command and records it in Activity. Returns its success message, or null if it
  /// failed. With [showOutput] the result is announced with a toast.
  Future<String?> runForResult({
    required Future<Result> Function() function,
    required String command,
    bool isRerun = false,
    bool showOutput = true,
  }) async {
    final startedAt = DateTime.now();
    final id = '${isRerun ? 'rerun-' : ''}${const Uuid().v4()}';

    final Result result;
    try {
      result = await function();
    } catch (e, s) {
      if (e is! AppException) logError('Could not start "$command"', error: e, stackTrace: s);
      if (showOutput) showError(e);
      return null;
    }

    commandQueueController.addCommand(CommandModel.adding(
      id: id,
      command: command,
      device: result.device,
      stdout: result.stdoutStream,
      stderr: result.stderrStream,
      rawCommand: result.command,
      arguments: result.arguments,
      startedAt: startedAt,
    ));

    try {
      final message = await result.messege;
      await commandQueueController.complete(id, message);
      if (showOutput) {
        final firstLine = message.trim().split('\n').first;
        final title = firstLine.isNotEmpty && firstLine.length <= 80 && !message.trim().contains('\n')
            ? firstLine
            : '$command finished';
        showSuccess(title, actions: [('Show output', () => openCommandDetails(id))]);
      }
      return message;
    } catch (e, s) {
      LogFile.instance.dispath('Error while running command: $command', error: e, stackTrace: s);
      await commandQueueController.fail(id, e);
      if (showOutput) {
        final stored = commandQueueController.byId(id);
        final output = stored?.whenError((c) => c.error);
        showError(
          e,
          output: output,
          onDetails: () => openCommandDetails(id),
          onRetry: () => runForResult(function: function, command: command, isRerun: true),
        );
      }
      return null;
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> openCommandDetails(String id) =>
      showDialog<void>(pageBuilder: (_) => CommandDetailsDialog(commandId: id));

  Future<void> openMirror(AdbDevice device) => push<void>((_) => MirrorPage(device: device));

  Future<void> openLogcat(AdbDevice device) => push<void>((_) => LogcatPage(device: device));

  Future<void> openActivity() => adaptivePush<void>((_) => const ActivityView());

  Future<void> openSettings() => adaptivePush<void>((_) => const SettingsView());

  Future<void> openPalette() async {
    final inline = LauncherPaletteFocus.node;
    if (_style == AppStyle.launcher && inline != null && inline.context != null) {
      inline.requestFocus();
      return;
    }
    return showDialog<void>(
        barrierColor: const Color(0x66000000),
        pageBuilder: (_) => const CommandPaletteDialog(),
      );
  }

  /// Opens the add-device flow on [tab]. Launcher shows QR pairing as a full page.
  Future<void> addDevice([AddDeviceTab tab = AddDeviceTab.qr]) {
    if (_style == AppStyle.launcher && tab == AddDeviceTab.qr) {
      return push<void>((_) => const QrPairPage());
    }
    return showDialog<void>(pageBuilder: (_) => AddDeviceDialog(initialTab: tab));
  }

  Future<void> pairWithQr() => addDevice();

  // ── Adding devices ────────────────────────────────────────────────────────

  /// `adb connect`. [address] must pass [validateHostPort].
  Future<bool> connect(String address) async {
    final target = parseHostPort(address);
    if (target == null) {
      showError(InvalidInputException(validateHostPort(address) ?? 'Invalid address'));
      return false;
    }
    final result = await runForResult(
      function: () => service.connect(target.host, target.port),
      command: 'Connect to ${target.host}:${target.port}',
    );
    return result != null;
  }

  /// `adb pair`. [address] must pass [validateHostPort], [code] [validatePairingCode].
  Future<bool> pair(String address, String code) async {
    final target = parseHostPort(address);
    final codeError = validatePairingCode(code);
    if (target == null || codeError != null) {
      showError(InvalidInputException(validateHostPort(address) ?? codeError!));
      return false;
    }
    final result = await runForResult(
      function: () => service.pair(code.replaceAll(' ', ''), target.host, target.port),
      command: 'Pair with ${target.host}:${target.port}',
    );
    return result != null;
  }

  /// `adb tcpip 5555` for Android 10 and older (device on USB).
  Future<bool> enableTcpip() async =>
      await runForResult(function: service.tcpip, command: 'Enable Wi-Fi debugging (tcpip 5555)') !=
      null;

  // ── Device actions ────────────────────────────────────────────────────────

  Future<void> disconnect(AdbDevice device) async {
    final ok = await showDialog<bool>(
      pageBuilder: (_) => ConfirmActionDialog(
        title: 'Disconnect ${device.displayName}?',
        message: device.isWireless
            ? 'You can reconnect it from Add device → IP address, or by pairing again.'
            : 'USB devices reconnect when you plug them in again.',
        confirmLabel: 'Disconnect',
        destructive: true,
      ),
    );
    if (ok != true) return;
    await run(function: () => service.disconnect(device), command: 'Disconnect ${device.displayName}');
  }

  Future<void> installApk(AdbDevice device, [String? path]) async {
    path ??= await showDialog<String>(pageBuilder: (_) => const FilePickerView.apk());
    if (path == null) return;
    final apk = path;
    await run(
      function: () => service.installApk(device, apk),
      command: 'Install ${p.basename(apk)}',
    );
  }

  /// Installs every `.apk` in [paths] on [device], one after another.
  Future<void> installDropped(AdbDevice device, List<String> paths) async {
    final apks = paths.where((e) => e.toLowerCase().endsWith('.apk')).toList();
    if (apks.isEmpty) {
      showToast(
        tone: ToastTone.info,
        title: 'Drop an .apk file to install it',
        message: 'To copy other files to the device, use Push files.',
      );
      return;
    }
    for (final apk in apks) {
      await installApk(device, apk);
    }
  }

  Future<void> uninstallApp(AdbDevice device, [String? packageName]) async {
    packageName ??= await showDialog<String>(
      pageBuilder: (_) => UninstallPickerDialog(device: device),
    );
    if (packageName == null || packageName.trim().isEmpty) return;
    final name = packageName.trim();
    final ok = await showDialog<bool>(
      pageBuilder: (_) => ConfirmActionDialog(
        title: 'Uninstall $name?',
        message: 'This removes the app and its data from ${device.displayName}.',
        confirmLabel: 'Uninstall',
        destructive: true,
      ),
    );
    if (ok != true) return;
    await run(function: () => service.uninstallApp(device, name), command: 'Uninstall $name');
    ref.invalidate(installedPackagesProvider);
  }

  /// The folder last pushed to this session; Push opens the device browser here.
  String lastPushFolder = '/sdcard/Download';

  /// Push files to [device] (spec/features/file-explorer-transfer.md).
  /// - Nothing given: opens the device file browser in push mode at [lastPushFolder]; the user
  ///   pushes from there (native picker or drop) and closes it when done.
  /// - [destination] only: opens the computer's own file picker, then pushes.
  /// - Both: pushes straight away.
  Future<void> pushFile(AdbDevice device, {List<String>? files, String? destination}) async {
    if (destination == null) {
      await showDialog<void>(
        pageBuilder: (_) => AdbFileExplorerView(
          device: device,
          openReason: AdbFileExplorerOpenReason.push,
          title: 'Push files to ${device.displayName}',
          initialPath: lastPushFolder,
        ),
      );
      return;
    }
    if (files == null) {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        dialogTitle: 'Choose files to push to $destination',
      );
      files = picked?.files.map((f) => f.path).whereType<String>().toList();
    }
    if (files == null || files.isEmpty) return;
    lastPushFolder = destination;
    await _transfer(
      verb: 'Push',
      done: 'Pushed',
      files: files,
      run: (file) => service.pushFile(device, file, destination),
      label: (file) => 'Push ${p.basename(file)}',
    );
    ref.invalidate(adbFilesProvider);
  }

  Future<void> pullFile(AdbDevice device, {List<String>? files, String? destination}) async {
    files ??= await showDialog<List<String>>(
      pageBuilder: (_) => AdbFileExplorerView(device: device, title: 'Choose files to pull'),
    );
    if (files == null || files.isEmpty) return;
    if (destination == null) {
      if (files.length == 1) {
        destination = await FilePicker.platform.saveFile(
          dialogTitle: 'Save file as',
          fileName: files.first.split('/').last,
        );
      } else {
        destination = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose a folder for the files',
        );
      }
    }
    if (destination == null) return;
    final target = destination;
    await _transfer(
      verb: 'Pull',
      done: 'Pulled',
      files: files,
      run: (file) => service.pullFile(device, file, target),
      label: (file) => 'Pull ${file.split('/').last}',
    );
  }

  Future<void> _transfer({
    required String verb,
    required String done,
    required List<String> files,
    required Future<Result> Function(String file) run,
    required String Function(String file) label,
  }) async {
    if (files.length == 1) {
      await this.run(function: () => run(files.first), command: label(files.first));
      return;
    }
    showToast(tone: ToastTone.info, title: '${verb}ing ${files.length} files…', message: 'Progress is in Activity.');
    var failed = 0;
    for (final file in files) {
      final ok = await runForResult(function: () => run(file), command: label(file), showOutput: false);
      if (ok == null) failed++;
    }
    if (failed == 0) {
      showSuccess('$done ${files.length} files', actions: [('Show activity', openActivity)]);
    } else {
      showToast(
        tone: ToastTone.error,
        title: '$failed of ${files.length} files failed',
        message: 'Open Activity to see why.',
        actions: [('Show activity', openActivity)],
      );
    }
  }

  /// Runs `adb -s <id> <command>`. Without [command], asks for one.
  Future<void> runCommand(AdbDevice device, [String? command]) async {
    command ??= await showDialog<String>(
      pageBuilder: (_) => AdbInputDialog.single(
        title: 'Run an adb command',
        label: 'Command',
        hint: 'shell pm list packages',
        prefix: 'adb ',
        info: 'Runs on ${device.displayName}. Arguments are split on spaces.',
      ),
    );
    final value = command?.trim();
    if (value == null || value.isEmpty) return;
    await run(function: () => service.runCustomCommand(device, value), command: 'adb $value');
  }

  Future<void> inputText(AdbDevice device, [String? text]) async {
    text ??= await showDialog<String>(
      pageBuilder: (_) => AdbInputDialog.single(
        title: 'Type text on ${device.displayName}',
        label: 'Text',
        info: 'Sent to the focused field on the device, as if typed.',
      ),
    );
    if (text == null || text.isEmpty) return;
    final value = text;
    await run(function: () => service.inputText(device, value), command: 'Type text');
  }

  Future<void> runScrcpy(AdbDevice device) =>
      run(function: () => service.scrcpy(device), command: 'Mirror ${device.displayName}');

  void copyId(AdbDevice device) {
    Clipboard.setData(ClipboardData(text: device.id));
    showToast(tone: ToastTone.success, title: 'Copied device id', message: device.id);
  }

  Future<void> rerunCommand(CommandModel command) => run(
        function: () => service.rerunCommand(command.rawCommand, command.device, command.arguments),
        command: command.command,
        isRerun: true,
      );
}
