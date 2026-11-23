# Feature: In-app screen mirror

**Status:** Shipped in 0.0.17 · **Code:** `lib/app/features/mirror/`
**Owner / requested by:** owner · **Last updated:** 2026-11-22

## Problem

"Mirror screen" opens scrcpy in its own window, outside the app, with keyboard-only controls.

## Behaviour

Entry: Workbench device tab **Screen**; `DeviceAction.mirror` (⇧⌘M) opens `MirrorPage`
in Console and Launcher; palette. "Open in scrcpy window" stays as a secondary action.

### Modes
1. **Live (scrcpy)** — default when scrcpy is installed (`scrcpyAvailableProvider`).
   - Push `scrcpy-server` (found next to the `scrcpy` binary: `<prefix>/share/scrcpy/scrcpy-server`,
     or `SCRCPY_SERVER_PATH`) to `/data/local/tmp/adbui-scrcpy-server.jar`.
   - Start it: `adb shell CLASSPATH=… app_process / com.genymobile.scrcpy.Server <version>
     scid=<8 hex> tunnel_forward=true audio=false control=true (stream options below)
     max_size=<quality> max_fps=<fps> video_bit_rate=<bitrate> stay_awake=true`.
     `<version>` is the installed scrcpy's version (from `scrcpy --version`) — client and
     server must match.
   - `adb forward tcp:<free port> localabstract:scrcpy_<scid>`; the app connects the **video**
     socket first, then the **control** socket (server accepts in that order).
   - Video: server options `send_stream_meta=true send_frame_meta=true send_dummy_byte=true`.
     The app parses codec id, session metas (size) and framed packets (`ScrcpyStreamParser`),
     converts H.264 to length-prefixed NAL units and re-muxes it as **live Matroska**
     (`LiveMatroska`) on a loopback TCP relay that `media_kit` (libmpv) opens as `tcp://…`
     with `load-unsafe-playlists=yes`, `cache=no`, `untimed`, low-latency profile and
     `hwdec=auto-safe`. Matroska is needed because media_kit's ffmpeg has no raw H.264
     demuxer; mpv reads Matroska natively. A new session (rotation) reopens the player with a
     new header; a connecting player gets the header plus the frames since the last keyframe.
   - Input goes over the control socket using scrcpy's control protocol (scrcpy 4.0):
     touch (type 2, 32 bytes), scroll (type 3, 21 bytes), keycode (type 0, 14 bytes),
     text (type 1), back-or-screen-on (type 4), expand notifications (5), collapse (7),
     set display power (10), rotate (11). Positions are in video-frame pixels with the frame
     size (from the session meta) attached.
2. **Snapshot (adb only)** — when scrcpy isn't installed or Live fails: `adb exec-out
   screencap -p` in a loop (~2–5 fps), input through `adb shell input tap/swipe/keyevent/text`.
   A banner says "Install scrcpy for smooth, real-time mirroring".

### Screen and controls
- The device screen fills the available space keeping aspect ratio, with a device-frame
  outline; FPS/latency readout (Live).
- Mouse: click = tap, drag = swipe, wheel = scroll, right-click = Back, middle-click = Home.
- Keyboard while the screen is focused: typed text is sent to the device; Esc = Back.
- Control bar (vertical next to the screen; horizontal at compact width):
  Back · Home · Recents · Volume − / + · Power · Rotate · Notifications · Screenshot
  (saves PNG to a chosen folder, toast with "Show in Finder") · Record (starts
  `screenrecord` on the device, Stop pulls the MP4) · Paste computer clipboard to device ·
  Quality (Low 720 / Medium 1080 / High original, fps 30/60) · Pop out (opens the scrcpy window).
- Ends cleanly: stop → close sockets, remove the forward, kill the server process.
- Errors (server push failed, version mismatch, decoder failed) go through the error catalogue
  (kind `mirror`) with "Switch to snapshot mode" as the retry.

## Acceptance criteria
- [ ] Live mode shows the Pixel smoothly (≥ 30 fps over Wi-Fi) and taps/swipes/keys work.
- [ ] Snapshot mode works with scrcpy uninstalled (simulated by setting mode).
- [ ] Screenshot and record save files; rotate and power work.
- [ ] Leaving the page stops the server and removes the forward.
- [x] Control message encoding unit-tested against the byte layouts above.

## As built (2026-11-22)
- Verified on a Pixel 10 Pro over Wi-Fi: live video at 482×1080 (Medium), key injection
  (Volume, Back) confirmed in the device's input queue.
- scrcpy's server deletes its own jar when it exits (`cleanup`), so the app pushes it on every start.
- media_kit doesn't survive a Flutter **hot restart** in debug (native crash); use a full restart.
- Not yet checked: rotation, recording, snapshot mode on a device without scrcpy, Windows/Linux.
- `[mirror]` stage messages go to the app log for diagnosing start-up failures.
