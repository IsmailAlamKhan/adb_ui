# Feature: Setup & requirements (first-run onboarding)

**Status:** Shipped in 0.0.19 · **Code:** `lib/app/features/setup/`, `test/setup_test.dart`, `test/setup_view_test.dart`
**Owner / requested by:** owner · **Last updated:** 2026-11-24

## Problem

ADB UI needs `adb` and works better with scrcpy, libmpv (Linux) and the on-device AI model.
Today a missing adb ends on the startup error screen with "install Platform-Tools and fix
your PATH", and the optional tools are only mentioned when something fails. People should
see what's needed in one place and install it from the app, with their permission.

Chosen design (2026-11-24, option B of three): **package manager first**. Installs go
through Homebrew (macOS), winget (Windows) or apt/dnf/pacman/zypper (Linux); when there is
no package manager, or the user prefers it, the app downloads the official archive into its
own folder instead.

## Behaviour

### Where it appears

| Entry | When | Mode |
|-------|------|------|
| After the style picker | First launch: **Continue** on the picker opens Setup before home | `firstRun` |
| Instead of the startup error | Startup found no working adb (`AdbNotFoundException` from `verifyAdb`) | `adbMissing` |
| Settings → **Setup & requirements** | Any time (row under a new "Setup" section, opens as a page) | `manual` |
| Command palette → **Setup & requirements** (App section, keywords "install requirements adb scrcpy") | Any time | `manual` |

Other startup errors (for example "Couldn't read your shell environment") still go to the
startup error screen. The error screen for adb missing is no longer shown at startup.

### The page

Title **"Set up ADB UI"**, subtitle "ADB UI checks what it needs on this computer. Nothing is
installed without your OK." In `adbMissing` mode a `warningSoft` `AppBanner` says
"adb wasn't found. ADB UI needs it to talk to your devices."

A line under the title names the installer: "Installs use Homebrew." / "Installs use winget."
/ "Installs use apt (needs your administrator password)." / "No package manager found.
Installs download from the official site into ADB UI's own folder."

Two sections, **Required** and **Optional**. Each row:

