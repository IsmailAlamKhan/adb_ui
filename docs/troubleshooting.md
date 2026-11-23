# Troubleshooting

When something fails, ADB UI shows what went wrong and what to try. **Details** shows adb's own
output. This page covers the common cases in more depth. If yours isn't here, see
[Reporting a problem](#reporting-a-problem).

On macOS, shortcuts use ⌘; on Windows and Linux, use Ctrl.

- [Installing and starting](#installing-and-starting)
- [Devices and connecting](#devices-and-connecting)
- [Apps](#apps)
- [Files](#files)
- [Logcat and the AI filter](#logcat-and-the-ai-filter)
- [Screen mirror](#screen-mirror)
- [Reporting a problem](#reporting-a-problem)

---

## Installing and starting

### "ADB UI couldn't start" / adb isn't found
ADB UI needs `adb` from Android platform-tools on your `PATH`.
1. Open a **new** terminal and run `adb version`. If that fails, install platform-tools (see the
   [README](../README.md#requirements)).
2. Quit ADB UI completely and open it again. It reads your `PATH` when it starts.
3. On macOS, ADB UI loads your shell's environment (`~/.zshrc` etc.). If `adb` is only added in
   a file your login shell doesn't read, add it to `~/.zprofile` or `~/.zshrc`.

### macOS says the app "can't be opened" or "is damaged"
The app isn't notarized by Apple yet. Right-click **ADB UI** in Applications → **Open**, or go to
**System Settings → Privacy & Security** and click **Open Anyway**. ADB UI 0.0.17 and later need
**macOS 14 (Sonoma)** or newer.

### Linux: "error while loading shared libraries: libmpv.so…"
Install libmpv, which plays the mirrored screen: `sudo apt install libmpv2` (Debian/Ubuntu;
`libmpv1` on older releases), or `mpv-libs` / `mpv` on Fedora and Arch.

---

## Devices and connecting

### My phone doesn't appear
- **USB:** use a data cable (some cables only charge). Turn on **USB debugging** in Developer
  options. Unlock the phone and look for the "Allow USB debugging?" prompt.
- Run `adb devices` in a terminal. If the phone isn't listed there either, the problem is
  between adb and the phone (cable, drivers on Windows, or the prompt), not ADB UI.
- **Windows:** you may need your phone maker's USB driver (Google USB Driver for Pixels).

### It shows "unauthorized"
The phone is waiting for you to allow this computer. Unlock it and tap **Allow** (tick "Always
allow from this computer"). If no prompt shows: in Developer options tap **Revoke USB debugging
authorizations**, then unplug and plug in again.

### It shows "offline"
Unplug and plug in again, or switch USB debugging off and on. Over Wi-Fi, switch Wireless
debugging off and on.

### QR code pairing doesn't finish
- The phone and computer must be on the **same Wi-Fi network**. Guest networks and some office
  networks block devices from seeing each other.
- Update platform-tools: QR pairing needs a recent adb (`adb mdns check` should print an mDNS
  version).
- If it says "Paired, but couldn't connect automatically", open the **IP address** tab and enter
  the address and port shown on the phone's Wireless debugging screen.
- A code is valid for 2 minutes. Click **New code** to try again.

### Pairing with a code fails
- Use the address and port from the **"Pair device with pairing code"** popup. That port is
  different from the one on the main Wireless debugging screen.
- The code changes every time the popup opens; enter the one currently showing.
- After pairing, connect with the **IP address** tab using the address on the main Wireless
  debugging screen (if it doesn't connect by itself within a few seconds).

### The phone drops off Wi-Fi, or doesn't come back after switching Wireless debugging off and on
Android switches Wireless debugging off when the phone changes Wi-Fi network, and sometimes
when it sleeps. Turn it back on in Developer options.

If the phone is on and on the same network but still doesn't appear, adb's own discovery may
have got stuck. Restart adb's server, then reconnect:

```bash
adb kill-server
```

```bash
adb start-server
```

ADB UI finds the phone again within a few seconds (or use **Add device**). A USB cable is the
most reliable connection for long sessions.

### Android 10 or older
Wireless debugging (pairing) needs Android 11+. On older phones: connect by USB, open **Add device
→ IP address**, click **Enable Wi-Fi debugging (adb tcpip 5555)**, unplug, then connect to
`phone-ip:5555`. You'll find the phone's IP under Settings → About phone → Status, or in Wi-Fi
settings.

---

## Apps

### Install fails
ADB UI explains the common reasons. The usual ones:
- **An app with the same name but a different signature is installed** (for example a debug
  build over a Play Store build). Uninstall the existing app first. This deletes its data.
- **Older version than the one installed:** Android won't downgrade by default. Uninstall
  first, or install with `adb install -d` from **Run command**.
- **Not enough space** on the phone.
- **Blocked by the phone** ("Install via USB" turned off on Xiaomi/MIUI, or a work profile
  policy). Turn the option on in Developer options.

### Apps show coloured letters instead of icons
ADB UI couldn't run its small helper on the phone (some company-managed phones block it).
Everything else still works; you'll just see letter tiles and package names. The first time a list
opens, icons can take a few seconds to fill in.

---

## Files

### "Permission denied"
Without root, adb can only read and write shared storage (`/sdcard` and below) and a few other
places. Other apps' private folders (`/data/data/…`) and system folders aren't reachable.

### "Read-only file system"
You tried to push into a system folder (`/system`, `/vendor`…). Push into `/sdcard` instead.

### Version 0.0.17 says a push or pull failed, but the file is there
That's a bug in 0.0.17: newer adb versions (37+) print their "1 file pushed" message somewhere
ADB UI didn't look. The copy itself worked. It's fixed in the next version, which checks adb's
result instead.

### A preview doesn't show
- Files over 50 MB (images) or 300 MB (video and music) aren't previewed. Use **Pull…** or **Open**.
- Some formats can't be shown inside the app (HEIC photos, PDFs, APKs). **Open** opens them in
  the matching app on your computer.
- A binary file with a text extension shows garbled characters.

---

## Logcat and the AI filter

### Logcat is empty or stops
- If a filter is active (chips above the list), click **Clear filters**.
- **Follow app** only shows that app's lines while it runs ("Waiting for … to start").
- If the phone disconnects, Logcat stops and offers **Restart**.

### The AI model won't download
The download (Fast ≈ 490 MB, Accurate ≈ 1.1 GB) comes from Hugging Face. Check your connection
and free disk space, then click **Download** again; it picks up where it stopped. Company
firewalls sometimes block huggingface.co.

### The AI picked the wrong filter
The filters it chooses are normal chips marked ✨: remove or change any of them. Short, concrete
requests work best ("errors from slack", "crashes", "hide chatty"). The **Accurate** model
(Settings → AI) handles unusual requests better than **Fast**.

### The AI is slow
The first request loads the model (a few seconds). After that, Apple Silicon answers in well under
a second; older or CPU-only computers can take a few seconds. The Fast model is quicker.

---

## Screen mirror

### "Install scrcpy for smooth, real-time mirroring"
Without scrcpy, ADB UI falls back to refreshed screenshots. Install scrcpy (see the
[README](../README.md#requirements)) and open the Screen tab again.

### Live mirroring doesn't start
- Make sure `scrcpy --version` works in a terminal and scrcpy is up to date. ADB UI uses the
  scrcpy server that comes with your scrcpy.
- If scrcpy was installed in an unusual place, set `SCRCPY_SERVER_PATH` to the `scrcpy-server`
  file.
- Switch to **Snapshot** in the Screen tab to keep working, and report the problem (the app's
  log has the details).

### Parts of the screen are black
Android hides protected content (banking apps, DRM video, some lock screens) from screen
capture. That's the phone's choice, not a bug.

### It's laggy over Wi-Fi
Lower **Quality** to Low (720p) or **Frame rate** to 30, or use a USB cable.

---

## Reporting a problem

1. **Settings → About → Report a bug or request a feature.**
2. Choose a folder. ADB UI saves its logs there as a zip. Tick **Include device details** if
   you're happy to share your computer's model and OS.
3. A GitHub issue page opens. Attach the zip and describe:
   - what you did and what happened;
   - your ADB UI version (Settings → About), computer OS, and phone model and Android version;
   - the output of `adb version`.

Logs stay on your computer unless you attach them yourself.
