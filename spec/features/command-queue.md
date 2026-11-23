# Feature: Activity (command queue) and command output

**Status:** Shipped; redesigned in 0.0.16 · **Code:** `command_queue/` (`CommandQueueController`, `command_queue_view.dart`)

Every command run through `AdbController.runForResult` is recorded here, newest first, and
persisted (`commands` key, see 03-data-models).

## Controller — `CommandQueueController` (`StateNotifier<List<CommandModel>>`)

- `init()` loads persisted commands (all `done`/`error`), sorted newest first.
- `addCommand(adding)` subscribes to stdout and stderr into a live buffer
  (`liveOutput(id)` → `ValueListenable<String>`) and stores the entry as `running`.
- `complete(id, message)` → `done` with the buffered output (or `message` if nothing was
  printed); `fail(id, error)` → `error` with the exception text followed by the output.
  Both persist the entry. **Streams never decide the final state** — `Result.messege` does
  (so stderr warnings and the word "Done" in output no longer end or fail a command).
- `removeCommand(c)`; `clear()` removes finished entries (running ones stay).
- `byId(id)`.

## Where it's shown (all share `ActivityList` / `ActivityTile` / `CommandStatusIcon`)

| Style | Surface |
|-------|---------|
| Workbench | Sidebar **Activity** (spinner while running, red count of failures) → `ActivityView`; "Recent activity" column / card on Overview (this device, 6 items); Shell tab shows the latest shell command's output |
| Console | Docked terminal: list (filter All / Errors, Clear finished) + live output of the selected entry, resizable 140 px–60 %, collapsible strip showing the latest entry; compact: list only, tap opens details |
| Launcher | "Today" chips (✓ / ✕ with explained error title / spinner) and **Activity** in the header |

Row: status icon, label, explained error title (red) for failures, device · time ago ·
duration · "re-run", and a **Run again** button. Tap → `CommandDetailsDialog`.

`ActivityView` (⇧⌘A, palette): `AdaptiveDialog` page with filters All / Running / Errors and
**Clear finished**.

## CommandDetailsDialog

Status icon, label, `Running/Done/Failed · device · duration · time ago`, the raw command line,
the explained error (title, message, numbered steps) for failures, then **Output** (live while
running, mono, selectable, copy button). Buttons: **Copy output**, **Run again**, **Close**.
Opened from activity rows and from the toasts ("Show output", "Details").

The old `CurrentCommandOutput` popup (auto-closing after 2 s) is removed.

## Re-run

Uses stored `rawCommand` + `arguments` + `device` (see 02-adb-layer re-run mapping). The new
entry gets id `rerun-<uuid>`.
