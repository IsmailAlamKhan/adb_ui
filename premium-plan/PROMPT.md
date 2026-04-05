# ADB UI Premium Version - Agent Prompt

## Context

You are working on **adb_ui**, a Flutter desktop application (macOS/Windows/Linux) that provides a GUI for Android Debug Bridge (ADB) commands. The app is at version 0.0.15 and is hosted on GitHub.

### Current Tech Stack
- **Framework:** Flutter (desktop: macOS, Windows, Linux)
- **State Management:** Hooks Riverpod with StateNotifierProvider
- **Models:** Freezed (immutable, code-generated)
- **Architecture:** Feature-based folder structure under `lib/app/features/`
- **ADB Execution:** `dart:io Process` spawning with stdout/stderr stream broadcasting
- **Persistence:** SharedPreferences (JSON serialization)
- **UI:** Material Design 3 with dynamic colors, responsive layouts, Google Fonts (Poppins)
- **Backend:** Supabase (Auth + PostgreSQL + Edge Functions) + Stripe (payments)
- **Key deps:** flutter_hooks, hooks_riverpod, freezed, window_manager, file_picker, desktop_drop, github (API)

### Open-Core / Closed-Source Strategy

This project uses an **open-core model with a private Dart package** for premium features:

- **Public repo** (`adb_ui`): Open-source, contains all free features + the licensing/auth infrastructure + abstract interfaces for premium features
- **Private repo** (`adb_ui_pro`): Closed-source, contains all premium feature implementations as a separate Dart package

The public repo defines a **plugin registration pattern** where premium features register themselves at startup. The app works fully without the private package (free mode). When the private package is included as a dependency, it registers premium feature implementations and they become available behind the license gate.

See PLAN.md "Closed-Source Architecture" section for full details on the two-repo structure, the registration pattern, and how to wire it all together.

### Current Features (Free Tier)
- Device discovery & connection (USB + wireless TCP/IP + pairing)
- APK install/uninstall
- File push/pull with basic file explorer
- Custom ADB shell command execution
- Command queue with history & persistence
- Scrcpy integration (screen mirroring)
- Text input to device
- Settings (theme: dark/light/system)
- Auto-update checking via GitHub API

### Architecture Patterns to Follow
- Each feature lives in `lib/app/features/<feature_name>/` with its own model, service, controller, providers, and view files
- Controllers extend `StateNotifier` and use the `NavigationController` mixin
- Services are abstract interfaces with concrete implementations
- Providers are defined per-feature and composed in `lib/app/shared/providers.dart`
- Error handling uses a custom `AppException` hierarchy
- Logging via custom `AppLogger` with file output
- Navigation via custom `NavigatorService` with dialog-based flows

### Existing Project Structure

```
lib/app/
├── features/
│   ├── adb/              # Core ADB functionality
│   │   ├── adb_service.dart
│   │   ├── adb_model.dart
│   │   ├── adb_controller.dart
│   │   ├── adb_providers.dart
│   │   ├── adb_dialogs.dart
│   │   └── adb_file_explorer/
│   ├── device/            # Device information management
│   ├── command_queue/     # Command execution history & management
│   ├── settings/          # User preferences (theme, etc.)
│   ├── home/              # Main UI layout
│   ├── about/             # About screen
│   ├── package_info/      # App version & update checking
│   ├── file_picker/       # File selection UI
│   ├── terminal_outputs/  # Command output display
│   ├── splash/            # Splash screen
│   ├── menubar/           # Platform-specific menu bar
│   ├── app_init_error/    # Error handling during init
│   └── update_checker/    # Check for app updates
├── shared/
│   ├── services/          # Local storage, network info
│   ├── widgets/           # Reusable UI components
│   ├── models/            # Shared data models
│   └── providers.dart     # GitHub provider
├── utils/                 # Utilities (logger, theme, extensions, constants, event_bus, etc.)
├── app.dart               # App initialization & theme setup
└── main.dart              # Entry point
```

### How ADB Commands Are Executed

**AdbService** (abstract interface in `adb_service.dart`) with **ProccessAdbServiceImpl**:

