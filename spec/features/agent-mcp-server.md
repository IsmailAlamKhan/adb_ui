# Feature: AI agent access (MCP server + UI-test tools)

**Status:** Shipped in 0.0.19 · **Code:** `lib/app/features/agent/`
**Owner / requested by:** Ismail · **Last updated:** 2026-11-24

## Problem

AI agents (Claude Code, Claude Desktop, other MCP clients) can't use ADB UI. They have to
call `adb` themselves, so nothing they do shows in Activity, and they have no help for
driving an app's UI in a test (finding a button, waiting for a screen, checking text).

## Behaviour

### Turning it on (Settings → AI agents)

A new **AI agents** section in Settings, below **AI**:

- Switch **Let AI agents use ADB UI** — off by default. When on, ADB UI starts a local
  MCP server; when off, it stops it. The choice is saved and the server starts with the
  app when it was on.
- Status line: `Listening on http://127.0.0.1:<port>/mcp`, `Stopped`, or the start error
  (e.g. `Port 47123 is in use. Pick another port.`).
- **Port** field (default `47123`), applied with **Apply** (restarts the server if running).
- **Access token**: shown masked with **Copy** and **New token** (new token invalidates the
  old one at once). The token is created the first time the switch is turned on.
- **Copy Claude Code command** copies
  `claude mcp add --transport http adb-ui http://127.0.0.1:<port>/mcp --header "Authorization: Bearer <token>"`.
- **Copy JSON config** copies an `mcpServers` entry (`type: http`, `url`, `headers`) for
  other MCP clients.
- When risky actions were allowed for the session: a line
  `Risky actions are allowed until ADB UI quits.` with **Ask again**.
- **Open test runs folder** opens `<app support>/agent_runs/` in the file manager.

### Safety

- Off by default. Binds to `127.0.0.1` only (never other interfaces).
- Every request needs `Authorization: Bearer <token>`; otherwise `401`.
- Requests with a `Host` other than `127.0.0.1:<port>` / `localhost:<port>`, or an
  `Origin` that isn't `http://localhost…` / `http://127.0.0.1…`, get `403` (DNS rebinding).
- **Risky tools** (`install_apk`, `uninstall_app`, `clear_app_data`, `shell`, `push_file`,
  `pull_file`) show a dialog in the app before running:
  title `Allow an AI agent to <action>?` (`install an app`, `uninstall an app`, `clear an app's data`,
  `run a shell command`, `copy a file from the device`, `copy a file to the device`), the exact details (package, path or command),
  checkbox **Allow risky actions until ADB UI quits**, buttons **Deny** / **Allow**.
  Deny (or closing the dialog) returns a tool error `The user denied this action.`.
  Before the dialog opens, ADB UI restores and focuses its window (`windowManager`), since a
  covered Flutter window doesn't repaint and the dialog would go unseen.
  Only one confirmation dialog is open at a time; others wait in order.
- Every adb command a tool runs goes through `AdbController.runForResult(showOutput: false)`,
  so it appears in Activity labelled `Agent · <what>`, with no toast. Large outputs
  (UI dumps, logcat, screenshots) are stored in Activity as a one-line summary, not the data.

### Device choice

Every device tool takes an optional `device` (adb serial). Without it: the only online
device; if none, error `No device connected.`; if several, error listing the serials.

### Tools

General:

| Tool | Does | Risky |
|------|------|-------|
| `list_devices` | Serial, state, model of each device | |
| `device_info` | Model, maker, Android version, SDK, ABI, screen size | |
| `list_packages` | Installed packages (`include_system` optional) | |
| `install_apk` | Install a host `.apk` path; optional `user` (id or `"all"`), else `--user current` ([install-profiles.md](install-profiles.md)) | yes |
| `uninstall_app` | Uninstall a package | yes |
| `launch_app` | Start a package's launcher activity (`monkey -p <pkg> -c android.intent.category.LAUNCHER 1`) | |
| `stop_app` | `am force-stop <pkg>` | |
| `clear_app_data` | `pm clear <pkg>` | yes |
| `screenshot` | PNG of the screen (MCP image content) | |
| `tap` | `input tap x y` | |
| `swipe` | `input swipe x1 y1 x2 y2 [ms]` | |
| `type_text` | `input text` into the focused field | |
| `press_key` | `input keyevent` — `back`, `home`, `enter`, `recents`, `delete`, `tab`, `escape`, `power`, `volume_up`, `volume_down`, `menu`, `search`, or a `KEYCODE_*` / number | |
| `shell` | `adb shell <command>`, returns output and exit code | yes |
| `logcat` | Recent log (`adb logcat -d -t <lines>`), filtered like the Logcat screen: `preset` (`all`/`warnings`/`errors`/`crashes`), `package`, `min_level`, `text`; `clear` clears after reading | |
| `list_files` | List a device folder | |
| `pull_file` | Copy device file → host path | yes |
| `push_file` | Copy host file → device folder | yes |

