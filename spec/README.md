# ADB UI — Specification

This folder is the **source of truth** for what ADB UI does and how it is built.
Any human or AI agent should be able to read this folder and understand the whole
app without opening the code first.

> **Spec-first rule:** every new feature, behaviour change, or refactor starts by
> updating this folder. Code follows the spec, not the other way round.
> See [WORKFLOW.md](WORKFLOW.md) for the exact process.

## Reading order

| # | File | What it covers |
|---|------|----------------|
| 1 | [00-overview.md](00-overview.md) | Product, platforms, feature list, tech stack |
| 2 | [01-architecture.md](01-architecture.md) | Layers, folder layout, DI, startup, navigation, errors |
| 3 | [02-adb-layer.md](02-adb-layer.md) | How adb/scrcpy processes are run; every command and its success check |
| 4 | [03-data-models.md](03-data-models.md) | Models, state shapes, persistence keys and JSON |
| 5 | [04-ui-conventions.md](04-ui-conventions.md) | Screens, dialogs, theming, shared widgets |
| 6 | [05-build-and-release.md](05-build-and-release.md) | Codegen, running, CI, versioning, release |
| 7 | [features/](features/) | One spec per user-facing feature |
| 8 | [06-known-issues.md](06-known-issues.md) | Bugs and tech debt seen in the current code |
| 9 | [07-roadmap.md](07-roadmap.md) | Planned / proposed work, not yet built |
| 10 | [08-redesign.md](08-redesign.md) | Full UI redesign: scope, directions, decisions (in progress) |

### Feature specs

| Feature | File | Status |
|---------|------|--------|
| Device list (home) | [features/device-list.md](features/device-list.md) | Shipped |
| Wireless connect & pair | [features/wireless-connect-pair.md](features/wireless-connect-pair.md) | Shipped |
| Pair & connect with QR code | [features/qr-pairing.md](features/qr-pairing.md) | Shipped in 0.0.16 |
| Restart adb (fix stalled Wi-Fi discovery) | [features/restart-adb.md](features/restart-adb.md) | Shipped in 0.0.19 |
| In-app updates and changelog | [features/updates.md](features/updates.md) | Shipped in 0.0.19 |
| App styles (first-run picker, Settings) | [features/app-styles.md](features/app-styles.md) | Shipped in 0.0.16 |
| Error handling & display | [features/error-handling.md](features/error-handling.md) | Shipped in 0.0.16 |
| Logcat (follow app, foreground, presets) | [features/logcat.md](features/logcat.md) | Shipped in 0.0.17 |
| AI log filter (on-device model) | [features/ai-log-filter.md](features/ai-log-filter.md) | Shipped in 0.0.17 |
| In-app screen mirror | [features/screen-mirror.md](features/screen-mirror.md) | Shipped in 0.0.17 |
| File preview (pane + Quick Look) | [features/file-preview.md](features/file-preview.md) | Shipped in 0.0.18 |
| App icons and names (on-device helper) | [features/app-icons.md](features/app-icons.md) | Shipped in 0.0.18 |
| AI agent access (MCP server + UI-test tools) | [features/agent-mcp-server.md](features/agent-mcp-server.md) | Shipped in 0.0.19 |
| Setup & requirements (first-run onboarding) | [features/onboarding.md](features/onboarding.md) | Shipped in 0.0.19 |
| Device actions | [features/device-actions.md](features/device-actions.md) | Shipped |
| Device file explorer & file transfer | [features/file-explorer-transfer.md](features/file-explorer-transfer.md) | Shipped |
| Command queue & output | [features/command-queue.md](features/command-queue.md) | Shipped |
| Settings (theme) | [features/settings.md](features/settings.md) | Shipped |
| About, update check, bug report | [features/about-updates-reporting.md](features/about-updates-reporting.md) | Shipped |
| Desktop shell (window, title bar, menu bar) | [features/desktop-shell.md](features/desktop-shell.md) | Shipped |
| Logging & log export | [features/logging.md](features/logging.md) | Shipped |

New feature? Copy [templates/feature-spec.md](templates/feature-spec.md).

## Glossary

- **adb** — Android Debug Bridge, the CLI the app wraps. Found on `PATH` or in the app's own `tools/platform-tools` folder (see [features/onboarding.md](features/onboarding.md)).
- **scrcpy** — optional third-party screen-mirroring CLI. Found on `PATH` or in the app's `tools/scrcpy` folder.
- **AdbDevice** — a phone/emulator reported by `adb devices`.
- **Device** — the *host* computer running the app (from `device_info_plus`). Not an Android device.
- **Command / CommandModel** — one adb invocation tracked in the command queue.
- **Controller** — Riverpod-provided class holding UI logic for a feature.
- **Service** — Riverpod-provided class doing I/O (process, storage, network).
