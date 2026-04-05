# ADB UI Premium Version - Implementation Plan

## Build Order Priority

| Priority | Phase | Feature | Why This Order |
|----------|-------|---------|----------------|
| 1 | Phase 0 | Licensing Infrastructure | Everything depends on it |
| 2 | Phase 1 | Advanced Logcat Studio | Highest user value, no deps on other premium features |
| 3 | Phase 3 | Enhanced File Explorer | Enhances existing feature, high value |
| 4 | Phase 2 | Intent & Deep Link Builder | Standalone, moderate complexity |
| 5 | Phase 4 | Macro & Automation Recorder | Can reference Intent Builder |
| 6 | Phase 6 | Wireless ADB Manager | Enhances existing feature |
| 7 | Phase 5 | Performance Dashboard | Most complex, needs charting library |

### Review Process

**After completing each phase, STOP and ask the user to review your work before moving on.** Present:
1. Summary of what was implemented
2. List of files created/modified
3. Any architectural decisions or trade-offs you made
4. Any open questions or concerns

Wait for explicit user approval before starting the next phase. If the user requests changes, address them before proceeding.

---

## Phase 0: Licensing & Feature Gating Infrastructure (Supabase + Stripe)

**Location:** `lib/app/features/auth/` and `lib/app/features/licensing/`

**Goal:** Create the foundation that distinguishes free vs. premium users, using Supabase for auth/data and Stripe for payments.

### Architecture Overview

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  adb_ui  │────→│   Supabase   │←────│    Stripe    │
│  (app)   │     │  (backend)   │     │  (payments)  │
└──────────┘     └──────────────┘     └──────────────┘
  Flutter app      - Auth (users)       - Checkout
  calls Supabase   - DB (licenses)      - Webhooks →
  directly         - Edge Functions       Supabase Edge
                   - RLS policies         Functions
```

**End-to-end flow:**
1. User signs up/in via Supabase Auth (email + password) inside the app
2. User clicks "Upgrade to Pro" → app calls Supabase Edge Function `create-checkout`
3. Edge Function creates a Stripe Checkout Session, returns URL
4. App opens Stripe Checkout in browser via `url_launcher`
5. User pays → Stripe fires `checkout.session.completed` webhook
6. Webhook hits Supabase Edge Function `stripe-webhook` → writes/updates `licenses` table row
7. App polls or re-queries `licenses` table → sees `plan: 'pro'` → unlocks features

### Supabase Schema

```sql
-- Users come from Supabase Auth (email/password sign up)

create table licenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null unique,
  stripe_customer_id text,
  stripe_payment_id text,                    -- for one-time payments
  plan text not null default 'free',         -- 'free', 'trial', 'pro'
  status text not null default 'active',     -- 'active', 'expired', 'revoked'
  device_ids text[] default '{}',            -- array of machine IDs for device limiting
  max_devices int default 3,
  trial_ends_at timestamptz,
  purchased_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS: users can only read their own license
alter table licenses enable row level security;

create policy "Users read own license"
  on licenses for select
  using (auth.uid() = user_id);

-- Auto-create a 'free' license row when a new user signs up (via trigger)
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.licenses (user_id, plan, status)
  values (new.id, 'free', 'active');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
```

### Supabase Edge Functions (2 required)

#### `create-checkout` Edge Function
```ts
// Called by the app when user clicks "Upgrade to Pro"
// POST /functions/v1/create-checkout
import Stripe from 'stripe';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

