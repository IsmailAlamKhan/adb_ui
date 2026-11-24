# Feature: App styles (first-run picker and Settings)

**Status:** Shipped in 0.0.16 · **Code:** `lib/app/design/`, `lib/app/features/style_picker/`, `lib/app/features/settings/`
**Owner / requested by:** owner · **Last updated:** 2026-11-22

## Problem

The app has one look. The owner wants all three redesign directions (Workbench, Console,
Launcher — see [08-redesign.md](../08-redesign.md)) to be available, chosen on first launch
and changeable later.

## Behaviour

### First launch
1. After the splash, if `SettingsModel.style` is `null` (fresh install, or an install from
   before this feature), the **style picker** page is shown instead of home.
2. Title "Choose how ADB UI looks", subtitle "You can change this any time in Settings."
3. Three selectable cards (radio semantics, arrow keys move, Space/Enter selects): a live
   miniature preview built from the style's tokens, the name, and one line:
   - Workbench — "Sidebar of devices. Each device gets tabs for apps, files and shell."
   - Console — "Dense and keyboard-driven, with a docked activity terminal."
   - Launcher — "Big device cards and a command palette for everything."
4. Below: **Theme** segmented control System / Light / Dark. The whole picker re-themes live
   to the highlighted style and theme.
5. **Continue** saves both, sets `setupGateProvider` to `SetupMode.firstRun` and opens
   Setup ([onboarding.md](onboarding.md)), then home in that style. There is no skip: Continue with the
   default selection (Workbench, System) is the skip.
6. At compact width the cards stack vertically and the page scrolls.

### Settings
- Settings is a page (dialog at medium/expanded, full window at compact) with sections:
  - **Appearance:** *Style* — the same three cards (smaller); *Theme* — System / Light / Dark.
    Changes apply immediately and are saved.
  - **About:** About ADB UI (version, links), opens `AboutView`.
- Shortcut ⌘/Ctrl+, opens Settings in every style.

## adb / process commands

None.

## Data & persistence

- `enum AppStyle { workbench, console, launcher }` (`design/app_style.dart`) with
  `label` and `tagline`.
- `SettingsModel` gains `AppStyle? style` (JSON key `style`, stored as the enum name;
  missing or unknown → `null`, which shows the picker). `SettingsModel.initial.style == null`.
- `SettingsController.setStyle(AppStyle)`, `completeOnboarding(AppStyle, ThemeMode)`.
- Theme: `AppThemeFactory.build(style, brightness)` → `ThemeData` with `AppTokens` attached.
  When `style` is null the picker's highlighted style is used for theming.

## Files to touch

- `lib/app/design/` (new): `app_style.dart`, `app_tokens.dart`, `style_tokens.dart`,
  `app_theme_factory.dart`, `window_size.dart`, `widgets/` (shared UI parts), `design.dart` barrel.
- `lib/app/features/style_picker/` (new): picker view + style preview widget.
- `lib/app/features/settings/`: model, controller, view.
- `lib/app/app.dart`: theming through `AppThemeFactory`, root switches picker / home.
- Specs: `03-data-models.md`, `features/settings.md`, `README.md` table, `04-ui-conventions.md`.

## Acceptance criteria

- [x] Fresh install shows the picker; Continue saves and opens home in the chosen style.
- [x] An existing install (settings JSON without `style`) shows the picker once, keeping its theme mode (unit-tested).
- [x] Changing style or theme in Settings re-themes and re-lays-out the app immediately, no restart.
- [ ] All three styles work in light and dark, at 480, 960 and 1440 px wide. (Checked on macOS at 500 and 1383 px: Workbench light, Console light, Launcher dark. Not every combination.)
- [ ] Picker is keyboard operable and its cards are announced as radio buttons.
- [ ] Works on Windows / macOS / Linux.

## Out of scope

Per-device styles, custom accent colours, importing themes.
