# 01 — Architecture

## Layering

```
View (widgets, HookConsumerWidget)
   │  ref.watch / ref.read
   ▼
Controller  (StateNotifier / AsyncNotifier / plain class, often `with NavigationController`)
   │  calls
   ▼
Service     (abstract interface + `...Impl`, Riverpod Provider)
   │  uses
   ▼
Platform    (Process.start for adb/scrcpy, SharedPreferences, GitHub API, file system)
```

Rules that the existing code follows and new code **must** follow:

1. **Services are interfaces.** Declare `abstract class FooService`, implement in
   `FooServiceImpl` (or a descriptive name like `ProccessAdbServiceImpl`,
   `LocalStorageSettingsServiceImpl`). Expose via `final fooServiceProvider = Provider<FooService>(FooServiceImpl.new);`.
2. **Controllers never touch `BuildContext`.** They navigate/show dialogs through the
   `NavigationController` mixin, which emits events on the `EventBus` (see below).
3. **Views do not call services directly** (exception: `UpdateChecker`/`UpdateAvailableDialog`
   read `packageInfoServiceProvider`/`aboutServiceProvider` — tolerated, not a pattern to copy).
4. Constructors take `Ref` and `ref.read(...)` their dependencies (`Foo(Ref ref) : dep = ref.read(depProvider)`).

## Folder layout

```
lib/
  main.dart                     → App.run()
  app/
    app.dart                    App bootstrap, AppWrapper, WindowTitleBar, theme builder
    features/
      features.dart             barrel: exports every feature barrel
      <feature>/
        <feature>.dart          barrel (exports the files below)
        <feature>_model.dart    freezed models (+ .freezed.dart / .g.dart generated)
        <feature>_service.dart  abstract service + impl + provider
        <feature>_controller.dart
        <feature>_view.dart
    shared/
      models/                   NavigationEvent (freezed union)
      services/                 LocalStorage, NetworkInfoService
      widgets/                  reusable widgets (dialogs, alerts, indicators, transitions…)
      providers.dart            githubProvider
    utils/                      constants, event_bus, navigation, exception, logger, theme, extensions, debouncer
```

Features: `about`, `adb` (+ `adb_file_explorer/`), `add_device`, `agent` (MCP server for AI agents), `app_init_error`,
`ai`, `apps` (app icons/names via the on-device helper), `command_queue` (Activity), `device` (host machine info), `device_page`, `errors`,
`file_picker`, `file_preview`, `logcat`, `menubar`, `mirror`, `package_info`, `palette`, `qr_pair`, `settings`, `shells`,
`splash`, `style_picker`, `update_checker`.

`lib/app/design/` (not a feature): styles, tokens, theme factory, width classes, shared
design widgets. See [04-ui-conventions.md](04-ui-conventions.md).

**Imports:** relative imports only (`prefer_relative_imports` lint). Features import
each other through `../features.dart`; shared code through `../../shared/shared.dart`
and `../../utils/utils.dart`. When you add a file, add it to its folder's barrel.

## Dependency injection (Riverpod)

