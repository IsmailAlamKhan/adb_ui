import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:github/github.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import 'update_model.dart';

/// Releases, downloads and platform installers. See spec/features/updates.md.
abstract class UpdateService {
  /// The latest 30 releases (drafts and pre-releases included; callers filter).
  Future<List<AppRelease>> releases();

  /// Downloads [asset] into the updates folder, reporting `(received, total)`. Throws
  /// [UpdateDownloadException] when the size doesn't match. [cancel] stops it.
  Future<File> download(
    InstallerAsset asset, {
    required void Function(int received, int total) onProgress,
    required Completer<void> cancel,
  });

  /// Starts a detached script that waits for this process to quit, installs [installer]
  /// over the running app and reopens it. Returns false when this install can't replace
  /// itself (read-only location, running from a disk image…) and the installer was opened
  /// for the user instead.
  Future<bool> install(File installer);

  /// The bundled `CHANGELOG-ALL.md`.
  Future<String> bundledChangelog();

  Future<UpdatePrefs> loadPrefs();
  Future<void> savePrefs(UpdatePrefs prefs);

  /// Deletes leftover downloaded installers.
  Future<void> clearDownloads();
}

final updateServiceProvider = Provider<UpdateService>(UpdateServiceImpl.new);

class UpdateDownloadException extends AppException {
  UpdateDownloadException(super.message);
}

class UpdateServiceImpl implements UpdateService {
  UpdateServiceImpl(Ref ref)
      : github = ref.read(githubProvider),
        storage = ref.read(localStorageProvider);

  final GitHub github;
  final LocalStorage storage;

  @override
  Future<List<AppRelease>> releases() async {
    final list = <AppRelease>[];
    await for (final r in github.repositories.listReleases(githubRepoSlug).take(30)) {
      final version = AppVersion.tryParse(r.tagName);
      if (version == null) continue;
      list.add(AppRelease(
        version: version,
        tag: r.tagName ?? '',
        notes: r.body ?? '',
        draft: r.isDraft ?? false,
        prerelease: r.isPrerelease ?? false,
        assets: [
          for (final a in r.assets ?? const <ReleaseAsset>[])
            if (a.name != null && a.browserDownloadUrl != null)
              InstallerAsset(name: a.name!, url: a.browserDownloadUrl!, size: a.size ?? 0),
        ],
      ));
    }
    return list;
  }

