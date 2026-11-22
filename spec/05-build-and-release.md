# 05 — Build, run & release

## Local development

```bash
flutter pub get
dart run build_runner build   # after model/provider changes
flutter run -d macos        # or windows / linux
flutter analyze
```

- Requires `adb` on PATH or the app stops at the init-error screen.
- Verified toolchain: **Flutter 3.47 stable**. `pubspec.yaml` requires Dart **>=3.8** (freezed 3's generated code needs it).
- macOS deployment target **12.0**; plugins that support it are linked through Swift Package
  Manager (`FlutterGeneratedPluginSwiftPackage`), the rest through CocoaPods. Both were set by
  Flutter's automatic project migration — commit them, don't revert.
- macOS: the App Sandbox is **off** in both `DebugProfile.entitlements` and
  `Release.entitlements`. The app must spawn `adb`/`scrcpy` from the user's PATH and run
  `env.sh`, which the sandbox forbids ("Operation not permitted"). The app is distributed as
  a DMG outside the Mac App Store, so the sandbox isn't required. Don't re-enable it.
- macOS: CocoaPods (`macos/Podfile`). Entitlements in `macos/Runner/*.entitlements`.
- Unit tests live in `test/` (`flutter test`). Start with pure parsing/model logic; there are no widget tests yet.

## Toolchain / codegen versions

| Package | Version | Why |
|---------|---------|-----|
| `freezed` / `freezed_annotation` | 3.x | 2.x depends on the `macros` SDK package, removed from current Dart |
| `build_runner` | 2.10+ (2.15 locked) | ≤2.6 precompile via a `frontend_server` snapshot current SDKs don't ship. `--delete-conflicting-outputs` no longer exists (it's the default) |
| `json_serializable` / `json_annotation` | 6.9+ / 4.9+ | matches analyzer 8 |
| `hooks_riverpod` / `flutter_hooks` | 2.6 / 0.20 | latest Riverpod 2 line |
| `google_fonts` | 6.x | 5.1.0 fails constant evaluation on current Flutter |
| `riverpod_generator` / `riverpod_annotation` | **removed** | 2.6 needs an older analyzer than freezed 3; its 3 providers are hand-written |

freezed 3 rules: every `@freezed` class is declared `abstract class` (single constructor) or
`sealed class` (unions). `when`/`map`/`whenOrNull` are still generated (re-added in 3.1).

## Lints (`analysis_options.yaml`)

`flutter_lints` plus: `prefer_relative_imports`, `avoid_redundant_argument_values`,
`type_annotate_public_apis`, `use_super_parameters`. Excluded from analysis: generated
files (`*.g.dart`, `*.freezed.dart`), `build/`, and the platform folders (`windows/`, `macos/`, `linux/`).
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

## CI build setup (updated 2026-11-22)

- `subosito/flutter-action@v2` with `channel: stable` and `cache: true` (v2.4.0 used the
  retired `actions/cache@v2`, which GitHub now rejects). `actions/checkout@v4`.
- Linux runs `apt-get update` before installing GTK deps.
- Windows output is `build\windows\x64\runner\Release` (Flutter ≥ 3.15); the workflow and
  `Installers/installer.iss` use that path. Inno Setup is installed with Chocolatey first.
- The tag step needs `secrets.PAT` (a token with `contents: write`). If it fails with
  "Bad credentials", renew the token; meanwhile the tag can be pushed by hand
  (`git tag vX.Y.Z <commit> && git push origin vX.Y.Z`).

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
