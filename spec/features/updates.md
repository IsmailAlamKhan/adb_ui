# Feature: In-app updates and changelog

**Status:** Shipped in 0.0.19 · **Code:** `lib/app/features/update_checker/`, `about/`,
`assets/CHANGELOG-ALL.md` (bundled copy)
**Owner / requested by:** owner · **Last updated:** 2026-11-24

## Problem

- An update is offered as soon as a GitHub release exists, even before this computer's
  installer is uploaded (v0.0.18's `.dmg` arrived an hour late; **Download** silently did
  nothing on macOS meanwhile).
- **Download** only opens the browser; the user installs by hand.
- The popup shows on every launch, with no way to skip a version, and updates are only
  checked at startup.
- "What's new" opens GitHub; after updating nothing says what changed.
- Version compare crashes on tags like `0.0.19-beta` and breaks for numbers ≥ 100.

## Behaviour

### Checking
- On startup (after the style picker) and then **every 6 hours** while the app runs; also
  **Check for updates** in the command palette and in About (with "You're up to date" /
  error feedback when run by hand).
- Asks GitHub for the latest **30 releases** of `IsmailAlamKhan/adb_ui` (anonymous API),
  ignoring drafts and pre-releases.
- The offered update is the **newest release newer than this version that has this OS's
  installer** (`*-setup-macos.dmg`, `*-setup-windows.exe`, `*-setup-linux.zip`). A release
  whose installer isn't uploaded yet is skipped until it is.
- Versions are compared component by component (`1.2.10 > 1.2.9`), a leading `v` dropped,
  anything after `-`/`+` ignored for the number; an unparsable tag is skipped.

### The update popup
Shown automatically when an update is found, unless the user chose **Skip this version** for
that version (a newer one shows again). Title **"ADB UI <version> is available"**, subtitle
"You have <current>."; then the release notes of **every version between yours and the new
one**, newest first, rendered in the app (headings and bullets), scrollable. Buttons:
**Skip this version**, **Later**, **Update** (primary).

### Updating (Update)
1. Download the installer inside the app into `<app support>/updates/`, with a progress bar
   ("Downloading 12.4 of 54.2 MB") and **Cancel**. The file's size must match the size
   GitHub reports, else "The download was incomplete" + **Try again**.
2. When it's downloaded: "Ready to install. ADB UI will close, update and reopen." with
   **Install and restart** (and **Later**, which keeps the file for next time).
3. Install, per platform, from a small detached script that waits for ADB UI to quit:
   - **macOS:** `hdiutil attach -nobrowse -readonly` the `.dmg`, copy `ADB UI.app` over the
     running app's bundle (`ditto`), detach, `open` the new app. Only when the running
     bundle's folder is writable and the app isn't running from the `.dmg`/a translocated path;
     otherwise open the `.dmg` and show "Drag ADB UI to Applications, replacing the old one".
   - **Windows:** run the downloaded `setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
     /CLOSEAPPLICATIONS` (Inno Setup reuses the existing install folder via `AppId`), then
     start the installed `adb_ui.exe` again.
   - **Linux:** unzip into a temp folder and copy it over the running bundle folder (the
     folder of the running executable), then start it again. Only if that folder is writable;
     otherwise show the folder with the zip and steps.
   The app then quits. If anything fails before quitting, the explained error shows with
   **Download in browser** (opens the asset URL) as a fallback.
4. Downloaded installers are deleted on the next start after a successful update.

### Changelog
- `CHANGELOG-ALL.md` is **bundled** with the app (copied into `assets/` at release time and
  in the repo), so the changelog works offline.
- **About → Show changelog** and the palette's **What's new** open an in-app **Changelog**
  dialog: every version, newest first, the running version marked "Installed".
- **After an update**, on the first start of a new version, a **"What's new in <version>"**
  dialog shows that version's notes once (stored `lastSeenVersion`). A fresh install only
  stores the version, no dialog.
- Notes format: `## <version>` headings, `- ` bullets, other lines as paragraphs.

## Data & persistence
- `AppVersion` (parse/compare), `AppRelease { version, tag, notes, assets }`,
  `ReleaseAsset { name, url, size }`, `ChangelogEntry { version, lines }` +
  `parseChangelog(markdown)`.
- `UpdateService` (GitHub releases, download with progress, platform installers),
  `updateServiceProvider`.
- `updateControllerProvider` = `StateNotifierProvider<UpdateController, UpdateState>`;
  `UpdateState { status (idle/checking/upToDate/available/downloading/ready/failed), release?,
  notes, received, total, file?, error? }`.
- `LocalStorageKeys.updates` → `{ skippedVersion?, lastSeenVersion? }`.

## Files to touch
- `update_checker/` (model, service, controller, views, barrel), `about/` (use the new
  controller; drop `downloadUpdates`), `package_info/` (old compare removed), `palette_view.dart`,
  `local_storage.dart`, `pubspec.yaml` assets, `.github/workflows/*` (nothing: assets are
  in the repo), release steps in `05-build-and-release.md` (copy `CHANGELOG-ALL.md` into
  `assets/`).
- Spec: this file, `about-updates-reporting.md`, `README.md`, `03-data-models.md`,
  `01-architecture.md`; docs: `docs/user-guide.md`.

## Acceptance criteria
- [x] A release without this OS's installer isn't offered. *(Unit-tested.)*
- [ ] Skip this version hides that version only.
- [x] macOS: Update downloads, replaces the app and reopens it on the new version. *(Verified 2026-11-24: debug build faking 0.0.17 → dialog with 0.0.18 notes → Update → Install and restart → reopened as the real 0.0.18. The install script alone was also run against the 0.0.18 `.dmg`.)*
- [ ] Windows / Linux install paths — not testable here; built per the steps above.
- [ ] What's new shows once after an update; changelog dialog works offline.
- [x] Version compare, changelog parsing and installer selection unit-tested (`test/updates_test.dart`).

## As built (2026-11-24)
- `update_checker/`: `update_model.dart` (`AppVersion`, `InstallerAsset` — named so it doesn't
  clash with `github`'s `ReleaseAsset` —, `AppRelease`, `pickUpdate`, `releasesBetween`,
  `ChangelogEntry`, `parseChangelog`, `releaseNoteLines`, `UpdateState`, `UpdatePrefs`),
  `update_service.dart`, `update_controller.dart` (uses `NavigationController` to show its
  own dialogs, so the 6-hourly check can prompt), `update_view.dart` (`UpdateChecker`,
  `UpdateDialog`, `WhatsNewDialog`, `ChangelogDialog`, `ReleaseNotesView`).
- The changelog is bundled straight from the repo root (`pubspec.yaml` assets list
  `CHANGELOG-ALL.md`), so there's no copy to keep in sync.
- `AboutService` was removed (only held the old check/download); `AboutController.build`
  returns `AboutModel.updateNotAvailable`, About's status banner reads
  `updateControllerProvider`. `PackageInfoService` keeps only `getPackageInfo`.
- Quitting for an install uses `exitApplication(AppExitType.cancelable)` so the AI model is
  freed first.
- Not checked: Windows and Linux installs, "What's new" after a real update (needs the next
  release), the 6-hourly re-check, Skip this version in the UI.

## Testing
Debug builds accept `--dart-define=ADB_UI_FAKE_VERSION=<version>` to pretend to be an older
version (ignored in release builds). Installing then replaces the debug app bundle.

## Out of scope
- Code signing / notarization (not set up for the project).
- Delta updates, background silent installs without asking.
