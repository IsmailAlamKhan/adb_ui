# Feature: AI log filter (on-device model)

**Status:** Shipped in 0.0.17 · **Code:** `lib/app/features/ai/`, logcat AI field
**Owner / requested by:** owner · **Last updated:** 2026-11-22

## Problem

Writing logcat filters needs knowing tags, levels and regex. People want to say
"network errors from my app" and get the right filter.

## Decision

An LLM **embedded in the app** turns a sentence into a `LogcatFilter`. It runs locally through
llama.cpp (`llamadart` package): **no log line or query leaves the computer**, no API key, works
offline. Only the sentence is given to the model — never the logs.

## Behaviour

- Logcat has a field "Describe what you want to see…" with a sparkle icon. Enter runs it.
- First use (no model yet): a card explains "AI filters run on this computer. Download a model
  once (Fast · 490 MB / Accurate · 1.1 GB)." with **Download** and size; progress bar with
  percent and **Cancel**. Download resumes if interrupted.
- While thinking: the field shows a spinner and "Thinking…" (typically ~1 s on Apple Silicon,
  2–5 s on CPU-only machines); the result is applied as filter chips marked with a sparkle so it's
  clear what the AI chose; the user can edit or remove any chip. The model's one-line
  explanation shows under the field ("Errors and warnings from com.example.app mentioning http").
- **Rules first, model second.** `AiFilterMapper.fromRules` reads the sentence itself: crash/ANR/
  exception words → Crashes, error/fail → Errors+, warn → Warnings+; an installed app whose name
  appears → App filter ("my app" → the followed app); "hide/without/except X" → hidden tags; other
  meaningful words → a search (one word, or `a|b` regex for 2–4 words). The model only fills
  what the rules didn't find, and its output is checked against the sentence: text must be a
  short phrase from it, tags must be named in it, an app must be named in it, and Crashes drops
  any minimum level (it would hide stack traces). Small models invent values; these checks stop
  them from hiding every line.
- The model gets: the sentence, the device's installed package names (so "my app" / "Slack"
  resolves to a real package), the currently followed app, and the list of level/preset names.
- Output is constrained to this JSON schema (grammar-constrained decoding, then validated):
  `{ preset?: all|warnings|errors|crashes, package?: string, minLevel?: V|D|I|W|E|F,
  includeTags?: string[], excludeTags?: string[], text?: string, regex?: boolean,
  explanation: string }`. A `package` not in the installed list is dropped.
- Errors (model failed to load, out of memory, invalid output twice) use the error catalogue
  kind `aiModel` with steps (e.g. "Switch to the Fast model in Settings").

### Settings → AI
- Model: **Fast** (Qwen2.5 0.5B Instruct Q4_K_M, 491 MB) / **Accurate** (Qwen2.5 1.5B Instruct
  Q4_K_M, 1.12 GB, default). Status (Not downloaded / Downloading n% / Ready), **Download**,
  **Delete model** (confirm, frees disk).
- Models are stored in the app support folder (`…/com.adb-ui/models/`), via llamadart's
  download manager; sources `hf://Qwen/Qwen2.5-{0.5B,1.5B}-Instruct-GGUF/…q4_k_m.gguf`.

## Engine lifecycle
- `aiFilterServiceProvider` owns one `LlamaEngine`, loaded lazily on first request and kept
  while the app runs; disposed on app exit (`AppLifecycleListener.onExitRequested`).
- One request at a time; a new request while one runs cancels the old one.

## Build / platform impact
- `llamadart` needs Dart ≥ 3.10.7 / Flutter ≥ 3.38.6 and **macOS deployment target 14.0**
  (was 12.0). The native llama.cpp runtime is fetched by the package's build hook on first build.
- Windows/Linux use Vulkan when available, else CPU.

## Acceptance criteria
- [x] "errors from slack" → package `com.Slack`, preset errors.
- [x] "crashes" → Crashes preset; "hide chatty and Choreographer logs" → hidden tags.
- [ ] Nothing is sent over the network except the one-time model download.
- [ ] Download progress, cancel and resume work; delete frees the file.
- [x] Prompt→filter mapping logic (validation, package resolution) unit-tested without the model.

## As built (2026-11-22)
- `AiController` (`aiControllerProvider`, kept alive) owns download (`DefaultModelDownloadManager`
  rooted at `<app support>/models`), lazy `LlamaEngine.load` (context 4096) and
  `createStructuredJson` with `AiFilterMapper.schema`, `temp: 0.1`, `maxTokens: 256`, two tries.
- Model choice is stored under `LocalStorageKeys.aiModel` (`ai_model`). Default: Accurate.
- `HomeShell` disposes the engine from `AppLifecycleListener.onExitRequested`.
- Before a model is downloaded, the logcat field is replaced by the setup card (choose Fast /
  Accurate, Download). Settings has the same card plus Delete model.
- Verified 2026-11-22 with the Fast model inside a macOS build (`integration_test/ai_model_test.dart`,
  run with `flutter test integration_test/ai_model_test.dart -d macos`; skipped when no model is
  downloaded): four requests mapped correctly in 0.2–0.4 s each (first load ~1.5 s). Download
  through the app worked (480 MB). The model can't run in plain `flutter test`: on macOS
  llama.cpp is linked into the app bundle by the companion package.
- Not yet checked: the Accurate model, Windows/Linux, typing a request in the running UI
  (automation can't type into Flutter fields in the background).
