# Feature: Error handling and error display

**Status:** Implemented (unreleased) · **Code:** `lib/app/features/errors/`, `lib/app/features/adb/`, `lib/app/features/command_queue/`
**Owner / requested by:** owner · **Last updated:** 2026-11-22

## Problem

Errors reach the user as raw text: `"Failed to install cause adb: failed to install …
INSTALL_FAILED_VERSION_DOWNGRADE …"` in a 4 s snackbar or a popup that closes after 2 s.
They don't say what went wrong in plain words or what to do. Some are wrong
(`No such file or directory` shows "Permission denied"), some crash (`host` without `:port`
throws `RangeError`; a non-numeric port throws `FormatException`), and any stderr output marks
a successful command as failed.

## Model

`AppError` (`errors/errors_model.dart`), immutable:

| Field | Meaning |
|-------|---------|
| `kind` | `ErrorKind` (below) |
| `title` | Short, plain: "Your phone hasn't allowed this computer yet" |
| `message` | One or two sentences on what happened |
| `steps` | `List<String>` — what to do, in order (may be empty) |
| `details` | Raw adb output / exception text, shown in a mono block (may be null) |
| `retryable` | Whether Try again makes sense |

`ErrorCatalogue.explain(Object error, {String? output})` is a **pure function** (unit tested)
that maps an exception and/or raw output to an `AppError`. It never throws; unknown input
gives `ErrorKind.unknown` with the raw text as details. Matching is case-insensitive on the
combined exception message + output.

### Catalogue

