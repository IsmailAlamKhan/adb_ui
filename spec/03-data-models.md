# 03 — Data models & persistence

Models are `freezed` 3 (`abstract`/`sealed` classes) unless noted as hand-written. JSON via `json_serializable` where persisted.

## AdbDevice — `adb/adb_model.dart`

```dart
AdbDevice({ required String id, required String type, required String model })
bool get isOffline => type.trim().toLowerCase() == 'offline';
```
- `id` — serial from `adb devices` (USB serial or `ip:port`).
- `type` — the state column (`device`, `offline`, `unauthorized`, …).
- `model` — `ro.product.model`. JSON-serializable (stored inside persisted commands).

## AdbFileSystem — `adb/adb_model.dart`

`mixin AdbFileSystem { String name; }` with two freezed implementations:
`AdbFile(name)` and `AdbDirectory(name)`. Not persisted.

## AdbMdnsService — `adb/adb_model.dart`

`AdbMdnsService({ name, type, host, port })` (hand-written immutable class) — one line of `adb mdns services`
(`<instance>\t<type>\t<ip>:<port>`). Getters `isPairing` (`_adb-tls-pairing._tcp`),
`isConnect` (`_adb-tls-connect._tcp`). `static parseList(String stdout)` skips the
`List of discovered mdns services` header and malformed lines, strips a trailing `.` from
the type, and splits the address on its last `:`. Not persisted.

## QrPairCode / QrPairState — `qr_pair/qr_pair_model.dart`

- `QrPairCode({ serviceName, password })`, `QrPairCode.generate()` (`adbui-` + 10 / 12
  random alphanumerics, `Random.secure`), `qrData` = `WIFI:T:ADB;S:<serviceName>;P:<password>;;`.
- `enum QrPairStatus { waitingForScan, pairing, connecting, connected, pairedNotConnected, failed }`
- `QrPairState({ code, status, host?, deviceId?, message? })` with `copyWith` — hand-written, not freezed. Not persisted.

## CommandModel — `command_queue/command_queue_model.dart`

Freezed union, all variants share `id, command, device, rawCommand, arguments, startedAt`:

| Variant | Extra fields | Meaning |
|---------|-------------|---------|
| `CommandModel.adding` (`CommandModelAdding`) | `stdout`, `stderr` streams | Just created, not yet wired |
| `CommandModel.running` (`CommandModelRunning`) | `output` stream (merged) | Live |
| `CommandModel.done` (`CommandModelDone`) | `output` string, `endedAt` | Finished OK |
| `CommandModel.error` (`CommandModelError`) | `error` string, `endedAt` | Failed |

Helpers: `toRunning`, `toDone`, `toError`, `isDone` (done or error), `isRerun` (id starts with `rerun-`),
`whenAdding/whenRunning/whenDone/whenError`, `finishedIn` (ms), `toLocalStorage()`.

Lifecycle: `adding → running → done | error`. Only `done`/`error` are persisted.

### CommandModelLocalStorage

Persisted form: `id, command, device?, rawCommand, arguments, startedAt, endedAt, output?, error?`
(dates as ISO-8601 via `DateTimeJsonConverter`). `toModel()` → `done` if `output != null`,
else `error` if `error != null`, else throws.

## SettingsModel — `settings/settings_model.dart`

```dart
SettingsModel({
  @ThemeModeJsonConverter() required ThemeMode themeMode,
  @AppStyleJsonConverter() AppStyle? style,   // null → first-run style picker
})
static const initial = SettingsModel(themeMode: ThemeMode.system);
```
`ThemeMode` stored as its `index` (int). `style` stored as the enum name
(`workbench` / `console` / `launcher`); missing or unknown → `null`.

## UI state (not persisted)

| Provider | Type | Meaning |
|----------|------|---------|
| `selectedDeviceIdProvider` | `StateProvider<String?>` | Device the user picked |
| `selectedDeviceProvider` | `Provider<AdbDevice?>` | That device if still connected, else the first connected one |
| `devicePropertiesProvider` | `FutureProvider.family<DeviceProperties, AdbDevice>` | `getprop` values for Overview |
| `installedPackagesProvider` | `FutureProvider.family<List<String>, PackagesQuery>` | `pm list packages` (third-party or all) |

`DeviceProperties` (`adb_model.dart`, hand-written): `model`, `manufacturer`,
`androidVersion`, `sdk`, `abi`, plus `raw` map; parsed from `[key]: [value]` lines.

## AppError — `errors/errors_model.dart`

See [features/error-handling.md](features/error-handling.md). Not persisted: a stored
command keeps its raw `error` text and is explained again when shown.

## AboutModel — `about/about_model.dart`

`AboutModel({ required bool updateAvailable, String? updateAvailableVersion })`. Not persisted.
(`updateAvailableVersion` is currently never populated.)

## Device (host machine) — `device/device_model.codegen.dart`

`Device({ name, id, manufacturer?, model?, product? })` with JSON keys `device, deviceId,
manufacturer, model, product`. Filled from `device_info_plus` per platform. Only used to
attach `device_info.json` to bug-report log zips.

## NavigationEvent — `shared/models/navigation.dart`

Freezed union carried on the EventBus: `dialog, push, adaptivePush, pushNamed, pushReplacement,
pushReplacementNamed, pop, popUntil, snackBar, showLoading, hideLoading, bottomSheet, overlay`.
Variants returning a value carry a `Completer<T?>`.

## Persistence (`LocalStorage` over SharedPreferences)

File: `shared/services/local_storage.dart`. Keys are the enum `LocalStorageKeys`:

| Key | Value | Written by |
|-----|-------|-----------|
| `commands` | JSON string: `List<CommandModelLocalStorage>` (newest first is **not** guaranteed; appended) | `LocalStorageCommandQueueServiceImpl` |
| `settings` | JSON string: `SettingsModel` | `LocalStorageSettingsServiceImpl` |

`set<T>` supports `bool/int/double/String` natively and JSON-encodes `Map`, `List`, or any
`LocalStorageModel`. `get<T>(key, defaultValue:, fromJson:)` decodes with `fromJson` when given.

**Adding a persisted value:** add an enum entry to `LocalStorageKeys`, make the model
`with LocalStorageModel` + `toJson/fromJson`, document it in this table. Changing the
shape of an existing key needs a migration or tolerant `fromJson` — old installs have data.

## Files on disk

| Path | Content |
|------|---------|
| `<appSupport>/env.sh` | env-loading script (macOS/Linux), see 02-adb-layer |
| `<appSupport>/logs/<year>/<Mon>/log-<day>.txt` | app log |
| `…/flutter-error-log-<day>.txt` | `FlutterError` details |
| `…/stdout-log-<day>.txt` | adb stdout **and** stderr |
| `…/stderr-log-<day>.txt` | (created; currently unused) |
| `~/.adb_ui` (user-created, optional) | sourced by env.sh to customise PATH etc. |
