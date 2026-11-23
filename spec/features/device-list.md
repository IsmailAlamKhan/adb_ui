# Feature: Devices (list and selection)

**Status:** Shipped; redesigned in 0.0.16 · **Code:** `adb/adb_providers.dart`, `device_page/device_widgets.dart`, `shells/`

- `connectedDevicesProvider` polls `adb devices` every second (models cached per device).
- The user **selects** a device (`selectedDeviceIdProvider`); `selectedDeviceProvider` resolves
  it against the live list and falls back to the first connected device. All actions target it.
- Each device shows a status (`AdbDeviceState`: Online / Offline / Unauthorized / Unavailable,
  dot + label, read by screen readers), its model (or id when unknown), id, and USB vs Wi-Fi.

| Style | Device list |
|-------|-------------|
| Workbench | Sidebar "Devices" (`DeviceListTile`); compact: in the drawer, selected name in the app bar |
| Console | Left column "Devices · N"; compact: dropdown in the title row |
| Launcher | Device cards (status line, big name, id); selecting focuses the palette |

- **Loading:** "Looking for devices…" until the first poll returns.
- **None connected:** `NoDeviceState` — "Connect an Android device", how to, and buttons
  Pair with QR code / Pairing code / IP address.
- **adb failed while polling:** `ErrorPanel` with the explained error and Try again.
- **Unauthorized / offline:** `DeviceStateBanner` with the catalogue steps (e.g. "Accept
  'Allow USB debugging?'"); actions are disabled with that reason.
- Device details (Overview / Console center): `devicePropertiesProvider` (`getprop`) → model,
  manufacturer, Android version + API, ABI, connection, serial.
