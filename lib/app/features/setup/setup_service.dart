import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:github/github.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../shared/providers.dart';
import '../../utils/utils.dart';
import '../adb/adb_service.dart';
import 'setup_model.dart';
import 'tool_paths.dart';

final setupServiceProvider = Provider<SetupService>(SetupServiceImpl.new);

/// Detects and installs what ADB UI needs. See spec/features/onboarding.md.
abstract class SetupService {
  Future<HostInfo> host();

  /// Status of [r] (not [Requirement.aiModel], which has its own controller).
  Future<ToolStatus> detect(Requirement r);

  /// Resolves what a download install will fetch, so it can be shown before consent.
  Future<DownloadTarget> resolveDownload(Requirement r, DownloadSource source, HostInfo host);

  /// Runs a package-manager install; Linux root commands go through pkexec.
  Future<void> runPackageManager(
    Requirement r,
    PackageManagerInstall method, {
    required void Function(String line) onOutput,
  });

  /// Downloads [target], checks it and unpacks it into the app's tools folder.
  Future<void> download(
    Requirement r,
    DownloadTarget target, {
    required void Function(String line) onOutput,
    void Function(double? progress)? onProgress,
  });
}

class SetupServiceImpl implements SetupService {
  SetupServiceImpl(Ref ref) : github = ref.read(githubProvider);

  final GitHub github;

  static const _timeout = Duration(seconds: 10);
  static final _scrcpySlug = RepositorySlug('Genymobile', 'scrcpy');
  static const _repositoryXml = 'https://dl.google.com/android/repository/repository2-3.xml';

  /// Why the last [_run] returned null (exception or timeout), for the log.
  String? _lastRunError;

  Future<ProcessResult?> _run(String exe, List<String> args) async {
    try {
      _lastRunError = null;
      return await Process.run(
        exe,
        args,
        environment: await processEnvironment(),
        runInShell: Platform.isWindows,
      ).timeout(_timeout);
    } on Object catch (e) {
      _lastRunError = e is TimeoutException ? 'timed out after ${_timeout.inSeconds} s' : '$e'.split('\n').first;
      logInfo('[setup] $exe ${args.join(' ')} failed: $e');
      return null;
    }
  }

  /// Full path of [name] via `command -v` (Unix, through /bin/sh) or `where` (Windows), with
  /// the login-shell environment; null when it isn't on PATH. See spec/features/onboarding.md.
  Future<String?> _which(String name) async {
    final r = Platform.isWindows ? await _run('where', [name]) : await _run('/bin/sh', ['-c', 'command -v $name']);
    if (r == null || r.exitCode != 0) return null;
    return firstPathLine(r.stdout.toString());
  }

  Future<bool> _exists(String name) async => await _which(name) != null;

  /// Logs why [tool] counts as missing, so it shows in bug reports.
  void _notFound(String tool, String reason) =>
      LogFile.instance.dispath('Setup: $tool not found — $reason', isError: false);

  /// Resolves [tool], runs it with [args] and returns its output, or null (reason logged).
  Future<String?> _toolOutput(String tool, List<String> args) async {
    final exe = await _which(tool) ?? ToolPaths.maybeInstance?.managedExecutable(tool);
    if (exe == null) {
      _notFound(tool, 'not on PATH');
      return null;
    }
    final res = await _run(exe, args);
    if (res == null) {
      _notFound(tool, "couldn't run $exe: ${_lastRunError ?? 'unknown error'}");
      return null;
    }
    if (res.exitCode != 0) {
      final err = '${res.stderr}'.trim().split('\n').first;
      _notFound(tool, '$exe exited with ${res.exitCode}${err.isEmpty ? '' : ': $err'}');
      return null;
    }
    return '${res.stdout}';
  }

  Future<String> _arch() async {
    if (Platform.isWindows) {
      final a = (Platform.environment['PROCESSOR_ARCHITEW6432'] ??
              Platform.environment['PROCESSOR_ARCHITECTURE'] ??
              '')
          .toUpperCase();
      return a == 'ARM64' ? 'arm64' : (a == 'X86' ? 'x86' : 'x86_64');
    }
    if (Platform.isMacOS) {
      // uname reports x86_64 under Rosetta; ask the hardware instead.
      final r = await _run('/usr/sbin/sysctl', ['-n', 'hw.optional.arm64']);
      if (r != null && r.stdout.toString().trim() == '1') return 'arm64';
      return 'x86_64';
    }
    final r = await _run('uname', ['-m']);
    final m = r?.stdout.toString().trim() ?? '';
    if (m == 'aarch64' || m == 'arm64') return 'arm64';
    if (RegExp(r'^i\d86$').hasMatch(m)) return 'x86';
    return 'x86_64';
  }

