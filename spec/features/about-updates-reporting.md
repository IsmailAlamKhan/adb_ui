# Feature: About, update check, bug report

**Status:** Shipped · **Code:** `about/`, `package_info/`, `update_checker/`

## Update check

- `PackageInfoService.newVersionAvailable()` gets the latest GitHub release of
  `IsmailAlamKhan/adb_ui` (anonymous API), strips `v` from the tag, compares numerically
  (`X*10000+Y*100+Z`) with the running version.
- **On startup:** `UpdateChecker` (wraps `HomeView`) runs it once; if newer →
  `UpdateAvailableDialog` with **Later** / **Download**.
- **Download** (`AboutService.downloadUpdates`): opens in the browser the first release
  asset whose name contains `setup-<os>`. No in-app install.

## AboutView

Dialog (600 wide): logo, update status (`_UpdateChecker` using `aboutControllerProvider`,
with download button), "Current version: X", report link, actions **Show licenses**,
**Show changelog** (opens `changelogUrl`), and "Please star the repo on GitHub".
Opened from Settings → About app, or the macOS app menu.

## Bug report / feature request

1. `FeatureRequestOrBugReportDialog`: choose **Bug report** or **Feature request**;
   for bugs, checkbox **Include device details to logs**. Returns
   `{is_bug_report: bool, add_device_details: bool}`.
2. Feature request → opens GitHub new-issue URL with `feature_request.md` template.
3. Bug report → `LogFile.getAllLogsAndReset(device?)`: user picks a folder, logs dir is
   zipped to `logs-<Mon>-<day>.zip` (+ `device_info.json` of the host if opted in), then
   **the logs dir is deleted** and recreated. Success alert, then opens the bug-report
   issue URL so the user can attach the zip.
