# M01 Foundation Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Spec**: `.specs/features/m01-foundation/spec.md`
**Design**: `.specs/features/m01-foundation/design.md`
**Status**: Draft

Project rules that apply to every task: code, file names and test descriptions in English; no explanatory comments (`///` allowed; ask before `// ignore:` or `TODO`); requirement code first in test names (`test('THEME-01: ...')`); library APIs checked in Context7 before writing code; commit messages in Portuguese, Conventional Commits, scopes `app` / `server` / `docs` / `infra`, no Claude co-authorship.

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec - confirm before Execute. Guidelines found: `app/.claude/docs/testes.md`, `docs/adr/0015-estrategia-de-testes-do-app.md`, `app/CLAUDE.md` ("all new code comes with a unit or widget test"). Existing tests: only the template `app/test/widget_test.dart` (removed in T2).

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Theme tokens, palette, font licenses (`lib/core/theme/`) | unit | Every value of the spec tables asserted 1:1 (THEME-01…04); every THEME AC | `app/test/core/theme/*_test.dart` | `fvm flutter test test/core/theme` |
| Preferences (`lib/core/preferences/`) | unit | Every PREF AC, including the failing-open path (PREF-06) | `app/test/core/preferences/*_test.dart` | `fvm flutter test test/core/preferences` |
| Database (`lib/core/database/`) | Drift (real in-memory SQLite) | TEST-01…05: opens, `SELECT 1`, distinct instances, provider override | `app/test/core/database/*_test.dart` | `fvm flutter test test/core/database` |
| Design system components (`lib/core/design_system/`) | widget | Every COMP AC of the component: semantics, callbacks, disabled behavior, tokens used; text scale 2.0 without overflow; long title ellipsis | `app/test/core/design_system/**/*_test.dart` | `fvm flutter test test/core/design_system` |
| App shell (`lib/main.dart`, `lib/app.dart`) | widget | STRUCT-01, 03, 05, 06; RVP-02; PREF-01/06 at app level; THEME-07/08 | `app/test/app_test.dart` | `fvm flutter test test/app_test.dart` |
| Repository source scans (THEME-09, STRUCT-07) | unit | Fails on any color/font literal or `Text('…')` literal outside `lib/core/theme/` | `app/test/core/theme/jot_theme_test.dart` | `fvm flutter test test/core/theme` |
| Commit hook (`.githooks/commit-msg`) | shell | Every COMMIT-02…06 case accepted/rejected + empty/comment-only edge case | `.github/scripts/commit-msg_test.sh` | `sh .github/scripts/commit-msg_test.sh` |
| CI workflows, LICENSE, ADRs, `CLAUDE.md`, docs, config | none | - (gate only; workflows verified on the first push) | - | Build gate |

## Gate Check Commands

> Generated from codebase - confirm before Execute. App commands run from `app/`.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | After tasks with unit/widget/Drift tests | `cd app && fvm flutter test` |
| Hook | After tasks touching `.githooks/` or `.github/scripts/` | `sh .github/scripts/commit-msg_test.sh` |
| Build | After config/docs-only tasks and at the end of each phase | `cd app && fvm flutter pub get && fvm dart run build_runner build --delete-conflicting-outputs && fvm flutter analyze && fvm dart format --output=none --set-exit-if-changed $(git ls-files '*.dart') && fvm flutter test` |

Before T3 (lint switch) the Build gate's `flutter analyze` runs with the template `flutter_lints` set.

---

## Execution Plan

Phases run in order; tasks inside a phase run in order. Arrows are real dependencies inside the phase; dependencies on earlier phases are listed in each task.

### Phase 1: App shell and lint

```
T1 → T2 → T3
```

### Phase 2: Repository tooling

```
T4 → T5
T4 → T8
T6
T7
```

### Phase 3: Decision records

```
T9 → T10 → T11 → T12 → T13
```

### Phase 4: Data and preferences infrastructure

```
T14 → T15
T14 → T16
T17 → T18 → T19
```

### Phase 5: Theme and tokens

```
T20 → T22 → T26 → T27
T21 → T22
T21 → T24 → T26
T21 → T26
T25 → T27
T23
```

### Phase 6: Primitive components

```
T28 → T30
T28 → T31 → T36
T28 → T34
T28 → T35
T28 → T36
T29
T32
T33
```

### Phase 7: Composite components

```
T37 → T38 → T46
T37 → T40 → T46
T37 → T43 → T46
T39 → T46
T41 → T46
T42 → T46
T44 → T46
T45 → T46
```

---

## Task Breakdown

### Phase 1: App shell and lint

#### T1: Clean `pubspec.yaml` and set up gen-l10n

**What**: Remove template comments and description from `pubspec.yaml`; add `flutter_localizations`, `intl`, `path_provider`; set `generate: true`; add `l10n.yaml` and `lib/l10n/app_pt.arb` with `appName`; ignore and analyzer-exclude the generated `lib/l10n/app_localizations*.dart`.
**Where**: `app/pubspec.yaml`
**Depends on**: None
**Reuses**: Existing dependency list in `app/pubspec.yaml`
**Requirement**: STRUCT-04 (pubspec), STRUCT-06, STRUCT-08

