# ADB UI

A desktop app for working with Android devices without typing `adb` commands.
Connect a phone over USB, Wi-Fi or a QR code, then install apps, move files, read logs,
mirror the screen and run commands, all from one window. Runs on **Windows, macOS and Linux**.

**[Download the latest release →](https://github.com/IsmailAlamKhan/adb_ui/releases/latest)**

## What it does

- **Connect devices:** plug in a USB cable, scan a QR code (like Android Studio), type a
  pairing code, or connect by IP address.
- **Apps:** see every installed app with its real icon and name, install an APK (or just drop
  it on the window), and uninstall apps from that list.
- **Files:** browse the phone's storage and **preview** files right in the app (photos,
  videos, music, text and logs). Push files to the folder you're in, or pull files back.
- **Logcat:** live device logs with one-click filters for warnings, errors and crashes. It
  can follow one app (even when it restarts) or whatever app is open on the phone.
- **AI log filter:** describe what you want ("network errors from Slack") and get the
  filter. The model runs **on your computer**: your logs and requests never leave it.
- **Screen mirror:** see and control the phone inside the app with mouse and keyboard.
  Buttons for Back, Home, Recents, volume, power, rotate, screenshot and screen recording.
- **Shell and text:** run any adb command, or type text into the phone's focused field.
- **Activity:** every command is recorded with its output, so you can see what happened and
  run it again.
- **Your choice of look:** three styles (Workbench, Console, Launcher), each with a light and
  a dark theme. It also works in a small window.
- **Clear errors:** when something fails, ADB UI says what went wrong and what to try next.
  The raw output is one click away.

## Requirements

| | Needed? | Why |
|---|---|---|
| **adb** (Android platform-tools) | **Required** | ADB UI runs it for everything. ADB UI can install it for you (see below). |
| **scrcpy** | Optional | Smooth, real-time screen mirroring. Without it, the Screen tab shows refreshed screenshots instead. |
| **libmpv** (Linux only) | Required on Linux | Plays the mirrored screen. |
| macOS **14 (Sonoma)** or newer | macOS only | Needed since 0.0.17 for the on-device AI. |

**Let ADB UI install them.** On first launch, and whenever adb is missing, ADB UI opens
**Set up ADB UI**: a list of what's required and what's optional, with an **Install** button for
each. It uses your package manager (Homebrew, winget, or apt/dnf/pacman/zypper) and shows the
exact command before running it. Without a package manager, or if you click **Download
instead**, it downloads the official build (Platform-Tools from Google, scrcpy from its GitHub
releases), checks its checksum and keeps it in its own folder, so you don't need to change your
`PATH`. Nothing is installed without your OK, and on Linux it never runs `sudo` itself: you
copy the command or approve it through `pkexec`. Open it again any time from **Settings → Setup
& requirements** or the command palette.

**Or install them yourself:**

- **macOS** (Homebrew): `brew install android-platform-tools scrcpy`
- **Windows** (winget): `winget install Google.PlatformTools Genymobile.scrcpy`, or download
  [platform-tools](https://developer.android.com/tools/releases/platform-tools) and add the
  folder to your `PATH`.
- **Linux** (Debian/Ubuntu): `sudo apt install adb scrcpy libmpv2` (on older releases
  `libmpv1`).

Check it worked by running `adb version` in a new terminal.

## Install

Get the files from the [releases page](https://github.com/IsmailAlamKhan/adb_ui/releases/latest).

### Windows
- **Installer (recommended):** download `adb-ui-setup-windows.exe` and run it.
- **Portable:** download `adb-ui-windows.zip`, extract it anywhere and run `adb_ui.exe`.

### macOS
1. Download `adb-ui-setup-macos.dmg`, open it and drag **ADB UI** to Applications.
2. The app isn't notarized by Apple yet, so the first time macOS may say it can't be opened.
   Right-click the app and choose **Open**, or go to **System Settings → Privacy & Security**
   and click **Open Anyway**.

### Linux
1. Install `libmpv2` (see Requirements).
2. Download `adb-ui-setup-linux.zip`, extract it (for example to `~/Applications/adb-ui/`) and
   run `adb_ui`.
3. *(Optional)* To get it in your app launcher, open the included `adb-ui.desktop`, replace
   `<Path to the instalation>` with the folder you extracted to, and copy the file to
   `~/.local/share/applications/`.

ADB UI checks for updates when it starts and tells you when a new version is out.

## Quick start

1. On your phone, turn on **Developer options** (Settings → About phone → tap *Build
   number* 7 times), then turn on **USB debugging**.
2. Plug the phone in and tap **Allow** on the "Allow USB debugging?" prompt.
3. Open ADB UI and pick a style (you can change it later in Settings).
4. Your phone appears in the device list. Select it and use the tabs or actions.
5. Press **⌘K** (Ctrl+K on Windows/Linux) to search every action.

To connect **without a cable** (Android 11+), press **⌘N / Ctrl+N** → **QR code**, then on the
phone go to **Developer options → Wireless debugging → Pair device with QR code** and scan.

## Documentation

- **[User guide](docs/user-guide.md):** every feature, step by step: connecting, apps, files,
  logcat, the AI filter, screen mirror, Activity, styles, settings and keyboard shortcuts.
- **[Troubleshooting](docs/troubleshooting.md):** common problems ("no devices", "unauthorized",
  pairing fails, the mirror won't start, macOS won't open the app) and what to do.
- **[Changelog](CHANGELOG-ALL.md):** what changed in each version.

## Privacy

- ADB UI talks to your devices through your own `adb`. It has no account and no analytics.
- It goes online only to check GitHub for updates and, if you choose, to download the AI
  model once from Hugging Face. The AI filter then works offline, and your logs and requests
  stay on your computer.
- Logs of the app itself stay on your computer. They are only shared if you make a bug
  report and attach the zip yourself.

## Reporting bugs and requesting features

In the app: **Settings → About → Report a bug or request a feature**. It saves the app's logs
to a zip you can attach to the GitHub issue it opens. Or open an
[issue](https://github.com/IsmailAlamKhan/adb_ui/issues/new/choose) directly.

## Contributors

Huge thanks to everyone who opened issues and feature requests, tested the app and gave
feedback.

Special thanks to [@roipeker](https://www.github.com/roipeker/) for running the app on macOS
and helping with the macOS build.

## Contributing

ADB UI is built with Flutter. The app is fully specified in [`spec/`](spec/README.md), and
changes are spec-first: update the spec, then the code. See
[`spec/WORKFLOW.md`](spec/WORKFLOW.md).

```bash
flutter pub get
flutter run -d macos   # or windows / linux
```
