# Feature: Desktop shell (window, title bar, menu bar)

**Status:** Shipped · **Code:** `app.dart` (`WindowTitleBar`, `AppWrapper`), `menubar/menubar_view.dart`, `splash/`, `app_init_error/`

## Per-platform chrome

| Platform | Behaviour |
|----------|-----------|
| Windows | Native title bar hidden; custom 30 px `WindowCaption` with logo + "ADB UI"; right-click opens the system window menu; `VirtualWindowFrameInit` wraps the app; themed via `_AppThemeBuilder` (follows platform brightness when theme = system). |
| macOS | `CustomMenuBar` (`PlatformMenuBar`): app menu with **About ADB UI**, **Open Application Support** (⌥A, opens the support dir in Finder), Hide/Hide others/Show all, Quit; **View** → full screen; **Window** → bring to front / zoom / minimise. Top padding adjusted for the transparent title bar. |
| Linux | Plain system window, no custom chrome. |

## Splash & init error

- `SplashView` — spinner shown while `App.init` runs; light/dark from OS brightness.
- `AppInitErrorView` — full app shell (same theming) showing `AppExceptionIndicator`
  titled "App Initialization Error" with the exception message.

## Global behaviours

- Tapping anywhere unfocuses the current text field.
- `NavigationEventListener` is mounted here around the root navigator.
