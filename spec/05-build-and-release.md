# 05 — Build, run & release

## Local development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after model/provider changes
flutter run -d macos        # or windows / linux
flutter analyze
```

- Requires `adb` on PATH or the app stops at the init-error screen.
- macOS: CocoaPods (`macos/Podfile`). Entitlements in `macos/Runner/*.entitlements`.
- There is **no `test/` directory** yet.

## Lints (`analysis_options.yaml`)

`flutter_lints` plus: `prefer_relative_imports`, `avoid_redundant_argument_values`,
`type_annotate_public_apis`, `use_super_parameters`. Generated files excluded.
`invalid_annotation_target`, `body_might_complete_normally_nullable`, `unused_element` are ignored.

## Versioning

- Version lives in `pubspec.yaml` (`version: X.Y.Z`) and `version.txt`.
- Update check compares `X*10000 + Y*100 + Z` — keep each part ≤ 99.
- Release tags are `vX.Y.Z`; the app strips the leading `v` from the latest GitHub release tag.

## Release flow

1. `./push_release.sh "<message>"` (Windows-oriented):
   - runs `version_incrementer.exe` to bump `pubspec.yaml` and write `version.txt`,
   - asks for changelog text, writes it to `CHANGELOG.md` (latest only) and prepends to `CHANGELOG-ALL.md`,
   - commits `Updating to <version>` and pushes `master`.
2. `.github/workflows/create_tag_pr.yml`: on push to `master` whose head commit contains
   `Updating to`, reads `version.txt` and creates tag `v<version>` (needs `secrets.PAT`).
   (`create_tag.yml` does the same via manual dispatch.)
3. `.github/workflows/build_and_release.yml` on tag `v*`: creates a GitHub Release with
   `CHANGELOG.md` as body, then calls `build_windows.yml`, `build_linux.yml`, `build_macos.yml`.

## Release assets (names matter — the in-app updater matches `setup-<os>`)

| OS | Asset | Built by |
|----|-------|---------|
| Windows | `adb-ui-setup-windows.exe` (Inno Setup, `Installers/installer.iss`) + `adb-ui-windows.zip` | build_windows.yml |
| macOS | `adb-ui-setup-macos.dmg` (`appdmg Installers/dmg_creator/config.json`) | build_macos.yml |
| Linux | `adb-ui-setup-linux.zip` with `adb-ui.desktop` template | build_linux.yml |

`AboutService.downloadUpdates()` picks the first asset whose name contains
`setup-${Platform.operatingSystem}` (`windows`, `macos`, `linux`). **Renaming assets breaks updates.**

## Changelog

Every user-visible change gets a line in the next `CHANGELOG.md` entry (written during
`push_release.sh`). Spec changes go in the spec, not the changelog.
