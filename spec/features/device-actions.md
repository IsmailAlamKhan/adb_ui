# Feature: Device actions

**Status:** Shipped; redesigned 2026-11-22 (unreleased) · **Code:** `adb/device_actions.dart` (`DeviceAction`, `AppShortcuts`), `adb/adb_controller.dart`, `device_page/`

Actions run on the **selected device** (`selectedDeviceProvider`). They're defined once in the
`DeviceAction` enum and rendered by every style: tiles (`DeviceActionGrid`, Workbench
Overview and Console center), palette rows (all styles; Launcher's main UI) and shortcuts.

| Action | Controller | adb | Activity label | Shortcut | Input |
|--------|-----------|-----|----------------|----------|-------|
| Install APK | `installApk(device, [path])` | `install <path>` | Install `<file>` | ⌘I | `FilePickerView.apk()`, or a dropped `.apk` |
| Uninstall app | `uninstallApp(device, [pkg])` | `uninstall <pkg>` | Uninstall `<pkg>` | ⌘U | `UninstallPickerDialog` (installed packages) → `ConfirmActionDialog` |
| Push files | `pushFile(device, {files, destination})` | `push` per file | Push `<file>` | ⌘P | folder on device → local files (or Files tab / drop) |
| Pull files | `pullFile(device, {files, destination})` | `pull` per file | Pull `<file>` | ⇧⌘P | files on device → local save location |
| Run command | `runCommand(device, [cmd])` | `<cmd split on spaces>` | `adb <cmd>` | ⌘R | `AdbInputDialog` (prefix `adb `) or Shell tab |
| Type text | `inputText(device, [text])` | `shell input text` | Type text | ⌘T | `AdbInputDialog` or Type text tab |
| Mirror screen | `runScrcpy` | `scrcpy -s ID` | Mirror `<model>` | ⇧⌘M | — |
| Copy device id | `copyId` | — (clipboard) | — | ⇧⌘C | — |
| Disconnect | `disconnect` | `disconnect ID` | Disconnect `<model>` | ⇧⌘D | `ConfirmActionDialog` |

- `DeviceAction.unavailableReason(device, scrcpyAvailable:)` disables an action with a reason
  shown as tooltip / toast: device not online (unauthorized, offline), scrcpy missing,
  Disconnect on a USB device.
- Every adb action runs through `AdbController.runForResult`: it appears in Activity and ends
  with a success or error toast ([error-handling.md](error-handling.md)). Multi-file push/pull
  shows one "Pushing N files…" toast and one summary toast.
- Dropping `.apk` files anywhere on the window installs them on the selected device
  (`ApkDropZone`); the Files tab takes its own drops (push into the open folder).

## Adding an action

Add the service method (02-adb-layer), a controller method using `run(...)`, a `DeviceAction`
value (icon, label, command, shortcut) with its `perform` case, and a row above. It then shows
up in all three styles, the palette and the shortcuts.
