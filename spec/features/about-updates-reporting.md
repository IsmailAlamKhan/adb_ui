# Feature: About, update check, bug report

**Status:** Shipped; bug-report flow reworked (unreleased) · **Code:** `about/`, `package_info/`, `update_checker/`

## Update check

> Being replaced by in-app updates and an in-app changelog: see [updates.md](updates.md).

- `PackageInfoService.newVersionAvailable()` gets the latest GitHub release of
  `IsmailAlamKhan/adb_ui` (anonymous API), strips `v` from the tag, compares numerically
  (`X*10000+Y*100+Z`) with the running version.
- **On startup:** `UpdateChecker` (wraps `HomeShell`) runs it once; if newer →
  `UpdateAvailableDialog` with **Later** / **Download**.
- **Download** (`AboutService.downloadUpdates`): opens in the browser the first release
  asset whose name contains `setup-<os>`. No in-app install.

## AboutView

Dialog (600 wide): logo, version, update status banner (from `updateControllerProvider`:
checking / up to date / "ADB UI x is available" → **See update** / couldn't check, with
**Check for updates**), actions **Changelog** (in-app, see [updates.md](updates.md)),
**Licenses**, **GitHub**, the report card, and "a star on GitHub helps".
Opened from Settings → About app, or the macOS app menu.

## Bug report / feature request

Reworked 2026-11-24 (was: pick a folder, zip, **delete the logs**, open a blank template).
GitHub's new-issue page can't take a file from a link and the app has no GitHub sign-in, so
the issue is **pre-filled** and the zip is saved where the user can drag it in one move.

1. `FeatureRequestOrBugReportDialog` (unchanged choice): **Bug report** or **Feature
   request**; for bugs, checkbox **Include this computer's model and OS** (was "Include device
   details to logs"). Returns `{is_bug_report, add_device_details}`.
2. **Bug report** (`AboutController.reportBug`):
   - Zips the logs folder (plus `device_info.json` if ticked) **without asking for a folder**
     into the **Downloads** folder (`getDownloadsDirectory()`; fallback
     `<app support>/reports/`) as `adb-ui-logs-<yyyy-MM-dd-HHmm>.zip`. **Logs are kept** (no
     longer deleted), so a later report still has the history.
   - Shows the zip in the file manager (macOS `open -R`, Windows `explorer /select,`, Linux
     `xdg-open` on the folder).
   - Opens a new issue with label `bug` and a **pre-filled body** (`BugReport.issueUrl`): the
     bug template's sections, **Your setup** filled in automatically (ADB UI version, style, OS
     and version, `adb version` first line, selected phone model / Android version / USB or
     Wi-Fi when a phone is selected), and **Logs**: "Attach `<zip name>` (saved in Downloads)"
     plus a collapsed `<details>` block with the **last log lines**.
   - Toast: **"Logs saved to Downloads"** — "Drag <zip name> onto the GitHub issue that just
     opened." with **Show file**.
3. **Feature request**: opens a new issue (label `enhancement`) pre-filled with the feature
   template's sections and an "ADB UI <version> on <OS>" line. No logs.

### Log excerpt rules (`logExcerpt`)
- Source: today's `log-<day>.txt` (falling back to the newest log file), plus the last
  `flutter-error` entry's first line if any. Only `Messege:` / `Error:` lines; stack traces dropped.
- Cleaned: the home folder becomes `~`; lines mentioning `PATH=` or "environment variables" are
  dropped; each line cut to 300 characters.
- Size: the whole URL stays under **7,000 characters** (GitHub rejects longer ones): oldest
  lines are dropped first, at most 40 lines.
- The user sees and can edit everything before submitting; nothing is sent by the app.

### As built (2026-11-24)
- `about/bug_report.dart`: `logExcerpt`, `BugReportInfo`, `bugIssueUrl`, `featureIssueUrl`
  (no `template=` parameter: the body is built from the templates' sections).
- `LogFile.exportLogs` replaces `getAllLogsAndReset` (no picker, no deleting);
  `LogFile.recentLogLines`. `AdbService.adbVersion()`.
- `AboutController.reportBug` / `featureRequest` / `revealFile`.
- Not clicked through in the running app (it opens the browser and Finder); the pieces are
  unit-tested and checked on real logs.

### Commands
`adb version` (quiet, not in Activity, like `adb devices`) for the setup line.

### Acceptance criteria
- [ ] Bug report: no folder picker; zip lands in Downloads and is revealed; issue opens pre-filled
  with setup and recent log lines; home folder and PATH don't appear.
- [ ] Feature request opens pre-filled with version and OS.
- [x] URL length cap and excerpt cleaning unit-tested (`test/bug_report_test.dart`); also run over
  the real log files on 2026-11-24 (75 lines → 42 kept, 2.4 k-character link, no home folder or PATH).
- [ ] Windows / Linux reveal — not run there.