- status dot + name + one-line purpose;
- status: `Checking…` · `Found · <version>` (+ path, muted) · `Installed by ADB UI · <version>`
  · `Not found` · `Installing…` · `Install failed` (with the explained error's title);
- under a missing item, the primary method in mono (`describeMethod`): `↳ brew install scrcpy`,
  `↳ sudo apt-get install -y adb` (root commands are shown with `sudo` so they can be pasted
  into a terminal), or `↳ download Platform-Tools from dl.google.com (Google) into ADB UI's folder`;
- buttons: **Install** (primary method), and **Download instead** when a download
  alternative exists next to a package-manager method. Linux root methods show
  **Install…** which opens the consent dialog below.

| Item | Required | Platforms | Purpose line |
|------|----------|-----------|--------------|
| adb (Android SDK Platform-Tools) | yes | all | "Talks to your phones. ADB UI can't work without it." |
| scrcpy | no | all | "Live screen mirror. Without it, the mirror uses screenshots." |
| libmpv | no | Linux only | "Plays the live mirror video inside ADB UI." (The Linux build links libmpv, so in practice the app only starts when it's there and the row shows Found; it stays non-blocking so a failed `ldconfig` check can't lock anyone out.) |
| AI log-filter model | no | all | The existing `AiModelSetupCard` (compact), unchanged |

Footer: **Check again** (re-detects everything) · **Install required** (only while a
required item is missing; runs the consent flow for each missing required item in turn) ·
**Continue** (`firstRun` / `adbMissing`: enabled only when every required item is found;
opens home) or **Done** (`manual`: closes the page).

A log panel (`TerminalBlock`) under the list shows the live output of the running install
and stays until the next install. Only one install runs at a time; other Install buttons are
disabled meanwhile.

### Consent (every install)

Nothing is run or downloaded before the user confirms a dialog:

- Title "Install <name>?"
- For a package manager: "ADB UI will run this command:" + the exact command (mono,
  selectable, **Copy**). winget commands include `--accept-package-agreements`; the dialog
  says "This accepts the package's licence agreement."
- For a download: "ADB UI will download:" + full URL, the checksum it will check
  ("SHA-1 from Google's repository index" / "SHA-256 from the release's SHA256SUMS.txt"),
  and the folder it unpacks into. No admin rights needed.
- For a command that needs root (Linux): "This command installs it:" + `sudo <command>`, and
  an info banner "This needs administrator rights". Buttons: **Copy command** (copies the
  `sudo` line and closes; the user runs it in a terminal, then **Check again**) and, only when
  `pkexec` exists, **Run with pkexec** (runs `pkexec <command>`; the system asks for the
  password). The app itself never runs `sudo`.
- Cancel leaves everything as it was.

### After an install

The item is re-detected. Success → success toast "<label> is installed". If the command
succeeded but the tool still isn't found, that is reported as `InstallFailedException`
("…still can't find …. Click Check again, or restart ADB UI."). Failure → the row
shows the explained error and an error toast (Details opens the explanation with the raw
output). On success `scrcpyAvailableProvider` is invalidated so the mirror picks scrcpy up
without a restart.

## Install methods

`InstallPlanner.plansFor(requirement, host)` is a **pure function** (unit tested). `host` =
OS, CPU arch, available package managers, `pkexec` present. It returns the methods in order;
the first is primary, a download method after a package-manager method is the alternative.

| Requirement | macOS | Windows | Linux |
|-------------|-------|---------|-------|
| adb | `brew install --cask android-platform-tools` | `winget install --id Google.PlatformTools -e --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity` | apt `apt-get install -y adb` · dnf `dnf install -y android-tools` · pacman `pacman -S --noconfirm android-tools` · zypper `zypper --non-interactive install android-tools` |
| adb fallback | Google download | Google download | Google download |
| scrcpy | `brew install scrcpy` | `winget install --id Genymobile.scrcpy -e …` (same flags) | apt `scrcpy` · pacman `scrcpy` · zypper `scrcpy` (dnf: none, Fedora ships it only in COPR) |
| scrcpy fallback | GitHub download (aarch64 / x86_64) | GitHub download (win64 / winarm64; win32 on x86) | GitHub download (x86_64 only) |
| libmpv | — | — | apt `libmpv2` · dnf `mpv-libs` · pacman `mpv` · zypper `libmpv2`; no download fallback; without a package manager the row says "Install libmpv with your system's package manager." |

Linux package-manager commands need root: they run as `pkexec <command>` after consent.
Package managers are detected in this order and the first found is used: macOS `brew`;
Windows `winget`; Linux `apt-get`, `dnf`, `pacman`, `zypper`.

### Downloads (fallback)

Only official sources:

- **Platform-Tools:** read `https://dl.google.com/android/repository/repository2-3.xml`,
  take the `remotePackage path="platform-tools"` on `channel-0`, the archive for the host OS
  (`macosx` / `windows` / `linux`), its `url`, `size` and SHA-1. Download
  `https://dl.google.com/android/repository/<url>`, check size and SHA-1.
- **scrcpy:** latest release of `Genymobile/scrcpy` from the GitHub API (`githubProvider`);
  the asset `scrcpy-<platform>-v<ver>.(zip|tar.gz)` and `SHA256SUMS.txt`; the SHA-256 of the
  asset must match its line in `SHA256SUMS.txt`. A release without `SHA256SUMS.txt` is
  refused.
- A mismatch deletes the file and fails with `ChecksumMismatchException`.

Archives are unpacked (package `archive`) into a temp folder, then moved to
`<app support>/tools/platform-tools/` or `<app support>/tools/scrcpy/` (the single top-level
folder of the archive is flattened), replacing an earlier copy. Entries with any execute bit
are `chmod +x` on macOS/Linux. The downloaded archive is deleted afterwards.

## Finding tools without editing PATH

`ToolPaths` (`setup/tool_paths.dart`) is initialised in `App.init` before `verifyAdb`. Every
process the app starts (`ProccessAdbServiceImpl.run` / `startProcess`, setup detection,
installs) gets an environment whose `PATH` is the user's PATH with these appended (user's
own tools win):

