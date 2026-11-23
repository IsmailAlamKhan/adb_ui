# 00 — Overview

## What it is

ADB UI is a **desktop GUI for the `adb` command line**. It lets a developer or tester
connect Android devices (USB, Wi-Fi or QR code), and run common adb actions — install/uninstall
apps, push/pull files, type text, run arbitrary commands, read logcat, mirror the screen —
without typing commands. Every action is recorded in a persistent **Activity** list (command
queue) that can be re-run.

- Repo: https://github.com/IsmailAlamKhan/adb_ui
- Package name: `adb_ui`; display name: `Adb ui` (`appName` in `lib/app/utils/constants.dart`)
- Current version: see `pubspec.yaml` (`version:`) and `version.txt`
- License / distribution: open source, released through GitHub Releases

## Platforms

| Platform | Supported | Notes |
|----------|-----------|-------|
| Windows  | Yes | Custom title bar via `window_manager`; Inno Setup installer + zip |
| macOS    | Yes (14.0+, since 0.0.17) | Native `PlatformMenuBar`; DMG; **not sandboxed**; loads shell env so `adb` on `PATH` is found |
| Linux    | Yes | Plain system window; zip with `.desktop` template; needs `libmpv` installed (in-app mirror) |
| Android/iOS/Web | No | Some host-device code paths exist (`DeviceService`) but are not targets |

## Hard runtime requirements

1. `adb` on the user's `PATH`. Checked at startup (`adb version`); if missing the app
   shows the **App Initialization Error** screen instead of home.
2. `scrcpy` on `PATH` — **optional**. Enables live in-app mirroring and the scrcpy window;
   without it the Screen tab falls back to adb screenshots.
3. Network access to `api.github.com` — optional; used for update checks.
4. Network access to `huggingface.co` — optional, once; downloads the AI filter model.
5. Linux: `libmpv` (e.g. `libmpv2`) — the in-app mirror's video player.

## Feature list (shipped)

| Area | Capability |
|------|-----------|
| Devices | Live list of attached devices (polled every 1 s), model name, offline marker |
| Connect | Wireless connect for Android 11+ (`ip:port`) and legacy flow (`tcpip 5555` then `ip`) |
| Pair | `adb pair host:port code` |
| Device actions | Install APK, Uninstall app (picker), Push file(s), Pull file(s), Type text, Run command, Logcat, Mirror screen, Copy id, Disconnect |
| Add device | QR code pairing, pairing code, connect by IP (with `adb tcpip 5555` for Android ≤ 10) |
| Logcat | Live logs, presets (Warnings+/Errors+/Crashes), follow app / foreground app, tags, search, AI filter |
| AI log filter | On-device Qwen2.5 model turns a sentence into a logcat filter; nothing leaves the computer |
| Screen mirror | In-app live mirror via scrcpy server (touch, keys, controls, screenshot, record) or adb snapshots |
| File explorer | Browse device filesystem, pick a folder (push) or multiple files (pull) |
| File picker | Drag-and-drop or system picker for local files; APK-only variant |
| Command queue | Every command with live output, status, timings, device; persisted; re-run; remove; clear |
| Settings | Style (Workbench / Console / Launcher), theme (system / light / dark), AI model |
| About | Version, update check against GitHub latest release, download installer, changelog, GitHub link |
| Reporting | Bug report (zips logs + optional host device info, opens GitHub issue), feature request link |
| Updates | Auto-check on startup → "Update Available" dialog |
| Logging | Daily log files (app, flutter errors, stdout, stderr) in app support dir |

## Tech stack

- **Flutter** 3.47+ (Dart SDK `>=3.8.0 <4.0.0`), Material 3
- **State / DI:** `hooks_riverpod` 2.6 + `flutter_hooks` (providers hand-written, no `riverpod_generator`)
- **Models:** `freezed` 3 + `json_serializable`
- **Persistence:** `shared_preferences` (wrapped by `LocalStorage`)
- **Desktop:** `window_manager`, `desktop_drop`, `file_picker`, `qr_flutter`
- **Other:** `github` (release API), `url_launcher`, `package_info_plus`, `device_info_plus`,
  `archive` (log zip), `logging`, `google_fonts` (Inter, Space Grotesk, JetBrains Mono, IBM Plex), `lottie`, `uuid`, `sliver_tools`

## Non-goals (current)

- No bundled adb binary — the user installs platform-tools.
- No multi-window, no localisation, no automated tests (yet).
