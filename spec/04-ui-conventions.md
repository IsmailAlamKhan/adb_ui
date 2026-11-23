# 04 — UI conventions

The UI comes in three selectable **styles** (Workbench, Console, Launcher), each in light and
dark. Design decisions, tokens and per-style layouts: [08-redesign.md](08-redesign.md).
This file covers how the UI code is put together. Last updated 2026-11-22.

## Screen map

```
SplashView ──(init ok)──► MaterialApp (theme = AppThemeFactory(style, brightness))
                            ├─ settings.style == null → StylePickerView (first run)
                            └─ UpdateChecker
                                 └─ HomeShell  (AppShortcuts + ApkDropZone)
                                      ├─ WorkbenchHome  sidebar │ device page (tabs: Overview, Screen, Logcat, Apps, Files, Shell, Type text)
                                      ├─ ConsoleHome    title row │ device list │ action grid │ docked activity terminal
                                      └─ LauncherHome   device cards · inline CommandPalette · "Today" chips
           ──(init fails)──► AppInitErrorView (explained error, Try again)

Shared dialogs/pages (all styles):
  AddDeviceDialog (QR code | Pairing code | IP address)  ·  QrPairPage (Launcher's full-page QR)
  CommandPaletteDialog (⌘K)  ·  CommandDetailsDialog  ·  ActivityView  ·  SettingsView → AboutView
  UninstallPickerDialog  ·  AdbFileExplorerView (pull picker / push browser, with FilePreviewPane)  ·  FilePickerView (APK only)
  FilePreviewDialog (Space: large preview, ← / →)
  AdbInputDialog  ·  ConfirmActionDialog  ·  ErrorDetailsDialog
  LogcatPage (⌘L)  ·  MirrorPage (⇧⌘M)  ·  AboutView  ·  UpdateAvailableDialog
macOS menu "About Adb ui" ► AboutView
```

## Folders

| Folder | Holds |
|--------|-------|
| `lib/app/design/` | `AppStyle`, `AppTokens` (+ `style_tokens.dart` values), `AppThemeFactory`, `WindowSize`, shortcut helpers, `widgets/design_widgets.dart` |
| `features/shells/` | `HomeShell`, `WorkbenchHome`, `ConsoleHome`, `LauncherHome`, `ApkDropZone` |
| `features/device_page/` | Device building blocks used by all styles: status line, list tile, action grid/tile, details card, state banner, Apps / Files / Shell / Type text views, `NoDeviceState` |
| `features/palette/` | `CommandPalette` (inline or dialog), `buildPaletteItems` |
| `features/add_device/` | `AddDeviceDialog`, `AddDeviceTab` |
| `features/apps/` | `AppIcon`, `AppLetterTile`, `AppInfoController`, `AppInfoService`, `AppInfoDiskCache` |
| `features/file_preview/` | `FilePreviewPane`, `FilePreviewContent`, `FilePreviewDialog`, `showFilePreview`, `FilePreviewService` |
| `features/errors/` | `AppError`, `ErrorCatalogue`, `ErrorExplanation`, `ErrorDetailsDialog`, `ErrorPanel` |
| `features/style_picker/` | `StylePickerView`, `StyleChooser`, `StylePreview`, `ThemeModeChooser` |

## Rules

- **Never hard-code colours.** Read `AppTokens.of(context)`; Material widgets pick tokens up
  from the theme. Text on the always-dark terminal surfaces uses `onTerminal`,
  `onTerminalMuted`, `terminalAccent` (not `accent`, which may be dark in light themes).
- **Layout by width class**, not raw pixels: `WindowSize.of(context)` → compact (< 720),
  medium (720–1199), expanded (≥ 1200). Every screen must work at 480 px wide.
- **A style changes presentation only.** Behaviour lives in controllers and in the shared
  `features/device_page`, `palette`, `add_device`, `errors` widgets. A new device action is
  added once to `DeviceAction` and appears in every style, the palette and shortcuts.
- **Errors** go through the error catalogue (see [features/error-handling.md](features/error-handling.md)):
  `showError(e)` for toasts, `ErrorPanel(error:)` for in-place failures (also the default of
  `AsyncValueBuilder`), `AppBanner` for device state. Never show raw exception text alone.
- **Destructive actions** confirm with `ConfirmActionDialog` naming the target.
- **Accessibility:** real buttons/inputs, `Semantics` labels on status dots and icon-only
  controls, visible focus (theme `focusColor`), `MediaQuery.disableAnimations` respected,
  contrast pairs checked (all `AppTokens` text pairs pass WCAG AA).

## Feedback

| Need | Use |
|------|-----|
| Command finished | automatic: `AdbController.runForResult` shows a success toast ("Show output") or an error toast (Details, Retry) |
| Short info / success | `showToast(tone:, title:, message:, actions:)`, `showSuccess(...)` |
| Error | `showError(error, onRetry:, onDetails:)` — explained by `ErrorCatalogue` |
| Loading list failed | `ErrorPanel` (via `AsyncValueBuilder`) with Try again |
| Device unauthorized / offline | `DeviceStateBanner` |
| Empty | `EmptyState`, `NoDeviceState` |
| Running | spinner in `CommandStatusIcon`; live output in `CommandDetailsDialog`, Console dock, Shell tab |

`showSnackbar(text:)` still exists and now shows an info toast.

## Dialogs and pages

- `AdaptiveDialog` + `adaptivePush`: page as a 800×600 dialog on larger windows, full page at
  < 500 px (`isTabletOrLarger`). Used by Settings and Activity.
- Plain dialogs use `Dialog` with `insetPadding: dialogInset(context)` (12 px when compact,
  40 px otherwise) and a `maxWidth` (460–680).
- Text input: `AdbInputDialog.single(title:, label:, hint:, prefix:, info:, validator:)` → `String?`,
  inline error, Enter submits.

## Keyboard (`AppShortcuts`, ⌘ on macOS, Ctrl elsewhere)

⌘K palette · ⌘N add device · ⌘, settings · ⇧⌘A activity · device actions: ⌘I install,
⌘U uninstall, ⌘P push, ⇧⌘P pull, ⌘R run command, ⌘T type text, ⇧⌘M mirror (in-app), ⌘L logcat, ⇧⌘C copy id,
⇧⌘D disconnect. Palette: ↑/↓, ↵, Esc. Style picker cards: arrow keys.

## Shared widgets (`lib/app/shared/widgets/`, older)

Still used: `AdaptiveDialog`, `ConstrainedDialog`, `AsyncValueBuilder` (error → `ErrorPanel`),
`AppLogo`, `Gap`, `NavigationEventListener`, transitions, `ConfirmDialog` (legacy `confirmDialog`).
`Alert`, `AppExceptionIndicator`, `PopupMenu` are legacy; prefer the design widgets.

## Copy / labels

Short, sentence case. Activity labels name the target: "Install app-release.apk",
"Uninstall com.example", "adb shell ls". Errors: plain title + "What to do" steps.