  @override
  Future<HostInfo> host() async {
    final os = Platform.isMacOS ? HostOs.macos : (Platform.isWindows ? HostOs.windows : HostOs.linux);
    final managers = <PackageManager>[];
    for (final m in PackageManager.candidatesFor(os)) {
      if (await _exists(m.executable)) managers.add(m);
    }
    return HostInfo(
      os: os,
      arch: await _arch(),
      managers: managers,
      hasPkexec: os == HostOs.linux && await _exists('pkexec'),
    );
  }

  @override
  Future<ToolStatus> detect(Requirement r) async {
    final tools = ToolPaths.maybeInstance;
    switch (r) {
      case Requirement.adb:
        final out = await _toolOutput('adb', ['version']);
        final parsed = out == null ? null : parseAdbVersion(out);
        if (parsed == null) {
          if (out != null) _notFound('adb', 'unrecognised output: ${out.trim().split('\n').first}');
          return const ToolStatus.missing();
        }
        return ToolStatus.found(
          version: parsed.platformTools ?? parsed.adb,
          path: parsed.path,
          managedByApp: tools?.isManaged(parsed.path) ?? false,
        );
      case Requirement.scrcpy:
        final out = await _toolOutput('scrcpy', ['--version']);
        final version = out == null ? null : parseScrcpyVersion(out);
        if (version == null) {
          if (out != null) _notFound('scrcpy', 'unrecognised output: ${out.trim().split('\n').first}');
          return const ToolStatus.missing();
        }
        final managed = tools?.managedExecutable('scrcpy');
        return ToolStatus.found(version: version, path: managed, managedByApp: managed != null);
      case Requirement.libmpv:
        if (!Platform.isLinux) return const ToolStatus.found();
        for (final exe in const ['ldconfig', '/sbin/ldconfig']) {
          final res = await _run(exe, ['-p']);
          final lib = res == null ? null : parseLibmpv(res.stdout.toString());
          if (lib != null) return ToolStatus.found(version: lib);
        }
        return const ToolStatus.missing();
      case Requirement.aiModel:
        return const ToolStatus.missing();
    }
  }

  // ── Package managers ──────────────────────────────────────────────────────