| Kind | Matches | Title | Steps (summary) |
|------|---------|-------|-----------------|
| `adbMissing` | `AdbNotFoundException`, `No such file or directory` spawning adb | adb isn't installed or can't be found | Install Android SDK Platform-Tools; make sure `adb` is on your PATH (or add it in `~/.adb_ui`); Try again |
| `environment` | "Error requesting environment" | Couldn't read your shell environment | Check your shell profile for errors; see logs |
| `unauthorized` | `unauthorized` | Your phone hasn't allowed this computer yet | Unlock the phone; accept "Allow USB debugging?"; tick "Always allow" |
| `offline` | `device offline` | The device is offline | Reconnect the cable or toggle Wireless debugging; `adb kill-server` if it persists |
| `noDevice` | `no devices/emulators found`, `device '…' not found` | The device isn't connected anymore | Reconnect it; for Wi-Fi, check it's on the same network |
| `connection` | `failed to connect`, `Connection refused`, `cannot connect`, `No route to host`, `timed out` | Couldn't reach the device | Same Wi-Fi network; check the IP and port in Wireless debugging (the port changes); Android 10 or older needs `adb tcpip` over USB first |
| `pairing` | `Failed to pair`, `Wrong password`, `protocol fault` during pair | Pairing failed | Use the code and port shown under "Pair device with pairing code"; they expire when that dialog closes |
| `installDowngrade` | `INSTALL_FAILED_VERSION_DOWNGRADE` | A newer version is already installed | Uninstall the app first, then install again |
| `installSignature` | `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, `signatures do not match` | The installed app was signed with a different key | Uninstall it first (this removes its data) |
| `installStorage` | `INSTALL_FAILED_INSUFFICIENT_STORAGE` | Not enough space on the device | Free up space and try again |
| `installAbi` | `INSTALL_FAILED_NO_MATCHING_ABIS` | This APK doesn't support the device's processor | Build or download an APK for the device's ABI |
| `installInvalid` | `INSTALL_PARSE_FAILED`, `INSTALL_FAILED_INVALID_APK` | That file isn't a valid APK | Check the file; rebuild it |
| `installOther` | any other `INSTALL_FAILED_*` / `Failure [` | The device refused to install the app | Read the details |
| `notFound` | `No such file or directory` (file ops), `NotFoundException` | That file or folder doesn't exist on the device | — |
| `permission` | `Permission denied`, `PermissionDeniedException` | Android doesn't allow access there | Use a folder under `/sdcard` |
| `uninstall` | `DELETE_FAILED_*`, `Unknown package` | Couldn't uninstall the app | It may be a system app or already removed |
| `scrcpyMissing` | `ScrcpyNotFoundException` | scrcpy isn't installed | Install scrcpy, then restart ADB UI |
| `mdns` | `AdbMdnsUnavailableException` | QR pairing needs a newer adb | Update Android SDK Platform-Tools (31+) |
| `invalidInput` | `InvalidInputException` (our validation) | (the field message) | — |
| `commandFailed` | `CommandFailedException` (non-zero exit of a shell command) | The command exited with code N | Read the details |
| `unknown` | anything else | Something went wrong | Read the details; report a bug from About |

## Where errors are shown

1. **Input validation** never reaches adb: fields show the message inline under the field
   (`host:port` format, port 1–65535, 6-digit pairing code, non-empty text/command).
   Fixes the `RangeError` / `FormatException` crashes.
2. **Command failures** (`AdbController.runForResult`):
   - The activity entry is marked **error**; its row shows the catalogue `title` in
     `danger` colour plus the first step as a hint.
   - An **error toast** appears (bottom right; full width at compact): icon, title, one-line
     message, **Details** and, when `retryable`, **Retry**. It stays 8 s and can be closed with ✕.
     Success toasts: 3 s, "Show output" action.
   - **Details** opens `CommandDetailsDialog` on that entry: status, duration, device, the
     explained error (title, message, numbered steps), then the raw output (mono, selectable),
     with **Copy output**, **Re-run**, **Close**.
3. **Errors outside a command** (e.g. file picker, mDNS, loading a list): `showError(AppError)`
   on `NavigationController` → the same toast with Details opening `ErrorDetailsDialog`
   (same layout without the command header).
4. **In-place loading errors**: `ErrorPanel` with the catalogue title, message, steps and
   **Try again** (only when retryable). It is the default error state of `AsyncValueBuilder`,
   so the file explorer dialog, About and any other user get it too.
5. **Startup errors**: `AppInitErrorView` shows the catalogue page with **Try again** (re-runs
   app init), **Copy details**, **Open logs folder**.
6. **Device state**: an `unauthorized` / `offline` device shows a `warningSoft` banner on its
   page with the catalogue steps; its actions are disabled with that reason as tooltip.

Every error is still written to the log file with its stack trace (`LogFile.instance.dispath`).

## Command completion (fixes 06-known-issues #7)

A command's final state comes from `Result.messege`, not from stream events:
`CommandQueueController.complete(id, message)` / `fail(id, error)` use the buffered
stdout + stderr as output. stderr no longer marks success as error, and output containing the
word "Done" no longer ends a command early. `run()` now also exposes the exit code; a custom
shell command with a non-zero exit fails with `CommandFailedException(exitCode, output)`.
`install` succeeds when stdout contains `Success` (stderr warnings are kept in output).

## Other fixes in this change

- `AppException(message, code)` now keeps `code` (it was dropped).
- `ls`: `No such file or directory` → `NotFoundException` (06 #3).
- `uninstallApp` is awaited (06 #11).
- Pair / connect parse `host:port` with `parseHostPort()` (last `:`; IPv6 in brackets) and
  validate before running (06 #10).

## Acceptance criteria

- [x] Each catalogue row has a unit test from a real adb output sample (`test/error_catalogue_test.dart`).
- [ ] Wrong pairing code → "Pairing failed" toast with steps; Details shows raw output.
- [x] `1.2.3.4` (no port) in Connect by IP → inline field error, no crash (validation unit-tested).
- [ ] A successful install that writes to stderr is shown as done.
- [ ] Unauthorized device → banner with steps, actions disabled with reason.
- [ ] adb missing → init page with steps and a working Try again.
- [ ] Errors readable in all three styles, light and dark (danger tokens pass AA).

Verified live 2026-11-22: explained "Android doesn't allow access there" panel when opening
`/data` in the file explorer; success toast. Not yet seen live: error toast from a failed command.
