# Feature: Command queue & command output

**Status:** Shipped · **Code:** `command_queue/`, `terminal_outputs/terminal_outputs_view.dart`

## Controller — `CommandQueueController` (`StateNotifier<List<CommandModel>>`)

- `init()` loads persisted commands (all `done`/`error`).
- `addCommand(c)` prepends and wires streams:
  - `adding`: creates a broadcast `StreamController`, pipes stdout → data, stderr → **error**,
    emits `"Running: <label>"`, emits `"Done"` when stdout closes; state → `running`.
  - `running`: buffers every event; an event containing `Done` → `done(buffer)`;
    any stream error → `error(buffer)`.
  - On `done`/`error`: cancels subscriptions and **persists** via `CommandQueueService.saveCommand`.
- `updateCommand(c)` replaces by id (also used by `AdbController.run` to force `error`
  when `Result.messege` throws).
- `removeCommand(c)` removes from state + storage. `clear()` empties both and cancels all streams.

> Note: any stderr output marks a command as **error** even if adb succeeded.

## CommandQueueView

Opened from the home AppBar via `adaptivePush`, wrapped in `AdaptiveDialog`.

- SliverAppBar "Command Queue" with **clear all** action.
- Empty → "No commands in queue".
- Row: leading icon (✓ done, ⚠ error, spinner running), title = label (+ " (rerun)"),
  subtitle = `Started <time ago> | Finished in <ms>ms` + device model,
  trailing **remove** (✕) and, when finished, **Re-run** (↻ → `AdbController.rerunCommand`).
- Tap → `CurrentCommandOutput(commandId)`.

## CurrentCommandOutput

Dialog (max 500×600), title = label + " on <model>". Content is selectable:
running → latest stream event (or "Running..."), done → full output, error → error text.
"Close" button. Route identified by `CurrentCommandOutput.routeSettings`
(`/terminal_outputs/current_command_output`) so the controller can close it.

## Re-run

Uses stored `rawCommand` + `arguments` + `device` (see 02-adb-layer re-run mapping).
New entry gets id `rerun-<uuid>`, output dialog stays open.
