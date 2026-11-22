# 08 — Full app redesign: three selectable styles

**Status:** Implemented (unreleased) — all three styles, light and dark · **Last updated:** 2026-11-22
**Mock-ups:** design canvas "ADB UI redesign options" (private to the owner).

## Decision

All three directions are built. They are **styles** the user picks: on first launch
(see [features/app-styles.md](features/app-styles.md)) and at any time in Settings.
A style is a whole layout plus its own light and dark theme — not only a colour skin.

| Style | Id (`AppStyle`) | One line | Default theme feel |
|-------|-----------------|----------|--------------------|
| **Workbench** | `workbench` | Sidebar of devices, each device a page with tabs | Light-first, cool greys, blue accent |
| **Console** | `console` | Dense three-zone dev tool with a docked activity terminal | Dark-first, near-black, green accent |
| **Launcher** | `launcher` | Device cards and a command palette as the main UI | Warm off-white, ink borders, burnt orange |

Every style supports **System / Light / Dark** (`ThemeMode`, independent of the style).
The first-run default selection is Workbench + System.

What every style shares (built once, in `lib/app/design/` and the feature folders):

- The same controllers, services and adb commands — a style only changes presentation.
- The selected device (`selectedDeviceIdProvider`), device actions (`DeviceAction`), and
  keyboard shortcuts (U8).
- The command palette (⌘/Ctrl+K), the add-device dialog (QR / Pairing code / IP address),
  the uninstall app picker, the activity list and command details, the error system
  ([features/error-handling.md](features/error-handling.md)), Settings, About.
- Design tokens through one `ThemeExtension` (`AppTokens`); widgets never hard-code colours.

## Design tokens

`AppTokens` (`lib/app/design/app_tokens.dart`) — read with `AppTokens.of(context)`. Each
style × brightness is one `AppTokens` value in `style_tokens.dart`. Text pairs below were
checked for WCAG AA (4.5:1 for body text; `textMuted` on `canvas` and `surface` too).

| Token | Use |
|-------|-----|
| `canvas` | Window background |
| `surface` | Cards, dialogs, panels |
| `surfaceAlt` | Sidebar / secondary panels / input fill |
| `border` | Card outlines (`strokeWidth` wide); heavy ink in Launcher |
| `borderSubtle` | Dividers and input outlines (same as `border` except Launcher: `#CFC6BA` light, `#3A352F` dark) |
| `text`, `textMuted` | Primary and secondary text |
| `accent`, `onAccent` | Primary buttons, selection, focus ring |
| `accentSoft`, `onAccentSoft` | Selected rows, info banners, icon tiles |
| `success`/`successSoft`/`onSuccessSoft` | Done states |
| `danger`/`dangerSoft`/`onDangerSoft` | Errors, destructive buttons |
| `warning`/`warningSoft`/`onWarningSoft` | Offline / unauthorized / hints |
| `terminal`, `onTerminal`, `onTerminalMuted` | Command output blocks and the palette (dark in every theme) |
| `terminalAccent` | Accent on `terminal` (Workbench `#8FA8FF`, Console `#3DD68C`, Launcher `#F08A5D`) |
| `radius`, `radiusLarge`, `strokeWidth` | Shape |
| `bodyFont`, `headingFont`, `monoFont` | Google Fonts family names |
| `density` | `VisualDensity` for list rows and buttons |

### Values

