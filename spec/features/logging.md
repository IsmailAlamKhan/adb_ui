# Feature: Logging

**Status:** Shipped · **Code:** `utils/logger.dart`

## Console logging — `AppLogger`

- `logInfo`, `logWarning`, `logError` → `package:logging` root logger `App Logger`.
- Level: `ALL` in debug, `WARNING` in release. Coloured, emoji-prefixed `print` output.
- `EventBus` logs every event at info level.

## File logging — `LogFile` (singleton, `LogFile.init()` at startup)

- Directory: `<applicationSupportDir>/logs/<year>/<Mon>/` (one folder per month, files per day).
- Files: `log-<day>.txt`, `flutter-error-log-<day>.txt`, `stdout-log-<day>.txt`, `stderr-log-<day>.txt`.
- `dispath(message, {isError=true, error, stackTrace})` *(sic)* — writes to `log-*.txt` and the console.
- `dispatchFlutterErrorLogs` — hooked to `FlutterError.onError`.
- `dispatchStdoutLogs` — every adb process's stdout and stderr (when `addToLogs`).
- Files are recreated lazily if missing.
- `getAllLogsAndReset` — zip + delete, used by bug reports (see about-updates-reporting).

**Rule:** log unexpected errors with `LogFile.instance.dispath(..., error:, stackTrace:)`
so they end up in bug reports; use `logInfo` for debug noise.
