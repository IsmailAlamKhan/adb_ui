# Feature: Device actions menu

**Status:** Shipped · **Code:** `adb/adb_dialogs.dart` (`AdbDeviceDialog`), `adb/adb_controller.dart`

Tapping a device opens `AdbDeviceDialog` (max width 400). Each item first pops the
dialog, then calls the controller. Order (online device):

| # | Item | Controller | adb | Queue label | Output dialog |
|---|------|-----------|-----|-------------|---------------|
| 1 | Install apk | `installApk` | `install <path>` | Install apk | auto-close 2 s |
| 2 | Uninstall app | `uninstallApp` | `uninstall <pkg>` | Uninstall app | auto-close |
| 3 | Push file | `pushFile` | `push` per file | Push file | hidden (queue only) |
| 4 | Pull file | `pullFile` | `pull` per file | Pull file | hidden (queue only) |
| 5 | Input text | `inputText` | `shell input text` | Input text | auto-close |
| 6 | Run command | `runCommand` | `<user args>` | Run command | **stays open** |
| 7 | Scrcpy | `runScrcpy` | `scrcpy -s ID` | Run scrcpy | auto-close |
| 8 | Copy id | — | — (clipboard) | — | — |
| 9 | Disconnect | `disconnect` | `disconnect ID` | Disconnect | auto-close |

- Items 1–7 are hidden when the device is **offline**.
- **Scrcpy** is disabled unless `scrcpyAvailableProvider` is `true`; subtitle shows
  "Not available" / "Loading..." / error.
- **Disconnect** subtitle: "Only available for WIFI devices".

## Inputs per action

- **Install apk:** `FilePickerView.apk()` — single `.apk`, drag-drop or picker. Nothing
  selected → snackbar "No apk selected to install".
- **Uninstall app:** text input "Enter your package name".
- **Input text:** text input "Enter your text" — sent to the focused field on the device.
- **Run command:** text input "Enter your command" — typed *without* the leading `adb`
  and without `-s` (e.g. `shell pm list packages`). Split on spaces (no quoting support).
- **Push / Pull:** see [file-explorer-transfer.md](file-explorer-transfer.md).

## Adding an action

Add the service method (see 02-adb-layer "Adding a new adb command"), a controller
method using `run(...)`, a `ListTile` in `AdbDeviceDialog` in the right group, and a row
in the table above.