  Future<Directory> _updatesDir() async {
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/updates');
    await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<File> download(
    InstallerAsset asset, {
    required void Function(int received, int total) onProgress,
    required Completer<void> cancel,
  }) async {
    final dir = await _updatesDir();
    final file = File('${dir.path}/${asset.name}');
    if (await file.exists() && asset.size > 0 && await file.length() == asset.size) {
      onProgress(asset.size, asset.size);
      return file;
    }
    final partial = File('${file.path}.part');
    final client = HttpClient()..userAgent = 'adb-ui-updater';
    try {
      final request = await client.getUrl(Uri.parse(asset.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw UpdateDownloadException('Download failed (HTTP ${response.statusCode}).');
      }
      final total = asset.size > 0 ? asset.size : response.contentLength;
      final sink = partial.openWrite();
      var received = 0;
      var lastReport = 0;
      try {
        await for (final chunk in response) {
          if (cancel.isCompleted) throw const _Cancelled();
          sink.add(chunk);
          received += chunk.length;
          if (received - lastReport > 256 * 1024 || received == total) {
            lastReport = received;
            onProgress(received, total);
          }
        }
      } finally {
        await sink.close();
      }
      onProgress(received, total);
      if (asset.size > 0 && received != asset.size) {
        throw UpdateDownloadException('The download was incomplete ($received of ${asset.size} bytes).');
      }
      if (await file.exists()) await file.delete();
      return await partial.rename(file.path);
    } on _Cancelled {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<bool> install(File installer) async {
    final dir = await _updatesDir();
    final exe = Platform.resolvedExecutable;
    if (Platform.isMacOS) {
      // …/ADB UI.app/Contents/MacOS/ADB UI → …/ADB UI.app
      final bundle = File(exe).parent.parent.parent.path;
      if (!bundle.endsWith('.app') ||
          bundle.startsWith('/Volumes/') ||
          bundle.contains('/AppTranslocation/') ||
          !await _writable(File(bundle).parent.path)) {
        await Process.run('open', [installer.path]);
        return false;
      }
      final script = File('${dir.path}/install-update.sh');
      await script.writeAsString(_macScript);
      await Process.start('/bin/sh', [script.path, '$pid', installer.path, bundle],
          mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isWindows) {
      final script = File('${dir.path}\\install-update.cmd');
      await script.writeAsString(_windowsScript);
      await Process.start('cmd', ['/c', script.path, '$pid', installer.path, exe],
          mode: ProcessStartMode.detached);
      return true;
    }
    if (Platform.isLinux) {
      final folder = File(exe).parent.path;
      if (!await _writable(folder)) {
        await Process.run('xdg-open', [installer.parent.path]);
        return false;
      }
      final script = File('${dir.path}/install-update.sh');
      await script.writeAsString(_linuxScript);
      await Process.start('/bin/sh', [script.path, '$pid', installer.path, folder, File(exe).uri.pathSegments.last],
          mode: ProcessStartMode.detached);
      return true;
    }
    throw UpdateDownloadException("Updating isn't supported on ${Platform.operatingSystem}.");
  }

  static Future<bool> _writable(String folder) async {
    final probe = File('$folder/.adb-ui-write-test-$pid');
    try {
      await probe.writeAsString('');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> bundledChangelog() => rootBundle.loadString('CHANGELOG-ALL.md');

  @override
  Future<UpdatePrefs> loadPrefs() => storage.get<UpdatePrefs>(
        LocalStorageKeys.updates,
        defaultValue: UpdatePrefs.initial,
        fromJson: (json) => UpdatePrefs.fromJson((json as Map).cast<String, dynamic>()),
      );

  @override
  Future<void> savePrefs(UpdatePrefs prefs) => storage.set<UpdatePrefs>(LocalStorageKeys.updates, prefs);

  @override
  Future<void> clearDownloads() async {
    final dir = await _updatesDir();
    await for (final entity in dir.list()) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {}
    }
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Waits for ADB UI to quit, swaps the app bundle for the one in the .dmg, reopens it.
/// Args: pid, dmg, path of the running .app. On failure the old app is put back and
/// the .dmg is opened for the user.
const _macScript = r'''#!/bin/sh
PID="$1"; DMG="$2"; DEST="$3"
while kill -0 "$PID" 2>/dev/null; do sleep 0.3; done
MNT=$(mktemp -d /tmp/adb-ui-update.XXXXXX)
if ! hdiutil attach -nobrowse -readonly -noautoopen -mountpoint "$MNT" "$DMG" >/dev/null; then
  open "$DMG"; exit 1
fi
APP=$(find "$MNT" -maxdepth 1 -name '*.app' | head -n 1)
OK=0
if [ -n "$APP" ]; then
  rm -rf "$DEST.old"
  if mv "$DEST" "$DEST.old"; then
    if ditto "$APP" "$DEST"; then OK=1; rm -rf "$DEST.old"
    else rm -rf "$DEST"; mv "$DEST.old" "$DEST"; fi
  fi
fi
hdiutil detach "$MNT" -quiet || hdiutil detach "$MNT" -force -quiet
rmdir "$MNT" 2>/dev/null
if [ "$OK" = 1 ]; then open "$DEST"; else open "$DMG"; fi
''';

/// Waits for ADB UI to quit, runs the Inno Setup installer silently (it reuses the install
/// folder through its AppId), then starts the app again. Args: pid, setup.exe, app exe.
const _windowsScript = r'''@echo off
:wait
tasklist /FI "PID eq %1" 2>nul | find "%1" >nul
if not errorlevel 1 (
  timeout /t 1 /nobreak >nul
  goto wait
)
"%~2" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS
start "" "%~3"
''';

/// Waits for ADB UI to quit, unzips the new bundle over the running folder, starts it.
/// Args: pid, zip, bundle folder, executable name.
const _linuxScript = r'''#!/bin/sh
PID="$1"; ZIP="$2"; DEST="$3"; EXE="$4"
while kill -0 "$PID" 2>/dev/null; do sleep 0.3; done
TMP=$(mktemp -d /tmp/adb-ui-update.XXXXXX)
if unzip -oq "$ZIP" -d "$TMP"; then
  SRC=$(dirname "$(find "$TMP" -maxdepth 2 -type f -name "$EXE" | head -n 1)")
  if [ -n "$SRC" ] && [ -f "$SRC/$EXE" ]; then
    cp -a "$SRC"/. "$DEST"/
    chmod +x "$DEST/$EXE"
  fi
fi
rm -rf "$TMP"
nohup "$DEST/$EXE" >/dev/null 2>&1 &
''';
