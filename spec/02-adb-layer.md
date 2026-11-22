# 02 — ADB process layer

File: `lib/app/features/adb/adb_service.dart` (`AdbService` interface, `ProccessAdbServiceImpl`).

## `run()` — the single process entry point

```dart
Future<Result> run(String command, {
  bool shell = false, List<String> arguments = const [],
  String executable = 'adb', AdbDevice? device, bool addToLogs = true,
})
```

Builds argv as: `[-s <device.id>]? [shell]? [command]? ...arguments` and calls
`Process.start(executable, argv, environment: _unixEnvironmentMap, runInShell: true)`.

- **macOS/Linux env loading:** on first call it writes `env.sh` into the application
  support dir, `chmod u+x`, runs it with `bash -c ./env.sh`, and parses the printed
  `env` into a map. The script sources system profiles and the user's shell rc files
  (`.zshrc`, `.bashrc`, `.profile`, …) plus an optional **`~/.adb_ui`** custom profile.
  Purpose: GUI apps on macOS don't inherit the shell `PATH`, so this is how `adb` and
  `scrcpy` are found. Cached for the process lifetime in `_unixEnvironmentMap`.
- **Not found:** `ProcessException` with message `No such file or directory` →
  `AdbNotFoundException` (if executable is `adb`) else `ScrcpyNotFoundException`.
  Other `ProcessException`s → `AppException('ProcessException: …')`.
- stdout/stderr are UTF-8 decoded broadcast streams. If `addToLogs`, both are appended to the stdout log file.

## `Result`

| Field | Meaning |
|-------|---------|
| `stdoutStream`, `stderrStream` | live decoded output |
| `stdout`, `stderr` | `Future<String>` of the full joined output |
| `exitCode` | `Future<int>` |
| `messege` *(sic)* | `Future<String>` — the **user-facing success message**; it **throws `AppException` on failure**. Each command sets it via `copyWith`. |
| `device` | target `AdbDevice?` |
| `command` | raw command name (`'connect'`, `'install'`…), or the executable name if not `adb` (`'scrcpy'`). Used for re-run. |
| `arguments` | args passed (used for re-run) |

**Success is detected by parsing output text**, not by exit code (except scrcpy availability).

## Command catalogue

| Method | Process | Success when | Message |
|--------|---------|--------------|---------|
| `getConnectedDevices()` | `adb devices` then per device `adb -s ID shell getprop ro.product.model` | — | returns `List<AdbDevice>` (`id`, `type` = state column, `model`) |
| `connectedDevicesStream` | `Stream.periodic(1s).asyncMap(getConnectedDevices)` | — | — |
| `verifyAdb()` | `adb version` | stderr empty and stdout contains `Android Debug Bridge version` | else throws `AdbNotFoundException` |
| `scrcpyAvailable()` | `scrcpy --version` | exit code 0 | `false` on any `AppException` |
| `connect(host, port)` | `adb connect host:port` | stdout contains `connected to` | `Connected to host:port` |
| `pair(code, host, port)` | `adb pair host:port code` | always (message = stdout) | stdout |
| `tcpip()` | `adb tcpip 5555` | stdout contains `restarting in TCP mode port: 5555` | `Restarted in TCP mode` |
| `disconnect(device)` | `adb -s ID disconnect ID` | stdout contains `disconnected` | `Disconnected from ID` |
| `installApk(device, path)` | `adb -s ID install path` | stderr empty and stdout contains `Success` | `Installed path` |
| `uninstallApp(device, pkg)` | `adb -s ID uninstall pkg` | stdout contains `Success` | `Uninstalled pkg` |
| `pushFile(device, file, dest)` | `adb -s ID push file dest` | stdout contains `pushed` | `Pushed file` |
| `pullFile(device, file, dest)` | `adb -s ID pull file dest` | stdout contains `pulled` | `Pulled file` |
| `inputText(device, text)` | `adb -s ID shell input text <escaped>` | stdout empty | `Text sent` |
| `runCustomCommand(device, cmd)` | `adb -s ID <cmd split on spaces>` | always | stdout |
| `scrcpy(device)` | `scrcpy -s ID` | stdout contains `INFO: Device` | `Scrcpy started` |
| `ls(device, path)` | `adb -s ID shell ls -i "<path or />"` | stderr empty | returns `List<AdbFileSystem>` |

`inputText` escaping: `'` → `\'`, `"` → `\"`, space → `%s`.

### `ls` parsing rules

- Each line is `<inode> <name>`; lines with inode `?` are skipped (no permission).
- Output containing `Permission denied` or `No such file or directory` → `PermissionDeniedException`.
- **Name contains `.` → `AdbFile`, otherwise `AdbDirectory`** (heuristic).
- A hard-coded deny-list of root system entries is hidden: `metadata, oem, odm, lost+found,
  bugreports, sys, system, apex, vendor, bin, acct, config, debug_ramdisk, default.prop, d, cache, system_ext`.
- Directories are sorted before files.

### Re-run mapping (`rerunCommand(rawCommand, device, arguments)`)

| rawCommand | Re-runs |
|------------|---------|
| `connect` | `connect(host, port)` parsed from `arguments.first` |
| `disconnect` / `install` / `push` / `pull` / `scrcpy` | same method with stored args |
| `tcpip` | `tcpip()` |
| `shell` | `input text …` → `inputText`; otherwise `runCustomCommand` |
| `''` (custom command) | `runCustomCommand(device, arguments.join(' '))` |
| other | throws `AppException('Command not found')` |

**Adding a new adb command:** add the method to `AdbService`, implement in
`ProccessAdbServiceImpl` with a `messege` success check, add a `rerunCommand` case so it
can be re-run from the queue, add a controller method in `AdbController` that wraps it in
`run(...)`, and update this table.

## `AdbController.run()` — wrapping a command for the UI

File: `lib/app/features/adb/adb_controller.dart`.

```dart
Future<void> run({required Future<Result> Function() function, required String command,
  bool autoCloseOutput = true, bool isRerun = false, bool showOutput = true})
```

1. Generates a UUID id (prefixed `rerun-` when `isRerun`), records `startedAt`.
2. Closes any open output dialog and cancels the auto-close timer.
3. Awaits `function()` → `Result`; adds `CommandModel.adding(...)` to the command queue.
4. If `showOutput`, opens `CurrentCommandOutput(commandId)` dialog (non-dismissable,
   `CurrentCommandOutput.routeSettings`).
5. Awaits `result.messege`; on throw, updates the queue entry to `CommandModel.error`
   with `exceptionToString(e)` and logs.
6. If `autoCloseOutput && showOutput`, closes the output dialog after **2 s**.
7. An `AppException` thrown by `function()` itself (e.g. "No apk selected", adb not found) → snackbar.

`command` is the **human label** shown in the queue (e.g. `'Install apk'`, `'Connect to 1.2.3.4:5555'`).