| Provider | Type | File |
|----------|------|------|
| `adbServiceProvider` | `Provider<AdbService>` | adb/adb_service.dart |
| `adbControllerProvider` | `Provider<AdbController>` | adb/adb_controller.dart |
| `connectedDevicesProvider` | `StreamProvider.autoDispose<List<AdbDevice>>` | adb/adb_providers.dart |
| `adbFilesProvider((device: d, path: p))` (key is the record typedef `AdbFilesQuery`) | `FutureProvider.family<List<AdbFileSystem>, AdbFilesQuery>` (kept alive) | adb/adb_providers.dart |
| `scrcpyAvailableProvider` | `FutureProvider<bool>` (kept alive) | adb/adb_providers.dart |
| `selectedDeviceIdProvider` / `selectedDeviceProvider` | `StateProvider<String?>` / `Provider<AdbDevice?>` | adb/adb_providers.dart |
| `devicePropertiesProvider(device)` | `FutureProvider.autoDispose.family<DeviceProperties, AdbDevice>` | adb/adb_providers.dart |
| `installedPackagesProvider((device:, includeSystem:))` | `FutureProvider.autoDispose.family<List<String>, PackagesQuery>` | adb/adb_providers.dart |
| `logcatControllerProvider(device)` / `mirrorControllerProvider(device)` | `StateNotifierProvider.autoDispose.family` | logcat/, mirror/ |
| `aiControllerProvider` | `StateNotifierProvider<AiController, AiState>` (on-device model) | ai/ai_service.dart |
| `appInfoServiceProvider` / `appInfoProvider(device)` | `Provider<AppInfoService>` / `StateNotifierProvider.family<AppInfoController, Map<String, AppInfo>, AdbDevice>` | apps/ |
| `filePreviewServiceProvider` / `filePreviewProvider((device:, path:))` | `Provider<FilePreviewService>` / `FutureProvider.autoDispose.family<FilePreviewData, FilePreviewQuery>` | file_preview/file_preview_service.dart |
| `activityCountsProvider` | `Provider<({int running, int errors})>` | shells/home_shell.dart |
| `adbFileExplorerControllerProvider` | `ChangeNotifierProvider` | adb/adb_file_explorer/… |
| `qrPairControllerProvider` | `StateNotifierProvider.autoDispose<QrPairController, QrPairState>` | qr_pair/qr_pair_controller.dart |
| `agentControllerProvider` | `StateNotifierProvider<AgentController, AgentState>` (MCP server for AI agents) | agent/agent_controller.dart |
| `agentSettingsServiceProvider` / `mcpServerProvider` / `agentRunRecorderProvider` | `Provider<AgentSettingsService>` / `Provider<McpServer>` / `Provider<AgentRunRecorder>` | agent/agent_service.dart |
| `commandQueueServiceProvider` / `commandQueueControllerProvider` | Provider / `StateNotifierProvider<…, List<CommandModel>>` | command_queue/ |
| `settingsServiceProvider` / `settingsControllerProvider` | Provider / `StateNotifierProvider<…, SettingsModel>` | settings/ |
| `aboutServiceProvider` / `aboutControllerProvider` | Provider / `AsyncNotifierProvider.autoDispose<AboutController, AboutModel>` | about/ |
| `packageInfoServiceProvider` / `packageInfoControllerProvider` | Provider / `StateNotifierProvider<…, PackageInfo?>` | package_info/ |
| `deviceServiceProvider` / `deviceControllerProvider` / `deviceInfoProvider` | host machine info | device/ |
| `localStorageProvider` | `Provider<LocalStorage>` | shared/services/local_storage.dart |
| `networkInfoServiceProvider` | `Provider<NetworkInfoService>` | shared/services/network.dart |
| `githubProvider` | `Provider<GitHub>` (anonymous client) | shared/providers.dart |
| `eventBusProvider` | `Provider<EventBus>` | utils/event_bus.dart |
| `globalNavigatorControllerProvider` | `Provider<GlobalNavigatorController>` | utils/navigation.dart |

Providers are global and kept alive by default (Riverpod 2 non-`autoDispose`); use `.autoDispose` for screen-scoped state.

## Startup sequence (`App.run` → `App.init`)

