# Feature: Device file explorer & file transfer

**Status:** Shipped; push flow reworked 2026-11-23 · **Code:** `adb/adb_file_explorer/`,
`device_page/device_files_view.dart`, `AdbController.pushFile/pullFile`, `file_preview/`
**Last updated:** 2026-11-23

## AdbFileExplorerView (device file chooser)

Dialog (full window at compact width). Props: `device`, `title`, `openReason`
(`pickFile` default | `push`), `initialPath` (default `/sdcard`).

- Header: title + one line of help; **quick places** chips (Internal storage, Download, DCIM,
  Pictures, Documents); Back / Up / editable path field / Refresh; clickable breadcrumbs.
- Lists `adbFilesProvider((device, path))`: folders first. Errors show `ErrorPanel` with retry.
- Click a folder → open it. Files: see the modes below. Files are previewed in a side pane at
  medium/expanded width ([file-preview.md](file-preview.md)); Space opens the large preview.
- State is local to the dialog (nothing leaks between openings).
- Entries come from `ls -1 -p -L` ([02-adb-layer.md](../02-adb-layer.md#ls-parsing-rules)).

| Mode | Click a file | Primary button | Pops |
|------|-------------|----------------|------|
| `pickFile` (pull) | toggles its checkbox and previews it | **Pull n files** | `List<String>` |
| `push` | previews it | **Push files here…** (computer's own file picker, multiple) | nothing — pushes in place |

`push` mode also accepts **files dropped** onto the dialog (drop overlay "Drop to push into
<folder>"). After a push the dialog **stays open**, the folder refreshes so the new files
show, and the usual transfer toast reports the result. **Done** closes it. While the
computer's picker is open the button shows a spinner. Drops on the browser are excluded from the
window-wide APK drop zone (`ApkDropZone.exclude`), so they don't also trigger "Drop an .apk".

## Push flow (`AdbController.pushFile(device, {files, destination})`)

- `DeviceAction.pushFiles` (⌘P), the palette and device panels call `pushFile(device)` with
  nothing → open the explorer in **`push` mode** at the **last folder pushed to** this
  session (`AdbController.lastPushFolder`, default `/sdcard/Download`; if that folder can't be
  listed the browser falls back to `/sdcard`).
- Files tab **Push files here…** → the computer's native file picker
  (`FilePicker.platform.pickFiles(allowMultiple: true)`) directly, destination = current folder.
- Drops on the Files tab or the push browser → `pushFile(device, files, destination)`.
  Dropping a non-APK elsewhere in the window still shows "Drop an .apk file to install it".
- With files and destination: each file `adb push <file> <dest>` sequentially through
  `AdbController.run` (Activity label `Push <name>`); one summary toast (`_transfer`).
- The old two-step flow (folder dialog, then the `FilePickerView` drop dialog) is gone.
  `FilePickerView` stays for **Install APK** only.

## Pull flow (`pullFile`)

1. Explorer in `pickFile` mode — "Choose files to pull".
2. One file → system **save file** dialog pre-filled with its name; many → **pick folder**.
3. Each file `adb pull <file> <dest>`; summary toast.

## Files tab (Workbench)

- Path bar (Up, editable path, Refresh), list with checkboxes, **Pull n selected…**,
  **Push files here…**, drop to push. Starts at `/sdcard`; resets when the device changes.
- Click a file row → preview pane (right side, medium/expanded) — selection is only the
  checkbox. Space → large preview.

## FilePickerView (local files, APK install only)

Drop zone + system picker; `FilePickerView.apk()` = single `.apk`.
