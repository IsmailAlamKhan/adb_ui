# Agent instructions — adb_ui

ADB UI is a Flutter desktop app (Windows / macOS / Linux) that wraps the `adb` CLI.

## 1. Read the spec first

The full specification lives in [`spec/`](spec/README.md). Start with `spec/README.md`;
it links everything else. Do not rely on guessing from the code when the spec answers it.

## 2. Spec-first rule (mandatory)

**Before writing or changing any code — new feature, behaviour change, refactor, or
anything added to the work — update the spec first.** Follow
[`spec/WORKFLOW.md`](spec/WORKFLOW.md):

1. Read the relevant spec files.
2. Write/modify the spec (new features: copy `spec/templates/feature-spec.md` into
   `spec/features/` and add it to the table in `spec/README.md`).
3. Implement.
4. Reconcile the spec with what was actually built; update `spec/06-known-issues.md`.
5. Commit spec and code together.

If a task is added mid-work, the same rule applies to it: spec it before coding it.
A change is not complete until `spec/` matches the code.

## 3. Key conventions (details in `spec/01-architecture.md`)

- Feature folders under `lib/app/features/<feature>/` with `_model`, `_service`,
  `_controller`, `_view` files and a barrel; add new files to the barrel.
- Services are `abstract class` + `Impl`, exposed through Riverpod `Provider`s.
- Controllers don't use `BuildContext`; they navigate through the `NavigationController` mixin (EventBus).
- Relative imports only.
- Every adb command goes through `ProccessAdbServiceImpl.run` and is wrapped by
  `AdbController.run` so it appears in the command queue; add a `rerunCommand` case.
- After editing `@freezed` / `@riverpod` / JSON models run
  `dart run build_runner build`. Generated files are committed.
- Keep existing typo'd API names (`messege`, `dispath`) unless doing a deliberate rename.
- Run `flutter analyze` before finishing.