- `<app support>/tools/platform-tools`, `<app support>/tools/scrcpy`;
- macOS: `/opt/homebrew/bin`, `/usr/local/bin` (Homebrew, when the shell profile lacks it);
- Windows: `%LOCALAPPDATA%\Microsoft\WinGet\Links` (winget portable packages; the running
  app's PATH is not refreshed by winget).

`appendToPath(path, dirs, separator)` is pure (unit tested): skips dirs already present,
keeps order, uses `;` on Windows and `:` elsewhere. On Windows the existing `Path`/`PATH`
key is reused case-insensitively. The live mirror finds scrcpy and `scrcpy-server` in the
app's scrcpy folder first.

## Detection

`SetupService.detect()` runs each check with that environment and a 10 s timeout:

| Item | Check | Parser (pure, unit tested) |
|------|-------|----------------------------|
| adb | `adb version` | `parseAdbVersion` → adb version, Platform-Tools version (`Version 37.0.3-…`), `Installed as` path |
| scrcpy | `scrcpy --version` | `parseScrcpyVersion` → `scrcpy 3.1 <…>` → `3.1` |
| libmpv | `ldconfig -p` (also `/sbin/ldconfig`) | `parseLibmpv` → first `libmpv.so.N` |
| package managers | `command -v <name>` (Unix) / `where <name>` (Windows) | — |
| AI model | `aiControllerProvider` state | — |

A found tool whose path is under `<app support>/tools` is shown as "Installed by ADB UI".

## adb / process commands

Not adb commands, so they don't go through `AdbController.run` and don't appear in Activity;
their output is shown in the page's log panel and written to the log file.

| Command | Success when |
|---------|--------------|
| `adb version`, `scrcpy --version`, `ldconfig -p` | exit 0 and the parser finds a version |
| package-manager install (table above) | exit 0 and the re-detection finds the tool |
| `pkexec …` | as above; exit 126/127 → "Administrator permission was not given" |

## Data & persistence

- `setup_model.dart`: `enum Requirement { adb, scrcpy, libmpv, aiModel }` (`label`,
  `purpose`, `required`), `enum PackageManager { brew, winget, apt, dnf, pacman, zypper }`,
  `HostInfo` (os, arch, managers, hasPkexec), `ToolStatus` (found, version, path,
  managedByApp), `InstallMethod` (sealed: `PackageManagerInstall(manager, args, needsRoot)`,
  `DownloadInstall(source)`, `ManualInstall(text)`), `SetupState` (host, statuses, running
  requirement, log lines, per-item `AppError`), `SetupMode { firstRun, adbMissing, manual }`.
- Providers: `setupServiceProvider` (`Provider<SetupService>`),
  `setupControllerProvider` (`StateNotifierProvider<SetupController, SetupState>`),
  `setupGateProvider` (`StateProvider<SetupMode?>`: non-null shows Setup before home).
- No `LocalStorageKeys` entry: whether Setup shows is decided per launch (first run comes
  from the picker; adb missing from startup).
- New exceptions (`setup_model.dart`): `InstallFailedException(requirement, exitCode,
  output, viaPkexec)`, `DownloadFailedException(url, reason)`,
  `ChecksumMismatchException(url, expected, actual)`. Catalogue kinds `setupInstall`,
  `setupPermission`, `setupDownload`, `setupChecksum` (see error-handling.md).

## Files to touch

- `lib/app/features/setup/` (new): `setup.dart` barrel, `setup_model.dart`,
  `install_planner.dart`, `tool_paths.dart`, `setup_service.dart`, `setup_controller.dart`,
  `setup_view.dart`; `features.dart` barrel.
- `lib/app/app.dart` (ToolPaths init, adb-missing → Setup, gate), style picker Continue,
  `adb_service.dart` (environment), `mirror_controller.dart` (scrcpy lookup), settings view,
  palette, error catalogue + model.
- `pubspec.yaml`: `crypto` as a direct dependency (was transitive).
- Specs: `README.md`, `01-architecture.md`, `03-data-models.md`, `04-ui-conventions.md`,
  `features/error-handling.md`, `features/app-styles.md`, `features/settings.md`,
  `features/screen-mirror.md`, `05-build-and-release.md` (dependency).

## Acceptance criteria

- [ ] Fresh install: picker → Setup → Continue → home.
- [ ] adb removed from PATH: launch opens Setup in `adbMissing` mode; Continue is disabled
      until adb is installed/found.
- [ ] macOS with Homebrew: Install on scrcpy shows `brew install scrcpy`, runs it after OK,
      the row turns "Found".
- [ ] Download instead for adb puts Platform-Tools in `<app support>/tools/platform-tools`,
      SHA-1 checked, and adb works without editing PATH (also after a restart).
- [ ] Linux: a root command is never run without the dialog; Copy command works without pkexec.
- [ ] Wrong checksum → explained error, file removed.
- [x] Unit tests: parsers, `InstallPlanner`, `appendToPath`, repository-XML and SHA256SUMS
      parsing, catalogue rows (`test/setup_test.dart`).
- [x] Widget tests: Setup page (Linux/apt adb missing, macOS first run at 480 px) and the
      consent dialog (root with/without pkexec, download) render without errors
      (`test/setup_view_test.dart`).
- [x] Checked live 2026-11-24 (macOS arm64): the real `repository2-3.xml` parses, the
      Platform-Tools 37.0.3 zip matches its SHA-1, unpacks with execute bits, and its `adb
      version` parses. Not yet checked: the full flow inside the running app.
- [ ] Works on Windows / macOS / Linux.

## Out of scope

Updating tools the user installed themselves; uninstalling; installing Homebrew or winget
themselves (the page links to brew.sh / the App Installer page when missing); Android Studio.

## Open questions

None.