| Token | Workbench light | Workbench dark | Console light | Console dark | Launcher light | Launcher dark |
|-------|-----|-----|-----|-----|-----|-----|
| canvas | `#F6F7F9` | `#111318` | `#F3F4F6` | `#0E1116` | `#FBF7F2` | `#171512` |
| surface | `#FFFFFF` | `#181B21` | `#FFFFFF` | `#151A21` | `#FFFFFF` | `#211E1A` |
| surfaceAlt | `#ECEEF2` | `#14161B` | `#E9ECEF` | `#0B0E12` | `#F3EDE5` | `#1C1A16` |
| border | `#DDE1E7` | `#2A2F38` | `#D5DAE0` | `#232A33` | `#1C1A17` | `#5A534B` |
| text | `#16181D` | `#E9ECF1` | `#101418` | `#E6EAF0` | `#1C1A17` | `#F5EFE8` |
| textMuted | `#5B6472` | `#9AA3B2` | `#525B66` | `#8B95A3` | `#6B635A` | `#B5ABA0` |
| accent | `#2F5BEA` | `#7C9BFF` | `#137A43` | `#3DD68C` | `#B8410F` | `#F08A5D` |
| onAccent | `#FFFFFF` | `#0B1640` | `#FFFFFF` | `#05200F` | `#FFFFFF` | `#2A1206` |
| accentSoft | `#EAF0FF` | `#1D2850` | `#E3F4EA` | `#16241D` | `#FBE3DA` | `#3A2016` |
| onAccentSoft | `#1E3A8A` | `#C9D6FF` | `#0E5A31` | `#6BE3A8` | `#8F310A` | `#FFC9B0` |
| success | `#1F7A45` | `#5BC58A` | `#137A43` | `#3DD68C` | `#1F7A45` | `#6CC98F` |
| successSoft | `#E5F5EC` | `#12301F` | `#E3F4EA` | `#16241D` | `#E5F2E9` | `#17301F` |
| onSuccessSoft | `#17603A` | `#A7E9C1` | `#0E5A31` | `#6BE3A8` | `#1F5E38` | `#B5EBC8` |
| danger | `#B42318` | `#FF8A80` | `#B42318` | `#FF9B9B` | `#A8321A` | `#FF9C84` |
| dangerSoft | `#FDECEA` | `#3A1513` | `#FDECEA` | `#241616` | `#FBE3DA` | `#3A1A14` |
| onDangerSoft | `#8A1C12` | `#FFC9C3` | `#8A1C12` | `#FFB4B4` | `#8F310A` | `#FFC9B8` |
| warning | `#8A5A00` | `#F5B544` | `#8A5A00` | `#F2C14E` | `#8A5A00` | `#F2C14E` |
| warningSoft | `#FFF4DB` | `#33260A` | `#FFF4DB` | `#2A2210` | `#FBF0D9` | `#33280F` |
| onWarningSoft | `#6B4500` | `#FCDFA6` | `#6B4500` | `#F7DC9A` | `#6B4500` | `#F7DC9A` |
| terminal | `#16181D` | `#0B0D11` | `#101418` | `#0B0E12` | `#1C1A17` | `#0F0E0C` |
| onTerminal | `#E6E8EC` | `#E6E8EC` | `#E6EAF0` | `#E6EAF0` | `#F5EFE8` | `#F5EFE8` |
| onTerminalMuted | `#A3AAB6` | `#A3AAB6` | `#A9B4C2` | `#A9B4C2` | `#B5ABA0` | `#B5ABA0` |
| radius / radiusLarge | 8 / 12 | 8 / 12 | 4 / 6 | 4 / 6 | 10 / 14 | 10 / 14 |
| strokeWidth | 1 | 1 | 1 | 1 | 2 | 2 |
| fonts (body / heading / mono) | Inter / Space Grotesk / JetBrains Mono | same | Inter / Inter / JetBrains Mono | same | IBM Plex Sans / IBM Plex Sans / IBM Plex Mono | same |
| density | standard | standard | compact | compact | comfortable | comfortable |

Type scale (all styles; heading font for display/headline/title-large): 12 label · 13 body
(Workbench, Console) / 14 body (Launcher) · 15 title · 20 headline · 26 page title
(Launcher: 28 device name, 56 "Scan to pair."). Mono 12–13. Spacing on a 4 px grid
(4, 8, 12, 16, 24, 32). Motion: 150 ms for hover/press, 200 ms for panels; disabled when the
platform asks for reduced motion (`MediaQuery.disableAnimations`).

Dynamic colour (`dynamic_color`) and Poppins are dropped: each style owns its palette.

## Width classes (U14)

`WindowSize.of(context)` → `compact` (< 720), `medium` (720–1199), `expanded` (≥ 1200).
Minimum window 480 × 560 on all three platforms.

## Layout per style

### Workbench
- **expanded:** sidebar 240 (Devices · Add device: Pair with QR / Pair with code / Connect by
  IP · bottom: Activity with running/error count, Settings) │ device page │ right column
  "Recent activity" 300.
- **medium:** sidebar 220; the recent-activity column moves under the Overview tab content.
- **compact:** sidebar becomes a `Drawer`; top bar shows the selected device and a menu button.
- **Device page:** header (name, connection line, Mirror screen, Disconnect) + tabs:
  **Overview** (quick-action tiles for every `DeviceAction`, device details list),
  **Apps** (installed packages with search, "Show system apps", Uninstall per row, Install APK),
  **Files** (browse device storage, select, Pull selected…, Push files here…, drop to push),
  **Shell** (command field, run, output of shell commands run on this device),
  **Type text** (multi-line field, Send to device).
- No device: an empty state with the three add-device options as buttons.

### Console
- Title bar row: app name, ⌘K palette field ("Search actions…"), Settings.
- **expanded/medium:** device list 240 (200 at medium) │ center: selected device header +
  action grid (each tile shows its shortcut) + device details │ docked **activity terminal**
  at the bottom (mono, live output of the selected entry, resizable 140–60 % of height,
  collapsible to a 36 px status strip).