1. Uses `dart:io.Process` to spawn ADB executable
2. On Unix (macOS/Linux): sources shell environment via bash script
3. Broadcasts stdout/stderr as streams
4. Prepends `-s <device_id>` for device-specific commands
5. Returns a `Result` object with stream + future accessors
6. Error handling via custom exceptions (`AdbNotFoundException`, `PermissionDeniedException`, etc.)

**Command Flow:**
```
AdbController.run()
  → AdbService.method() (e.g., connect, installApk, etc.)
    → run() (spawns Process)
      → Streams stdout/stderr
      → Wraps Result with status/message futures
  → CommandQueueController.addCommand()
    → Listens to streams
    → Updates state (adding → running → done/error)
    → Persists finished commands
```

### Key Models

- `AdbDevice` (Freezed): `{id, type, model, isOffline}`
- `AdbFile` / `AdbDirectory` (Freezed): File system representations
- `CommandModel` (Freezed, tagged union): States `adding`, `running`, `done`, `error` with id, command, device, output, timing
- `SettingsModel` (Freezed): `{themeMode}`

### Key Dependencies

```yaml
# State & Models
flutter_hooks, hooks_riverpod, freezed_annotation

# UI
dynamic_color, google_fonts, lottie, animations, font_awesome_flutter

# Desktop
window_manager, file_picker, desktop_drop

# Data
shared_preferences, path_provider, device_info_plus, package_info_plus

# Network
github, url_launcher, network_info_plus

# Utils
archive, intl, validators, logging, uuid
```

---

## Your Task

Implement the premium version of adb_ui following the implementation plan in `PLAN.md`. Start with Phase 0 (Licensing Infrastructure) as everything else depends on it, then proceed through the phases in the recommended order.

**IMPORTANT: After completing each phase, STOP and ask the user to review your work.** Do not proceed to the next phase until the user explicitly approves. Present a summary of what was implemented, what files were created/modified, and any decisions you made. Wait for the user's go-ahead before continuing.

### Code Style Rules

- **Follow existing patterns exactly.** Study `lib/app/features/adb/` and `lib/app/features/command_queue/` as reference implementations.
- Every new feature module: `model → service (abstract + impl) → controller (StateNotifier) → providers → view`
- Use `@freezed` annotation for all models
- Use `StateNotifierProvider` for mutable state
- Register providers in each feature's own `*_providers.dart` file
- Handle errors by throwing/catching `AppException` subclasses
- Log important operations via the existing `AppLogger`
- All user-facing strings should be extractable for future i18n

### New Dependencies to Add

**In the public repo (`adb_ui`):**
- `supabase_flutter` — Auth, database queries, Edge Function calls (required for licensing)

**In the private repo (`adb_ui_pro`):**
- `fl_chart` or `syncfusion_flutter_charts` — for Performance Dashboard charts
- Consider `sqlite3` or `drift` — for SQLite database viewer in File Explorer
- Consider a cryptography package for license tamper detection

**Linking the private package (for development/release builds):**
```yaml
# In adb_ui/pubspec.yaml — uncomment for pro builds, keep commented for open-source
dependency_overrides:
  adb_ui_pro:
    path: ../adb_ui_pro  # local development
    # git:
    #   url: git@github.com:IsmailAlamKhan/adb_ui_pro.git
    #   ref: main
```

### Backend Setup (Supabase + Stripe)

The licensing system uses Supabase as the backend and Stripe for payment processing. The agent implementing this should:

1. **Supabase project** should have:
   - Auth enabled (email/password)
   - A `licenses` table (schema defined in PLAN.md Phase 0)
   - Row Level Security policies so users can only read their own license
   - Two Edge Functions: `create-checkout` and `stripe-webhook`

2. **Stripe** should have:
   - A product + price configured (one-time payment recommended for dev tools)
   - Webhook endpoint pointing to the Supabase `stripe-webhook` Edge Function
   - Events to listen for: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted` (if using subscriptions)

3. **Environment config** in the Flutter app:
   - Supabase URL and anon key (safe to embed in client)
   - Stripe publishable key (safe to embed in client)
   - All secrets (Stripe secret key, webhook signing secret) stay in Supabase Edge Function environment variables only

### Testing Requirements
- Unit tests for all services and controllers
- Widget tests for complex UI components (LogcatView virtual list, MacroEditor)
- Integration tests for the licensing flow (mock Supabase client)
- Edge Function tests for webhook handling
