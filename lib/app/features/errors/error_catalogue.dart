import 'dart:io';

import '../../utils/constants.dart';
import '../../utils/exception.dart';
import '../adb/adb_service.dart';
import 'errors_model.dart';

/// Turns exceptions and raw adb output into [AppError]s people can act on.
///
/// Pure and total: never throws, unknown input becomes [ErrorKind.unknown] with the raw text
/// as details. Keep in sync with the catalogue table in spec/features/error-handling.md.
class ErrorCatalogue {
  const ErrorCatalogue._();

  static AppError explain(Object? error, {String? output}) {
    final raw = {
      if (error != null) _describe(error),
      if (output != null && output.trim().isNotEmpty) output.trim(),
    }.join('\n').trim();
    final details = raw.isEmpty ? null : raw;
    final text = raw.toLowerCase();

    AppError make(
      ErrorKind kind,
      String title,
      String message, [
      List<String> steps = const [],
      bool retryable = true,
    ]) =>
        AppError(
          kind: kind,
          title: title,
          message: message,
          steps: steps,
          details: details,
          retryable: retryable,
        );

    if (error is InvalidInputException) {
      return AppError(
        kind: ErrorKind.invalidInput,
        title: error.message,
        message: 'Check the value and try again.',
        retryable: false,
      );
    }
    if (error is AdbNotFoundException ||
        (error is ProcessException && error.executable == 'adb')) {
      return make(
        ErrorKind.adbMissing,
        "adb isn't installed or can't be found",
        'ADB UI runs the adb command from Android SDK Platform-Tools, and it could not start it.',
        [
          'Install Android SDK Platform-Tools (developer.android.com/tools/releases/platform-tools).',
          'Make sure adb is on your PATH. Running "adb version" in a terminal should work.',
          'If adb is somewhere else, add it to PATH in ~/.adb_ui (a shell file ADB UI reads).',
          'Click Try again.',
        ],
      );
    }
    if (error is ScrcpyNotFoundException) {
      return make(
        ErrorKind.scrcpyMissing,
        "scrcpy isn't installed",
        'Screen mirroring uses scrcpy, which was not found on this computer.',
        ['Install scrcpy (github.com/Genymobile/scrcpy).', 'Restart ADB UI.'],
        false,
      );
    }
    if (error is AdbMdnsUnavailableException) {
      return make(
        ErrorKind.mdns,
        'QR pairing needs a newer adb',
        "Your adb can't discover phones on the network (mDNS).",
        ['Update Android SDK Platform-Tools to version 31 or newer.', 'Or use a pairing code instead.'],
        false,
      );
    }
    if (error.runtimeType.toString() == 'AiModelException' ||
        text.contains('llama') && (text.contains('load') || text.contains('memory'))) {
      return make(
        ErrorKind.aiModel,
        "The AI filter didn't work",
        error is AppException ? error.message : 'The on-device model failed.',
        [
          'Try again, or rephrase the request more simply.',
          'If the model fails to load, switch to the Fast model in Settings → AI.',
          'You can always use the presets and search instead.',
        ],
      );
    }
    if (error is CommandFailedException) {
      return make(
        ErrorKind.commandFailed,
        'The command exited with code ${error.exitCode}',
        'The device or adb reported an error. The output below says why.',
      );
    }
    if (text.contains('error requesting environment')) {
      return make(
        ErrorKind.environment,
        "Couldn't read your shell environment",
        'ADB UI loads your shell profile to find adb, and the profile failed to run.',
        ['Check your shell profile (~/.zshrc, ~/.bashrc, ~/.adb_ui) for errors.', 'Open the logs for details.'],
      );
    }
    if (text.contains('unauthorized')) {
      return make(
        ErrorKind.unauthorized,
        "Your phone hasn't allowed this computer yet",
        'Android asks before it lets a computer use USB debugging.',
        [
          'Unlock your phone.',
          'Accept "Allow USB debugging?". Tick "Always allow from this computer".',
          "If there's no prompt, unplug and plug the cable back in.",
        ],
      );
    }
    if (text.contains('device offline') || text.contains('error: offline')) {
      return make(
        ErrorKind.offline,
        'The device is offline',
        "adb can see the device but can't talk to it right now.",
        [
          'Reconnect the cable, or turn Wireless debugging off and on.',
          'If it keeps happening, run "adb kill-server" and try again.',
        ],
      );
    }
    if (text.contains('no devices/emulators found') ||
        (text.contains("device '") && text.contains('not found'))) {
      return make(
        ErrorKind.noDevice,
        "The device isn't connected anymore",
        'It disconnected before the command could run.',
        ['Reconnect it.', 'For Wi-Fi, check the phone and this computer are on the same network.'],
      );
    }
    if (text.contains('failed to pair') ||
        text.contains('wrong password') ||
        (text.contains('pair') && text.contains('protocol fault'))) {
      return make(
        ErrorKind.pairing,
        'Pairing failed',
        "The phone didn't accept the pairing code, or the code expired.",
        [
          'On the phone, open Wireless debugging → "Pair device with pairing code".',
          'Use the IP address, port and 6-digit code shown there. They change each time.',
          'Keep that screen open until pairing finishes.',
        ],
      );
    }
    if (text.contains('failed to connect') ||
        text.contains('connection refused') ||
        text.contains('cannot connect') ||
        text.contains('no route to host') ||
        text.contains('timed out') ||
        text.contains('failed to authenticate')) {
      return make(
        ErrorKind.connection,
        "Couldn't reach the device",
        'Nothing answered at that address.',
        [
          'Check the phone and this computer are on the same Wi-Fi network.',
          'Use the IP address and port shown in Wireless debugging. The port changes when it restarts.',
          'Android 10 or older: connect by USB and enable Wi-Fi debugging (adb tcpip) first.',
        ],
      );
    }
    if (text.contains('install_failed_version_downgrade')) {
      return make(
        ErrorKind.installDowngrade,
        'A newer version is already installed',
        "Android won't replace an app with an older version.",
        ['Uninstall the app from the device first, then install again.'],
        false,
      );
    }
    if (text.contains('install_failed_update_incompatible') ||
        text.contains('signatures do not match')) {
      return make(
        ErrorKind.installSignature,
        'The installed app was signed with a different key',
        "Android only updates an app with an APK signed by the same key.",
        ['Uninstall the existing app first (this deletes its data), then install again.'],
        false,
      );
    }
    if (text.contains('install_failed_insufficient_storage')) {
      return make(
        ErrorKind.installStorage,
        'Not enough space on the device',
        'The device ran out of storage while installing.',
        ['Free up space on the device and try again.'],
      );
    }
    if (text.contains('install_failed_no_matching_abis')) {
      return make(
        ErrorKind.installAbi,
        "This APK doesn't support the device's processor",
        'The APK has no native code for this device (ABI).',
        ["Build or download an APK for the device's ABI (shown on the device page)."],
        false,
      );
    }
    if (text.contains('install_parse_failed') || text.contains('install_failed_invalid_apk')) {
      return make(
        ErrorKind.installInvalid,
        "That file isn't a valid APK",
        "Android couldn't read the package.",
        ['Check the file is a complete .apk, or rebuild it.'],
        false,
      );
    }
    if (text.contains('delete_failed') || text.contains('unknown package') ||
        text.contains('failed to uninstall')) {
      return make(
        ErrorKind.uninstall,
        "Couldn't uninstall the app",
        "It may be a system app that can't be removed, or it's already gone.",
        const [],
        false,
      );
    }
    if (text.contains('install_failed') ||
        text.contains('failed to install') ||
        text.contains('failure [')) {
      return make(
        ErrorKind.installOther,
        'The device refused to install the app',
        'Android rejected the install. The details below give the reason code.',
      );
    }
    if (error is NotFoundException || text.contains('no such file or directory')) {
      return make(
        ErrorKind.notFound,
        "That file or folder doesn't exist on the device",
        'It may have been moved or deleted.',
        const [],
        false,
      );
    }
    if (error is PermissionDeniedException || text.contains('permission denied')) {
      return make(
        ErrorKind.permission,
        "Android doesn't allow access there",
        'Apps and adb can only read some folders.',
        ['Use a folder under /sdcard, such as /sdcard/Download.'],
        false,
      );
    }
    return make(
      ErrorKind.unknown,
      'Something went wrong',
      details == null ? 'No details were reported.' : 'The details below say what adb reported.',
      ['If it keeps happening, report a bug from About and attach the logs.'],
    );
  }

  static String _describe(Object error) {
    if (error is CommandFailedException) return error.output;
    return exceptionToString(error);
  }
}
