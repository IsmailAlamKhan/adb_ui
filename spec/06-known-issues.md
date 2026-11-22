# 06 — Known issues & tech debt

Observed while writing the spec (2026-11-22). Not yet fixed unless marked.
Fixed 2026-11-22 (redesign): `No such file` reported as permission denied (#3), stderr marking successful commands as failed (#7), activity order after restart (#8), `host:port` crashes (#10), uninstall not awaited (#11), no tests (#17). Also fixed (second pass): folder detection and sorting in file listings (#2, #4), selection leaking in the file chooser (#5), changelog 404 (#14). Also fixed: startup wrote the full shell environment (including secrets) to the log file — now only the variable count and PATH are logged; macOS sandbox blocking adb, `build_runner` not running, `google_fonts` not compiling (see 05-build-and-release "Toolchain"). When you
fix one, delete it here and update the owning spec. When you find a new one, add it.

| # | Area | Issue | Where |
|---|------|-------|-------|
| 6 | Devices | Polling runs `adb devices` every 1 s (models are now cached per device, so no extra `getprop`). | `connectedDevicesStream` |
| 9 | Command queue | `saveCommand` reads/writes the whole list each time; concurrent completions (multi-file push) can lose entries. | `LocalStorageCommandQueueServiceImpl` |
| 12 | Run command | Arguments split on spaces — no quoting support. | `runCustomCommand` |
| 13 | Logging | stderr is written to the stdout log; `stderr-log-*.txt` is never written. | `ProccessAdbServiceImpl.run` |
| 14 | About | `AboutModel.updateAvailableVersion` is never set (the changelog link is fixed). | `about_service.dart` |
| 15 | Updates | Version compare assumes exactly 3 numeric parts ≤ 99; a tag like `v1.0.0-beta` throws. | `PackageInfoServiceImpl` |
| 16 | Dead code | `NetworkInfoService` unused; Android/iOS/Web `DeviceService` impls and `isPerAppLangSupported` unused; commented-out Dio exception. | various |
| 18 | Naming | Typos are part of the public API: `messege`, `dispath`, `ProccessAdbServiceImpl`, `Result.messege`. Keep using them until a deliberate, repo-wide rename. | — |
| 19 | Deps | Riverpod is on 2.6 (`StateNotifier` style); Riverpod 3 is available but is a large API migration. freezed is on 3.x. | `pubspec.yaml` |
| 20 | Redesign | An error toast from a failed command hasn't been seen in the running app yet (typing into the app from automation didn't work); the error catalogue behind it is unit-tested. Windows and Linux layouts not checked. | `AdbController.runForResult` |
| 21 | Logs | Log files written before 2026-11-22 may contain the user's full shell environment, including secrets. They live in the app support folder's `logs/`. | — |
| 22 | AI filter | The Fast model alone is unreliable (invents tags/text, sometimes returns only an explanation); the rules + checks in `AiFilterMapper` carry most requests. App names are matched by package name only, so apps whose package doesn't contain their name (Gmail = `com.google.android.gm`) aren't recognised. | `AiFilterMapper` |
| 23 | Mirror | media_kit crashes on Flutter hot restart in debug builds; rotation, recording and snapshot mode not yet checked live. | `mirror/` |
| 24 | Platforms | Logcat, AI and mirror only tried on macOS; the Windows/Linux media_kit and llama.cpp runtimes are untested. | — |