**Tools**:

- MCP: `context7` (Flutter gen-l10n)
- Skill: NONE

**Done when**:

- [x] `pubspec.yaml` has no `#` comment lines and `description` names Jotline
- [x] `fvm flutter pub get` generates `lib/l10n/app_localizations.dart`; `git status` does not list it
- [x] `l10n.yaml` has `arb-dir`, `template-arb-file: app_pt.arb`, `output-localization-file`, `nullable-getter: false`, no `synthetic-package`
- [x] Build gate passes (template app still in place)

**Tests**: none
**Gate**: build
**Commit**: `build(app): configura gen-l10n e limpa o pubspec`

---

#### T2: Replace the template with the app shell

**What**: New `lib/main.dart` (binding + `ProviderScope` + `runApp`) and `lib/app.dart` (`JotlineApp`: `MaterialApp`, l10n delegates, `pt` only, `onGenerateTitle`, `home: Scaffold()`); delete `test/widget_test.dart`; add `test/helpers/pump_jot.dart` and `test/app_test.dart`.
**Where**: `app/lib/app.dart`
**Depends on**: T1
**Reuses**: Generated `AppLocalizations` from T1

**Tools**:

- MCP: `context7` (Riverpod `ProviderScope`, Flutter localization)
- Skill: NONE

**Done when**:

