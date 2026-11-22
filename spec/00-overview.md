# 00 — Overview

## What it is

ADB UI is a **desktop GUI for the `adb` command line**. It lets a developer or tester
connect Android devices (USB or Wi-Fi), and run common adb actions — install/uninstall
apps, push/pull files, type text, run arbitrary commands, launch scrcpy — without typing
commands. Every action is recorded in a persistent **command queue** that can be
re-run.

- Repo: https://github.com/IsmailAlamKhan/adb_ui
- Package name: `adb_ui`; display name: `Adb ui` (`appName` in `lib/app/utils/constants.dart`)
- Current version: see `pubspec.yaml` (`version:`) and `version.txt`
- License / distribution: open source, released through GitHub Releases

## Platforms

| Platform | Supported | Notes |
|----------|-----------|-------|
| Windows  | Yes | Custom title bar via `window_manager`; Inno Setup installer + zip |
| macOS    | Yes | Native `PlatformMenuBar`; DMG; loads shell env so `adb` on `PATH` is found |
| Linux    | Yes | Plain system window; zip with `.desktop` template |
| Android/iOS/Web | No | Some host-device code paths exist (`DeviceService`) but are not targets |

## Hard runtime requirements

1. `adb` on the user's `PATH`. Checked at startup (`adb version`); if missing the app
   shows the **App Initialization Error** screen instead of home.
2. `scrcpy` on `PATH` — **optional**. Only enables the "Scrcpy" device action.
3. Network access to `api.github.com` — optional; used for update checks.

## Feature list (shipped)

| Area | Capability |
|------|-----------|
| Devices | Live list of attached devices (polled every 1 s), model name, offline marker |
| Connect | Wireless connect for Android 11+ (`ip:port`) and legacy flow (`tcpip 5555` then `ip`) |
| Pair | `adb pair host:port code` |
| Device actions | Install APK, Uninstall app (by package), Push file(s), Pull file(s), Input text, Run custom command, Scrcpy, Copy id, Disconnect |
| File explorer | Browse device filesystem, pick a folder (push) or multiple files (pull) |
| File picker | Drag-and-drop or system picker for local files; APK-only variant |
| Command queue | Every command with live output, status, timings, device; persisted; re-run; remove; clear |
| Settings | Theme mode: system / light / dark; dynamic (OS accent) colours |
| About | Version, update check against GitHub latest release, download installer, changelog, GitHub link |
| Reporting | Bug report (zips logs + optional host device info, opens GitHub issue), feature request link |
| Updates | Auto-check on startup → "Update Available" dialog |
| Logging | Daily log files (app, flutter errors, stdout, stderr) in app support dir |

## Tech stack

- **Flutter** (Dart SDK `>=3.0.0 <4.0.0`), Material 3
- **State / DI:** `hooks_riverpod` 2 + `flutter_hooks`, some `riverpod_generator` (`@riverpod`)
- **Models:** `freezed` + `json_serializable`
- **Persistence:** `shared_preferences` (wrapped by `LocalStorage`)
- **Desktop:** `window_manager`, `desktop_drop`, `file_picker`, `dynamic_color`
- **Other:** `github` (release API), `url_launcher`, `package_info_plus`, `device_info_plus`,
  `archive` (log zip), `logging`, `google_fonts` (Poppins), `lottie`, `uuid`, `sliver_tools`

## Non-goals (current)

- No bundled adb binary — the user installs platform-tools.
- No multi-window, no localisation, no automated tests (yet).