UI testing:

| Tool | Does |
|------|------|
| `ui_dump` | View hierarchy (`uiautomator dump`) as one line per useful element: index, class, text, resource id, content-desc, bounds, center, flags. `all: true` lists every node. |
| `find_elements` | Elements matching a selector |
| `tap_element` | Tap the center of the matching element (`nth` picks among several, default first) |
| `wait_for_element` | Re-dump every 500 ms until the selector matches (or, with `gone: true`, stops matching); `timeout_ms` default 10000, max 60000 |
| `assert_element` | Pass/fail: `exists` (default), `gone`, or `text_equals`. A failure is a tool error starting `FAIL:` |
| `start_test_run` | Start recording a run named `name` |
| `end_test_run` | Stop recording with `status` (`passed`/`failed`) and `notes`; returns the folder |

A **selector** is any of `text`, `text_contains`, `resource_id`, `content_desc`, `class_name`
(AND-ed; text matching ignores case for `text_contains` only). `resource_id` matches the
full id or the part after `:id/`. Element tools take the selector fields directly.

`uiautomator dump` sometimes fails while the screen animates; the dump is retried once.

### Test runs

While a run is recording, each tool call is a step: time, tool, arguments, ok/failed,
a short result. Screenshots taken during the run are saved as `step-<n>.png`.
`end_test_run` writes `run.json` and a readable `report.md` into
`<app support>/agent_runs/<yyyyMMdd-HHmmss>-<name>/`. Starting a run while one is
recording ends the old one as `abandoned`.

## MCP transport

Streamable HTTP, JSON responses only (no SSE stream, no sessions): `POST /mcp` with a
JSON-RPC 2.0 message. Supported methods: `initialize`, `ping`, `tools/list`,
`tools/call`; notifications get `202`. `GET`/`DELETE` → `405`. Protocol version: echoes
the client's if it is one of `2024-11-05`, `2025-03-26`, `2025-06-18`, `2025-11-25`,
else `2025-06-18`. Unknown method → JSON-RPC error `-32601`; bad JSON → `-32700`.
Tool failures are results with `isError: true`, not JSON-RPC errors.

## adb / process commands

All with `-s <serial>`, through `AgentController._runInActivity`. Labels in Activity start with `Agent · `.
Each command times out for the agent after 60 s (`<label> got no answer from adb in 60s…`); finding the
device (`adb devices`) after 20 s. The adb process itself is not killed.
`device_info`, `list_packages`, `list_files` and the `package` lookup of `logcat` use the existing
read-only service calls (not in Activity), like the rest of the app.

