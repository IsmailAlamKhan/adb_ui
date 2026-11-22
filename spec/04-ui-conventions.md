# 04 — UI conventions

## Screen map

```
SplashView ──(init ok)──► MaterialApp
                            └─ UpdateChecker
                                 └─ HomeView
                                      ├─ AppBar: [Command Queue] [Settings]
                                      ├─ Sidebar (HomeViewSideBar): Connect wireless, Pair
                                      └─ Content (HomeViewContent): device list
                                            └─ tap ► AdbDeviceDialog (actions)
                                                   ├─ FilePickerView / FilePickerView.apk
                                                   ├─ AdbFileExplorerView
                                                   ├─ AdbInputDialog
                                                   └─ CurrentCommandOutput
           ──(init fails)──► AppInitErrorView
Settings ► AboutView ► FeatureRequestOrBugReportDialog
macOS menu "About Adb ui" ► AboutView
```

## Responsive rules

- Breakpoint **500 px** width (`isMobileSize` / `isTabletOrLarger` in `constants.dart`).
- `< 500`: sidebar moves into a `Drawer`; `adaptivePush` pushes full pages.
- `≥ 500`: sidebar inline (250 px, 200 px when narrow); `adaptivePush` opens a dialog.
- `AdaptiveDialog` wraps a full-screen widget (e.g. a `Scaffold`) so it renders as a
  dialog sized by `ConstrainedDialog` (800×600) on large screens. Use it for any
  "page" opened with `adaptivePush` (CommandQueueView, SettingsView do this).
- Minimum window size 400×600 (Windows).

## Dialogs

- Device actions, inputs, outputs are `AlertDialog`s centred inside `ConstrainedBox`
  (max width 400–500). The file explorer is a fixed 500×700 `Dialog` containing a `Scaffold`.
- Text input: use `AdbInputDialog.single(title:, label:)` → pops `String?`; multi-field
  `AdbInputDialog(inputs: {key: builder})` → pops `Map<String,String>` (empty fields omitted). Cancel pops `null`.
- Yes/No: `confirmDialog(...)` from `NavigationController` → `bool?` (`null` = dismissed / extra "Cancel" action).
- Feedback: `showSnackbar(text:)` for errors and short info; `Alert.success/error` (Lottie) for big outcomes.
- Loading: `showLoading()` / `hideLoading()` (modal spinner dialog).

## Theming — `utils/theme.dart`

- Material 3, Poppins via `google_fonts`.
- Colours come from the OS accent through `DynamicColorBuilder`; fallback seed in `AppTheme`.
- `AppTheme.themeDataFrom(colorScheme:, brightness:)` builds both themes; outlined
  8-radius input borders; always-visible scrollbars.
- `AppTheme.defaultDuration` is the standard animation duration — reuse it.
- Theme mode comes from `settingsControllerProvider` (system/light/dark).

## Shared widgets (`lib/app/shared/widgets/`) — reuse before writing new ones

| Widget | Use |
|--------|-----|
| `AsyncValueBuilder` / `SliverAsyncValueBuilder` | Render `AsyncValue` with loading/error(+try again)/data |
| `AdaptiveDialog`, `ConstrainedDialog` | Dialog sizing (see above) |
| `ConfirmDialog` | Backing widget for `confirmDialog` |
| `Alert` | Lottie success/error popup with auto-hide (`Alert.duration`) |
| `AppSnackbar` | Snackbar used by `showSnackbar` |
| `AppExceptionIndicator(Compact)`, `AppLoadingIndicator`, `AppNoItemsIndicator` | Status states |
| `Gap` | Fixed spacing |
| `AppLogo` | `assets/logo.png` |
| `PopupMenu<T>` | Dropdown used in Settings |
| `CardWithoutElevation`, `KeepAlivePage`, `PersistentHeader`, `RunAnimation` | Misc |
| `FadeSlideTransition`, `FadeSizeTransition`, `AppFadeScaleTransition`, `SharedAxisSwitcher` | Animations |
| `NavigationEventListener` | Executes EventBus navigation (mounted once at root) |

## Copy / labels

Labels are short, sentence case ("Install apk", "Push file", "Connect wireless").
Queue labels come from the `command:` argument passed to `AdbController.run`.
