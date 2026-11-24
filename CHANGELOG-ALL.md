## 0.0.20

- Fixed: Setup & requirements said adb and scrcpy were "Not found" even when they were installed and working
- The app is called ADB UI everywhere (title bar, About, menus, Windows installer); it said "Adb ui" in places

## 0.0.19

- Bug reports fill in the GitHub issue for you (version, OS, adb, phone and recent log lines, with your home folder and PATH removed) and save the logs to Downloads ready to attach, with no folder to pick. Logs are no longer deleted after a report
- Updates install from inside the app: see what's new in every version since yours, download with progress, then Install and restart (macOS replaces the app; Windows runs the installer silently; Linux updates its folder). Skip a version, or check any time from the palette or About
- The changelog opens in the app and works offline; after an update, "What's new" shows once
- Restart adb (QR dialog, Settings, command palette): fixes QR pairing stuck on "Pairing device…" and Wi-Fi phones that stop showing up
- AI agents: turn on Settings → AI agents to let Claude Code and other MCP clients use your devices (screenshots, taps, logcat, files) and run UI tests; risky actions ask you first, and everything shows in Activity
- Setup & requirements: on first launch (and whenever adb is missing) ADB UI checks for adb, scrcpy, libmpv and the AI model, and installs what's missing with your OK, through Homebrew, winget or apt/dnf/pacman/zypper, or by downloading the official, checksum-checked build into its own folder. Open it again from Settings or the command palette

## 0.0.18

- App icons and names: the Apps tab, uninstall list and "Follow app" show each app's real icon and name (also in work profiles); search by name
- File preview: click a file on the phone to preview it (photos, videos, music, text and logs); Space for a large preview with ← / →
- Push opens the phone's file browser at the last folder you used; "Push files here…" uses your computer's normal file picker, or drop files in
- The AI log filter understands app names ("errors from gmail")
- Fixed: pushes and pulls were reported as failed with adb 37+ even though they worked
- New user guide and troubleshooting pages in docs/

## 0.0.17

- Logcat: live device logs with Errors/Warnings/Crashes presets, search and regex, and filters that follow an app (even across restarts) or whatever app is open
- AI log filters: describe what you want ("network errors from Slack"); a small model runs on your computer, logs never leave it
- Screen mirror inside the app (via scrcpy) with Back/Home/Recents, volume, power, rotate, screenshot, screen recording and paste; falls back to screenshots without scrcpy
- Redesigned the device file chooser (starts in /sdcard, quick places, breadcrumbs), About, bug report and update dialogs
- Folders and files on the device are now detected and sorted correctly

## 0.0.16

- New look, in three styles you pick on first launch or in Settings: Workbench, Console and Launcher, each in light and dark
- Pick a device once; actions, a command palette (⌘K) and keyboard shortcuts work on it
- Add device: QR code, pairing code and IP address in one place (no more "Android 11?" question)
- Pair with a QR code, like Android Studio
- Uninstall picks from installed apps; Apps, Files, Shell and Type text tabs (Workbench)
- Drop an APK anywhere to install it
- Errors now say what went wrong and what to do, with the raw output one click away
- Command output stays in Activity instead of a popup that closes after 2 seconds
- Works down to a 480 × 560 window
- Logs no longer contain your shell environment
## 0.0.15

- Fixed input text bug
- Fixed the ui problem on about page
- Re-arrenged the device options(commands)
- Added new device options(commands)
  - Uninstall apk
- Added cancel button on connect wireless dialog
## 0.0.14

- Fix app initialization
## 0.0.13

- Command queue will persist across restarts
- Added timestamps to command queue
# 0.0.12

- Added Linux support

# 0.0.11

- Update checker is improved.
- Added support for Mac os(thanks to [@roipeker](!https://www.github.com/roipeker/)).

# 0.0.10

- Recreate about page and added check for update there([#13](https://github.com/IsmailAlamKhan/adb_ui/issues/13))
- Moved report from settings to about page
- Auto update check on app startup([#13](https://github.com/IsmailAlamKhan/adb_ui/issues/13))

# 0.0.9

- Wireless connect for Android devices older than android 11 .
- Implemented features
  1. Input text to device

# 0.0.8

- Closed issue #12
- Add a checkbox in file pull/ push to indicate the selected state.

# 0.0.7

- Closed issue #7.
- Implemented features
  1. open scrcpy if its available.

# 0.0.6

- Closed issues #9 #2 #8 #4 #10, tons of thanks goes to ![clragon](https://github.com/clragon) for those feedbacks
- Add about page.
- Check for ADB in the app startup

# 0.0.5

- App can collect logs and can be used to create github issues.

- Implemented features
  1. Change theme within app

# 0.0.4

- Implemented features
  1. Command queue

# 0.0.3

Updated app interface, chagned logo and title name, custom title bar. And added msix installer

# 0.0.2

- Imlemented features
  1. File pull.
  2. Run custom commands.

# 0.0.1

- Implemented features:
  1. File push
  2. Install apk
