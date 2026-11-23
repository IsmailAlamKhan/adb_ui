# Feature: File preview

**Status:** Shipped in 0.0.18 · **Code:** `lib/app/features/file_preview/`
**Owner / requested by:** owner · **Last updated:** 2026-11-23

## Problem

Browsing the device's files shows names only. To see what `IMG_2041.jpg` or `app.log` is, you
have to pull it and open it yourself.

## Behaviour

### Preview pane
- In the **Files tab** and in the device file chooser (pull and push), clicking a **file row**
  previews it in a pane on the right (medium/expanded width; the list takes ~55 %). At compact
  width clicking a file opens the large preview instead. Folders still open on click.
- In the Files tab, selection for pulling is the **checkbox**; clicking the row only previews.
  In the pull chooser, clicking a row both toggles selection and previews it.
- Pane content: the preview, then file **name**, **size**, **modified** date and full path
  (mono), then actions **Pull…** (normal recorded pull, save dialog) and **Open** (quietly pulls
  to the preview cache and opens it with the computer's default app), and an expand button.
  With nothing selected: "Select a file to preview it".

### What previews
| Kind | Extensions | How |
|------|-----------|-----|
| Image | png jpg jpeg gif webp bmp | pulled to the preview cache; big images fitted, small ones at real size (`BoxFit.scaleDown`); gif animates |
| Video | mp4 mkv webm 3gp mov | pulled to the cache, media_kit with desktop controls (paused at open; play/pause, seek, volume) |
| Audio | mp3 m4a aac ogg opus wav flac | pulled, media_kit player with play/pause and position |
| Text | txt log json xml csv md yaml yml ini conf cfg properties prop sh html htm kt java dart gradle js ts py | first 256 KB read with `exec-out head -c 262144`; mono, selectable; JSON pretty-printed; "Showing the first 256 KB" note when cut |
| Other | everything else (and heic, pdf, apk) | file-type icon + "No preview for this kind of file" + Open |

- Size limits for pulled previews: images 50 MB, video/audio 300 MB. Bigger: "Too big to
  preview here" with Pull… / Open.
- File info comes from `adb shell stat -c '%s|%Y' <path>` (size bytes, mtime seconds).
- Pulled previews go to `<temp>/adb_ui_preview/<device>/<hash>.<ext>` where the hash covers
  path, size and mtime, so a changed file is pulled again. The folder is cleared on app start.
- Preview work is quiet: none of `stat`, `head`, the preview pull or Open goes into Activity.
  Pull… is a normal recorded action.
- A preview that's still loading when another file is clicked is abandoned (stale results
  are ignored). Errors (permission denied, file vanished) show inside the pane with the
  explained error and a retry.

### Large preview (Quick Look)
- **Space** (when the file list has focus and a file is previewed) or the pane's expand
  button opens a large preview dialog: same renderer, nearly window-sized.
- ← / → go to the previous/next **file** in the folder (folders skipped), Esc or Space closes.
  Title shows the name and "n of m".

## Data & persistence
- `FilePreviewKind` (image, video, audio, text, other) from the extension.
- `RemoteFileInfo { path, size, modified }`; `filePreviewProvider((device, path))` (autoDispose)
  resolves info + either a local cached file or text.
- No settings, nothing persisted besides the temp cache.

## Acceptance criteria
- [x] Pixel: an image previews in the pane; an MP4 shows; .log and .json show text (JSON formatted).
- [x] Space opens the large preview, arrows move, Esc closes.
- [x] Preview commands don't appear in Activity (Overview's recent activity unchanged after previews).
- [x] Kind detection and `stat` parsing unit-tested.

## As built (2026-11-23)
- `lib/app/features/file_preview/`: `FilePreviewKind`, `RemoteFileInfo`, `FilePreviewData`,
  `FilePreviewService` (`stat -L`, `exec-out head -c`, `pull` into the cache),
  `filePreviewProvider` (autoDispose family), `FilePreviewPane`, `FilePreviewContent`,
  `FilePreviewDialog`, `showFilePreview`; `fileKindIcon` (in the explorer) picks row icons.
- Verified on a Pixel 10 Pro over Wi-Fi with test files (png, mp4, log, json): each preview
  ~1 s; the large preview's "n of m" and ←/→ work.
- Each preview re-runs `stat` when reopened (autoDispose); the pulled copy is reused.
- Not yet checked: audio, gif, a large photo, compact width (opens the large preview), Windows/Linux.
