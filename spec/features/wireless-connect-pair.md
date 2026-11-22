# Feature: Wireless connect & pair

**Status:** Shipped · **Code:** `AdbController.connect()`, `AdbController.pair()`; sidebar entries

## Connect wireless (`connect()`)

1. Confirm dialog "Android 11 or higher required" — *"Do you have android 11 or higher?"*
   with Yes / No / **Cancel**. Cancel/dismiss → abort.
2. **No (legacy, < Android 11):**
   1. Confirm "USB cable required" — connect via USB. Cancel → abort; No → snackbar
      explaining USB is needed first, abort.
   2. Run `adb tcpip 5555` (queue label `adb tcpip 5555`), wait for output auto-close.
   3. Confirm "Take out the usb cable" — same Wi-Fi network. `false` → abort.
   4. Input dialog "Enter your ip" (label `IP`); port fixed to **5555**.
3. **Yes (Android 11+):** input dialog "Enter your ip and port" (label `IP:PORT`).
   Must split into exactly 2 parts on `:` or snackbar "Invalid ip".
4. Run `adb connect host:port` (label `Connect to host:port`).

## Pair (`pair()`)

- Two-field input "Enter your pair code and ip": `Pair code`, `host:port`.
- Both required; runs `adb pair host:port code` (label `Pair to host:port`).
- Output message is raw stdout (no success parsing).

## Notes

- `NetworkInfoService.getWifiIp()` is injected into `AdbController` but not used yet
  (intended for auto-filling the host IP).
