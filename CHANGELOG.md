## Unreleased

- Updates install from inside the app: see what's new in every version since yours, download with progress, then Install and restart (macOS replaces the app; Windows runs the installer silently; Linux updates its folder). Skip a version, or check any time from the palette or About
- The changelog opens in the app and works offline; after an update, "What's new" shows once
- Restart adb (QR dialog, Settings, command palette): fixes QR pairing stuck on "Pairing device…" and Wi-Fi phones that stop showing up
- AI agents: turn on Settings → AI agents to let Claude Code and other MCP clients use your devices (screenshots, taps, logcat, files) and run UI tests; risky actions ask you first, and everything shows in Activity

## 0.0.18

- App icons and names: the Apps tab, uninstall list and "Follow app" show each app's real icon and name (also in work profiles); search by name
- File preview: click a file on the phone to preview it (photos, videos, music, text and logs); Space for a large preview with ← / →
- Push opens the phone's file browser at the last folder you used; "Push files here…" uses your computer's normal file picker, or drop files in
- The AI log filter understands app names ("errors from gmail")
- Fixed: pushes and pulls were reported as failed with adb 37+ even though they worked
- New user guide and troubleshooting pages in docs/
