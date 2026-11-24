# Feature: Restart adb

**Status:** Implemented (unreleased) · **Code:** `AdbService.restartServer`, `AdbController.restartAdb`,
`qr_pair/`, `palette/palette_view.dart`, `settings/settings_view.dart`
**Owner / requested by:** owner · **Last updated:** 2026-11-24

## Problem

adb's own mDNS discovery stalls: after Wi-Fi changes or Wireless debugging being switched off
and on, `adb mdns services` stays empty until the adb server restarts
([06-known-issues.md](../06-known-issues.md) #25). QR pairing then hangs (the phone sits on
"Pairing device…") and Wi-Fi phones don't come back. Today the only fix is typing
`adb kill-server` / `adb start-server` in a terminal.

An app-side mDNS listener was tried instead (2026-11-24) and dropped: on macOS it only got
answers to unicast-reply queries, about 1 in 2–8 tries, while restarting adb fixed every
stall seen.

## Behaviour

**Action "Restart adb"** — `AdbController.restartAdb()`:
1. If any device is connected, confirm first: title **"Restart adb?"**, message "Every device
   disconnects for a few seconds. USB and paired Wi-Fi phones come back by themselves;
   phones added by IP address (port 5555) need connecting again.", button **Restart**.
   Cancel does nothing. With no devices it runs straight away.
2. Runs `adb kill-server` then `adb start-server` as one Activity entry, label
   **"Restart adb"**. Success toast "adb restarted". Failure: explained error as usual.
3. Device list refreshes through the normal polling.

**Entry points**
- **QR pairing** (Add device → QR code, and Launcher's "Scan to pair." page): after **15 s**
  in "Waiting for your phone to scan the code…", or **10 s** in "Paired. Connecting…", a hint
  appears under the status line: **"Phone stuck on "Pairing device…"?"** — "adb sometimes
  stops seeing phones on the network. Restarting it usually fixes this." — with a
  **Restart adb** button. While it runs the button shows a spinner; the pairing flow keeps
  the same code and carries on afterwards (the phone keeps advertising, so the scan doesn't
  need repeating). Polling is paused during the restart so its errors aren't shown.
  "Paired, but it didn't connect automatically" also offers **Restart adb**.
- **Command palette:** section *App*, "Restart adb", keywords `kill-server reset stuck wifi
  wireless discovery`.
- **Settings:** new section **adb** with a row "Restart adb" — "Fixes phones not showing up
  over Wi-Fi and QR pairing that never finishes."

## adb / process commands

| Command | Success when | Message | Re-runnable from queue? |
|---------|--------------|---------|-------------------------|
| `adb kill-server` then `adb start-server` (one entry, recorded as `kill-server`) | `start-server` exits 0 | `adb restarted` | Yes (`kill-server` case → `restartServer`) |

`kill-server` exits 1 when no server is running; that's ignored.

## Data & persistence

- `QrPairState.adbMaybeStuck` (bool) — set by the controller when the 15 s / 10 s thresholds
  pass; `restartingAdb` (bool) while a restart from the dialog runs.
- `QrPairController.restartAdb()`.
- Nothing persisted.

## Files to touch

- `adb/adb_service.dart` (`restartServer`, `rerunCommand`), `adb/adb_controller.dart`
- `qr_pair/qr_pair_model.dart`, `qr_pair_controller.dart`, `qr_pair_view.dart`
- `palette/palette_view.dart`, `settings/settings_view.dart`
- Spec: this file, `README.md`, `02-adb-layer.md`, `qr-pairing.md`, `06-known-issues.md` #25;
  docs: `docs/troubleshooting.md`, `docs/user-guide.md`; `CHANGELOG.md`.

## Acceptance criteria

- [x] With adb's discovery stalled, the QR dialog's **Restart adb** lets the same scan finish pairing and connect. *(Verified 2026-11-24 on macOS with a Pixel 10 Pro: stall simulated with `ADB_MDNS=0 adb start-server`; hint appeared, Restart adb, the same scan paired and connected.)*
- [ ] Palette and Settings restart adb; connected devices ask first. *(Built; not clicked through.)*
- [ ] Activity shows one "Restart adb" entry; re-running it restarts again. *(Not checked.)*
- [x] `QrPairState` hint flags and thresholds unit-tested (`test/qr_pair_code_test.dart`).
- [ ] Windows / Linux: same adb commands; not run there.

## As built (2026-11-24)
- `AdbService.restartServer()` (kill-server quietly, then start-server recorded as
  `kill-server`; success = exit code 0), `rerunCommand` case `kill-server`.
- `AdbController.restartAdb()` → `Future<bool>`, confirms with `ConfirmActionDialog` when
  `getConnectedDevices()` is non-empty.
- `QrPairState.adbMaybeStuck`, `restartingAdb`, `QrPairState.stuckAfter(status)`;
  `QrPairController.restartAdb()` pauses polling, resets the stuck clock, and from
  "paired, not connected" goes back to connecting.
- `QrPairStatusView` adds the info banner with **Restart adb** under the working status and
  on "paired, not connected"; Launcher's page shows the status view when `adbMaybeStuck`.
- Palette item (section App) and Settings section **adb**.

## Out of scope

- Restarting adb automatically (it drops every device, so the user decides).
- The app's own mDNS discovery (tried and dropped, see Problem).