Deno.serve(async (req) => {
  const { user_id, email, device_id } = await req.json();

  const session = await stripe.checkout.sessions.create({
    customer_email: email,
    line_items: [{ price: Deno.env.get('STRIPE_PRICE_ID')!, quantity: 1 }],
    mode: 'payment',  // one-time purchase (use 'subscription' for recurring)
    success_url: 'https://yoursite.com/success',  // or a custom URI scheme
    cancel_url: 'https://yoursite.com/cancel',
    metadata: { user_id, device_id },
  });

  return new Response(JSON.stringify({ url: session.url }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

#### `stripe-webhook` Edge Function
```ts
// Called by Stripe after payment events
// POST /functions/v1/stripe-webhook
import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!  // service role for writing
);

Deno.serve(async (req) => {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature')!;
  const event = stripe.webhooks.constructEvent(
    body, sig, Deno.env.get('STRIPE_WEBHOOK_SECRET')!
  );

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const userId = session.metadata.user_id;
    const deviceId = session.metadata.device_id;

    await supabase.from('licenses').upsert({
      user_id: userId,
      plan: 'pro',
      status: 'active',
      stripe_customer_id: session.customer,
      stripe_payment_id: session.payment_intent,
      purchased_at: new Date().toISOString(),
      device_ids: deviceId ? [deviceId] : [],
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' });
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 });
});
```

### Flutter App Files to Create

#### `lib/app/features/auth/` — Authentication Module

##### `auth_service.dart` (abstract)
- `Future<AuthUser?> signUp(String email, String password)`
- `Future<AuthUser?> signIn(String email, String password)`
- `Future<void> signOut()`
- `Future<void> resetPassword(String email)`
- `Stream<AuthUser?> get authStateChanges`
- `AuthUser? get currentUser`

##### `auth_service_impl.dart`
- Implementation using `supabase_flutter` package
- `SupabaseAuth` for all auth operations
- Handle auth state persistence (Supabase SDK handles this automatically)

##### `auth_controller.dart`
- StateNotifier managing `AuthState` (Freezed: `unauthenticated`, `loading`, `authenticated(AuthUser user)`, `error(String message)`)
- Methods: `signUp()`, `signIn()`, `signOut()`, `resetPassword()`

##### `auth_providers.dart`
- `authServiceProvider`, `authControllerProvider`, `currentUserProvider`

##### `auth_view.dart`
- Sign in / Sign up form (email + password)
- Toggle between sign in and sign up modes
- "Forgot password" link
- Error messages for invalid credentials, network errors, etc.
- After successful auth → navigate to home

#### `lib/app/features/licensing/` — License Management Module

##### `premium_feature.dart`
- Enum of all gated features: `logcatStudio`, `intentBuilder`, `fileExplorer`, `macroRecorder`, `performanceDashboard`, `wirelessManager`

##### `license_model.dart`
- Freezed model `LicenseState` with tagged union variants:
  - `free` — no license / not signed in
  - `trial(DateTime expiresAt)` — 14-day trial
  - `pro(DateTime purchasedAt, List<String> deviceIds)` — paid license

##### `license_service.dart` (abstract)
- `Future<LicenseState> fetchLicense(String userId)` — query Supabase `licenses` table
- `Future<void> cacheLicenseLocally(LicenseState state)` — SharedPreferences cache
- `Future<LicenseState> loadCachedLicense()` — read local cache for offline use
- `Future<String> createCheckoutSession(String userId, String email, String deviceId)` — call `create-checkout` Edge Function, return Stripe URL
- `Future<void> startTrial(String userId)` — update `licenses` row to `plan: 'trial'`
- `Future<void> registerDevice(String userId, String deviceId)` — add device to `device_ids` array
- `bool isFeatureUnlocked(PremiumFeature feature, LicenseState state)` — check access

##### `license_service_impl.dart`
- `supabase.from('licenses').select().eq('user_id', uid).single()` for fetching license
- `supabase.functions.invoke('create-checkout', body: {...})` for checkout
- SharedPreferences for local caching with `lastValidated` timestamp
- Offline grace period: trust cache for 7 days without server validation
- Use `device_info_plus` to generate a stable machine ID for device registration

##### `license_controller.dart`
- StateNotifier managing `LicenseState`
- Methods: `checkLicense()`, `startTrial()`, `purchasePro()`, `refreshLicense()`
- On app launch: load cached → if online, re-fetch from Supabase → update cache
- After `purchasePro()`: open Stripe URL, then poll Supabase every 2 seconds for up to 60 seconds waiting for webhook to update the row

##### `license_providers.dart`
- `licenseServiceProvider`
- `licenseControllerProvider`
- `isPremiumProvider` (computed bool — true if `pro` or `trial` with time remaining)
- `isFeatureUnlockedProvider(PremiumFeature)` (family provider)
- `licenseStateProvider` (exposes current state for UI)

##### `license_dialog.dart` / `upgrade_view.dart`
- Shows current plan status (Free / Trial with X days left / Pro)
- "Start Free Trial" button (if free)
- "Upgrade to Pro" button → triggers checkout flow
- Trial countdown display
- Device count display (e.g., "2 of 3 devices activated")
- Sign out option

### Shared Widget: `PremiumGate`

**Location:** `lib/app/shared/widgets/premium_gate.dart`

- Takes `PremiumFeature` enum and `Widget child`
- If licensed (pro or active trial): renders child normally
- If not licensed: renders blur overlay with upgrade prompt and "Upgrade" button
- Reads from `isFeatureUnlockedProvider`

### Trial System
- User clicks "Start Free Trial" → app updates Supabase row: `plan: 'trial', trial_ends_at: now + 14 days`
- On each launch, check: `trial_ends_at > now`
- Trial expired → Supabase row stays as `plan: 'trial'` but `isFeatureUnlocked` returns false when `trial_ends_at` is in the past
- Local cache also stores trial expiry for offline checking
- Additional local tamper detection: hash trial_ends_at with device-specific salt (use `device_info_plus` machine ID)

### Device Limiting
- On first activation (sign in on a new machine), register device ID in `device_ids` array via Edge Function or direct Supabase RPC
- If `device_ids.length >= max_devices` → deny activation, show message: "License active on maximum devices. Deactivate a device from your account page."
- Provide an Edge Function or account web page where users can deactivate old devices

### App Initialization Flow (Updated)
```
main()
  ↓
App.run()
  ↓
Initialize (existing):
  - Widgets Binding, Navigator, Logger, etc.
  ↓
Initialize (new):
  - Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY)
  - Check auth state: signed in? → fetch license : → show auth screen or continue as free
  - Cache license locally
  ↓
App.init(container) → existing init flow
  ↓
Show Splash Screen → Home Screen (with license state loaded)
```

### Pricing Model Recommendation
One-time purchase works best for developer tools:
- **Free:** All basic ADB features (open-source)
- **Pro:** $29 one-time, all premium features, 3 device activations
- **Major version upgrades:** New Stripe price for v2, v1 buyers get discount (handle via Stripe coupons + metadata)

### Environment Configuration
Create `lib/app/utils/supabase_config.dart`:
```dart
class SupabaseConfig {
  // These are safe to embed in the client
  static const String url = 'https://your-project.supabase.co';
  static const String anonKey = 'eyJ...your-anon-key';
}
```
- All secrets (Stripe secret key, webhook signing secret, Supabase service role key) live ONLY in Supabase Edge Function environment variables
- Never embed Stripe secret key in the Flutter app

---

## Phase 1: Advanced Logcat Studio

**Location:** `adb_ui_pro/lib/src/logcat/` (private repo)

**Premium gate:** `PremiumFeature.logcatStudio`

### LogEntry Model (Freezed)
```
{DateTime timestamp, int pid, int tid, LogLevel level, String tag, String message}
```
- `LogLevel` enum: `verbose, debug, info, warn, error, fatal`

### LogcatFilter Model (Freezed)
- `minLevel` (LogLevel)
- `includeTags` (List<String>, supports regex)
- `excludeTags` (List<String>, supports regex)
- `pidFilter` (int?, optional)
- `packageFilter` (String?, optional)
- `messagePattern` (String?, regex)
- `name` (String, for saved presets)

### LogcatService
- Start `adb logcat -v threadtime` as persistent process stream
- Parse each line into `LogEntry` model
- Buffer: keep last 50,000 entries in memory, flush older to temp file
- Support start/stop/clear operations
- Per-device streaming (multiple devices simultaneously)

### CrashDetector
- Monitor stream for `FATAL EXCEPTION` / `AndroidRuntime` patterns
- Extract full stack trace block (from `FATAL EXCEPTION` to next blank line or new log entry)
- Store in separate crash list
- Export to clipboard or file

### LogcatController (StateNotifier)
- State: `{entries, filters, activeFilter, crashes, isStreaming, isPaused}`
- Methods: `start(device)`, `stop()`, `pause()`, `resume()`, `clear()`, `applyFilter(filter)`, `saveFilterPreset(filter)`, `exportLogs(path)`

### LogcatView
- **Virtualized list** (`ListView.builder`) — CRITICAL for performance with 50k+ entries
- **Color coding by level:**
  - Verbose = grey
  - Debug = blue
  - Info = green
  - Warn = yellow/orange
  - Error = red
  - Fatal = red bold with background
- **Search bar** with regex support (highlight matches in-place)
- **Filter panel** (collapsible sidebar):
  - Level slider
  - Tag include/exclude text fields
  - Package name field
  - Message regex field
  - Preset dropdown (save/load/delete)
- **Crash tab** — separate view showing isolated crash reports
- **Toolbar:** Pause/Resume, Clear, Export, Device selector
- **Multi-device:** Tab per device, or merged view with device column
- **Auto-scroll** to bottom (toggleable)

### Integration
- Add "Logcat" button to device action dialog in HomeView
- Gate behind `PremiumGate(feature: PremiumFeature.logcatStudio)`

---

## Phase 2: Intent & Deep Link Builder

**Location:** `adb_ui_pro/lib/src/intent_builder/` (private repo)

**Premium gate:** `PremiumFeature.intentBuilder`

### IntentModel (Freezed)
- `action` (String, e.g., `android.intent.action.VIEW`)
- `data` (String?, URI)
- `component` (String?, package/class)
- `category` (String?, optional)
- `extras` (List<IntentExtra>)
- `flags` (List<String>)

### IntentExtra (Freezed)
- `key` (String)
- `value` (String)
- `type` (IntentExtraType enum: `string, int, bool, float, long, uri`)

### IntentService
- Convert `IntentModel` → `adb shell am start` command string
  - Map extras to `--es`, `--ei`, `--ez`, `--ef`, `--el` flags
  - Handle flags, categories, component, data URI
- Execute via existing AdbService
- List installed packages: `adb shell pm list packages -3`

### IntentHistoryService
- Persist sent intents to SharedPreferences
- Bookmark/unbookmark intents
- Delete history entries

### IntentBuilderController (StateNotifier)
- State: `{currentIntent, history, bookmarks, installedPackages}`
- Methods: `send(device, intent)`, `bookmark(intent)`, `loadHistory()`, `clearHistory()`

### IntentBuilderView
- **Action field:** Dropdown with common actions (`VIEW`, `SEND`, `MAIN`, `DIAL`, `CALL`, etc.) + custom text input
- **Data/URI field:** Text input for URI
- **Component picker:** Optional package/activity selector (populated from `pm list packages`)
- **Extras form:** Dynamic key-value rows
  - Add/remove rows
  - Type selector dropdown per row (string, int, bool, etc.)
  - Key and value text fields
- **Flags:** Checkboxes for common flags (`FLAG_ACTIVITY_NEW_TASK`, `FLAG_ACTIVITY_CLEAR_TOP`, etc.)
- **Send button** with device selector
- **History sidebar:**
  - List of previously sent intents
  - Bookmark star toggle
  - One-click resend
  - Delete individual entries
- **Quick mode:** "Deep Link" tab — just paste a URI and fire (auto-fills action=VIEW)

### Integration
- Add "Intent Builder" to device action dialog
- Gate behind `PremiumGate(feature: PremiumFeature.intentBuilder)`

---

## Phase 3: Enhanced Visual File Explorer

**Location:** `adb_ui_pro/lib/src/file_explorer/` (private repo, replaces the basic explorer when loaded)

**Premium gate:** `PremiumFeature.fileExplorer`

### Strategy
Keep the existing basic file explorer for free users. When premium, replace with the enhanced version.

### Enhancements

#### Dual-Pane Layout
- Left pane: local filesystem (use `file_picker` or `dart:io` Directory listing)
- Right pane: device filesystem (existing ADB `ls` functionality)
- Resizable divider between panes

#### Drag & Drop
- Drag files between panes to push/pull (leverage existing `desktop_drop` dependency)
- Visual drop indicator

#### Multi-Selection
- Shift+click for range select
- Cmd/Ctrl+click for individual toggle
- Select all checkbox
- Batch push/pull/delete

#### Context Menu (Right-Click)
- Copy, Move, Delete, Rename
- View properties (size, permissions, modified date)
- Open with system default (local files)

#### Navigation
- Breadcrumb path bar (clickable segments)
- Back/Forward buttons
- Path text input (type a path and go)

#### App Data Access
- Quick-access button to `/data/data/<package>/` for debuggable apps
- List third-party packages from `pm list packages -3`
- `run-as <package>` for accessing app-private directories

#### SQLite Database Viewer
- Detect `.db` files in file listing
- Pull to temp directory
- Display tables list → select table → show rows in DataTable widget
- Basic query input (optional)
- Read-only is fine for v1

#### SharedPreferences Viewer
- Detect `shared_prefs/*.xml` files
- Pull and parse XML
- Display as editable key-value table
- Push changes back to device

#### Progress & Feedback
- Progress indicators for push/pull operations (parse ADB transfer output)
- Transfer speed display
- Queue multiple transfers

### Integration
- Replace existing file explorer view when `PremiumFeature.fileExplorer` is unlocked
- Free users keep current basic file explorer

---

## Phase 4: Macro & Automation Recorder

**Location:** `adb_ui_pro/lib/src/macros/` (private repo)

**Premium gate:** `PremiumFeature.macroRecorder`

### MacroModel (Freezed)
- `id` (String, UUID)
- `name` (String)
- `description` (String?, optional)
- `steps` (List<MacroStep>)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)

### MacroStep (Freezed, tagged union)
- `adbCommand(String command)` — raw ADB shell command
- `installApk(String apkPath)`
- `pushFile(String localPath, String remotePath)`
- `pullFile(String remotePath, String localPath)`
- `delay(Duration duration)` — wait between steps
- `inputText(String text)`
- `launchIntent(IntentModel intent)` — reuse from Phase 2 if available
- `grantPermission(String package, String permission)`
- `uninstallApp(String packageName)`

### MacroService
- CRUD: create, read, update, delete macros
- Persist to SharedPreferences or JSON file in app support directory
- Import/export macros as `.json` files (for team sharing)

### MacroExecutor
- Execute macro steps sequentially against a target device
- Use existing AdbService methods for each step type
- Emit progress events (current step index, output, errors)
- Support cancel mid-execution
- Continue-on-error option vs. stop-on-error

### MacroRecorderController (StateNotifier)
- State: `{macros, currentMacro, isRecording, executionState}`
- Recording mode:
  - Hook into `CommandQueueController` or `AdbController`
  - Intercept all ADB commands sent through the app
  - Append each as a `MacroStep`
  - User clicks "Stop Recording" to finalize
- Methods: `startRecording()`, `stopRecording()`, `executeMacro(device, macro)`, `cancelExecution()`

### MacroView
- **Macro list:** Cards with name, description, step count, last run date
- **Search/filter** macros by name
- **Macro editor:**
  - Ordered list of steps (drag-to-reorder)
  - Edit individual step parameters (inline or dialog)
  - Add step manually (step type selector + params form)
  - Add delay step with duration picker
  - Delete step
- **Record button** in toolbar — toggles recording mode
  - Visual indicator when recording (red dot, pulsing border)
  - All app actions become macro steps while recording
- **Play button** — select target device, then execute
- **Execution view:**
  - Step list with current step highlighted
  - Output stream per step
  - Progress bar
  - Cancel button
- **Import/Export** buttons (file picker for `.json`)

### Integration
- Add "Macros" button to main app navigation (sidebar or app bar)
- Gate behind `PremiumGate(feature: PremiumFeature.macroRecorder)`

---

## Phase 5: Performance & Network Dashboard

**Location:** `adb_ui_pro/lib/src/performance/` (private repo)

**Premium gate:** `PremiumFeature.performanceDashboard`

**New dependency:** Add `fl_chart` (or `syncfusion_flutter_charts`) to `pubspec.yaml`

### Performance Models (Freezed)

#### MemorySnapshot
```
{int totalPss, int javaHeap, int nativeHeap, int graphics, int stack, int code, DateTime timestamp}
```

#### CpuSnapshot
```
{double userPercent, double kernelPercent, double totalPercent, DateTime timestamp}
```

#### BatterySnapshot
```
{int level, double temperature, int voltage, bool isCharging, DateTime timestamp}
```

### PerformanceService
- **Memory:** Parse `adb shell dumpsys meminfo <package>` output
  - Extract: Total PSS, Java Heap, Native Heap, Graphics, Stack, Code
- **CPU:** Parse `adb shell dumpsys cpuinfo` output
  - Extract per-process CPU: user%, kernel%, total%
- **Battery:** Parse `adb shell dumpsys battery` output
  - Extract: level, temperature, voltage, charging status
- **Polling:** Configurable interval (default 2 seconds)
- **Streaming:** Emit snapshots as `Stream<T>` for each metric type
- Keep rolling buffer of snapshots (configurable, default 15 minutes)

### NetworkThrottleService
- Simulate network conditions using:
  - `adb shell settings put global` commands
  - Or emulator console commands (`network delay`, `network speed`)
- **Presets enum:**
  - `none` — No throttle
  - `edge` — EDGE (50kbps up/down, 300ms latency)
  - `threeg` — 3G (750kbps up/down, 100ms latency)
  - `lte` — LTE (5Mbps up/down, 50ms latency)
  - `poorWifi` — Poor WiFi (1Mbps, 200ms latency, 5% loss)
  - `noConnection` — Airplane mode
  - `custom(int uploadKbps, int downloadKbps, int latencyMs, double packetLoss)`

### PerformanceController (StateNotifier)
- State: `{targetPackage, memorySnapshots, cpuSnapshots, batterySnapshots, isMonitoring, pollInterval, networkThrottle}`
- Methods: `startMonitoring(device, package)`, `stopMonitoring()`, `setThrottle(preset)`, `exportData(path)`, `setPollInterval(duration)`

### PerformanceDashboardView
- **Package selector:** Dropdown populated from `pm list packages -3`
- **Start/Stop monitoring** toggle button
- **Charts panel** (3 charts, vertically stacked or tabbed):
  - **Memory chart:** Line chart with multiple series (Total PSS, Java Heap, Native Heap, etc.)
  - **CPU chart:** Line chart (user%, kernel%, total%)
  - **Battery chart:** Line chart (level over time)
- **Time range selector:** Last 1min, 5min, 15min, all data
- **Network throttle panel:**
  - Preset buttons
  - Custom input fields (when custom selected)
  - Current throttle status indicator
- **Export:** Save chart data as CSV file
- **Snapshot comparison** (nice-to-have): Capture a snapshot at point A, another at point B, show delta

### Integration
- Add "Performance" to device action dialog
- Gate behind `PremiumGate(feature: PremiumFeature.performanceDashboard)`

---

## Phase 6: Seamless Wireless ADB Manager

**Location:** `adb_ui_pro/lib/src/wireless_manager/` (private repo)

**Premium gate:** `PremiumFeature.wirelessManager`

### WirelessDeviceModel (Freezed)
- `name` (String, user-assigned nickname)
- `ip` (String)
- `port` (int)
- `lastConnected` (DateTime)
- `isPaired` (bool)
- `macAddress` (String?, optional)

### WirelessManagerService
- **Store known devices** in SharedPreferences
- **Network discovery:**
  - Use `adb mdns services` (Android 11+ / API 30+) to discover mDNS-advertised devices
  - Fallback: subnet scan using existing `network_info_plus` to get local IP, then scan common ADB ports
- **Auto-reconnect:**
  - On app startup, attempt to reconnect to all previously connected devices
  - Background retry with exponential backoff
- **Connection health:**
  - Periodic ping (every 30 seconds) to check device is still reachable
  - Auto-reconnect on connection drop
  - Status: `connected`, `connecting`, `disconnected`, `unreachable`

### WirelessManagerController (StateNotifier)
- State: `{knownDevices, connectionStatuses, isScanning}`
- Methods: `scan()`, `connect(device)`, `disconnect(device)`, `forget(device)`, `rename(device, name)`, `autoReconnectAll()`

### WirelessManagerView
- **Known devices list:**
  - Device cards with nickname, IP:port, last connected time
  - Status indicator dot (green=connected, yellow=connecting, red=disconnected, grey=unreachable)
  - One-click connect/disconnect button
  - Edit nickname (inline or dialog)
  - Forget device (with confirmation)
- **Scan button:** Discover new devices on network
  - Scanning animation
  - Results list with "Add & Connect" button for each found device
- **Auto-reconnect toggle** (global on/off)
- **Connection log:** Expandable panel showing connection attempts and results

### Integration
- Enhance/replace existing wireless connect flow in HomeView sidebar
- Gate behind `PremiumGate(feature: PremiumFeature.wirelessManager)`
- Free users keep existing basic wireless connect (IP:port manual input)

---

## Closed-Source Architecture (Private Package)

This project uses an **open-core model** where the public open-source repo contains all free features, and a **separate private Dart package** contains all premium feature implementations.

### Two-Repo Structure

```
# PUBLIC REPO: github.com/IsmailAlamKhan/adb_ui (open-source, MIT/Apache)
adb_ui/
├── lib/app/
│   ├── features/
│   │   ├── adb/                  # free — open source
│   │   ├── home/                 # free — open source
│   │   ├── command_queue/        # free — open source
│   │   ├── settings/             # free — open source
│   │   ├── auth/                 # auth — open source (needed for licensing)
│   │   ├── licensing/            # licensing — open source (gate logic + UI)
│   │   └── ...                   # all other free features
│   ├── shared/
│   │   ├── widgets/
│   │   │   └── premium_gate.dart # open source — shows upgrade prompt
│   │   └── premium/
│   │       ├── premium_feature.dart        # enum of all premium features
│   │       ├── premium_registry.dart       # registration pattern (abstract)
│   │       └── premium_feature_factory.dart # abstract factory interface
│   └── ...
├── pubspec.yaml                  # adb_ui_pro is an OPTIONAL dependency
└── ...

# PRIVATE REPO: github.com/IsmailAlamKhan/adb_ui_pro (closed-source)
adb_ui_pro/
├── lib/
│   ├── adb_ui_pro.dart           # package entry point — exports register()
│   ├── src/
│   │   ├── pro_feature_factory.dart  # concrete factory implementing all features
│   │   ├── logcat/               # Advanced Logcat Studio implementation
│   │   ├── intent_builder/       # Intent & Deep Link Builder implementation
│   │   ├── file_explorer/        # Enhanced File Explorer implementation
│   │   ├── macros/               # Macro & Automation Recorder implementation
│   │   ├── performance/          # Performance & Network Dashboard implementation
│   │   └── wireless_manager/     # Wireless ADB Manager implementation
│   └── ...
├── pubspec.yaml
│   name: adb_ui_pro
│   dependencies:
│     adb_ui:                     # depends on the public package for shared types
│       git:
│         url: https://github.com/IsmailAlamKhan/adb_ui.git
│     fl_chart: ^x.x.x
│     sqlite3: ^x.x.x
│     # ... other premium-only deps
└── ...
```

### Plugin Registration Pattern

#### In the public repo — define the interfaces:

```dart
// lib/app/shared/premium/premium_feature.dart
enum PremiumFeature {
  logcatStudio,
  intentBuilder,
  fileExplorer,
  macroRecorder,
  performanceDashboard,
  wirelessManager,
}

// lib/app/shared/premium/premium_feature_factory.dart
abstract class PremiumFeatureFactory {
  /// Each method returns the premium widget for that feature.
  /// The public repo only has this interface — no implementations.
  Widget buildLogcatStudio({required AdbDevice device});
  Widget buildIntentBuilder({required AdbDevice device});
  Widget buildEnhancedFileExplorer({required AdbDevice device});
  Widget buildMacroRecorder();
  Widget buildPerformanceDashboard({required AdbDevice device});
  Widget buildWirelessManager();

  /// Provider overrides that the pro package needs to register
  /// (e.g., custom service implementations)
  List<Override> get providerOverrides;
}

// lib/app/shared/premium/premium_registry.dart
class PremiumRegistry {
  static PremiumFeatureFactory? _factory;

  /// Called by the pro package at startup to register its implementations
  static void register(PremiumFeatureFactory factory) {
    _factory = factory;
  }

  /// Check if the pro package is loaded
  static bool get isProPackageAvailable => _factory != null;

  /// Get the factory (null if pro package not loaded)
  static PremiumFeatureFactory? get factory => _factory;
}
```

#### In the private repo — implement and register:

```dart
// lib/adb_ui_pro.dart
import 'package:adb_ui/app/shared/premium/premium_registry.dart';
import 'src/pro_feature_factory.dart';

/// Call this from main() to activate premium features
void registerProFeatures() {
  PremiumRegistry.register(ProFeatureFactory());
}

// lib/src/pro_feature_factory.dart
class ProFeatureFactory implements PremiumFeatureFactory {
  @override
  Widget buildLogcatStudio({required AdbDevice device}) => LogcatStudioView(device: device);

  @override
  Widget buildIntentBuilder({required AdbDevice device}) => IntentBuilderView(device: device);

  // ... etc for each feature

  @override
  List<Override> get providerOverrides => [
    // Any Riverpod provider overrides needed
  ];
}
```

#### In the public repo's main.dart — conditional activation:

```dart
// lib/app/main.dart
import 'package:adb_ui_pro/adb_ui_pro.dart'
    if (dart.library.io) 'package:adb_ui/app/shared/premium/premium_stub.dart';

void main() {
  // This call does nothing if the stub is loaded (free version)
  // It registers all pro features if adb_ui_pro is available
  registerProFeatures();

  App.run();
}

// lib/app/shared/premium/premium_stub.dart
/// Stub file — used when adb_ui_pro package is not available
void registerProFeatures() {
  // No-op: pro package not included in this build
}
```

#### How PremiumGate uses the registry:

```dart
// lib/app/shared/widgets/premium_gate.dart
class PremiumGate extends ConsumerWidget {
  final PremiumFeature feature;
  final Widget child;

  const PremiumGate({required this.feature, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnlocked = ref.watch(isFeatureUnlockedProvider(feature));
    final isProAvailable = PremiumRegistry.isProPackageAvailable;

    // Feature is unlocked (licensed) AND pro package is available
    if (isUnlocked && isProAvailable) {
      return child;
    }

    // Show upgrade prompt / blur overlay
    return PremiumUpgradeOverlay(
      feature: feature,
      child: child,
    );
  }
}
```

### How to Build Both Versions

#### Free version (open-source, what GitHub users get):
```bash
# pubspec.yaml does NOT include adb_ui_pro
flutter build macos   # builds free version
flutter build windows
flutter build linux
```

#### Pro version (closed-source, what paying users download):
```yaml
# pubspec.yaml includes adb_ui_pro
dependencies:
  adb_ui_pro:
    git:
      url: git@github.com:IsmailAlamKhan/adb_ui_pro.git
      ref: v1.0.0
```
```bash
flutter build macos   # builds pro version with all features
flutter build windows
flutter build linux
```

#### CI/CD Setup
- **Public CI** (GitHub Actions on `adb_ui`): builds and releases the free version
- **Private CI** (GitHub Actions on `adb_ui_pro` or a separate release repo):
  - Clones both repos (uses deploy key for private repo)
  - Adds `adb_ui_pro` as dependency
  - Builds and signs the pro version
  - Uploads to distribution channel (GitHub Releases, your website, etc.)

### What Goes Where — Quick Reference

| Component | Repo | Why |
|-----------|------|-----|
| All free features | Public | Open source |
| Auth module (Supabase) | Public | Needed for free users to sign up |
| Licensing module (gate logic, UI) | Public | License checking is not secret |
| `PremiumFeature` enum | Public | Needed by both repos |
| `PremiumFeatureFactory` interface | Public | Needed by both repos |
| `PremiumRegistry` | Public | Registration point |
| `PremiumGate` widget | Public | Shows upgrade prompt |
| `premium_stub.dart` | Public | No-op when pro not available |
| Logcat Studio implementation | **Private** | Premium feature |
| Intent Builder implementation | **Private** | Premium feature |
| Enhanced File Explorer implementation | **Private** | Premium feature |
| Macro Recorder implementation | **Private** | Premium feature |
| Performance Dashboard implementation | **Private** | Premium feature |
| Wireless Manager implementation | **Private** | Premium feature |
| `ProFeatureFactory` | **Private** | Concrete implementations |
| `fl_chart`, `sqlite3` deps | **Private** | Only needed for premium |
| Supabase Edge Functions | Separate (Supabase) | Backend code |

### Important Notes for Implementation

1. **The public repo must compile and run perfectly without `adb_ui_pro`.** The conditional import + stub pattern ensures this. Test both configurations in CI.

2. **Shared types go in the public repo.** Any models or interfaces that both repos need (like `AdbDevice`, `PremiumFeature`, etc.) must be in the public repo. The private repo depends on the public one, never the reverse.

3. **Never import private repo code in the public repo.** The only reference is the conditional import in `main.dart` which falls back to the stub.

4. **Version both repos together.** When the public repo makes breaking changes to interfaces, bump a major version and update the private repo to match. Use the same version tags (e.g., both at v1.0.0).

5. **The licensing check happens in the public repo.** The private repo only provides the UI implementations. Even if someone somehow got the pro package, it won't work without a valid license because `PremiumGate` checks the license state from Supabase.

---

## Open-Core Strategy Summary

| Feature | Free | Premium |
|---------|------|---------|
| Device connect/disconnect (USB + manual wireless) | Yes | Yes |
| APK install/uninstall | Yes | Yes |
| Basic file push/pull | Yes | Yes |
| Custom ADB commands | Yes | Yes |
| Command queue & history | Yes | Yes |
| Scrcpy launch | Yes | Yes |
| Text input | Yes | Yes |
| Theme settings | Yes | Yes |
| **Advanced Logcat Studio** | No | Yes |
| **Intent & Deep Link Builder** | No | Yes |
| **Enhanced File Explorer** (dual-pane, SQLite viewer, etc.) | No | Yes |
| **Macro & Automation Recorder** | No | Yes |
| **Performance & Network Dashboard** | No | Yes |
| **Wireless ADB Manager** (auto-discovery, auto-reconnect) | No | Yes |
