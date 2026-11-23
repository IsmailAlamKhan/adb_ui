# Feature: Pair & connect with QR code

**Status:** Shipped in 0.0.16 · **Code:** `lib/app/features/qr_pair/`, `AdbService.mdnsServices`, `AdbMdnsService`
**Requested by:** owner · **Last updated:** 2026-11-22

## Problem

Android 11+ "Wireless debugging" can pair by scanning a QR code, but only Android Studio
offers that today. In ADB UI the user must read a 6-digit code and an `ip:port` off the
phone, type them into **Pair**, then type another `ip:port` into **Connect wireless**.

## How the protocol works (same as Android Studio)

1. The host makes a random **service name** and **password** and shows them as a QR code
   with the payload `WIFI:T:ADB;S:<service name>;P:<password>;;`.
2. The phone (Developer options → Wireless debugging → **Pair device with QR code**) scans it
   and advertises the mDNS service `_adb-tls-pairing._tcp` whose **instance name is the
   service name**, on a random port.
3. The host finds it with `adb mdns services` and runs `adb pair <ip>:<port> <password>`.
   Success output: `Successfully paired to <ip>:<port> [guid=<adb-SERIAL-xxxxxx>]`.
4. The phone then advertises `_adb-tls-connect._tcp` with instance name = that guid.
   Recent adb servers auto-connect; otherwise the host runs `adb connect <ip>:<port>`.

