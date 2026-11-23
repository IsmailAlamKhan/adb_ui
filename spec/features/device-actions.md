# Feature: Device actions

**Status:** Shipped; redesigned in 0.0.16 · **Code:** `adb/device_actions.dart` (`DeviceAction`, `AppShortcuts`), `adb/adb_controller.dart`, `device_page/`

Actions run on the **selected device** (`selectedDeviceProvider`). They're defined once in the
`DeviceAction` enum and rendered by every style: tiles (`DeviceActionGrid`, Workbench
Overview and Console center), palette rows (all styles; Launcher's main UI) and shortcuts.

| Action | Controller | adb | Activity label | Shortcut | Input |
|--------|-----------|-----|----------------|----------|-------|
| Install APK | `installApk(device, [path])` | `install <path>` | Install `<file>` | ⌘I | `FilePickerView.apk()`, or a dropped `.apk` |
| Uninstall app | `uninstallApp(device, [pkg])` | `uninstall <pkg>` | Uninstall `<pkg>` | ⌘U | `UninstallPickerDialog` (installed packages) → `ConfirmActionDialog` |
| Push files | `pushFile(device, {files, destination})` | `push` per file | Push `<file>` | ⌘P | device file browser in push mode at the last folder → **Push files here…** (native picker) or drop; see [file-explorer-transfer.md](file-explorer-transfer.md) |
| Pull files | `pullFile(device, {files, destination})` | `pull` per file | Pull `<file>` | ⇧⌘P | files on device → local save location |
| Run command | `runCommand(device, [cmd])` | `<cmd split on spaces>` | `adb <cmd>` | ⌘R | `AdbInputDialog` (prefix `adb `) or Shell tab |
| Type text | `inputText(device, [text])` | `shell input text` | Type text | ⌘T | `AdbInputDialog` or Type text tab |
| Logcat | `openLogcat` | `logcat` stream | — | ⌘L | `LogcatPage` (Workbench: Logcat tab) |
| Mirror screen | `openMirror` (in-app); `runScrcpy` for the separate window | scrcpy server / screencap | Mirror `<model>` (window only) | ⇧⌘M | `MirrorPage` (Workbench: Screen tab) |
| Copy device id | `copyId` | — (clipboard) | — | ⇧⌘C | — |
| Disconnect | `disconnect` | `disconnect ID` | Disconnect `<model>` | ⇧⌘D | `ConfirmActionDialog` |

- `DeviceAction.unavailableReason(device, scrcpyAvailable:)` disables an action with a reason
  shown as tooltip / toast: device not online (unauthorized, offline), Disconnect on a USB
  device. Without scrcpy, the mirror falls back to snapshot mode.
- Every adb action runs through `AdbController.runForResult`: it appears in Activity and ends
  with a success or error toast ([error-handling.md](error-handling.md)). Multi-file push/pull
  shows one "Pushing N files…" toast and one summary toast.
- Dropping `.apk` files anywhere on the window installs them on the selected device
  (`ApkDropZone`); the Files tab takes its own drops (push into the open folder).

## Adding an action

Add the service method (02-adb-layer), a controller method using `run(...)`, a `DeviceAction`
value (icon, label, command, shortcut) with its `perform` case, and a row above. It then shows
up in all three styles, the palette and the shortcuts.
