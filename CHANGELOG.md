## Unreleased

- Fixed: the "Drop to install" overlay showed its text with yellow underlines
- Fixed (Windows): after installing adb or scrcpy from Setup, ADB UI said it still couldn't find it until you restarted the app
- A new look for first-run setup: a small fixed window with two steps (pick a look, then get your tools ready), a readiness summary, and clearer status for each tool

## 0.0.21

- Install APK asks which profile to install on when your phone has a work profile, Private space or another user (it used to land in the work profile on some phones). Phones with one profile install as before
- AI agents: `install_apk` installs to your personal profile unless a profile is given
