# Feature: Settings

**Status:** Shipped (redesign in progress, see [app-styles.md](app-styles.md)) · **Code:** `settings/`

- `SettingsView` (via `adaptivePush`, inside `AdaptiveDialog`), AppBar "Settings":
  - **Theme mode** — `PopupMenu<ThemeMode>` with System / Light / Dark; subtitle shows current.
  - **About app** → `AboutView`.
- `SettingsController.setThemeMode` → `save()` persists `SettingsModel` under key `settings`
  then updates state; the whole app re-themes through `AppWrapper`.
- Default: `ThemeMode.system`.

**Adding a setting:** add a field to `SettingsModel` with a default in `initial` (and a
`@Default` so old stored JSON without the field still parses), a setter on the
controller, a tile in the view, and update this file + 03-data-models.

## Redesign (in progress)

Settings becomes a page with **Appearance** (Style: Workbench / Console / Launcher cards;
Theme: System / Light / Dark) and **About**. ⌘/Ctrl+, opens it. Full behaviour in
[app-styles.md](app-styles.md).
