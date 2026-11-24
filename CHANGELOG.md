## Unreleased

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