- **compact:** device list becomes a dropdown in the title bar; action grid 2 columns;
  activity collapses to the status strip by default.
- Light theme is supported, but the Console defaults to looking right in dark.

### Launcher
- Header: "adb ui" · Activity · Settings.
- Device cards (wrap): status line, big name, address; "+ Add device" dashed card.
  Selecting a card selects the device.
- An always-visible **palette** below the cards (dark `terminal` panel): input "Type a command"
  filters actions for the selected device, then Add device / Settings / Activity, then
  **Recent** (re-run). ↑/↓ moves, ↵ runs, Esc clears. ⌘K focuses it from anywhere.
- Bottom: "Today" activity chips (✓ / ✕ / spinner), click → command details.
- **Add device** opens the full-page "Scan to pair." screen (QR big, numbered steps, footer
  status line "waiting for phone · <name> · 1:42 left", "Use a pairing code instead",
  "New code"); pairing code / IP are links on that page.
- Compact: cards one per row, palette full width, QR page stacks QR above the steps.

## UX goals (all three styles)

The redesign is a UX overhaul, not only a new look. Each goal names today's problem, what
changes, and how we'll check it.

| # | Goal | Today | After | Check |
|---|------|-------|-------|-------|
| U1 | Fewer steps for common tasks | Device → modal list → action → input dialog → output popup (4–5 steps) | Select device once; actions are one click or one shortcut away | Install APK in ≤2 interactions from the main window |
| U2 | Output you can actually read | Output popup auto-closes after 2 s | Output stays in the activity surface, can be copied, expanded and re-run | Any past command's full output can be found without re-running it |
| U3 | No typing what the app can know | Package names, IPs and ports typed by hand | Pick from installed packages; remember recent IPs; mDNS-discovered devices offered | Uninstall without typing; reconnect a known device in one click |
| U4 | Clear add-device flow | "Do you have Android 11?" question, then a chain of dialogs | QR, pairing code and IP side by side, with QR as the default for Android 11+ | First-time pairing without reading docs |
| U5 | Progress and status always visible | Long installs/pushes show a spinner or nothing | Per-command progress, elapsed time, success/failure state in activity; device status (online/offline/unauthorized) on every device row | Never a "did it work?" moment |
| U6 | Errors that say what to do | Raw stderr in a snackbar | Plain-language message + the raw output + a next step (e.g. "Accept the prompt on your phone", "adb not found → set path") | Each error in the adb-layer catalogue has a mapped message |
| U7 | Safe destructive actions | Uninstall/disconnect run immediately | Confirm with the target named (app, device); undo where possible (e.g. reconnect) | No destructive action without the target shown |
| U8 | Keyboard-first, mouse-friendly | No shortcuts | Shortcuts for every device action, ⌘/Ctrl+K palette, full tab/focus order, Esc closes | Every action reachable without a mouse |
| U9 | Drag and drop everywhere it makes sense | Only the local file picker drop zone | Drop an APK anywhere to install; drop files on the file explorer to push | APK installs by dropping on the window |
| U10 | Good first run and empty states | Blank list when no device; init error is plain text | Empty state explains how to connect a phone; adb-missing screen with a fix (download / choose path) and a retry | A new user reaches a connected device without leaving the app |
| U11 | Multiple devices handled clearly | Every action asks which device via the modal | Selected device is always shown; actions target it; switching is one click | Never unclear which device a command runs on |
| U12 | Accessible | Unchecked contrast, Material defaults | WCAG AA contrast in light and dark, visible focus rings, semantic labels for screen readers, respects reduced motion and system text size | Contrast checked on every token pair; screen reader announces device status |
| U13 | Native feel per platform | Same custom chrome everywhere | Platform title bar conventions, native menus on macOS, platform shortcut keys (⌘ vs Ctrl) | Looks at home on macOS, Windows and Linux |
| U14 | Responsive to any window size | Fixed layouts; 500×700 file explorer dialog; content clips when the window is small | Three width classes: **compact** < 720 px (sidebar becomes a drawer, activity a toggleable bottom sheet, dialogs full-window, action grid one or two columns), **medium** 720–1199 px (sidebar collapses to an icon rail, activity docks below), **expanded** ≥ 1200 px (everything side by side). Heights adapt too (activity panel resizable, collapses on short windows). Layout also reflows at 200 % text size. Minimum window size 480 × 560. | Every screen designed and checked at 480, 960 and 1440 px wide, with nothing clipped and no horizontal scroll |

## Every surface

