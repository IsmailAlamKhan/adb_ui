# Feature: Choose the profile when installing an APK

**Status:** Shipped in 0.0.21 · **Code:** `adb/adb_service.dart` (`listUsers`, `installApk`),
`adb/adb_model.dart` (`DeviceUser`), `adb/adb_controller.dart` (`installApk`, `installDropped`),
`adb/install_target_dialog.dart`, `agent/agent_tools.dart` (`install_apk`)
**Owner / requested by:** owner · **Last updated:** 2026-11-24

## Problem

On a phone with more than one profile (a work profile, Island/Shelter, Private space, a second
user), `adb install` without `--user` doesn't install where the user expects; on the owner's
Pixel it ended up in the work profile. Nothing in ADB UI said where the app went.

## Behaviour

### Install APK (⌘I, the Apps tab button, the palette) and dropped APKs
1. The APK is picked (or dropped) as today.
2. ADB UI asks the phone for its profiles (`pm list users`, quiet: not in Activity).
   - **One profile** (or the list can't be read): install straight away, as before, with no
     `--user`.
   - **More than one:** show the **Install on which profile?** dialog.
3. **Install on which profile?**
   - Subtitle: the APK name (or "3 APKs") and the device name.
   - One radio row per profile, with a label and a muted detail line:
     - user 0 → **Personal** · "Main profile"
     - managed profile (flag `0x20`) → **Work profile** · "<name> · user 10"
     - name "Private space" → **Private space** · "user 11"
     - anything else → its name · "user N"
   - A profile that isn't running (locked Private space, a stopped user) is shown but disabled,
     with "Locked: unlock it on the phone first".
   - A last row **All profiles** · "Installs it in every profile" (`--user all`).
   - Pre-selected: the profile chosen last time for this device in this session, otherwise
     **Personal** (the current user from `am get-current-user`, 0 when unknown).
   - Buttons **Cancel** (installs nothing) and **Install** (primary).
4. The install runs with `--user <id>` (or `all`). The Activity label says where:
   `Install app.apk (Work profile)`; the success message `Installed app.apk in Work profile`.
5. Several dropped APKs: asked once, all go to the chosen profile.

### AI agents (`install_apk`)
- New optional argument `user`: a user id (number) or `"all"`. Without it the app goes to the
  phone's **current user** (`--user current`), i.e. the personal profile, never the work one.
- The approval prompt names the profile when one was given: `Install /x/app.apk on Pixel
  (user 10)`.

## adb / process commands

| Command | Success when | Message | Re-runnable from queue? |
|---------|--------------|---------|-------------------------|
| `adb -s ID shell pm list users` (quiet) | parses `UserInfo{id:name:flagsHex} [running]` lines | — | no |
| `adb -s ID shell am get-current-user` (quiet) | an integer | — | no |
| `adb -s ID install [--user <id\|all\|current>] <path>` | stdout has `Success` | `Installed <file>` (+ ` in <profile>`) | yes: rerun keeps `--user` |

## Data & persistence

- `DeviceUser { int id, String name, int flags, bool running }` with `isManagedProfile`
  (`flags & 0x20`), `isPrivateSpace`, `label`, `detail`; `parseDeviceUsers(String)` in
  `adb_model.dart`. Pure, unit-tested.
- `InstallTarget` = a `DeviceUser` or all profiles; passed to the service as the `--user`
  argument string.
- Last choice per device serial: in memory on `AdbController` (`_installUser`), not stored.

## Files to touch

- `adb/adb_model.dart`, `adb/adb_service.dart` (+ `rerunCommand` `install` case),
  `adb/adb_controller.dart`, new `adb/install_target_dialog.dart` (+ barrel), `agent/agent_tools.dart`.
- Spec: this file, `README.md` table, `device-actions.md`, `02-adb-layer.md`,
  `agent-mcp-server.md`, `03-data-models.md`; docs: `docs/user-guide.md`.

## Acceptance criteria

- [x] A phone with only one profile installs exactly as before (no dialog, no `--user`).
- [x] With a work profile, the dialog lists Personal and Work profile; Install goes only to the
      chosen one. *(Dialog widget-tested; on the owner's Pixel `install --user 0` and
      `--user current` both landed only in the personal profile.)*
- [x] Locked Private space is shown disabled. *(Widget test.)*
- [ ] Re-run from Activity installs to the same profile. *(Code path only.)*
- [ ] Agent `install_apk` without `user` installs to the current user. *(Uses `--user current`,
      checked by hand with adb; not through the agent.)*
- [x] `parseDeviceUsers` unit-tested (`test/device_users_test.dart`); dialog in
      `test/install_target_dialog_test.dart`.

## As built (2026-11-24)
- Both install paths (picker and drop) go through `AdbController._install`, which asks once
  for all the APKs and then refreshes the app list.
- The dialog has no double-click-to-install: a double-tap handler delayed every single click.
- Not checked in the running app: the dialog was tested as a widget, not clicked through in a
  build. `--user all` with a locked profile wasn't tried (it may fail for that profile).

## Out of scope

- Uninstall per profile (`adb uninstall` still removes it for every user) and listing apps per
  profile in the Apps tab.
