# Feature: App icons and names (on-device helper)

**Status:** Shipped in 0.0.18 · **Code:** `tool/device_helper/` (Java source + build script),
`assets/device/adbui-helper.jar`, `lib/app/features/apps/`
**Owner / requested by:** owner · **Last updated:** 2026-11-23

## Problem

App lists (Apps tab, uninstall picker, logcat "Follow app") show bare package names with a
generic Android icon. `com.google.android.gm` is not recognisable; "Gmail" with its icon is.
adb has no command that returns an app's label or icon.

## Decision

A tiny helper program runs **on the device** the same way the scrcpy server does: a dex jar
pushed to `/data/local/tmp/adbui-helper.jar` and started with `app_process`. Nothing is
installed, nothing stays running. It asks Android's `PackageManager` for each app's label and
icon (adaptive icons rendered correctly), and prints them. Rejected alternatives: pulling every
APK and reading the icon from it (slow, huge transfers, misses adaptive/vector icons); letter
tiles only (no real names). Letter tiles remain the **fallback**.

## Behaviour

- Apps tab, uninstall picker and the "Follow app" picker show, per app: the **icon** (36 px,
  rounded), the **label** ("Gmail") as the title and the package name under it (mono, muted).
  Search matches label or package.
- While icons load (first time per app), and whenever the helper can't run, a **letter tile**
  shows: the label's (or last package segment's) first letter on a colour picked from the
  package name's hash.
- Starting the helper costs 1.5–5 s over Wi-Fi (app_process VM start), so it runs **once** for
  all apps that aren't cached, returning label and icon together, streamed and shown in groups
  of 12 as they arrive (75 apps ≈ 2 s on a Pixel 10 Pro). Version codes come from
  `pm list packages --show-versioncode` (instant), so cache hits need no helper run. Cached:
  - in memory per device for the session;
  - on disk, icons as PNG keyed by `package@versionCode` in `<app support>/app_icons/`, labels
    in `<app support>/app_icons/labels.json` keyed the same way, so a reopened app shows
    everything instantly and only new/updated apps are asked for.
- The helper runs quietly: not in Activity (like logcat polling). Failures are logged and the
  UI keeps letter tiles and package names; nothing is shown as an error.
- The AI log filter gets labels too ("errors from gmail" works even if "gmail" isn't in the
  package name).

## Helper protocol

`adb shell CLASSPATH=/data/local/tmp/adbui-helper.jar app_process / com.adbui.helper.Main <cmd> [args]`

| Command | Output (stdout, one record per line, tab-separated, flushed per line) |
|---------|------------------------------------------------------|
| `version` | `adbui-helper <n>` |
| `info <size> <pkg>…` | `package \t label \t base64 PNG` (label empty / `-` when unknown or failed) |

- Context: `ActivityThread` created by reflection, `getSystemContext()` (the scrcpy approach);
  `Looper.prepareMainLooper()` first.
- Lookups use `MATCH_UNINSTALLED_PACKAGES | MATCH_ANY_USER` so apps that only exist in a work
  profile (e.g. Island/Shelter) are found, matching `pm list packages`.
- Icons: `ApplicationInfo.loadIcon(pm)` drawn onto a 64 × 64 ARGB bitmap, PNG.
- The jar (from the app's assets, written to the temp folder) is pushed once per device per
  session (it's ~2.6 KB); a failed run clears that so the next request pushes again. Helper
  version: `Main.VERSION` = `AppInfoServiceImpl.helperVersion`.
- Batches of 150 packages per run (command-line length).
- Build: `tool/device_helper/build.sh` (javac `--release 11` against `android.jar`, `d8`,
  zip) → `assets/device/adbui-helper.jar`. The built jar is committed so normal builds don't
  need the Android SDK.

## Data & persistence
- `lib/app/features/apps/`: `AppInfo { package, label?, icon? }`; `AppInfoService`
  (`appInfoServiceProvider`); `appInfoProvider` = `StateNotifierProvider.family<AppInfoController,
  Map<String, AppInfo>, AdbDevice>`; `AppInfoController.ensure(packages)` never throws (failures
  are logged and leave letter tiles); `AppInfoDiskCache`; widgets `AppIcon`, `AppLetterTile`.
- `PackagesList` (Apps tab, uninstall picker, Follow app) calls `ensure` when its list loads,
  sorts named apps by name, and searches label + package.
- AI filter: `AiLogFilterField` waits up to 8 s for labels, then passes `labels` to
  `AiFilterMapper` (system prompt lists `package (Label)`; an app is named when its label appears
  as a whole word).
- Disk cache as above; no `LocalStorageKeys`.

## Acceptance criteria
- [x] Pixel: Apps tab shows real names and icons (verified 2026-11-23, 75 apps incl. a work-profile app).
- [ ] Helper failure (e.g. jar push denied) falls back to letter tiles with no error dialogs.
- [ ] Search by label works.
- [x] Output parsing unit-tested.

## As built (2026-11-23)
- Verified on a Pixel 10 Pro (Android 17) over Wi-Fi in a macOS debug build.
- Not yet checked: helper on old Android (min API 26 in d8), Windows/Linux hosts, second-open
  timing from the disk cache after an app restart.
