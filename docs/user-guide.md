# ADB UI user guide

This guide covers everything ADB UI can do (version 0.0.17, plus what's coming in the next
release: app icons, file preview and the new Push flow). If something doesn't work, see
[Troubleshooting](troubleshooting.md).

On macOS, shortcuts use **⌘**. On Windows and Linux, use **Ctrl** where you see ⌘
(for example ⌘K is Ctrl+K).

- [Before you start](#before-you-start)
- [First launch: choosing a style](#first-launch-choosing-a-style)
- [The three styles](#the-three-styles)
- [Connecting a device](#connecting-a-device)
- [Working with a device](#working-with-a-device)
- [Apps](#apps)
- [Files](#files)
- [Logcat](#logcat)
- [AI log filter](#ai-log-filter)
- [Screen mirror](#screen-mirror)
- [Shell and Type text](#shell-and-type-text)
- [Activity (command history)](#activity-command-history)
- [Command palette](#command-palette)
- [Settings](#settings)
- [AI agents (Claude and other MCP clients)](#ai-agents-claude-and-other-mcp-clients)
- [Updates, bug reports and logs](#updates-bug-reports-and-logs)
- [Keyboard shortcuts](#keyboard-shortcuts)

---

## Before you start

ADB UI is a front end for **adb** (Android Debug Bridge), so adb has to be installed. If it
isn't, ADB UI can install it for you (see [Setup & requirements](#setup--requirements)), or you
can install it yourself with the steps in the [README](../README.md#requirements).

[scrcpy](https://github.com/Genymobile/scrcpy) is optional, but you need it for smooth live
screen mirroring. Setup can install it too.

On the phone, turn on **Developer options**: Settings → About phone → tap **Build number**
seven times. Then, in Developer options, turn on **USB debugging** and, for Wi-Fi connections,
**Wireless debugging** (Android 11+).

## First launch: choosing a style

The first time ADB UI opens, it asks **"Choose how ADB UI looks"**. Pick one of three styles and
a theme (**System**, **Light** or **Dark**), then click **Continue**. Each card shows a live
preview, and you can move between them with the arrow keys. You can change both at any time in
[Settings](#settings).

Next comes **Set up ADB UI**.

## Setup & requirements

This page lists what ADB UI needs on your computer and whether it's there:

- **Required:** **adb** (Android SDK Platform-Tools).
- **Optional:** **scrcpy** (live screen mirror), **libmpv** (Linux only, plays the mirror video)
  and the **AI log-filter model**.

Each item shows **Found** with its version, **Installed by ADB UI**, or **Not found**. For a
missing item, the line under it shows how it would be installed, for example
`brew install scrcpy`.

- **Install** uses your package manager: Homebrew on macOS, winget on Windows, apt, dnf, pacman
  or zypper on Linux. A dialog shows the exact command first; nothing runs until you click
  **Install**.
- **Download instead** (or **Install** when you have no package manager) downloads the official
  build: Platform-Tools from Google, scrcpy from its GitHub releases. The dialog shows the
  address, the checksum ADB UI checks, and the folder it goes into (`<app data>/tools/`).
  ADB UI finds tools there without you changing your `PATH`.
- On **Linux**, package installs need administrator rights. ADB UI never runs `sudo` itself:
  **Copy command** and run it in a terminal, or **Run with pkexec** and your system asks for
  your password.
- **Install required** installs everything required that's missing, one at a time.
- **Check again** looks again, for example after you installed something in a terminal.

The output of the running install is shown at the bottom. When adb is found, **Continue** takes
you to your devices.

If adb goes missing later, ADB UI opens this page when it starts instead of an error. You can
open it any time from **Settings → Setup & requirements** or the command palette (⌘K, type
"setup").

## The three styles

All three styles have the same features. They only differ in layout.

| Style | Layout | Good for |
|---|---|---|
| **Workbench** | Device list on the left. The selected device has tabs: Overview, Screen, Logcat, Apps, Files, Shell, Type text. | Doing a lot with one device |
| **Console** | Dense and keyboard-driven, with a docked Activity terminal along the bottom. Drag its edge to resize it or collapse it. | Watching command output as you work |
| **Launcher** | Big device cards and a command palette for everything. | Quick, occasional tasks |

Every style adapts to the window size, down to 480 × 560. In a narrow window, the sidebar
becomes a device picker and dialogs open full-window.

## Connecting a device

### USB
Plug the phone in and tap **Allow** on the "Allow USB debugging?" prompt on the phone. It
appears in the device list within a second. If it shows as **unauthorized**, the prompt is
still waiting on the phone.

### Wi-Fi: Add device (⌘N)
Open **Add device** with ⌘N, the **+** button, or the palette. It has three tabs:

**QR code** (Android 11+, easiest)
1. On the phone: **Developer options → Wireless debugging → Pair device with QR code**.
2. Scan the code shown in ADB UI.
3. ADB UI pairs, connects, and closes the dialog by itself a couple of seconds later.

The phone and the computer must be on the same Wi-Fi network. The status line under the code
says what's happening: waiting for the scan, pairing, then connecting. If nothing scans within
2 minutes, click **New code**. If the phone stays on "Pairing device…", click **Restart adb**
in the hint that appears after 15 seconds; adb sometimes stops seeing phones on the network. If pairing works but connecting doesn't, use the IP address
tab with the address shown on the phone's Wireless debugging screen.

**Pairing code** (Android 11+)
1. On the phone: **Wireless debugging → Pair device with pairing code**.
2. Enter the **IP address & port** and the **6-digit code** the phone shows, then click **Pair**.
3. Then connect with the **IP address** tab, using the address on the Wireless debugging
   screen. Its port is different from the pairing port.

**IP address**
- Android 11+: enter `ip:port` from the Wireless debugging screen and click **Connect**.
- Android 10 or older: connect by USB first, click **Enable Wi-Fi debugging
  (adb tcpip 5555)**, unplug the cable, then connect to `phone-ip:5555`.

The fields check what you type as you go. For example, they warn you if the address has no port.

### Disconnecting
Use **Disconnect** (⇧⌘D) on a Wi-Fi device. ADB UI asks before it disconnects.

## Working with a device

Select a device in the list to make it the **current device**. Every action, tab and shortcut
then works on it. The device's actions are in these places:
- the **Overview** tab (Workbench) or the device panel (Console and Launcher)
- the [command palette](#command-palette) (⌘K)
- the [keyboard shortcuts](#keyboard-shortcuts)

The Overview shows the model, Android version and connection type, and has **Copy device
id** (⇧⌘C).

## Apps

- **Apps tab (Workbench), uninstall list and "Follow app" list:** every app shows its **real
  icon and name** with the package name under it. Search by either ("gmail" or
  `com.google.android.gm`). Turn on **Show system apps** to include the built-in ones.
  - The first time, names and icons take a couple of seconds to appear (a coloured letter tile
    shows meanwhile). ADB UI then remembers them, so they show straight away next time.
  - To get them, ADB UI briefly runs a tiny helper on the phone, the same way screen mirroring
    works. Nothing is installed and nothing stays running. If the helper can't run, you just
    see letter tiles and package names.
- **Install APK (⌘I):** choose an `.apk` file, or **drop one anywhere on the window**. The result
  shows as a notification, and failures explain the reason (for example "an older version
  with a different signature is installed").
- **Uninstall app (⌘U):** choose from the list of installed apps. ADB UI asks before it
  uninstalls.

## Files

### Browsing and previewing
- **Files tab (Workbench)** and the phone's file browser (used by Push and Pull) start in
  `/sdcard`, with quick places (Internal storage, Download, DCIM, Pictures, Documents), Back /
  Up, an editable path and clickable breadcrumbs. Folders are listed first.
- **Click a file to preview it** in the pane on the right:

  | File | Preview |
  |---|---|
  | Photos and images (jpg, png, gif, webp, bmp) | the picture |
  | Videos (mp4, mkv, webm, 3gp, mov) | a player |
  | Music (mp3, m4a, aac, ogg, opus, wav, flac) | a player |
  | Text, logs, JSON, XML, CSV, code… | the text (the first 256 KB; JSON is formatted) |
  | Anything else | its size and date, with **Open** |

  Under the preview: name, size, date and the full path, plus **Pull…** (save it to your
  computer) and **Open** (opens it in the matching app on your computer).
- **Space** opens a large preview. ← / → move to the previous or next file, and Esc closes it.
- In a narrow window, clicking a file opens the large preview straight away.
- Previews are copied to a temporary folder that's cleared each time ADB UI starts. Images
  over 50 MB and videos over 300 MB aren't previewed; use Pull… or Open instead.

### Push files (⌘P)
1. **Push files** opens the phone's file browser, starting in the folder you last pushed to
   (Download the first time).
2. Go to the folder where the files should go.
3. Click **Push files here…** to choose files with your computer's normal file picker, **or drop
   files** from Finder / Explorer onto the browser.
4. The folder refreshes so you can see the new files. Push more, or click **Done**.

In the Files tab, **Push files here…** pushes into the folder you're looking at, and you can
drop files onto the list too.

### Pull files (⇧⌘P)
- Tick the files to copy (click a row to tick it and preview it), then **Pull n files**.
- For one file you choose the name and place to save it; for several you choose a folder.
- In the Files tab, tick files and click **Pull n selected…**.
- A summary tells you how many files were copied, and each copy is listed in Activity.

## Logcat

Open with **⌘L** or the **Logcat** tab. Logs stream live, starting with the last 1,000 lines.

**Presets** (one click):
- **All**
- **Warnings+:** warnings, errors and crashes
- **Errors+:** errors and crashes
- **Crashes:** crashes (Java `FATAL EXCEPTION`), ANRs and native crashes, each with the stack
  trace that follows

**Follow an app:**
- **Follow app…:** pick an installed app to see only its logs. If the app restarts, ADB UI keeps
  following it and marks the restart with a "Process restarted" row. While the app isn't
  running, it shows "Waiting for … to start".
- **Follow foreground app:** always shows the logs of whichever app is open on the phone, and
  switches when you change apps.

**Other filters:**
- **Minimum level:** Verbose, Debug, Info, Warning, Error or Fatal and above.
- **Search:** matches messages and tags. Wrap the search in slashes for a regular expression,
  e.g. `/time(out|d out)/`.
- **Tags:** shown as chips. A hidden tag shows as **Hide: tag**.

Every active filter shows as a chip you can remove. **Clear filters** resets them all.

**Reading and saving:**
- Scrolling up pauses the view. New lines keep arriving and a **"N new · Jump to latest"**
  button takes you back. You can also click **Pause / Resume**.
- Crash lines are marked with a red stripe and **CRASH**.
- **Copy visible lines** copies what the current filters show.
- **Save visible lines…** writes them to a `.txt` file.
- **Clear** empties the view and the phone's log buffer (`adb logcat -c`). It asks first.
- ADB UI keeps the latest 20,000 lines.

## AI log filter

Instead of building filters by hand, describe what you want in the field at the top of Logcat
and press **Enter**. For example:

- `errors from slack`
- `crashes`
- `network timeouts in my app` ("my app" means the app you're following)
- `hide chatty and Choreographer logs`
- `warnings and up`

ADB UI turns the sentence into normal filters and marks them with a ✨ so you can see what the AI
chose. You can edit or remove them like any other filter. A short line under the field explains
the result.

**It runs on your computer.** A small language model (Qwen2.5) runs locally through llama.cpp. Your
sentence and the names of the apps installed on the phone go to the model. Your logs never do,
and nothing is sent over the internet. It also works offline.

**Setting it up:** the first time, Logcat shows a card where you choose a model and click
**Download**:

| Model | Size | Notes |
|---|---|---|
| **Fast** | about 490 MB | Answers in well under a second on Apple Silicon |
| **Accurate** (default) | about 1.1 GB | Better with unusual requests |

The download shows its progress and can be cancelled. Models are stored in the app's data
folder (see [Where things are stored](#where-things-are-stored)). To change or delete a model,
go to **Settings → AI**.

**How it decides:** ADB UI first reads the sentence itself:
- words like *crash*, *error* and *warning* set the preset
- an installed app's name selects that app
- *hide / without / except* hides tags

The model only fills in what's left, and ADB UI checks its answer against your sentence so it
can't invent tags or apps you didn't mention.

## Screen mirror

Open with **⇧⌘M** or the **Screen** tab to see and control the phone inside ADB UI.

**Modes:**
- **Live:** smooth video using scrcpy. This is the default when scrcpy is installed.
- **Snapshot:** refreshed screenshots over plain adb, a few per second. It's used when scrcpy
  isn't installed, or if Live fails.

**Mouse and keyboard on the screen:**

| You do | Phone gets |
|---|---|
| Click | Tap |
| Drag | Swipe |
| Scroll wheel | Scroll |
| Right-click | Back |
| Middle-click | Home |
| Type (screen focused) | The text, typed into the focused field |
| Esc | Back |

**Control buttons:**
- Back, Home, Recent apps
- Volume down / up
- Power
- Rotate
- Notifications
- **Screenshot:** saves a PNG to a folder you choose.
- **Record the screen:** click again to stop. The video (MP4, up to 3 minutes) is saved to a
  folder you choose.
- **Paste your clipboard on the device:** types your computer's clipboard on the phone.
- **Open in a scrcpy window:** opens the separate scrcpy app.

**Quality** (Low 720p, Medium 1080p, High full resolution) and **Frame rate** (30 or 60 fps)
are next to the mode switch. Leaving the page stops mirroring and cleans up on the phone.

## Shell and Type text

- **Run command (⌘R):** run any adb command for the current device. You type everything
  after `adb`, e.g. `shell pm list packages`. The output appears in Activity.
- **Shell tab (Workbench):** the same, with the output right below and a history of what you ran.
- **Type text (⌘T / Type text tab):** sends text to the phone's focused text field.

## Activity (command history)

Everything ADB UI runs on your behalf is recorded in **Activity** (⇧⌘A), along with:
- the command and the device it ran on
- whether it's running, succeeded or failed, and how long it took
- the full output, updated live while it runs

Click an entry to see its details, copy the output, or **run it again**. The list is kept
between launches, and you can filter it by **All**, **Running** or **Errors**. **Clear finished**
tidies it up. In the Console style, Activity is docked at the bottom of the window.

Long-running things such as the Logcat stream, mirroring and device polling don't fill up
Activity. One-off actions (like **Clear** in Logcat) do appear there.

**When something fails**, ADB UI shows a notification that says what went wrong and what to
try next. **Details** opens the full error with the raw adb output.

## Command palette

Press **⌘K** to search every action: device actions, Add device, Activity, Settings, and
switching devices. Use ↑/↓ to move, ↵ to run and Esc to close. In the Launcher style, the
palette is the main way to do things.

## Settings

Open with **⌘,** or from the sidebar/menu.

- **Appearance:** **Style** (Workbench, Console or Launcher) and **Theme** (System, Light or
  Dark). Changes apply straight away.
- **AI:** choose the Fast or Accurate model, see whether it's downloaded, **Download** it or
  **Delete model** to free the disk space.
- **AI agents:** let Claude and other MCP clients use ADB UI (see below).
- **adb:** **Restart adb** fixes phones not showing up over Wi-Fi and QR pairing that never
  finishes. Every device disconnects for a few seconds (asks first if any are connected).
- **Setup:** **Setup & requirements** opens the [setup page](#setup--requirements) to check or
  install adb, scrcpy and the other tools.
- **About:** version, changelog, GitHub link, and *Report a bug or request a feature*.

## AI agents (Claude and other MCP clients)

ADB UI can act as an MCP server, so an AI agent such as Claude Code can use your devices:
list them, take screenshots, tap and type, read logcat, browse files, and run UI tests.
Everything the agent runs shows in **Activity** as `Agent · …`.

1. Open **Settings → AI agents** and turn on **Let AI agents use ADB UI**. It's off until you
   do this, and it only listens on this computer (`http://127.0.0.1:47123/mcp`).
2. Click **Copy Claude Code command** and run it in a terminal, or **Copy JSON config** for
   another MCP client. Both include the access token; keep it private. **New token** makes
   the old one stop working.
3. Ask the agent to do something, e.g. "open the app, sign in as test@example.com and check
   the welcome text".

**Asking first:** installing or uninstalling apps, clearing app data, shell commands and file
copies open a dialog in ADB UI. Choose **Deny** or **Allow**; tick **Allow risky actions until
ADB UI quits** to stop being asked. **Ask again** in Settings turns the questions back on.

**UI tests:** the agent can read the screen as a list of elements (`ui_dump`), tap by text or
id (`tap_element`), wait for something to appear (`wait_for_element`) and check it
(`assert_element`). If it starts a test run, each step and screenshot is saved to
`<app data>/agent_runs/<date>-<name>/` with a `report.md`; **Open test runs folder** opens it.

If the status says the port is in use, type another port, click **Apply**, and copy the
command again.

## Updates, bug reports and logs

**Updates:** ADB UI checks for a new version when it starts and every few hours. When there is
one, it shows what's new in every version since yours, with three buttons:
- **Update** downloads it inside the app (with progress), then **Install and restart** closes
  ADB UI, installs the new version and reopens it. On macOS it replaces the app; on Windows it
  runs the installer silently; on Linux it updates the folder you run it from. If it can't
  replace itself (for example when run straight from the disk image), it opens the installer
  for you instead.
- **Later** asks again next time; **Skip this version** stays quiet until a newer one comes out.

Check any time with **Check for updates** in the command palette (⌘K) or **Settings → About**.
**Changelog** (About, or "What's new" in the palette) shows every version's notes inside the
app, even offline, and after an update ADB UI shows what's new in it once.

**Bug reports:** go to **Settings → About → Report a bug or request a feature**.
1. Choose **Bug report** (you can tick **Include this computer's model and OS**) or **Feature
   request**.
2. For a bug, ADB UI saves its logs to your **Downloads** folder as `adb-ui-logs-<date>.zip`,
   shows the file, and opens a GitHub issue already filled in with your setup (ADB UI
   version, style, OS, `adb version`, the selected phone) and the most recent log lines, with
   your home folder and PATH removed. Drag the zip onto the issue and describe the problem.
3. A feature request opens pre-filled with the questions and your version.

Nothing is sent until you submit the issue on GitHub. ADB UI keeps its logs after a report.

### Where things are stored

| What | Where |
|---|---|
| Settings, Activity history | The app's preferences |
| App logs (one folder per month, files per day) | `<app data>/logs/` |
| AI models | `<app data>/models/` |
| adb and scrcpy installed by Setup | `<app data>/tools/platform-tools/`, `<app data>/tools/scrcpy/` |
| App icons and names | `<app data>/app_icons/` |
| File previews | your system's temp folder, `adb_ui_preview/` (cleared at start) |
| AI agent test runs | `<app data>/agent_runs/` |
| Downloaded updates (removed after updating) | `<app data>/updates/` |

`<app data>` is:
- macOS: `~/Library/Application Support/com.adb-ui/`
- Windows: `%APPDATA%\com.example\adb_ui\`
- Linux: `~/.local/share/com.example.adb_ui/`

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘K | Command palette |
| ⌘N | Add device |
| ⌘, | Settings |
| ⇧⌘A | Activity |
| ⌘I | Install APK |
| ⌘U | Uninstall app |
| ⌘P | Push files |
| ⇧⌘P | Pull files |
| ⌘R | Run command |
| ⌘T | Type text |
| ⌘L | Logcat |
| ⇧⌘M | Mirror screen |
| ⇧⌘C | Copy device id |
| ⇧⌘D | Disconnect |

In the palette: ↑/↓ move, ↵ run, Esc close. In the style picker, the arrow keys move between
the cards.