- [x] `MyApp`/`MyHomePage` gone; `main.dart` has no template comments
- [x] `test/app_test.dart`: STRUCT-05 (one `Scaffold`, no `Text`), RVP-02 (`ProviderScope` ancestor), STRUCT-06 (only `pt` supported), STRUCT-01 (top level of `lib/` within the allowed set), STRUCT-03 (every `test/**/*_test.dart` has a `lib/` counterpart)
- [x] Quick gate passes: `cd app && fvm flutter test` — 5 tests pass

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): substitui o template pelo shell do app`

---

#### T3: Adopt `very_good_analysis`

**What**: Replace `flutter_lints` with `very_good_analysis` 11.0.0; rewrite `analysis_options.yaml` (include, excludes `**/*.g.dart`, `lib/l10n/app_localizations*.dart`, `build/**`, `android/**`, `ios/**`, `public_member_api_docs: false`); fix every finding in `lib/` and `test/`.
**Where**: `app/analysis_options.yaml`
**Depends on**: T2
**Reuses**: Current analyzer excludes

**Tools**:

- MCP: `context7` (very_good_analysis)
- Skill: NONE

**Done when**:

- [x] `flutter_lints` absent and `very_good_analysis` present in `pubspec.yaml` (LINT-01, 02)
- [x] `fvm flutter analyze` → "No issues found!" (LINT-05)
- [x] No `// ignore` added
- [x] Build gate passes — 5 tests pass

**Tests**: none
**Gate**: build
**Commit**: `build(app): adota very_good_analysis`

---

### Phase 2: Repository tooling

#### T4: Commit message hook and its test

**What**: POSIX `sh` hook `.githooks/commit-msg` per design, plus `.github/scripts/commit-msg_test.sh` with accepted and rejected cases.
**Where**: `.githooks/commit-msg`
**Depends on**: None
**Reuses**: Type/scope regex from design

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Accepts: `feat(app): x`, `docs: x`, `fix!: x`, `refactor(infra)!: x`, `Merge branch 'a'`, `Revert "feat: x"`, message with `#` comment lines after the header (COMMIT-02, 06)
- [x] Rejects with message on stderr: `feature: x` (lists types), `feat(prd): x` (lists scopes), `feat:x`, `feat: ` (empty description), 101-char header, empty file, comments-only file (COMMIT-03, 04, 05, edge case)
- [x] Hook is executable and uses only `sh`, `grep`, `sed` (COMMIT-01)
- [x] Hook gate passes: `sh .github/scripts/commit-msg_test.sh` — all cases pass

**Tests**: shell
**Gate**: hook
**Commit**: `build(infra): hook commit-msg com Conventional Commits`

---

#### T5: Commit check in CI

**What**: `.github/scripts/check-commits.sh <range>` and `.github/workflows/commits.yml` (push + pull_request, `fetch-depth: 0`, runs the hook test then the range check; new branch → `origin/main..sha`).
**Where**: `.github/workflows/commits.yml`
**Depends on**: T4
**Reuses**: `.githooks/commit-msg`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `sh .github/scripts/check-commits.sh HEAD~3..HEAD` exits 0 locally on conforming commits
- [x] The script exits 1 and prints the SHA for a range containing a scratch commit `feature: x` (made in a temp clone, never on the real branch)
- [x] Hook gate passes

**Tests**: shell
**Gate**: hook
**Commit**: `ci(infra): valida mensagens de commit em push e PR`

---

#### T6: App CI workflow

**What**: `.github/workflows/app.yml` per design (paths filter, `flutter-version-file: app/.fvmrc`, Java 17, pub get, build_runner, analyze, format check on tracked files, test, `build apk --debug`).
**Where**: `.github/workflows/app.yml`
**Depends on**: T3
**Reuses**: Commands from `app/CLAUDE.md`

**Tools**:

- MCP: `context7` (GitHub Actions `subosito/flutter-action`)
- Skill: NONE

- [x] Triggers cover CI-01/02 (push to `main` + PR, `paths: app/**` and the workflow file)
- [x] Step order matches CI-04…09
- [x] Every step command runs locally from `app/` without error (`build apk --debug` included)
- [ ] First green run confirmed after the user authorizes the push (recorded in `validation.md`) — OPEN: blocked on push authorization, not performed by this worker

**Tests**: none
**Gate**: build
**Commit**: `ci(infra): workflow do app com analyze, format, testes e build`

---

#### T7: MIT license

**What**: `LICENSE` with the MIT text and `Copyright (c) 2026 Jonatas Sennas`; README "License" section states MIT and links `LICENSE`.
**Where**: `LICENSE`
**Depends on**: None
**Reuses**: README section `## License`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `head -3 LICENSE` shows "MIT License" and the copyright line (LIC-01)
- [x] README no longer says "To be defined" (LIC-02)

**Tests**: none
**Gate**: build
**Commit**: `docs: licença MIT`

---

#### T8: Document the commit convention

**What**: README "Getting started" gets `git config core.hooksPath .githooks`; root `CLAUDE.md` "Commits and PRs" gets one line with types, scopes and the hook.
**Where**: `README.md`
**Depends on**: T4
**Reuses**: Existing sections

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Both files describe the format, allowed types and scopes, and the hook setup (COMMIT-09)
- [x] `git config core.hooksPath .githooks` set in this clone and the commit of this task passes the hook

**Tests**: none
**Gate**: hook
**Commit**: `docs: convenção de commits e hook local`

---

### Phase 3: Decision records

#### T9: ADR 0017 — lint set

**What**: `docs/adr/0017-…md` (very_good_analysis, alternatives flutter_lints and flutter_lints + extras); index in `docs/adr/README.md`; `app/CLAUDE.md` names the lint set and drops it from "undecided".
**Where**: `docs/adr/0017-lint-very-good-analysis.md`
**Depends on**: T3
**Reuses**: Format of `docs/adr/0016-idioma-e-comentarios-no-codigo.md`

**Tools**:

- MCP: NONE
- Skill: `create-adr` (adapted to the repo ADR format of 0016)

**Done when**:

- [x] ADR in Portuguese with Status, Data, Decisores, Relacionados, Contexto, Decisão, Alternativas descartadas, Consequências (ADR-01)
- [x] Listed in `docs/adr/README.md` (ADR-02); LINT-06 satisfied

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0017 — lint set very_good_analysis`

---

#### T10: ADR 0018 — `lib/` structure

**What**: ADR for feature-first; `app/CLAUDE.md` "Structure" section filled and item dropped from "undecided"; `testes.md` mirroring rule for the chosen structure.
**Where**: `docs/adr/0018-estrutura-feature-first.md`
**Depends on**: T9, T2
**Reuses**: ADR format

**Tools**:

- MCP: NONE
- Skill: `create-adr` (adapted to the repo ADR format of 0016)

**Done when**:

- [x] ADR + index entry (ADR-01, 02); STRUCT-02 satisfied
- [x] `testes.md` no longer says the organization is undecided (TEST-07, first half)

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0018 — estrutura feature-first do app`

---

#### T11: ADR 0019 — Riverpod without codegen

**What**: ADR; `app/CLAUDE.md` states hand-written providers and drops the item from "undecided".
**Where**: `docs/adr/0019-riverpod-sem-codegen.md`
**Depends on**: T10, T2
**Reuses**: ADR 0015 reasoning on codegen

**Tools**:

- MCP: NONE
- Skill: `create-adr` (adapted to the repo ADR format of 0016)

**Done when**:

- [x] ADR + index entry; RVP-01 (no generator deps) and RVP-03 satisfied
- [x] `app/CLAUDE.md` has no remaining "undecided" item among lint, structure, Riverpod

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0019 — Riverpod sem geração de código`

---

#### T12: ADR 0020 — commit convention and check

**What**: ADR for Conventional Commits + shell hook + CI (alternatives lefthook, commitlint + husky, CI only).
**Where**: `docs/adr/0020-convencao-de-commits.md`
**Depends on**: T11, T5
**Reuses**: ADR format

**Tools**:

- MCP: NONE
- Skill: `create-adr` (adapted to the repo ADR format of 0016)

**Done when**:

- [x] ADR + index entry (ADR-01, 02)

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0020 — convenção e verificação de commits`

---

#### T13: ADR 0021 — license

**What**: ADR for MIT (alternatives: all rights reserved, Apache-2.0, AGPL-3.0; link to the open business-model question).
**Where**: `docs/adr/0021-licenca-mit.md`
**Depends on**: T12, T7
**Reuses**: ADR format

**Tools**:

- MCP: NONE
- Skill: `create-adr` (adapted to the repo ADR format of 0016)

**Done when**:

- [x] ADR + index entry (ADR-01, 02)

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0021 — licença MIT`

---

### Phase 4: Data and preferences infrastructure

#### T14: Empty `AppDatabase` and the in-memory helper

**What**: `lib/core/database/app_database.dart` (`@DriftDatabase()`, constructor takes `QueryExecutor`, `schemaVersion` 1); `test/helpers/test_database.dart`; `test/core/database/app_database_test.dart`.
**Where**: `app/lib/core/database/app_database.dart`
**Depends on**: T3
**Reuses**: `testes.md` database pattern

**Tools**:

- MCP: `context7` (Drift)
- Skill: NONE

**Done when**:

- [x] `build_runner` generates `app_database.g.dart` with zero tables (if it refuses: STOP and ask — see design risk)
- [x] Tests: TEST-01 (`schemaVersion` 1, no tables), TEST-03 (`SELECT 1` on the helper DB), TEST-04 (two helper calls → distinct instances, a temp table created in one is absent in the other)
- [x] Quick gate passes — 3 new tests

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): AppDatabase vazio e helper de banco em memória`

---

#### T15: `databaseProvider`

**What**: `lib/core/database/database_provider.dart` with the `drift_flutter` executor in the support directory and `onDispose(close)`.
**Where**: `app/lib/core/database/database_provider.dart`
**Depends on**: T14
**Reuses**: `AppDatabase`, test helper

**Tools**:

- MCP: `context7` (Drift, Riverpod)
- Skill: NONE

**Done when**:

- [x] Test: TEST-02 — `ProviderContainer.test` with `databaseProvider.overrideWithValue(helperDb)` returns the helper instance
- [x] Quick gate passes — 1 new test

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): provider do banco local`

---

#### T16: Update `testes.md` for the helpers

**What**: `testes.md` database example uses `createTestDatabase()` (`closeStreamsSynchronously: true`); helpers live in `test/helpers/`.
**Where**: `app/.claude/docs/testes.md`
**Depends on**: T14
**Reuses**: Existing doc sections

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Example matches the helper's code; TEST-07 complete

**Tests**: none
**Gate**: build
**Commit**: `docs(app): testes.md com os helpers de teste`

---

#### T17: `PreferencesStore` and the Hive implementation

**What**: `preferences_store.dart` (interface) and `hive_preferences_store.dart` (`Box<String>`, key `lastOpenedNotebookId`, `null` deletes).
**Where**: `app/lib/core/preferences/hive_preferences_store.dart`
**Depends on**: T3
**Reuses**: `hive_ce` from `pubspec.yaml`

**Tools**:

- MCP: `context7` (hive_ce)
- Skill: NONE

**Done when**:

- [x] Tests (Hive in a temp dir): PREF-03 (write, close, reopen, read), PREF-04 (never written → `null`; cleared → `null`), PREF-05 (box holds only `lastOpenedNotebookId` after writes)
- [x] Quick gate passes — 4 new tests

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): preferências locais com hive_ce`

---

#### T18: `UnavailablePreferencesStore` and `openPreferencesStore`

**What**: `unavailable_preferences_store.dart` and `open_preferences_store.dart` (injectable opener; on exception logs and returns the unavailable store; never deletes).
**Where**: `app/lib/core/preferences/open_preferences_store.dart`
**Depends on**: T17
**Reuses**: `PreferencesStore`

**Tools**:

- MCP: `context7` (hive_ce)
- Skill: NONE

**Done when**:

- [x] Tests: successful opener → `HivePreferencesStore`; throwing opener → `UnavailablePreferencesStore` whose reads return `null` and writes do not throw; box file still exists after a failed open (PREF-06)
- [x] Quick gate passes — 4 new tests

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): abertura das preferências tolerante a falha`

---

#### T19: Preferences provider and bootstrap wiring

**What**: `preferences_provider.dart` (throws until overridden); `main.dart` opens the store before `runApp` and overrides it; `pump_jot.dart` overrides it with a fake.
**Where**: `app/lib/core/preferences/preferences_provider.dart`
**Depends on**: T18
**Reuses**: `ProviderScope` from T2

**Tools**:

- MCP: `context7` (Riverpod)
- Skill: NONE

**Done when**:

- [x] Tests: PREF-02 (override returns the fake); app test with `UnavailablePreferencesStore` still shows the root `Scaffold` (PREF-06 app level); reading the provider without override throws `UnimplementedError`
- [x] PREF-01: `main` awaits `openPreferencesStore()` before `runApp` (checked by reading `main.dart` in review)
- [x] Quick gate passes — 3 new tests

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): preferências injetadas via Riverpod no bootstrap`

---

### Phase 5: Theme and tokens

#### T20: Bundled fonts and license registration

**What**: Download the TTFs and `OFL.txt` files from `google/fonts` into `app/assets/fonts/<family>/`; declare them in `pubspec.yaml`; `lib/core/theme/font_licenses.dart` with `registerFontLicenses()`, called in `main`.
**Where**: `app/lib/core/theme/font_licenses.dart`
**Depends on**: T19
**Reuses**: File list from the design

**Tools**:

- MCP: `context7` (Flutter fonts, `LicenseRegistry`)
- Skill: NONE

**Done when**:

- [ ] Tests: THEME-05 (font manifest declares the three families with the weights/styles of the spec; no `google_fonts` dependency), THEME-06 (after `registerFontLicenses()`, `LicenseRegistry.licenses` has one entry per family)
- [ ] Quick gate passes — 2 new tests

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): fontes empacotadas e licenças OFL`

---

#### T21: `JotColors`

**What**: `ThemeExtension` with the 20 color tokens (`copyWith`, `lerp`, `static const light`).
**Where**: `app/lib/core/theme/jot_colors.dart`
**Depends on**: None
**Reuses**: Spec "Color tokens" table

**Tools**:

- MCP: `context7` (Flutter `ThemeExtension`)
- Skill: NONE

**Done when**:

- [ ] Test: THEME-01 — each of the 20 names has the exact hex from the spec table
- [ ] Quick gate passes — ≥1 new test covering 20 values

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): tokens de cor do design system`

---

#### T22: `JotTextStyles`

**What**: `ThemeExtension` with the 12 text styles; Literata styles carry `FontVariation.opticalSize(size)`.
**Where**: `app/lib/core/theme/jot_text_styles.dart`
**Depends on**: T20, T21
**Reuses**: Spec "Typography tokens" table

**Tools**:

- MCP: `context7` (Flutter `TextStyle`, `FontVariation`)
- Skill: NONE

**Done when**:

- [ ] Test: THEME-02 — family, size, weight, letter spacing (−0.02 × size for ≥ 28), line height and color of all 12 styles
- [ ] Quick gate passes

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): tokens de tipografia`

---

#### T23: `JotSpace` and `JotRadius`

**What**: Const spacing and radius tokens (including `rCapa` asymmetric and `rSheet` 24).
**Where**: `app/lib/core/theme/jot_spacing.dart`
**Depends on**: None
**Reuses**: Spec "Shape tokens" table

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Test: THEME-03 (spacing and radius rows) — every value
- [ ] Quick gate passes

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): tokens de espaçamento e raio`

---

#### T24: `JotShadows`

**What**: `ThemeExtension` with `toque`, `capa`, `erguido`, `fab`.
**Where**: `app/lib/core/theme/jot_shadows.dart`
**Depends on**: T21
**Reuses**: Spec "Shape tokens" shadow rows

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Test: THEME-03 (shadow rows) — offsets, blur and colors of all four, `capa` with two layers
- [ ] Quick gate passes

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): tokens de sombra`

---

#### T25: Notebook palette

**What**: `NotebookColor` (6, with values), `CoverPattern` (4), `NotebookCoverPaint` (spine, elastic, pattern overlays); l10n keys for the 10 canvas names.
**Where**: `app/lib/core/theme/notebook_palette.dart`
**Depends on**: None
**Reuses**: Spec "Notebook palette" table

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Test: THEME-04 — enum names in order, the six hex values, the four patterns; `NotebookCoverPaint` values match the canvas (spine 12 px black 18%, elastic 6 px black 28% at 18 px)
- [ ] Quick gate passes

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): paleta de cores e capas de caderno`

---

#### T26: `buildJotTheme`, context accessors and literal scans

**What**: `jot_theme.dart` + `theme_context.dart`; `JotlineApp` uses `buildJotTheme()`; source-scan tests.
**Where**: `app/lib/core/theme/jot_theme.dart`
**Depends on**: T21, T22, T24, T19
**Reuses**: The three extensions

**Tools**:

- MCP: `context7` (Flutter `ThemeData`, `ColorScheme`)
- Skill: NONE

**Done when**:

- [ ] Tests: THEME-07 (M3, `scaffoldBackgroundColor` = `bgMesa`, `colorScheme.primary` = `accent`, no dark theme); `context.colors/textStyles/shadows` resolve; app test asserts root `Scaffold` background `bgMesa` (STRUCT-05) and that `MediaQuery.textScaler` 2.0 reaches a `Text` unclamped (THEME-08)
- [ ] Scan tests: THEME-09 (no `Color(`, `Colors.`, `fontFamily:` in `lib/` outside `lib/core/theme/` and generated files) and STRUCT-07 (no `Text('` / `Text("` literal in `lib/`); each scan proven to fail on a temp fixture
- [ ] Quick gate passes

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): tema claro do Jotline e verificação de literais`

---

#### T27: ADR 0022 and `design.md` "Open" resolved

**What**: ADR for token mapping (ThemeExtension + consts, camelCase, canvas names) and bundled variable fonts; `app/.claude/docs/design.md` "Open" items resolved.
**Where**: `docs/adr/0022-tokens-e-fontes.md`
**Depends on**: T26, T25, T13
**Reuses**: ADR format

**Tools**:

- MCP: NONE
- Skill: `create-adr` (adapted to the repo ADR format of 0016)

**Done when**:

- [ ] ADR + index entry (ADR-01, 02); THEME-10 satisfied
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0022 — tokens do tema e fontes empacotadas`

---

### Phase 6: Primitive components

Every component task: widget test file mirrors the source file under `test/core/design_system/`; includes a text scale 2.0 no-overflow test and reads only theme tokens (COMP-15, enforced by the T26 scan).

#### T28: `JotIcon` and the ten glyphs

**What**: `JotIconGlyph` enum + `JotIcon` widget with a `CustomPainter` per glyph from the canvas SVG geometry; size 22, stroke 1.8 default, parametric stroke.
**Where**: `app/lib/core/design_system/icons/jot_icon.dart`
**Depends on**: T26
**Reuses**: Canvas SVG paths ("Espaço, forma, elevação e ícones")

**Tools**:

- MCP: `context7` (Flutter `CustomPainter`, `Path`)
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-14 — 10 glyphs exist; default size 22 on a 24 grid; color inherited from `IconTheme`; `strokeWidth` parameter honored; each glyph paints without error
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): ícones do design system`

---

#### T29: `JotButton`

**What**: `.primary`, `.destructive`, `.pill`, `.text` variants.
**Where**: `app/lib/core/design_system/jot_button.dart`
**Depends on**: T26
**Reuses**: Theme tokens

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-01 (min 44 × 44, each variant's tokens), COMP-02 (`onPressed: null` → disabled style, tap does not call back) for primary, pill and text
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): botões do design system`

---

#### T30: `JotFab`

**What**: Floating button with icon and label, `rFab`, `shadowFab`, required `onPressed`.
**Where**: `app/lib/core/design_system/jot_fab.dart`
**Depends on**: T28
**Reuses**: `JotIcon`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-01 (min 44, tokens), COMP-03 (`onPressed` required non-null), tap calls back
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): botão flutuante`

---

#### T31: `JotIconButton`

**What**: Icon-only button with required semantic label and required `onPressed`.
**Where**: `app/lib/core/design_system/jot_icon_button.dart`
**Depends on**: T28
**Reuses**: `JotIcon`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-01 (44 × 44), COMP-03, COMP-04 (`find.bySemanticsLabel` finds the label)
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): botão de ícone`

---

#### T32: `JotSegmentedControl`

**What**: Generic segmented control with "label · count" segments.
**Where**: `app/lib/core/design_system/jot_segmented_control.dart`
**Depends on**: T26
**Reuses**: Theme tokens

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-05 — renders "Ativos · 6"; exactly one segment has `selected: true`; tapping another calls `onChanged` with its value
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): controle segmentado`

---

#### T33: `JotTextField`

**What**: Labeled text field with focused/unfocused border tokens.
**Where**: `app/lib/core/design_system/jot_text_field.dart`
**Depends on**: T26
**Reuses**: Theme tokens

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-06 (field half) — label shown; unfocused border `lineForte`, focused border `accent`; `onChanged` receives typed text
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): campo de texto`

---

#### T34: `JotSearchField`

**What**: Search field with the search glyph and a placeholder parameter.
**Where**: `app/lib/core/design_system/jot_search_field.dart`
**Depends on**: T28
**Reuses**: `JotIcon`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-06 (search half) — search glyph present, placeholder shown, `onChanged` receives text
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): campo de busca`

---

#### T35: `EmptyState`

**What**: Icon 40 px stroke 1.4, title UI 16/600, one sentence, no action.
**Where**: `app/lib/core/design_system/empty_state.dart`
**Depends on**: T28
**Reuses**: `JotIcon`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-11 — icon size 40 and stroke 1.4, title style, message shown, no button in the subtree
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): estado vazio`

---

#### T36: `JotTopBar`

**What**: `.back` (back glyph + previous label in `accent`) and `.root` (`tituloTela` + icon actions).
**Where**: `app/lib/core/design_system/jot_top_bar.dart`
**Depends on**: T28, T31
**Reuses**: `JotIcon`, `JotIconButton`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-12 — back mode shows label in `accent` and tap calls `onBack`; root mode title uses `tituloTela` and renders the actions; long title ellipsizes (edge case)
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): navegação de topo`

---

### Phase 7: Composite components

#### T37: `NotebookCover`

**What**: Cover painter: color, pattern, spine, elastic, `bgPapel` label, `shadowCapa`, `rCapa`.
**Where**: `app/lib/core/design_system/notebook_cover.dart`
**Depends on**: T25, T26
**Reuses**: `NotebookColor`, `CoverPattern`, `NotebookCoverPaint`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-07 — paints for every color × pattern; label text shown on `bgPapel`; decoration uses `shadowCapa` and `rCapa`; long label ellipsizes
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): capa de caderno`

---

#### T38: `NotebookCoverTile`

**What**: Cover + title (`cardTitulo`) + meta (`meta`), tappable.
**Where**: `app/lib/core/design_system/notebook_cover_tile.dart`
**Depends on**: T37
**Reuses**: `NotebookCover`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-07 (tile) — title and meta styles; tap calls back; long title ellipsizes
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): item de caderno na grade`

---

#### T39: `NotebookColorPicker`

**What**: Six swatches with ring selection and l10n names.
**Where**: `app/lib/core/design_system/notebook_color_picker.dart`
**Depends on**: T25, T26
**Reuses**: `NotebookColor`, l10n names

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-08 — six options labeled with canvas names; selected has 2 px `ink1` ring and `selected: true`; tap calls `onChanged`
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): seletor de cor do caderno`

---

#### T40: `NotebookCoverPicker`

**What**: Four pattern options rendered with the current color.
**Where**: `app/lib/core/design_system/notebook_cover_picker.dart`
**Depends on**: T37
**Reuses**: Cover pattern painter from T37

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-08 — four options labeled Lisa/Pautada/Pontos/Grade; selected ring + `selected: true`; tap calls `onChanged`
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): seletor de capa do caderno`

---

#### T41: `PageRow`

**What**: Title, date (`meta`), optional excerpt (`itemTrecho`).
**Where**: `app/lib/core/design_system/page_row.dart`
**Depends on**: T26
**Reuses**: Theme tokens

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-09 (page) — styles; excerpt absent when `null`; tap calls back; long title/excerpt ellipsize
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): linha de página`

---

#### T42: `DraggingPageRow`

**What**: Handle (l10n "Mover {title}") + title + `shadowErguido`.
**Where**: `app/lib/core/design_system/dragging_page_row.dart`
**Depends on**: T28
**Reuses**: `JotIcon` (drag handle)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-09 (dragging) — handle semantic label "Mover <title>"; shadow is `shadowErguido`
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): linha de página arrastando`

---

#### T43: `ArchivedNotebookRow`

**What**: Mini cover, title, meta, one pill action.
**Where**: `app/lib/core/design_system/archived_notebook_row.dart`
**Depends on**: T37, T29
**Reuses**: `NotebookCover`, `JotButton.pill`

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-09 (archived/trash) — cover, title, meta rendered; action label shown and tap calls `onAction`
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): linha de caderno arquivado`

---

#### T44: `showJotBottomSheet`

**What**: Sheet over `bgVeu`, top radius 24, 40 × 5 handle, "Cancelar", title, content, primary action.
**Where**: `app/lib/core/design_system/jot_bottom_sheet.dart`
**Depends on**: T29
**Reuses**: `JotButton.primary`, `JotButton.text`

**Tools**:

- MCP: `context7` (Flutter `showModalBottomSheet`)
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-10 — barrier color `bgVeu`; handle 40 × 5; "Cancelar" from l10n closes the sheet; primary tap calls `onPrimary`; title and child rendered
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): bottom sheet`

---

#### T45: `showConfirmDialog`

**What**: Alert dialog with title, message, destructive action and "Cancelar"; returns `true`/`false`.
**Where**: `app/lib/core/design_system/confirm_dialog.dart`
**Depends on**: T29
**Reuses**: `JotButton.destructive`, `JotButton.text`

**Tools**:

- MCP: `context7` (Flutter dialogs, semantics)
- Skill: NONE

**Done when**:

- [ ] Tests: COMP-13 — confirm returns `true`, "Cancelar" returns `false`; radius 24 and `shadowErguido`; exposed as an alert dialog to semantics
- [ ] Quick gate passes

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): diálogo de confirmação`

---

#### T46: Component map in `design.md`

**What**: `app/.claude/docs/design.md` maps each canvas component to its Dart widget and file; notes editor blocks and block bar as out of scope until the editor ADR.
**Where**: `app/.claude/docs/design.md`
**Depends on**: T38, T39, T40, T41, T42, T43, T44, T45, T28–T36
**Reuses**: Design component table

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Every in-scope "Componentes" component listed with its widget (COMP-16)
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs(app): mapa dos componentes do design system`

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7

Phase 1:  T1 → T2 → T3                                   (3)
Phase 2:  T4…T8                                          (5)
Phase 3:  T9 → T10 → T11 → T12 → T13                     (5)
Phase 4:  T14…T19                                        (6)
Phase 5:  T20…T27                                        (8)
Phase 6:  T28…T36                                        (9)
Phase 7:  T37…T46                                        (10)
```

Cross-phase dependencies (not drawn): T6 ← T3 · T9 ← T3 · T10 ← T2 · T11 ← T2 · T12 ← T5 · T13 ← T7 · T14, T17 ← T3 · T20 ← T19 (`main.dart`) · T26 ← T19 (`pump_jot.dart`) · T27 ← T13 (ADR numbering) · Phase 6 ← T26 · T37, T39 ← T25, T26 · T42 ← T28 · T43, T44, T45 ← T29 · T46 ← T28–T36.

46 tasks → 7 task-budgeted batches if delegated (one per phase).

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1 | pubspec + l10n config (one concern: build config) | ⚠️ Cohesive |
| T2 | app shell: `main.dart` + `app.dart` + its test | ⚠️ Cohesive (cannot exist apart) |
| T3 | lint config + resulting fixes | ⚠️ Cohesive |
| T4, T5 | one script/workflow each (+ test script) | ✅ |
| T6, T7, T8 | one file each (README touched in T7/T8 sections only) | ✅ |
| T9–T13, T27 | one ADR each + index line (+ CLAUDE.md line it decides) | ✅ |
| T14–T19 | one class/provider each + its test | ✅ |
| T20 | font assets + one function | ⚠️ Cohesive (the function reads those assets) |
| T21–T25 | one token file each | ✅ |
| T26 | theme builder + context extension + scans | ⚠️ Cohesive (scans protect the theme boundary) |
| T28–T45 | one component each | ✅ |
| T46 | one doc | ✅ |

---

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1 | None | — | ✅ |
| T2 | T1 | T1 → T2 | ✅ |
| T3 | T2 | T2 → T3 | ✅ |
| T4 | None | — | ✅ |
| T5 | T4 | T4 → T5 | ✅ |
| T6 | T3 (phase 1) | — | ✅ |
| T7 | None | — | ✅ |
| T8 | T4 | T4 → T8 | ✅ |
| T9 | None in phase (T3 cross) | — | ✅ |
| T10 | T9 | T9 → T10 | ✅ |
| T11 | T10 | T10 → T11 | ✅ |
| T12 | T11 | T11 → T12 | ✅ |
| T13 | T12 | T12 → T13 | ✅ |
| T14 | None in phase | — | ✅ |
| T15 | T14 | T14 → T15 | ✅ |
| T16 | T14 | T14 → T16 | ✅ |
| T17 | None in phase | — | ✅ |
| T18 | T17 | T17 → T18 | ✅ |
| T19 | T18 | T18 → T19 | ✅ |
| T20 | None in phase | — | ✅ |
| T21 | None | — | ✅ |
| T22 | T20, T21 | T20 → T22, T21 → T22 | ✅ |
| T23 | None | — | ✅ |
| T24 | T21 | T21 → T24 | ✅ |
| T25 | None | — | ✅ |
| T26 | T21, T22, T24 | T21 → T26, T22 → T26, T24 → T26 | ✅ |
| T27 | T26, T25 | T26 → T27, T25 → T27 | ✅ |
| T28 | None in phase | — | ✅ |
| T29 | None in phase | — | ✅ |
| T30 | T28 | T28 → T30 | ✅ |
| T31 | T28 | T28 → T31 | ✅ |
| T32 | None in phase | — | ✅ |
| T33 | None in phase | — | ✅ |
| T34 | T28 | T28 → T34 | ✅ |
| T35 | T28 | T28 → T35 | ✅ |
| T36 | T28, T31 | T28 → T36, T31 → T36 | ✅ |
| T37 | None in phase | — | ✅ |
| T38 | T37 | T37 → T38 | ✅ |
| T39 | None in phase | — | ✅ |
| T40 | T37 | T37 → T40 | ✅ |
| T41 | None in phase | — | ✅ |
| T42 | None in phase | — | ✅ |
| T43 | T37 | T37 → T43 | ✅ |
| T44 | None in phase | — | ✅ |
| T45 | None in phase | — | ✅ |
| T46 | T38–T45 | T38…T45 → T46 | ✅ |

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1 | config | none | none | ✅ |
| T2 | app shell | widget | widget | ✅ |
| T3 | config (+ lint fixes, behavior unchanged) | none | none | ✅ |
| T4, T5 | commit hook / scripts | shell | shell | ✅ |
| T6, T7, T8 | CI workflow, license, docs | none | none | ✅ |
| T9–T13 | ADRs / docs | none | none | ✅ |
| T14, T15 | database | Drift | Drift | ✅ |
| T16 | docs | none | none | ✅ |
| T17, T18 | preferences | unit | unit | ✅ |
| T19 | preferences + app shell | widget (highest) | widget | ✅ |
| T20–T25 | theme tokens | unit | unit | ✅ |
| T26 | theme + scans + app shell | unit/widget | unit (+ app widget test in Done when) | ✅ |
| T27 | ADR / docs | none | none | ✅ |
| T28–T45 | design system components | widget | widget | ✅ |
| T46 | docs | none | none | ✅ |