  @override
  Future<void> runPackageManager(
    Requirement r,
    PackageManagerInstall method, {
    required void Function(String line) onOutput,
  }) async {
    final viaPkexec = method.needsRoot;
    final exe = viaPkexec ? 'pkexec' : method.manager.executable;
    final args = viaPkexec ? [method.manager.executable, ...method.arguments] : method.arguments;
    onOutput('\$ ${[exe, ...args].join(' ')}');
    LogFile.instance.dispath('[setup] running ${[exe, ...args].join(' ')}');

    final env = await processEnvironment();
    if (method.manager == PackageManager.brew) {
      env['NONINTERACTIVE'] = '1';
      env['HOMEBREW_NO_ENV_HINTS'] = '1';
    }
    final Process process;
    try {
      process = await Process.start(exe, args, environment: env, runInShell: Platform.isWindows);
    } on ProcessException catch (e) {
      throw InstallFailedException(r, -1, e.message, viaPkexec: viaPkexec);
    }
    final output = StringBuffer();
    void collect(String line) {
      output.writeln(line);
      onOutput(line);
    }

    final done = Future.wait([
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).forEach(collect),
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).forEach(collect),
    ]);
    final code = await process.exitCode;
    await done;
    LogFile.instance.dispath('[setup] ${method.command} exited with $code');
    if (code != 0) throw InstallFailedException(r, code, output.toString().trim(), viaPkexec: viaPkexec);
  }

  // ── Downloads ─────────────────────────────────────────────────────────────

  Future<String> _getText(Requirement r, String url) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200) throw DownloadFailedException(r, url, 'HTTP ${res.statusCode}');
      return await res.transform(utf8.decoder).join();
    } on SocketException catch (e) {
      throw DownloadFailedException(r, url, e.message);
    } on HttpException catch (e) {
      throw DownloadFailedException(r, url, e.message);
    } finally {
      client.close();
    }
  }

  @override
  Future<DownloadTarget> resolveDownload(Requirement r, DownloadSource source, HostInfo host) async {
    switch (source) {
      case DownloadSource.googlePlatformTools:
        final xml = await _getText(r, _repositoryXml);
        final target = parsePlatformToolsRepository(xml, host.os);
        if (target == null) {
          throw DownloadFailedException(r, _repositoryXml, 'no Platform-Tools archive for this OS in the index');
        }
        return target;
      case DownloadSource.scrcpyGithub:
        final Release release;
        try {
          release = await github.repositories.getLatestRelease(_scrcpySlug);
        } on Object catch (e) {
          throw DownloadFailedException(r, 'https://github.com/Genymobile/scrcpy/releases', e.toString());
        }
        final assets = release.assets ?? const <ReleaseAsset>[];
        final name = selectScrcpyAsset(assets.map((a) => a.name ?? ''), host.os, host.arch);
        final asset = assets.where((a) => a.name == name).firstOrNull;
        final sums = assets.where((a) => a.name == 'SHA256SUMS.txt').firstOrNull;
        if (asset?.browserDownloadUrl == null || name == null) {
          throw DownloadFailedException(r, release.htmlUrl ?? '', 'this release has no build for this computer');
        }
        if (sums?.browserDownloadUrl == null) {
          throw DownloadFailedException(r, release.htmlUrl ?? '', 'this release has no SHA256SUMS.txt to check against');
        }
        final checksum = parseSha256Sums(await _getText(r, sums!.browserDownloadUrl!), name);
        if (checksum == null) {
          throw DownloadFailedException(r, sums.browserDownloadUrl!, 'no checksum listed for $name');
        }
        return DownloadTarget(
          url: asset!.browserDownloadUrl!,
          checksum: checksum,
          algorithm: 'sha256',
          size: asset.size,
          version: release.tagName,
        );
    }
  }

  static bool _officialHost(String url) {
    final host = Uri.parse(url).host;
    return host == 'dl.google.com' || host == 'github.com';
  }

  @override
  Future<void> download(
    Requirement r,
    DownloadTarget target, {
    required void Function(String line) onOutput,
    void Function(double? progress)? onProgress,
  }) async {
    if (!_officialHost(target.url)) {
      throw DownloadFailedException(r, target.url, 'not an official download location');
    }
    final tools = ToolPaths.instance;
    final dest = switch (r) {
      Requirement.adb => tools.platformToolsDir,
      Requirement.scrcpy => tools.scrcpyDir,
      _ => throw StateError('$r has no download'),
    };
    final dlDir = Directory(tools.downloadDir)..createSync(recursive: true);
    final file = File(p.join(dlDir.path, target.fileName));
    final unpack = Directory(p.join(dlDir.path, 'unpack-${r.name}'));

    try {
      onOutput('Downloading ${target.url}');
      await _downloadTo(r, target, file, onProgress);
      onProgress?.call(null);

      onOutput('Checking ${target.algorithm.toUpperCase()}…');
      final hash = target.algorithm == 'sha1' ? sha1 : sha256;
      final digest = (await hash.bind(file.openRead()).first).toString();
      if (digest != target.checksum) {
        throw ChecksumMismatchException(target.url, target.checksum, digest);
      }
      onOutput('Checksum OK ($digest)');

      onOutput('Unpacking into $dest');
      if (unpack.existsSync()) unpack.deleteSync(recursive: true);
      unpack.createSync(recursive: true);
      final executables = <String>[];
      await extractFileToDisk(file.path, unpack.path, callback: (entry) {
        if (entry.isFile && entry.unixPermissions & 0x49 != 0) {
          executables.add(p.join(unpack.path, entry.name));
        }
      });
      if (!Platform.isWindows && executables.isNotEmpty) {
        await Process.run('chmod', ['u+x', ...executables]);
      }

      // Flatten the archive's single top-level folder.
      final children = unpack.listSync();
      final root = children.length == 1 && children.single is Directory ? children.single.path : unpack.path;
      final target0 = Directory(dest);
      if (target0.existsSync()) target0.deleteSync(recursive: true);
      Directory(root).renameSync(dest);
      onOutput('Installed in $dest');
    } finally {
      if (file.existsSync()) file.deleteSync();
      if (unpack.existsSync()) unpack.deleteSync(recursive: true);
    }
  }

  Future<void> _downloadTo(
    Requirement r,
    DownloadTarget target,
    File file,
    void Function(double?)? onProgress,
  ) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(target.url));
      final res = await req.close();
      if (res.statusCode != 200) throw DownloadFailedException(r, target.url, 'HTTP ${res.statusCode}');
      final total = target.size ?? (res.contentLength > 0 ? res.contentLength : null);
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          received += chunk.length;
          if (total != null) onProgress?.call((received / total).clamp(0, 1).toDouble());
        }
      } finally {
        await sink.close();
      }
      if (target.size != null && received != target.size) {
        throw DownloadFailedException(r, target.url, 'got $received bytes, expected ${target.size}');
      }
    } on SocketException catch (e) {
      throw DownloadFailedException(r, target.url, e.message);
    } on HttpException catch (e) {
      throw DownloadFailedException(r, target.url, e.message);
    } finally {
      client.close();
    }
  }
}