| # | Surface | Redesign (all styles unless noted) | UX goals |
|---|---------|-------------------------------------|----------|
| 1 | Window chrome | Windows custom caption tinted with `canvas`; macOS native menu bar kept, title-bar space respected; Linux default. Min size 480 × 560 | U13, U14 |
| 2 | Splash | Logo + "Starting adb…" on `canvas` of the default style | U5 |
| 3 | Init error | Full page from the error catalogue (title, what happened, numbered fix steps, details block, **Try again**, Copy details, Open logs) | U6, U10 |
| 4 | Home layout | Per style (above) | U1, U11, U14 |
| 5 | Device list / item | Status dot + label (online / offline / unauthorized), model, address, connection type; selected state | U5, U11 |
| 6 | Device actions | `DeviceAction` list rendered as tiles (Workbench, Console) or palette rows (Launcher), each with shortcut | U1, U8 |
| 7 | Connect by IP | Add-device dialog "IP address" tab: `host:port` with inline validation; "Android 10 or older?" section that runs `adb tcpip 5555` first | U4, U6 |
| 8 | Pair with code | "Pairing code" tab: `host:port` + 6-digit code, inline validation | U4, U6 |
| 9 | Pair with QR | "QR code" tab (Workbench, Console) / full page (Launcher); unchanged protocol | U4 |
| 10 | Text inputs | Themed `AppTextField` with label, hint, inline error; Enter submits | U6, U8 |
| 11 | Local file picker / drop zone | Themed; dropping an `.apk` on the main window installs on the selected device | U9 |
| 12 | Device file explorer | Workbench: Files tab. Others: dialog sized to the window (max 640 × 760, full-window at compact) | U14, U9 |
| 13 | Command output | Removed as an auto-closing popup. `CommandDetailsDialog`: live output, status, duration, explained error, Copy, Re-run | U2, U6 |
| 14 | Activity (was command queue) | Shared `ActivityList` with filter All / Running / Errors, rows with status, device, duration, explained error line, Re-run, Remove; Clear all | U2, U5 |
| 15 | Settings | Page: Appearance (Style cards with previews, Theme System/Light/Dark), About app | — |
| 16 | About / update / report | Same content, themed with tokens | — |
| 17 | Feedback | `AppToast` (success 3 s, error 8 s with **Details** and **Retry**), `AppBanner`, `EmptyState`, inline progress | U5, U6 |
| 18 | Theme | `AppTokens` × 3 styles × light/dark | U12 |
| 19 | Iconography | Material Icons, rounded/outlined variants, 16–20 px; no emoji | — |

## Product changes (decided)

1. Devices are **selected** (master/detail) instead of opening a modal action list.
2. Command output lives in activity; no 2 s auto-closing popup.
3. No "Do you have Android 11?" question: QR, pairing code and IP are side by side.
4. Uninstall picks from installed packages (`pm list packages`).
5. Command palette and shortcuts for every device action.
6. A first-run style picker; style and theme can be changed any time in Settings.

## Not in this round

Remembered recent IPs (U3, part) and undo for disconnect (U7, part) — tracked in
`07-roadmap.md`.

## Second pass (2026-11-22): screens still on the old design

| Surface | Redesign |
|---------|----------|
| Device folder/file chooser (`AdbFileExplorerView`, used by Push and Pull) | Same look as the Files tab: title + close, **starts in `/sdcard`** (not `/`), breadcrumb path bar with Up and an editable path, Refresh, quick places (Internal storage `/sdcard`, Download, DCIM, Pictures, Documents), folders first then files sorted A–Z, file sizes hidden, checkbox selection for files with "N selected", footer **Cancel** + primary button "Push here" / "Pull N files", explained errors via `ErrorPanel`. Local state (no global controller), so selection never leaks (fixes 06 #5). Full window at compact. |
| About | Page in `AdaptiveDialog`: logo, name, version, update status row (checking / up to date / "Version X is available" + Download), buttons Changelog · Licenses · GitHub, "Report a bug or request a feature" card. |
| Report a bug / feature request | Dialog with two choice cards (Bug report / Feature request), "Include device details in the log file" switch for bugs, explanation that a log zip is saved and GitHub opens; success uses a toast, not the Lottie alert. |
| Update available (startup) | Themed dialog: "ADB UI X is available", the release's changelog text, **Download** / **Later**. |
| Loading overlay | Themed spinner card instead of the default dialog. |

`Alert` (Lottie) and `confirmDialog`'s old `ConfirmDialog` are no longer used by redesigned code.

## Built (2026-11-22)

Checked on macOS with a Pixel 10 Pro over Wi-Fi: first-run picker (live re-theme, Continue),
Settings style/theme switching without restart, Workbench (Overview, Apps with 75 packages,
Files on /sdcard, uninstall confirmation, palette, toast) in light at 500 px wide, Console in
light at 1383 px and compact, Launcher in dark at both widths, the explained permission error
in the file explorer. Not yet seen live: an error toast from a failed command (covered by unit
tests of the catalogue), Windows and Linux.