| Command | Success when | Message | Re-runnable from queue? |
|---------|--------------|---------|-------------------------|
| `exec-out screencap -p` | exit 0, PNG bytes | `Screenshot <w>×<h>` | yes (`exec-out` case) |
| `shell 'uiautomator dump /sdcard/.adb_ui_dump.xml >/dev/null && cat /sdcard/.adb_ui_dump.xml'` (one argument, so the host shell doesn't read `&&`) | output has `<hierarchy` | `UI dump: <n> elements` | yes (`''` → custom; see known issues) |
| `logcat -d -v threadtime -t <n>` | exit 0 | `<n> log lines` | yes (`''` → custom command) |
| `shell input tap/swipe/keyevent …`, `shell am force-stop`, `shell pm clear`, `shell monkey …`, `shell <agent command>` | exit 0 | output or `Done` | yes |
| install / uninstall / push / pull / `input text` | existing `AdbService` methods | existing | yes |

New `AdbService` methods: `runArguments(device, arguments, {summarize})` (exit-code
checked, big output kept out of Activity when `summarize` is given) and
`screenshot(device, onBytes)`.

## Data & persistence

- `LocalStorageKeys.agentServer` (`agent_server`): `AgentServerSettings` JSON
  `{enabled: bool, port: int, token: String}`. Plain class with `toJson`/`fromJson`.
- `agentControllerProvider` — `StateNotifierProvider<AgentController, AgentState>`;
  `AgentState {settings, running, error, allowRiskyForSession, activeRun}`.
- `mcpServerProvider` — `Provider<McpServer>` (`McpHttpServerImpl`).
- `agentSettingsServiceProvider` — `Provider<AgentSettingsService>`.
- Pure helpers: `UiNode.parseDump`, `UiSelector`, `McpProtocol` (JSON-RPC handling, no I/O).

## Files to touch

- `lib/app/features/agent/` — `agent.dart`, `agent_model.dart`, `agent_service.dart`
  (settings, `McpProtocol`, `McpHttpServerImpl`, `FileAgentRunRecorderImpl`), `agent_tools.dart`
  (`AgentToolbox`), `agent_controller.dart`, `agent_view.dart` (`AgentSettingsCard`, `AgentConfirmDialog`)
- `test/agent_mcp_test.dart`
- `lib/app/features/features.dart` barrel
- `lib/app/features/adb/adb_service.dart` (`runArguments`, `screenshot`, rerun case)
- `lib/app/features/settings/settings_view.dart` (section)
- `lib/app/shared/services/local_storage.dart` (key)
- `lib/app/app.dart` (start server at startup when enabled)
- Spec: `README.md`, `01-architecture.md`, `02-adb-layer.md`, `03-data-models.md`,
  `04-ui-conventions.md`, `06-known-issues.md`; `CHANGELOG.md`, `docs/user-guide.md`

## Acceptance criteria

- [x] Off by default; switching on starts the server and shows the URL; off stops it.
- [x] Requests without the token get 401; wrong Host/Origin get 403.
- [ ] `initialize` → `tools/list` → `tools/call` works from Claude Code with the copied command.
- [x] Every adb command an agent runs shows in Activity as `Agent · …`, without toasts.
- [x] Risky tools ask first; Deny returns an error; Allow runs the tool (verified live 2026-11-24). "Allow until quit" not yet checked live.
- [ ] `ui_dump`, `find_elements`, `tap_element`, `wait_for_element`, `assert_element` work on a real app screen.
- [x] A recorded run writes `run.json`, `report.md` and step screenshots.
- [x] Unit tests cover dump parsing, selectors, JSON-RPC handling and HTTP auth.
- [ ] Works on Windows / macOS / Linux (loopback server; no platform code).

## Out of scope

- SSE streaming, MCP sessions, resources/prompts, OAuth.
- Per-agent tokens and per-tool allowlists (one token; risky tools always confirm).
- Driving ADB UI's own screens (mirror window, file browser) from the agent.
- Recording a run as video.

## Verification (2026-11-24)

- Unit tests: `test/agent_mcp_test.dart` (20 tests: dump parsing, selectors, key names, settings
  JSON, JSON-RPC, HTTP auth/Host/Origin on a real loopback socket, run recorder).
- Live, debug macOS build + Pixel 10 Pro (Android 17) over Wi-Fi, driven by a small HTTP MCP client:
  `initialize`, `tools/list` (25 tools), `list_devices`, `device_info`, `press_key`, `screenshot`,
  `ui_dump`, `find_elements`, `wait_for_element` (found and timed out), `assert_element`
  (exists / gone / text_equals, PASS and FAIL), `logcat` with the `errors` preset, `list_files`,
  `list_packages`, and a recorded run (`report.md`, `run.json`, step screenshot). Activity listed
  every command as `Agent · …`. The settings section renders and shows `Listening on …`.
- Risky actions: the dialog opened, **Deny** returned `The user denied this action.`, and after
  the user clicked **Allow** the shell command ran (Activity: `Agent · shell getprop …` →
  `Pixel 10 Pro`). The first try found that a covered window doesn't repaint, so the dialog went
  unseen; ADB UI now brings its window to the front first. `launch_app` also ran from that session.
  Not checked: the "allow until quit" checkbox, `tap_element` inside an app.

## Open questions

- None blocking. Per-agent tokens may come later if more than one agent is used at once.
