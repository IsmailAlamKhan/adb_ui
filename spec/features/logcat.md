# Feature: Logcat

**Status:** Implemented (unreleased) · **Code:** `lib/app/features/logcat/`
**Owner / requested by:** owner · **Last updated:** 2026-11-22

## Problem

Reading device logs means running `adb logcat` in a terminal and grepping by hand. Finding
"my app's logs", following an app across restarts, or spotting crashes is tedious.

## Behaviour

Entry points: Workbench device tab **Logcat**; `DeviceAction.logcat` ("Logcat", ⌘L) in every
style, which opens the full-page `LogcatPage` in Console and Launcher; the palette.

### Stream
- Runs `adb -s ID logcat -v threadtime` (and `-T 1000` so the last 1000 lines show at once).
  This is a long-running session, so it does **not** go into Activity (it would grow forever);
  it still starts through `ProccessAdbServiceImpl` so the user's PATH/env applies.
- Lines are parsed into `LogcatEntry` (time, pid, tid, level V/D/I/W/E/F, tag, message).
  Unparsed lines (e.g. `--------- beginning of main`) are kept as plain entries.
- A ring buffer keeps the last **20,000** entries. Pause freezes the view (the buffer keeps
  filling, a "N new lines" chip shows); Resume jumps back to live.
- Auto-scroll sticks to the bottom until the user scrolls up; a "Jump to latest" chip returns.
- If the process ends (device gone), a banner explains it (error catalogue) with **Restart**.

### Filters (combine with AND)
| Filter | UI | Matching |
|--------|----|----------|
| **Preset** | segmented: All · Warnings+ · Errors+ · Crashes | level ≥ W / ≥ E / crash detector |
| **App** | "Follow app" picker (installed packages) | pid ∈ pids of that package |
| **Foreground** | toggle "Follow foreground app" | as App, package = current top activity |
| Min level | menu V D I W E F | level ≥ min |
| Tags | chips, include or exclude (`-Tag`) | exact tag match |
| Text | search field; `/regex/` for regex | message or tag contains / matches |
| **AI** | "Describe what you want…" | produces the filters above (see [ai-log-filter.md](ai-log-filter.md)) |

- **Follow app:** polls `adb shell pidof <package>` every 2 s. Every pid seen for the package
  stays in the set, so logs from before and after a restart both show; a divider row
  "Process restarted (pid N)" is inserted when a new pid appears. While the app isn't running:
  "Waiting for <package> to start…".
- **Follow foreground app:** polls `adb shell dumpsys activity activities` every 2 s and reads
  the package of `topResumedActivity` (or `mResumedActivity` on older Android); the App filter
  switches to it and the header shows "Following <package> (foreground)".
- **Crash detector:** an entry is a crash line if level F, or tag `AndroidRuntime` with
  `FATAL EXCEPTION`, or tag `ActivityManager` with `ANR in`, or tag `DEBUG` (native tombstone).
  The Crashes preset shows those plus the 40 following lines from the same pid (the stack trace).
- Active filters show as removable chips; **Clear filters** resets.

### Rows
Time · level badge (colour by level, readable in light and dark) · tag (fixed width) · message
(mono, wraps). Crash lines get a danger stripe and "Crash" label. Selection + Copy, **Copy
visible**, **Save…** (writes the visible lines to a `.txt`), **Clear** (`adb logcat -c` after
confirmation, and empties the buffer).

## adb / process commands

| Command | Use | In Activity? |
|---------|-----|-------------|
| `logcat -v threadtime -T 1000` | stream | No (long-running) |
| `shell pidof <pkg>` | follow app | No (polling) |
| `shell dumpsys activity activities` | follow foreground | No (polling) |
| `logcat -c` | clear device buffer | Yes ("Clear logcat") |

## Data & persistence
- `LogcatEntry`, `LogLevel`, `LogcatFilter` (hand-written, immutable) in `logcat_model.dart`.
- `logcatControllerProvider` — `StateNotifierProvider.autoDispose.family<LogcatController, LogcatState, AdbDevice>`.
- Not persisted. Last-used preset is remembered per session only.

## Acceptance criteria
- [ ] Streams live from the Pixel; 20k-line buffer stays smooth (list virtualised).
- [ ] Follow app keeps showing logs after the app is force-stopped and reopened.
- [ ] Follow foreground switches when another app is opened on the phone.
- [ ] Crashes preset shows a FATAL EXCEPTION with its stack trace.
- [ ] Works in all three styles, light and dark, compact width.
- [x] Parser unit-tested on real threadtime lines.

## As built (2026-11-22)
- Rows show time only (`HH:MM:SS.mmm`); date and pid columns hidden at compact width.
- Scrolling up more than 48 px pauses the view; "N new · Jump to latest" resumes.
- Verified on a Pixel 10 Pro: live stream, Errors+ preset, Follow foreground app (switched to the
  launcher, marker row shown). Not yet checked live: Follow app across a force-stop, a real crash.
