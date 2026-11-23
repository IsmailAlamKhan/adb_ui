# 07 — Roadmap

Ideas that are **not built yet**. Moving an item into development means: write its
feature spec under `features/` (status `Proposed` → `In progress`), link it here, then build.

| Idea | Status | Spec |
|------|--------|------|
| Logcat viewer with filters, follow app/foreground, presets, AI filter, export | Shipped in 0.0.17 | [features/logcat.md](features/logcat.md) |
| In-app screen mirror with controls | Shipped in 0.0.17 | [features/screen-mirror.md](features/screen-mirror.md) |
| Intent & deep-link builder (`am start`, broadcasts) with saved presets | Proposed | — |
| Better device file explorer (real file/dir detection, sizes, delete/rename, drag-drop) | Proposed | — |
| Macro / automation recorder (record & replay command sequences) | Proposed | — |
| Performance dashboard (CPU, memory, battery, network via `dumpsys`) | Proposed | — |
| Full UI redesign: three selectable styles | Shipped in 0.0.16 | [08-redesign.md](08-redesign.md) |
| Error handling & display overhaul | Shipped in 0.0.16 | [features/error-handling.md](features/error-handling.md) |
| Remember recent IPs; undo disconnect | Planned (after redesign) | [08-redesign.md](08-redesign.md) |
| QR code pairing + auto-connect | Shipped in 0.0.16 | [features/qr-pairing.md](features/qr-pairing.md) |
| Wireless ADB manager (auto-detect IP, remember devices, list discovered devices to connect) | Proposed | — |
| Installed-package picker for Uninstall (instead of typing the package name) | Proposed | — |
| Screenshot / screen recording | Proposed | — |
| Automated tests (more parsers: `devices`, `ls`; widget tests) | Started | `test/` |

Fixes for items in [06-known-issues.md](06-known-issues.md) don't need a roadmap entry.