"Connect via QR" therefore means: **one scan pairs and then connects automatically.**
Android has no QR flow for connecting without pairing; after a device has been paired
once, the existing **Connect wireless** flow (or adb's own auto-connect) covers it.

## Behaviour

Entry points (redesign, 2026-11-22): **Add device → QR code** (`AddDeviceDialog`, the default
tab) in Workbench and Console; Launcher opens the full-page **"Scan to pair."** screen
(`QrPairPage`) with a countdown status line, "Use a pairing code instead" and "Connect by IP".
Also ⌘N and the palette. Both use `QrPairPanel` / `QrCodeTile` / `QrPairStatusView` and close
2 s after connecting. Failures show the explained error (`QrPairState.error`) with steps.
The description below is the original dialog's behaviour, which the panel keeps:

- Title **"Pair with QR code"**.
- QR code (always on a white background so it scans in dark theme), 220 px.
- Status line **directly under the QR code** (so it's visible without scrolling in small windows).
- Steps:
  1. "On your phone open Developer options → Wireless debugging (Android 11+)."
  2. "Tap **Pair device with QR code** and scan this code."
  3. "Your phone and this computer must be on the same Wi-Fi network."
- Status line, by state:

| State | Shown | Actions |
|-------|-------|---------|
| `waitingForScan` | spinner + "Waiting for your phone to scan the code…" | Cancel |
| `pairing` | spinner + "Pairing with `<ip>`…" | Cancel |
| `connecting` | spinner + "Paired. Connecting to `<ip>`…" | Cancel |
| `connected` | ✓ "Connected to `<device id>`" — dialog **closes automatically after 2 s** | Done |
| `pairedNotConnected` | ⚠ "Paired, but couldn't connect automatically. Use **Connect wireless** with the IP and port shown on your phone." | New code, Close |
| `failed` | ⚠ error message | New code, Close |

- Waiting for a scan times out after **2 minutes** → `failed` ("Timed out waiting for the
  QR code to be scanned."). Auto-connect waits up to **30 s** → `pairedNotConnected`.
- **New code** generates a fresh name/password and restarts from `waitingForScan`.
- Closing the dialog at any point stops all polling (provider is `autoDispose`).
- `adb mdns` missing/unsupported (old platform-tools) → `failed` with
  "mDNS discovery isn't available in your adb. Update Android platform-tools." + adb's stderr.
- When connected, the device appears in the home list through the normal 1 s polling.

## adb / process commands

| Command | Success when | Message | In queue? | Re-runnable? |
|---------|--------------|---------|-----------|--------------|
| `adb mdns services` (poll every 1 s) | stderr empty or stdout non-empty | parsed list | No (like `devices`) | — |
| `adb pair ip:port password` | stdout contains `Successfully paired` | stdout | Yes, label `QR pair with <ip>:<port>`, no output dialog | Yes (`pair`) |
| `adb connect ip:port` | existing `connect` check | `Connected to …` | Yes, label `Connect to <ip>:<port>`, no output dialog | Yes |

Changes to existing behaviour that ship with this feature:
- `AdbService.pair` now **fails** (throws in `messege`) unless stdout contains
  `Successfully paired`. Before, every pair counted as success. Applies to manual Pair too.
- `rerunCommand` gains a `pair` case (`arguments = [host:port, code]`) — previously
  re-running a pair threw "Command not found".
- `AdbController.runForResult(...)` added: same as `run` but returns the success message
  (or `null` on failure) so flows can continue after a command. `run` delegates to it.

## Connect detection (after pairing)

Poll every 1 s for up to 30 s:
1. `getConnectedDevices()` — done if an online device's id contains the guid, or starts with `<ip>:`.
2. Only after a **5 s grace period** (to let adb's own mDNS auto-connect happen first and
   avoid the device being connected twice, once as `adb-<guid>._adb-tls-connect._tcp` and
   once as `<ip>:<port>`), find `_adb-tls-connect._tcp` in `mdnsServices()` whose name equals the guid
   (or, if no guid was parsed, whose host equals the paired ip) and run `adb connect` once.
   Success → `connected` with `<ip>:<port>`.

## Data

- `AdbMdnsService` (plain immutable class with `==`/`hashCode`, `adb_model.dart`): `name, type, host, port`; getters
  `isPairing` (`_adb-tls-pairing._tcp`), `isConnect` (`_adb-tls-connect._tcp`);
  `static List<AdbMdnsService> parseList(String stdout)` — skips the header and blank
  lines, splits on whitespace, tolerates a trailing `.` on the type, splits address on
  the **last** `:`; skips malformed lines.
- `QrPairCode` (`qr_pair_model.dart`): `serviceName` = `adbui-` + 10 random alphanumerics,
  `password` = 12 random alphanumerics (`Random.secure`), `qrData` getter. Alphanumerics
  only, so no escaping is needed in the `WIFI:` payload.
- `QrPairState` (plain immutable class with `copyWith`): `code, status (QrPairStatus), host?, deviceId?, message?`.
- Both are hand-written (no codegen) — small, fully unit-tested, and they don't need JSON.
- `qrPairControllerProvider`: `StateNotifierProvider.autoDispose<QrPairController, QrPairState>`.
- Nothing persisted.

## Files to touch

- `pubspec.yaml` — add `qr_flutter`.
- `features/adb/adb_model.dart`, `adb_service.dart`, `adb_controller.dart`, `adb_dialogs.dart` (none), `home/home_view_sidebar.dart`
- New `features/qr_pair/` (`qr_pair.dart`, `qr_pair_model.dart`, `qr_pair_controller.dart`, `qr_pair_view.dart`) + export in `features.dart`.
- `test/adb_mdns_service_test.dart`, `test/qr_pair_code_test.dart` (first tests in the repo).
- Spec: this file, `README.md`, `01-architecture.md`, `02-adb-layer.md`, `03-data-models.md`,
  `04-ui-conventions.md`, `05-build-and-release.md`, `wireless-connect-pair.md`, `07-roadmap.md`.

## Acceptance criteria

- [x] Scanning the code on an Android 11+ phone pairs it and the device shows up connected without typing anything. *(Verified 2026-11-22 on macOS with a Pixel 10 Pro.)*
- [x] The device appears **once** (adb's auto-connect wins; no duplicate `ip:port` entry). *(Verified.)*
- [x] The dialog closes by itself ~2 s after connecting; status is visible without scrolling. *(Verified.)*
- [x] The pair command appears in the command queue; no output dialog covers the QR dialog.
- [ ] Closing the dialog stops `adb mdns services` polling. *(By construction — session counter + autoDispose; not observed directly.)*
- [ ] Timeout, failed pair, and missing mDNS each show a clear message and a **New code** button. *(Not exercised manually.)*
- [ ] Manual **Pair** reports failure when adb doesn't print `Successfully paired`. *(Not exercised manually.)*
- [x] `parseList`, `QrPairCode`, `QrPairState` covered by unit tests (`test/`); `flutter analyze` adds no new issues.
- [ ] Windows/Linux: same adb commands (adb does the mDNS, not the app) — not run on those platforms.

## Out of scope

- Discovering and connecting already-paired devices from a list (future: Wireless ADB manager in the roadmap).
- Our own mDNS implementation (fallback if adb's mDNS is unreliable) — later if needed.

## Open questions

- None blocking. If some phones reject a service name not starting with `studio-`, switch the prefix.
