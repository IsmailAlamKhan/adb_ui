# 01 — Architecture

## Layering

```
View (widgets, HookConsumerWidget)
   │  ref.watch / ref.read
   ▼
Controller  (StateNotifier / plain class / @riverpod Notifier, often `with NavigationController`)
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

Features: `about`, `adb` (+ `adb_file_explorer/`), `app_init_error`, `command_queue`,
`device` (host machine info), `file_picker`, `home`, `menubar`, `package_info`,
`settings`, `splash`, `terminal_outputs`, `update_checker`.

**Imports:** relative imports only (`prefer_relative_imports` lint). Features import
each other through `../features.dart`; shared code through `../../shared/shared.dart`
and `../../utils/utils.dart`. When you add a file, add it to its folder's barrel.

## Dependency injection (Riverpod)

| Provider | Type | File |
|----------|------|------|
| `adbServiceProvider` | `Provider<AdbService>` | adb/adb_service.dart |
| `adbControllerProvider` | `Provider<AdbController>` | adb/adb_controller.dart |
| `connectedDevicesProvider` | `StreamProvider.autoDispose<List<AdbDevice>>` | adb/adb_providers.dart |
| `adbFilesProvider(device:, path:)` | generated, keepAlive `FutureProvider` family | adb/adb_providers.dart |
| `scrcpyAvailableProvider` | generated, keepAlive `FutureProvider<bool>` | adb/adb_providers.dart |
| `adbFileExplorerControllerProvider` | `ChangeNotifierProvider` | adb/adb_file_explorer/… |
| `commandQueueServiceProvider` / `commandQueueControllerProvider` | Provider / `StateNotifierProvider<…, List<CommandModel>>` | command_queue/ |
| `settingsServiceProvider` / `settingsControllerProvider` | Provider / `StateNotifierProvider<…, SettingsModel>` | settings/ |
| `aboutServiceProvider` / `aboutControllerProvider` | Provider / generated `AsyncNotifier<AboutModel>` | about/ |
| `packageInfoServiceProvider` / `packageInfoControllerProvider` | Provider / `StateNotifierProvider<…, PackageInfo?>` | package_info/ |
| `deviceServiceProvider` / `deviceControllerProvider` / `deviceInfoProvider` | host machine info | device/ |
| `localStorageProvider` | `Provider<LocalStorage>` | shared/services/local_storage.dart |
| `networkInfoServiceProvider` | `Provider<NetworkInfoService>` | shared/services/network.dart |
| `githubProvider` | `Provider<GitHub>` (anonymous client) | shared/providers.dart |
| `eventBusProvider` | `Provider<EventBus>` | utils/event_bus.dart |
| `globalNavigatorControllerProvider` | `Provider<GlobalNavigatorController>` | utils/navigation.dart |

`riverpodKeepAlive` (`Riverpod(keepAlive: true)`) is a shared annotation constant in `constants.dart`.

## Startup sequence (`App.run` → `App.init`)

1. `runZonedGuarded` wraps everything.
2. `NavigatorService.init()`, `AppLogger.init()`, `await LogFile.init()`.
3. Preload Poppins (`GoogleFonts.pendingFonts`). `FlutterError.onError` → log file.
4. `App.init(container)`:
   1. `runApp(SplashView)` (spinner, follows OS brightness).
   2. **Windows only:** `windowManager` init — hidden title bar, min size 400×600, show + focus.
   3. Sequentially, on a shared `ProviderContainer`:
      `packageInfoController.init()` → `localStorage.init()` → `deviceController.init()` →
      **`adbService.verifyAdb()`** → `settingsController.init()` → `commandQueueController.init()`.
   4. Any `AppException`/`ProcessException` is re-thrown as `AppInitializationException`.
5. On success: `runApp(UncontrolledProviderScope(container, _App))` → `MaterialApp(home: UpdateChecker(child: HomeView()))`.
6. On zone error that is an `AppInitializationException`: `runApp(AppInitErrorView)` showing
   the message (most commonly "Adb not found please install it…"). All zone errors are written to the log file.

Order matters: storage must init before settings/queue; adb must be verified before home is shown.

## Navigation: EventBus pattern

Controllers have no `BuildContext`. They mix in `NavigationController` (`utils/navigation.dart`),
whose methods (`showDialog`, `push`, `adaptivePush`, `pop`, `popUntil`, `confirmDialog`,
`showSnackbar`, `showLoading/hideLoading`, `showAlert`, `modalBottomSheet`, `insertOverlay`, `runAsync`)
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
- Controllers catch `AppException` and show a snackbar; unexpected errors are logged with
  `LogFile.instance.dispath(...)` / `logError(...)`.
- Command failures don't throw to the UI — they mark the `CommandModel` as `error` (see command-queue spec).

## Code generation

Generated files are committed: `*.freezed.dart`, `*.g.dart`. After changing any
`@freezed`, `@JsonSerializable`, or `@riverpod` declaration, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files are excluded from analysis (`analysis_options.yaml`).
