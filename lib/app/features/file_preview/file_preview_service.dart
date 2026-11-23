import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../utils/utils.dart';
import '../adb/adb.dart';
import '../errors/errors.dart';
import 'file_preview_model.dart';

/// Reads device files for previews. Quiet: nothing goes to Activity (spec/features/file-preview.md).
abstract class FilePreviewService {
  Future<RemoteFileInfo> stat(AdbDevice device, String path);

  /// The first [maxBytes] of a file, decoded as UTF-8 (bad bytes replaced).
  Future<String> head(AdbDevice device, String path, {int maxBytes = textPreviewBytes});

  /// A local copy in the preview cache, pulled when missing or changed.
  Future<File> pullToCache(AdbDevice device, RemoteFileInfo info);
}

final filePreviewServiceProvider = Provider<FilePreviewService>(FilePreviewServiceImpl.new);

typedef FilePreviewQuery = ({AdbDevice device, String path});

/// Loads a preview; a new query abandons the old one (autoDispose).
final filePreviewProvider = FutureProvider.autoDispose.family<FilePreviewData, FilePreviewQuery>((ref, query) async {
  final service = ref.read(filePreviewServiceProvider);
  final info = await service.stat(query.device, query.path);
  final kind = FilePreviewKind.of(query.path);
  switch (kind) {
    case FilePreviewKind.text:
      final text = await service.head(query.device, query.path);
      final shown = query.path.toLowerCase().endsWith('.json') && info.size <= textPreviewBytes
          ? prettyJsonOrSame(text, const JsonEncoder.withIndent('  ').convert, jsonDecode)
          : text;
      return FilePreviewData(info: info, kind: kind, text: shown, truncated: info.size > textPreviewBytes);
    case FilePreviewKind.image:
    case FilePreviewKind.video:
    case FilePreviewKind.audio:
      if (info.size > kind.maxBytes!) return FilePreviewData(info: info, kind: kind, tooBig: true);
      return FilePreviewData(info: info, kind: kind, file: await service.pullToCache(query.device, info));
    case FilePreviewKind.other:
      return FilePreviewData(info: info, kind: kind);
  }
});

class FilePreviewServiceImpl implements FilePreviewService {
  FilePreviewServiceImpl(this.ref);
  final Ref ref;
  Directory? _cache;

  AdbService get _adb => ref.read(adbServiceProvider);

  Future<({String out, String err, int code})> _run(AdbDevice device, List<String> args) async {
    final process = await _adb.startProcess(args, device: device);
    final out = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
    final err = process.stderr.transform(const Utf8Decoder(allowMalformed: true)).join();
    final code = await process.exitCode;
    return (out: await out, err: (await err).trim(), code: code);
  }

  Never _fail(String path, String err) {
    if (err.contains('No such file')) throw NotFoundException(path);
    if (err.contains('Permission denied')) throw PermissionDeniedException();
    throw AppException(err.isEmpty ? "Couldn't read $path" : err);
  }

  @override
  Future<RemoteFileInfo> stat(AdbDevice device, String path) async {
    final r = await _run(device, ['shell', "stat -L -c '%s|%Y' ${shellQuote(path)}"]);
    final info = RemoteFileInfo.parse(path, r.out);
    if (info == null) _fail(path, r.err.isEmpty ? r.out.trim() : r.err);
    return info;
  }

  @override
  Future<String> head(AdbDevice device, String path, {int maxBytes = textPreviewBytes}) async {
    final r = await _run(device, ['exec-out', 'head -c $maxBytes ${shellQuote(path)}']);
    if (r.code != 0 && r.out.isEmpty) _fail(path, r.err);
    return r.out;
  }

  Future<Directory> _cacheDir() async {
    if (_cache != null) return _cache!;
    final dir = Directory(p.join(Directory.systemTemp.path, 'adb_ui_preview'));
    // Start each session clean so old previews don't pile up.
    if (dir.existsSync()) await dir.delete(recursive: true).catchError((_) => dir);
    return _cache = await dir.create(recursive: true);
  }

  static String _hash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final unit in utf8.encode(value)) {
      hash ^= unit;
      hash *= 0x100000001b3; // wraps at 64 bits
    }
    return hash.toUnsigned(64).toRadixString(16);
  }

  @override
  Future<File> pullToCache(AdbDevice device, RemoteFileInfo info) async {
    final folder = Directory(p.join((await _cacheDir()).path, device.id.replaceAll(RegExp(r'[^\w.-]'), '_')));
    await folder.create(recursive: true);
    final ext = p.extension(info.name);
    final file = File(
      p.join(folder.path, '${_hash('${info.path}|${info.size}|${info.modified.millisecondsSinceEpoch}')}$ext'),
    );
    if (file.existsSync() && file.lengthSync() == info.size) return file;
    final r = await _run(device, ['pull', info.path, file.path]);
    if (r.code != 0 || !file.existsSync()) _fail(info.path, r.err.isEmpty ? r.out.trim() : r.err);
    return file;
  }
}
