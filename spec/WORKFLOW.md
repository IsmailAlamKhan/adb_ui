# Spec-first workflow (mandatory)

These rules apply to **every** change: new feature, behaviour change, bug fix that changes
behaviour, refactor that moves code or renames providers/models, dependency or release
process change. They apply to humans and AI agents alike.

## The rule

> **Update the spec first. Then write code. Then reconcile the spec with what you built.**
> A change is not done until `spec/` describes the code as it now is.

## Steps

1. **Read** `spec/README.md`, then the spec files your change touches
   (usually one feature file + `02-adb-layer.md` / `03-data-models.md`).
2. **Write the spec change before any code:**
   - *New feature:* copy `templates/feature-spec.md` to `features/<kebab-name>.md`,
     set status `In progress`, fill Problem / Behaviour / Commands / Data / Files / Acceptance.
     Add it to the feature table in `README.md` (and remove it from `07-roadmap.md` if listed there).
   - *Change to an existing feature:* edit its feature file so it describes the **new** behaviour.
   - *Cross-cutting change:* edit `01-architecture.md`, `02-adb-layer.md`, `03-data-models.md`,
     `04-ui-conventions.md` or `05-build-and-release.md` as relevant.
   - If the request is ambiguous, record the question under "Open questions" and ask
     before coding.
3. **Implement** following the conventions in `01-architecture.md` and `04-ui-conventions.md`.
4. **Reconcile:** after the code works, re-read your spec edits and fix anything that
   drifted (labels, provider names, file paths, edge cases). Set status to `Shipped`
   once released.
5. **Issues:** fixed an item in `06-known-issues.md`? Remove it. Found a new bug or
   debt you're not fixing? Add it.
6. **Commit spec and code together** in the same commit/PR, so history shows why the code changed.

## What must stay in sync (checklist)

- [ ] New/renamed adb command → `02-adb-layer.md` command catalogue + re-run mapping
- [ ] New/changed model, provider, or `LocalStorageKeys` entry → `03-data-models.md` and `01-architecture.md` provider table
- [ ] New screen/dialog or shared widget → `04-ui-conventions.md` screen map / widget table
- [ ] New device action → `features/device-actions.md` table
- [ ] New feature folder → `01-architecture.md` feature list + `README.md` feature table
- [ ] Startup order change → `01-architecture.md` startup sequence
- [ ] Release asset, version or CI change → `05-build-and-release.md`
- [ ] User-visible change → also a line for the next `CHANGELOG.md` entry, and the user docs
      (`README.md`, `docs/user-guide.md`, `docs/troubleshooting.md`) if it changes what users do or see

## Style for spec files

- Describe **behaviour and contracts** (what the user sees, exact labels, inputs/outputs,
  provider names, file paths) — not line-by-line code.
- Prefer tables and short bullets. Keep each file focused; link instead of duplicating.
- Use real names from the code (`AdbController.pushFile`, `adbFilesProvider`) so they can be grepped.
- Date-stamp observations that may go stale (e.g. "Observed 2026-11-22").
