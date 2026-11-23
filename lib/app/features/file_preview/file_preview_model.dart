import 'dart:io';

import 'package:flutter/foundation.dart';

/// What kind of preview a device file gets (spec/features/file-preview.md).
enum FilePreviewKind {
  image({'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'}, 50 * 1000 * 1000),
  video({'mp4', 'mkv', 'webm', '3gp', 'mov'}, 300 * 1000 * 1000),
  audio({'mp3', 'm4a', 'aac', 'ogg', 'opus', 'wav', 'flac'}, 300 * 1000 * 1000),
  text({
    'txt',
    'log',
    'json',
    'xml',
    'csv',
    'md',
    'yaml',
    'yml',
    'ini',
    'conf',
    'cfg',
    'properties',
    'prop',
    'sh',
    'html',
    'htm',
    'kt',
    'java',
    'dart',
    'gradle',
    'js',
    'ts',
    'py',
  }, null),
  other({}, null);

  const FilePreviewKind(this.extensions, this.maxBytes);
  final Set<String> extensions;

  /// Largest file pulled for a preview; null = not pulled (text is read in part).
  final int? maxBytes;

  static FilePreviewKind of(String path) {
    final name = path.split('/').last.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return FilePreviewKind.other;
    final ext = name.substring(dot + 1);
    return FilePreviewKind.values.firstWhere((k) => k.extensions.contains(ext), orElse: () => FilePreviewKind.other);
  }
}

/// Size and modified time of a device file, from `stat -c '%s|%Y'`.
@immutable
class RemoteFileInfo {
  const RemoteFileInfo(this.path, {required this.size, required this.modified});
  final String path;
  final int size;
  final DateTime modified;

  String get name => path.split('/').last;

  /// Parses `size|mtimeSeconds`; null when the output isn't that.
  static RemoteFileInfo? parse(String path, String output) {
    final match = RegExp(r'^(\d+)\|(\d+)').firstMatch(output.trim());
    if (match == null) return null;
    return RemoteFileInfo(
      path,
      size: int.parse(match.group(1)!),
      modified: DateTime.fromMillisecondsSinceEpoch(int.parse(match.group(2)!) * 1000),
    );
  }
}

/// A loaded preview: info plus either a local copy, some text, or neither.
@immutable
class FilePreviewData {
  const FilePreviewData({
    required this.info,
    required this.kind,
    this.file,
    this.text,
    this.truncated = false,
    this.tooBig = false,
  });
  final RemoteFileInfo info;
  final FilePreviewKind kind;
  final File? file;
  final String? text;
  final bool truncated;
  final bool tooBig;
}

/// Bytes read for a text preview.
const textPreviewBytes = 256 * 1024;

/// "1.2 MB", "340 KB", "12 bytes".
String formatFileSize(int bytes) {
  if (bytes < 1000) return '$bytes ${bytes == 1 ? 'byte' : 'bytes'}';
  if (bytes < 1000 * 1000) return '${(bytes / 1000).toStringAsFixed(bytes < 10000 ? 1 : 0)} KB';
  if (bytes < 1000 * 1000 * 1000) return '${(bytes / 1e6).toStringAsFixed(1)} MB';
  return '${(bytes / 1e9).toStringAsFixed(2)} GB';
}

/// Shell single-quoting for a device path.
String shellQuote(String value) => "'${value.replaceAll("'", r"'\''")}'";

/// Pretty-prints JSON text; returns it unchanged when it isn't JSON.
String prettyJsonOrSame(String text, String Function(Object?) encode, Object? Function(String) decode) {
  try {
    return encode(decode(text));
  } catch (_) {
    return text;
  }
}
