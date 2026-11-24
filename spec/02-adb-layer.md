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
`Process.start(executable, argv, environment: await processEnvironment(), runInShell: true)`.
`processEnvironment()` is the env below (or the app's own on Windows) with the `ToolPaths`
folders appended to `PATH` (app-installed Platform-Tools / scrcpy, Homebrew, winget links),
see [features/onboarding.md](features/onboarding.md).

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
| `verifyAdb()` | `adb version` | stderr empty and stdout contains `Android Debug Bridge version` | else throws `AdbNotFoundException` (also when the shell says the command doesn't exist: exit 127, `not found`, `is not recognized`); at startup this opens Setup |
| `scrcpyAvailable()` | `scrcpy --version` | exit code 0 | `false` on any `AppException` |
| `connect(host, port)` | `adb connect host:port` | stdout contains `connected to` | `Connected to host:port` |
| `pair(code, host, port)` | `adb pair host:port code` | stdout contains `Successfully paired` | stdout |
| `mdnsServices()` | `adb mdns services` (not logged) | stderr empty, or stdout non-empty | returns `List<AdbMdnsService>` via `AdbMdnsService.parseList`; else throws `AdbMdnsUnavailableException` |
| `tcpip()` | `adb tcpip 5555` | stdout contains `restarting in TCP mode port: 5555` | `Restarted in TCP mode` |
| `disconnect(device)` | `adb -s ID disconnect ID` | stdout contains `disconnected` | `Disconnected from ID` |
| `installApk(device, path)` | `adb -s ID install path` | stdout contains `Success` (stderr warnings allowed) | `Installed <file name>` |
| `uninstallApp(device, pkg)` | `adb -s ID uninstall pkg` | stdout contains `Success` | `Uninstalled pkg` |
| `pushFile(device, file, dest)` | `adb -s ID push file dest` | exit code 0 (adb 37+ prints "1 file pushed" to **stderr** when not on a terminal, so output isn't checked); error = stderr/stdout | `Pushed file` |
| `pullFile(device, file, dest)` | `adb -s ID pull file dest` | exit code 0 (summary goes to stderr on adb 37+) | `Pulled file` |
| `inputText(device, text)` | `adb -s ID shell input text <escaped>` | stdout empty | `Text sent` |
| `runCustomCommand(device, cmd)` | `adb -s ID <cmd split on spaces>` | exit code 0 | stdout; non-zero → `CommandFailedException` with stdout + stderr |
| `scrcpy(device)` | `scrcpy -s ID` | stdout contains `INFO: Device` | `Scrcpy started` |
| `ls(device, path)` | `adb -s ID shell ls -1 -p -L "<path or />"` (`parseLsOutput`: `/` suffix = folder, folders first A–Z) | stderr empty | returns `List<AdbFileSystem>`; `No such file or directory` → `NotFoundException`, `Permission denied` → `PermissionDeniedException` |
| `deviceProperties(device)` *(redesign)* | `adb -s ID shell getprop` (not logged) | exit code 0 | returns `DeviceProperties` |
| `startProcess(args, {device})` | long-running process with the user's env (logcat, mirror server); not in Activity | — | caller kills it |
| `pidsOf(device, pkg)` | `adb -s ID shell pidof <pkg>` (not logged) | — | `Set<int>` |
| `foregroundPackage(device)` | `adb -s ID shell dumpsys activity activities` (not logged) | — | package of the resumed activity |
| `clearLogcat(device)` | `adb -s ID logcat -c` | exit 0 | `Cleared the device log` |
| `listPackages(device, {includeSystem})` *(redesign)* | `adb -s ID shell pm list packages [-3]` (not logged) | exit code 0 | sorted package names (`package:` prefix stripped) |

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
| `pair` | `pair(arguments.last, host, port)` with host/port from `arguments.first` |
| `disconnect` / `install` / `push` / `pull` / `scrcpy` | same method with stored args |
| `tcpip` | `tcpip()` |
| `logcat` | `clearLogcat(device)` |
| `shell` | `input text …` → `inputText`; otherwise `runCustomCommand` |
| `''` (custom command) | `runCustomCommand(device, arguments.join(' '))` |
| other | throws `AppException('Command not found')` |

**Adding a new adb command:** add the method to `AdbService`, implement in
`ProccessAdbServiceImpl` with a `messege` success check, add a `rerunCommand` case so it
can be re-run from the queue, add a controller method in `AdbController` that wraps it in
`run(...)`, and update this table.

## `AdbController.run()` / `runForResult()` — wrapping a command for the UI

File: `lib/app/features/adb/adb_controller.dart`.

```dart
Future<void> run({required Future<Result> Function() function, required String command,
  bool isRerun = false, bool showOutput = true})
```

1. Generates a UUID id (prefixed `rerun-` when `isRerun`), records `startedAt`.
2. Awaits `function()` → `Result`. If that throws (e.g. no APK chosen, adb missing), the error
   is explained and shown with `showError` (when `showOutput`), and `null` is returned.
3. Adds `CommandModel.adding(...)` to Activity (live output starts streaming).
4. Awaits `result.messege`: success → `CommandQueueController.complete` and a success toast
   ("Show output"); throw → `fail`, log, and an error toast (Details → `CommandDetailsDialog`,
   Retry re-runs the same function).
5. With `showOutput: false` nothing is announced (used for multi-file transfers and QR pairing).

`runForResult(...)` takes the same arguments and returns `Future<String?>`: the success
message from `Result.messege`, or `null` if the command failed (queue entry marked error)
or `function()` threw. `run(...)` is `runForResult(...)` with the result ignored. Use
`runForResult` when a flow must continue after a command (e.g. QR pairing).

Input (addresses, pairing codes) is validated before `function()` runs (`validateHostPort`,
`validatePairingCode`). See [features/error-handling.md](features/error-handling.md).

`command` is the **human label** shown in the queue (e.g. `'Install apk'`, `'Connect to 1.2.3.4:5555'`).
