# Feature: Device list (home)

**Status:** Shipped · **Code:** `features/home/`, `adb/adb_providers.dart`

## Behaviour

- `HomeView` = AppBar titled **"ADB"** with actions **Command Queue** (list icon) and
  **Settings** (gear), both opened with `adaptivePush`.
- Body: sidebar (`HomeViewSideBar`: "Connect wireless", "Pair") + `HomeViewContent`.
  Below 500 px the sidebar is in a `Drawer`.
- `HomeViewContent` watches `connectedDevicesProvider` (polls `adb devices` every 1 s).
  - Empty → centred "No connected devices".
  - Otherwise pinned header "`N` Connected device(s)" and one `ListTile` per device:
    title = `model` (+ " (Offline)" when `isOffline`), subtitle = `id`.
  - Tap → `AdbDeviceDialog(device)` (see [device-actions.md](device-actions.md)).
- Loading/error states via `AsyncValueBuilder`.

## Acceptance

- Plugging/unplugging a device updates the list within ~1 s without user action.
- Offline devices are listed and labelled; their dialog shows only Copy id / Disconnect.