1. `runZonedGuarded` wraps everything.
2. `NavigatorService.init()`, `AppLogger.init()`, `await LogFile.init()`.
3. `FlutterError.onError` → log file; `MediaKit.ensureInitialized()` (mirror video). (Steps 2–3 run once, so Try again on the error screen can call `App.run()` again.)
4. `App.init(container)`:
   1. `runApp(SplashView)` (logo + "Starting adb…", Workbench tokens, OS brightness).
   2. **Windows only:** `windowManager` init — hidden title bar, min size 480×560 (`WindowSize.minimum`), show + focus.
      macOS (`MainFlutterWindow.swift`) and Linux (`my_application.cc`) set the same minimum.
   3. Sequentially, on a shared `ProviderContainer`:
      `packageInfoController.init()` → `localStorage.init()` → `settingsController.init()` →
      `deviceController.init()` → **`adbService.verifyAdb()`** → `commandQueueController.init()` →
      `agentController.init()` (starts the MCP server if it was on; never throws, so a busy port
      only shows in Settings).
      Settings load before adb is checked so the error screen uses the user's style.
   4. Any `AppException`/`ProcessException` is re-thrown as `AppInitializationException`.
5. On success: `runApp(UncontrolledProviderScope(container, _App))` → `MaterialApp` themed by
   `AppThemeFactory.build(style, brightness)`; `home` is `StylePickerView` until a style is
   chosen, then `UpdateChecker(child: HomeShell())`.
6. On zone error that is an `AppInitializationException`: `runApp(AppInitErrorView)` — the
   explained error (most commonly "adb isn't installed or can't be found") with Try again,
   Copy details, Open logs folder. All zone errors are written to the log file.

Order matters: storage must init before settings/queue; adb must be verified before home is shown.

## Navigation: EventBus pattern

Controllers have no `BuildContext`. They mix in `NavigationController` (`utils/navigation.dart`),
whose methods (`showDialog`, `push`, `adaptivePush`, `pop`, `popUntil`, `confirmDialog`,
`showSnackbar`, `showToast`, `showSuccess`, `showError`, `showLoading/hideLoading`, `showAlert`, `modalBottomSheet`, `insertOverlay`, `runAsync`)
emit a `NavigationEvent` (freezed union, `shared/models/navigation.dart`) on the global
`EventBus`. Results come back through a `Completer` carried in the event.

`NavigationEventListener` (`shared/widgets/navigation_event_listener.dart`) is mounted in the
`MaterialApp.builder` (via `AppWrapper`) around the root navigator and performs the real
Flutter navigation for each event.

- Inside widgets, prefer `Navigator.of(context)` + the extensions in `utils/extensions.dart`
  (`showDialog`, `adaptivePush`, `pushBuilder`, `showLoading`).
- `NavigatorService` (global navigator key) exists only for code with no context; it logs a warning when used.
- `adaptivePush`: on width > 500 px it opens the page as a dialog, otherwise pushes a full page.

## Error handling

- `AppException(message, [code])` is the app's base exception (`utils/exception.dart`).
  Subclasses: `PermissionDeniedException`, `NotDirException`, `AdbNotFoundException`,
  `ScrcpyNotFoundException` (in adb_service.dart), `SwallowedError`, `NotImplementedException`.
- `AppInitializationException` wraps startup failures → error screen.
- `exceptionToString(e)` converts any error to a user string (hides non-`Exception` details in release).
- Also `InvalidInputException`, `CommandFailedException(exitCode, output)`, `NotFoundException`
  (`features/errors/errors_model.dart`). `AppException.code` is kept.
- Errors reach people through `ErrorCatalogue.explain` → `AppError` (title, message, steps,
  details): `showError` toasts, `ErrorPanel`, `AppInitErrorView`. Unexpected errors are also
  logged with `LogFile.instance.dispath(...)` / `logError(...)`.
- Command failures mark the `CommandModel` as `error` via `CommandQueueController.fail` and show
  an error toast. Full contract: [features/error-handling.md](features/error-handling.md).

## Code generation

Generated files are committed: `*.freezed.dart`, `*.g.dart`. After changing any
`@freezed` or `@JsonSerializable` declaration, run:

```bash
dart run build_runner build
```

Generated files are excluded from analysis (`analysis_options.yaml`).

Versions and freezed 3 rules: see [05-build-and-release.md](05-build-and-release.md#toolchain--codegen-versions).
`@riverpod` codegen is **not** used — write providers by hand.
