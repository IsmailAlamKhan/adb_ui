## Unreleased

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
