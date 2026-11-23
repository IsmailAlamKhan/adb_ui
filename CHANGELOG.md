## Unreleased

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
