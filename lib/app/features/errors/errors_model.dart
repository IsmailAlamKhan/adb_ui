import 'package:flutter/foundation.dart';

import '../../utils/exception.dart';

/// Categories in the error catalogue. See spec/features/error-handling.md.
enum ErrorKind {
  adbMissing,
  environment,
  unauthorized,
  offline,
  noDevice,
  connection,
  pairing,
  installDowngrade,
  installSignature,
  installStorage,
  installAbi,
  installInvalid,
  installOther,
  notFound,
  permission,
  uninstall,
  scrcpyMissing,
  mdns,
  invalidInput,
  commandFailed,
  aiModel,
  mirror,
  unknown,
}

/// An error explained for people: what happened, what to do, and the raw details.
@immutable
class AppError {
  const AppError({
    required this.kind,
    required this.title,
    required this.message,
    this.steps = const [],
    this.details,
    this.retryable = true,
  });

  final ErrorKind kind;
  final String title;
  final String message;
  final List<String> steps;
  final String? details;
  final bool retryable;

  /// First step, used as a one-line hint in lists.
  String? get hint => steps.isEmpty ? null : steps.first;

  AppError copyWith({String? details, bool? retryable}) => AppError(
        kind: kind,
        title: title,
        message: message,
        steps: steps,
        details: details ?? this.details,
        retryable: retryable ?? this.retryable,
      );

  @override
  String toString() => 'AppError($kind: $title)';
}

/// Input failed validation before anything was run.
class InvalidInputException extends AppException {
  InvalidInputException(super.message);
}

/// A command ran but exited with a non-zero code.
class CommandFailedException extends AppException {
  CommandFailedException(this.exitCode, this.output)
      : super('The command exited with code $exitCode\n$output');
  final int exitCode;
  final String output;
}

/// A file or folder on the device doesn't exist.
class NotFoundException extends AppException {
  NotFoundException([String? path])
      : super(path == null ? 'No such file or directory' : 'No such file or directory: $path');
}
