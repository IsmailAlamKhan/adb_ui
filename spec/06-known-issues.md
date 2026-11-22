# 06 — Known issues & tech debt

Observed while writing the spec (2026-11-22). Not yet fixed unless marked. When you
fix one, delete it here and update the owning spec. When you find a new one, add it.

| # | Area | Issue | Where |
|---|------|-------|-------|
| 1 | macOS | `Release.entitlements` enables `app-sandbox` with no `network.client`. A sandboxed release may be unable to run `adb` from the user's PATH and to reach the GitHub API. **Needs verification** on a release build. | `macos/Runner/Release.entitlements` |
| 2 | File explorer | File vs directory is guessed by "name contains `.`" — dotted folders and extensionless files are misclassified. | `AdbService.ls` |
| 3 | File explorer | `No such file or directory` is reported as `PermissionDeniedException`. | `AdbService.ls` |
| 4 | File explorer | Sort comparator returns `-1` whenever `a` is a directory (ignores `b`) — inconsistent ordering; no alphabetical sort. | `AdbService.ls` |
| 5 | File explorer | Selection highlight uses `endsWith(file.name)` — a file with the same name in another folder shows as selected. Controller is global, so history persists across openings and devices. | `adb_file_explorer_*` |
| 6 | Devices | Polling every 1 s spawns `adb devices` **plus one `getprop` per device** every second. | `connectedDevicesStream` |
| 7 | Command queue | Any stderr output marks the command as error, even on success. | `CommandQueueController.listenAndChangeCommand` |
| 8 | Command queue | Persisted list is appended (oldest first) but live list prepends → order is mixed after restart. | `CommandQueueService.saveCommand` / `init` |
| 9 | Command queue | `saveCommand` reads/writes the whole list each time; concurrent completions (multi-file push) can lose entries. | `LocalStorageCommandQueueServiceImpl` |
| 10 | Pair | `host:port` without `:` crashes on `parts[1]`; non-numeric port throws `FormatException` (not caught as `AppException`). Same for connect port. | `AdbController.pair/connect` |
| 11 | Uninstall | `run(...)` is not awaited/returned. | `AdbController.uninstallApp` |
| 12 | Run command | Arguments split on spaces — no quoting support. | `runCustomCommand` |
| 13 | Logging | stderr is written to the stdout log; `stderr-log-*.txt` is never written. | `ProccessAdbServiceImpl.run` |
| 14 | About | `changelogUrl` lacks `/blob/master/` → 404. `AboutModel.updateAvailableVersion` is never set. | `constants.dart`, `about_service.dart` |
| 15 | Updates | Version compare assumes exactly 3 numeric parts ≤ 99; a tag like `v1.0.0-beta` throws. | `PackageInfoServiceImpl` |
| 16 | Dead code | `NetworkInfoService` unused; Android/iOS/Web `DeviceService` impls and `isPerAppLangSupported` unused; commented-out Dio exception. | various |
| 17 | Quality | No automated tests. | — |
| 18 | Naming | Typos are part of the public API: `messege`, `dispath`, `ProccessAdbServiceImpl`, `Result.messege`. Keep using them until a deliberate, repo-wide rename. | — |
| 19 | Deps | Older majors (riverpod 2.0, freezed 2, intl 0.17, google_fonts 5). Upgrades need codegen regeneration. | `pubspec.yaml` |
