# Feature: Device file explorer & file transfer

**Status:** Shipped · **Code:** `adb/adb_file_explorer/`, `file_picker/file_picker_view.dart`,
`AdbController.pushFile/pullFile`

## AdbFileExplorerView

Fixed 500×700 dialog. Props: `device`, `title`, `openReason` (`pickFile` default | `pickFolder`).

- Path bar: editable text field showing `/` + history joined; submit → `goToPath`.
  Back button when not at root.
- Lists `adbFilesProvider(device, currentPath)` (keepAlive cache per path) — directories
  first, folder/file icons. Errors show "try again" which invalidates the provider.
- Tap a directory → navigate in. Tap a file → toggle selection (only in `pickFile` mode).
- AppBar shows "Selected (n)" in `pickFile` mode.
- **Select** button: `pickFolder` → pops current path string; `pickFile` → pops
  `List<String>` of selected paths (disabled while none selected).
- State lives in the global `AdbFileExplorerController` (ChangeNotifier); selection is
  cleared when the dialog is disposed. History is **not** reset between openings.
- See [02-adb-layer.md](../02-adb-layer.md#ls-parsing-rules) for how entries are parsed and filtered.

## FilePickerView (local files)

- Drop zone ("Drag and drop a file here or click to pick one") using `desktop_drop`;
  click opens the `file_picker` dialog.
- Validates extensions by `FileType` (`any`, `media`, `image`, `video`, `audio`, `custom`).
- `allowMultiple` (default true) → pops `List<String>` of paths; single → `String`.
- `FilePickerView.apk()` = custom `['apk']`, single file.

## Push flow (`pushFile`)

1. Explorer in `pickFolder` mode — "Select destination folder". None → snackbar.
2. `FilePickerView()` (multiple). None → snackbar "No file selected".
3. Snackbar "Your files are being pushed check the command queue".
4. For each file sequentially: `adb push file dest` with `showOutput: false`.

## Pull flow (`pullFile`)

1. Explorer in `pickFile` mode — "Select files to pull".
2. One file → system **save file** dialog pre-filled with its name; many → **pick folder**.
   None → snackbar "No destination path selected".
3. Snackbar "Your files are being pulled check the command queue".
4. For each file sequentially: `adb pull file dest`, `showOutput: false`.
