# M01 Foundation Validation

**Date**: 2026-10-11
**Spec**: `.specs/features/m01-foundation/spec.md`
**Diff range**: `main..HEAD` (branch `milestone/m01-foundation`, 48 commits, `6bfaa56`..`e2cbea8`)
**Verifier**: independent sub-agent (author ≠ verifier)
**Iteration**: fix→re-verify 1 of 3 (first run: FAIL at `c284341`)

## Validation verdict: PASS ✅

Re-verified at `e2cbea8` after two fix commits (see Fix Verification). The hook test now checks the printed help and the 100/101-character boundary. M5 and M6 are killed, and so are two new twin mutants (scope-branch help, `-gt 101`). `NotebookColorPicker` no longer overflows at 280 px. A new widget test checks this, and it fails against the old fixed-48 px code. The gate is green: 182 tests, analyze 0, format 0, hook test green. 76/78 ACs match the spec outcome. The two remaining items (STRUCT-06, COMP-15) are spec-precision gaps that stay open as non-blocking notes.

*First run (FAIL, kept for history):* the hook test checked only exit codes. Mutants M5 and M6 survived, so COMMIT-03/04 (printed help) and the COMMIT-05 100-character boundary had no test evidence.

---

## Fix Verification (iteration 1)

| Commit | Gap closed | What changed | Independent check |
| ------ | ---------- | ------------ | ----------------- |
| `fa78393` `test(infra): cobre limite de 100 caracteres e texto de ajuda no hook` | Fix 1 (COMMIT-03/04), Fix 2 (COMMIT-05) | `.github/scripts/commit-msg_test.sh:29-38` adds `assert_rejects_with_help`, which captures stderr (`2>&1 >/dev/null`) and checks it with `grep -qF`. New cases: `:55` `"Expected format:"` and `:56` `"Allowed types:"` for `feature: x`; `:57` `"Allowed scopes"` for `feat(prd): x`; `:64-65` accepts a 100-char header (`feat: ` + 94 `x`); `:67-68` rejects a 101-char header (`feat: ` + 95 `x`) | Re-ran M5 and M6 in a scratch worktree. Both are killed, and so are the twins M6b and M5b (table below) |
| `e2cbea8` `fix(app): seletor de cor do caderno não transborda em telas estreitas` | Fix 3 (picker overflow below 288 px) | `app/lib/core/design_system/notebook_color_picker.dart:22-29`: a `LayoutBuilder` sizes each option at `maxWidth / 6`, clamped to `[44, 48]` (`minOptionSize = 44`, `:13`). The swatch scales with it (`36 × option / 48`). The ring stays `Border.all(color: ink1, width: ringWidth = 2)` (`:49-51`), and the `selected` semantics are unchanged (`:37-40`). New test `app/test/core/design_system/notebook_color_picker_test.dart:155-184` pumps the picker at width 280 | `:162` `takeException(), isNull`; `:165-166` every option is `>= 44` wide and tall; `:167-169` all six options can be tapped (`changes, NotebookColor.values`); `:170-173` `Border.all(color: ink1, width: 2)` on the selected option; `:174-181` `isSelected: true`. Against the old implementation (`e2cbea8^`) in a scratch, the test fails with `A RenderFlex overflowed by 8.0 pixels on the right` (M7 killed) |

Residual notes (non-blocking, not spec ACs):
- The picker clamps at 44 px, so it would still overflow if it got less than 264 px (6 × 44). With the bottom sheet's 20 px padding on each side, that means screens narrower than 304 dp, below the 320 dp floor of common phones. No AC sets a minimum width.
- `"Allowed types:"` and `"Allowed scopes"` (`commit-msg_test.sh:56-57`) match only the label prefix, not the listed values. A mutant that dropped a type from the printed list would survive. COMMIT-03/04 do not pin the exact text, so this is acceptable. A future hardening could grep the full `print_help` line.

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T1–T5 | ✅ Done | - |
| T6 | ✅ Done (one item open by design) | "First green run confirmed after the user authorizes the push" is still `[ ]`. This is expected: it waits on push authorization and is not a gap. Every step runs locally (see Gate Check). |
| T7–T46 | ✅ Done | Every "Done when" box checked |

The tasks.md checkboxes match the diff. Each task has one commit, and `sh .github/scripts/check-commits.sh main..HEAD` passes for all 46 commit messages.

---

## Spec-Anchored Acceptance Criteria

"Inspection" means a config, doc or wiring AC that the Test Coverage Matrix leaves to the gate (layer "none"). For these, the evidence is the source `file:line` that satisfies the AC.

### P1: Lint set

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| LINT-01 | include very_good_analysis, no flutter_lints | `app/analysis_options.yaml:1` - `include: package:very_good_analysis/analysis_options.yaml`; grep `flutter_lints` → none | ✅ PASS (inspection) |
| LINT-02 | very_good_analysis in dev_dependencies, no flutter_lints | `app/pubspec.yaml:33` - `very_good_analysis: ^11.0.0` | ✅ PASS (inspection) |
| LINT-03 | excludes `**/*.g.dart`, `build/**`, `android/**`, `ios/**` | `app/analysis_options.yaml:5-9` | ✅ PASS (inspection) |
| LINT-04 | `public_member_api_docs` disabled | `app/analysis_options.yaml:13` - `public_member_api_docs: false` | ✅ PASS (inspection) |
| LINT-05 | analyze after build_runner → 0 issues | Gate run: `No issues found! (ran in 1.5s)` | ✅ PASS (gate) |
| LINT-06 | CLAUDE.md names the lint set, not undecided | `app/CLAUDE.md:10` - `**Lint:** very_good_analysis (ADR 0017)`; grep `undecided` → none | ✅ PASS (inspection) |

### P1: Feature-first structure and app shell

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| STRUCT-01 | `lib/` top level ⊆ {main.dart, app.dart, core, features, l10n} | `app/test/app_test.dart:109` - `expect(entries.difference(allowed), isEmpty)` | ✅ PASS |
| STRUCT-02 | Structure section describes core/ and features/<f>/{data,presentation} | `app/CLAUDE.md:40` | ✅ PASS (inspection) |
| STRUCT-03 | every `test/x/y_test.dart` ↔ `lib/x/y.dart` | `app/test/app_test.dart:123-127` - `expect(File('lib/$relative').existsSync(), isTrue)` | ✅ PASS |
| STRUCT-04 | template app, template test and template comments removed | `app/test/widget_test.dart` deleted; grep `MyApp\|MyHomePage` in lib/test → none; no `#` lines in `app/pubspec.yaml`, `app/analysis_options.yaml` or `//` comments in `app/lib/main.dart:1-18` | ✅ PASS (inspection) |
| STRUCT-05 | empty Scaffold, background bgMesa, no text/child | `app/test/app_test.dart:34-35` - `findsOneWidget` / `find.byType(Text), findsNothing`; `app/test/app_test.dart:50` - `expect(material.color?.toARGB32(), 0xFFF3F2EE)`; `app/lib/app.dart:15` - `home: const Scaffold()` | ✅ PASS |
| STRUCT-06 | gen-l10n, one `app_pt.arb`, **`pt_BR` only**, English keys | `app/test/app_test.dart:96-97` - `hasLength(1)` and `languageCode, 'pt'`; `app/lib/l10n/app_pt.arb:2` - `"@@locale": "pt"` | ⚠️ Spec-precision gap: the spec says `pt_BR`, design.md says "pt only", and the code ships `pt` with no country code. The test name says pt_BR but asserts only `languageCode` |
| STRUCT-07 | no UI string literals in widgets | `app/test/core/theme/jot_theme_test.dart:129-132` (fixture: flags `Text('…')` and `Text(\n "…")`, ignores `Text(title)`); `:136` - `expect(_textLiteralsIn(Directory('lib')), isEmpty)` | ✅ PASS |
| STRUCT-08 | description names Jotline | `app/pubspec.yaml:2` - `"Jotline: offline-first notebook and notes app."` | ✅ PASS (inspection) |

### P1: Riverpod

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| RVP-01 | no riverpod_annotation / riverpod_generator | grep in `app/pubspec.yaml` → none (`app/pubspec.yaml:10-33`) | ✅ PASS (inspection) |
| RVP-02 | root widget wrapped in ProviderScope at startup | `app/lib/main.dart:12-16` - `runApp(ProviderScope(overrides: [...], child: const JotlineApp()))`. The test at `app/test/app_test.dart:84` (`find.byType(ProviderScope), findsOneWidget`) is **tautological**: it pumps its own `ProviderScope` and never runs `main()` | ✅ PASS (inspection). Weak test noted, low priority |
| RVP-03 | CLAUDE.md: hand-written providers, not undecided | `app/CLAUDE.md:11` | ✅ PASS (inspection) |

### P1: Test foundation

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| TEST-01 | AppDatabase(QueryExecutor), no tables, schemaVersion 1 | `app/test/core/database/app_database_test.dart:13-14` - `schemaVersion, 1` / `allTables, isEmpty`; ctor `app/lib/core/database/app_database.dart:7` | ✅ PASS |
| TEST-02 | production executor outside AppDatabase, provider overridable | `app/lib/core/database/database_provider.dart:7-20`; `app/test/core/database/database_provider_test.dart:18` - `container.read(databaseProvider), same(database)` | ✅ PASS |
| TEST-03 | helper returns new AppDatabase on `NativeDatabase.memory()` | `app/test/helpers/test_database.dart:5-7`; `app/test/core/database/app_database_test.dart:20` - `result.single.data['value'], 1` | ✅ PASS |
| TEST-04 | two helper calls → distinct DBs, no shared state | `app/test/core/database/app_database_test.dart:37` - `expect(tablesInOther, isEmpty)` after `CREATE TABLE marker` in the other | ✅ PASS |
| TEST-05 | ≥1 passing unit, widget, Drift test | unit `app/test/core/theme/jot_colors_test.dart:33`; widget `app/test/app_test.dart:34`; Drift `app/test/core/database/app_database_test.dart:20` | ✅ PASS |
| TEST-06 | `flutter test` passes with no device | Gate: `+181: All tests passed!` on a headless machine | ✅ PASS (gate) |
| TEST-07 | testes.md mirroring rule replaces "undecided" | `app/.claude/docs/testes.md:13` | ✅ PASS (inspection) |

### P1: CI for `app/`

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| CI-01 / CI-02 | runs on push to main / PR touching `app/**` or the workflow, not otherwise | `.github/workflows/app.yml:3-12` - `paths: ['app/**', '.github/workflows/app.yml']` on both triggers | ✅ PASS (inspection) |
| CI-03 | Flutter from `app/.fvmrc` | `.github/workflows/app.yml:37` - `flutter-version-file: app/.fvmrc` | ✅ PASS (inspection) |
| CI-04 | build_runner before analyze/format/test/build | `.github/workflows/app.yml:43-44` precedes `:46-56` | ✅ PASS (inspection) |
| CI-05 / CI-08 / CI-09 | analyze issue, failing test or failed APK build fails the job | `.github/workflows/app.yml:47`, `:53`, `:56` (default fail-fast steps) | ✅ PASS (inspection) |
| CI-06 / CI-07 | format check fails on unformatted tracked file, never on `*.g.dart` | `.github/workflows/app.yml:50` - `$(git ls-files '*.dart')`; `*.g.dart` ignored at `app/.gitignore:54` | ✅ PASS (inspection) |
| First green run on GitHub | - | not yet pushed (T6 open item) | ⏭️ Pending push authorization (not a gap) |

### P2: Theme and design tokens

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| THEME-01 | 20 colors, exact hex | `app/test/core/theme/jot_colors_test.dart:9-33` - `expect(color.toARGB32(), hex, reason: name)` for all 20 table rows (checked row by row against the spec table) | ✅ PASS |
| THEME-02 | 12 styles: family, size, weight, spacing (−0.02×size ≥28), height, color | `app/test/core/theme/jot_text_styles_test.dart:22-55` - 7 fields per row, e.g. `tituloTela ... -0.68`, `blocoTexto ... 1.55`, `meta ... colors.ink2` (all 12 match the spec table) | ✅ PASS |
| THEME-03 | spacing 4…56, radii incl. rCapa 4/12, rPilula 22/24, 4 shadows | `app/test/core/theme/jot_spacing_test.dart:7-38`; `app/test/core/theme/jot_shadows_test.dart:22-72` - offsets, blur, rgb, alpha (capa two layers) | ✅ PASS |
| THEME-04 | 6 colors, 4 covers, closed sets, identifiers and values | `app/test/core/theme/notebook_palette_test.dart:13-70` - names in order, six hex values, pattern values | ✅ PASS |
| THEME-05 | 3 families with listed weights/styles bundled, no runtime download | `app/test/core/theme/font_licenses_test.dart:30-37` - variant sets; `:54` - `pubspec, isNot(contains('google_fonts'))` | ✅ PASS |
| THEME-06 | OFL of each font registered at startup | `app/test/core/theme/font_licenses_test.dart:70-75` - 3 entries, one per family; called at `app/lib/main.dart:10` | ✅ PASS |
| THEME-07 | single light M3 theme, scaffold bgMesa, primary accent | `app/test/core/theme/jot_theme_test.dart:60` (`useMaterial3, isTrue`), `:65` (`0xFFF3F2EE`), `:69` (`0xFF2747C9`); `app/test/app_test.dart:61` - `darkTheme, isNull` | ✅ PASS |
| THEME-08 | text scale not clamped | `app/test/app_test.dart:74-75` - `scale(17), 34` / `scale(34), 68` at system scale 2.0 | ✅ PASS |
| THEME-09 | no `Color(`, `Colors.`, `fontFamily:` outside theme folder, scan test | `app/test/core/theme/jot_theme_test.dart:102-109` (fixture proves the scan flags all three and skips theme + generated); `:114` - `_themeLiteralsIn(Directory('lib')), isEmpty` | ✅ PASS |
| THEME-10 | design.md "Open" resolved | `app/.claude/docs/design.md:27-31` (location, camelCase rule, palette identifiers) | ✅ PASS (inspection) |

### P2: Base components

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| COMP-01 | 6 button variants, min 44×44 | `app/test/core/design_system/jot_button_test.dart:42-43, 62-63, 75-76, 91-92` (≥44 / ≥56); `app/test/core/design_system/jot_fab_test.dart:32-33`; `app/test/core/design_system/jot_icon_button_test.dart:27` - `Size(44, 44)` | ✅ PASS |
| COMP-02 | primary/pill/text with null onPressed → disabled style, no taps | `app/test/core/design_system/jot_button_test.dart:122-123, 131-133, 139` (bgTrilho/inkFeito); `:152-158` - `matchesSemantics(... hasEnabledState: true)` (implies `isEnabled: false`, `hasTapAction: false`) | ✅ PASS |
| COMP-03 | FAB and icon button: `onPressed` required, non-null | `app/lib/core/design_system/jot_fab.dart:11,17` and `app/lib/core/design_system/jot_icon_button.dart:11,17` - `required this.onPressed` / `final VoidCallback onPressed`; `app/test/core/design_system/jot_fab_test.dart:83-94` | ✅ PASS (compile-time + test) |
| COMP-04 | icon button requires and exposes a semantic label | `app/test/core/design_system/jot_icon_button_test.dart:74` - `find.bySemanticsLabel('Buscar'), findsOneWidget` | ✅ PASS |
| COMP-05 | "Ativos · 6", exactly one `selected: true`, callback with tapped value | `app/test/core/design_system/jot_segmented_control_test.dart:62` - `find.text('Ativos · 6')`; `:72-89` - `isSelected: true` / `false`; `:100` - `changes, [_Filter.archived]` | ✅ PASS |
| COMP-06 | labeled field with distinct focus styles; search field with icon + placeholder | `app/test/core/design_system/jot_text_field_test.dart:65` (`lineForte`), `:78` (`accent`), `:88`; `app/test/core/design_system/jot_search_field_test.dart:42` (`JotIconGlyph.search`), `:75` (placeholder) | ✅ PASS |
| COMP-07 | cover: color, pattern, spine 12 / black 18%, elastic 6 / black 28% / 18 from edge, bgPapel label, shadowCapa | `app/test/core/design_system/notebook_cover_test.dart:64-70` (every color × pattern), `:78-101` (spine rect `0,0,12,h` + `spineColor`; elastic rect at `w-18-6`), `:207` (`bgPapel`), `:241` (`JotShadows.light.capa`); constants pinned by `app/test/core/theme/notebook_palette_test.dart:42-49` | ✅ PASS |
| COMP-08 | 6 colors + 4 covers, labels = canvas names, selected → 2 px ink1 ring + `selected: true` | `app/test/core/design_system/notebook_color_picker_test.dart:75-77, 90, 93-99, 144`; `app/test/core/design_system/notebook_cover_picker_test.dart:64-66, 100, 103-110, 149` | ✅ PASS |
| COMP-09 | page row (title, date in meta, excerpt in itemTrecho); dragging row (labeled handle, shadowErguido); archived row (mini cover, title, count, one pill) | `app/test/core/design_system/page_row_test.dart:48-50, 57-59, 67-71`; `app/test/core/design_system/dragging_page_row_test.dart:38-39, 94`; `app/test/core/design_system/archived_notebook_row_test.dart:51-55, 68-74, 92, 102` | ✅ PASS |
| COMP-10 | sheet: 40×5 handle, top radius 24, "Cancelar" from l10n, title, content, primary at end, over bgVeu | `app/test/core/design_system/jot_bottom_sheet_test.dart:52` (`bgVeu`), `:60-67` (radius 24), `:74` (`Size(40, 5)`), `:107-115` (Cancelar closes), `:133-140` (primary last, calls back) | ✅ PASS |
| COMP-11 | empty state: icon 40 px, title UI 16/600, one sentence, no CTA | `app/test/core/design_system/empty_state_test.dart:34` (`Size(40, 40)`), `:58-59` (16 / w600), `:66`, `:73-80` (no button in subtree) | ✅ PASS |
| COMP-12 | top bar back (back icon + label in accent) and root (tituloTela + right icon actions) | `app/test/core/design_system/jot_top_bar_test.dart:46, 59, 64, 75` (back); `:123-126` (34 / w700 / −0.68), `:147-150` (actions on the right) | ✅ PASS |
| COMP-13 | dialog: title, description, destructive action, "Cancelar", radius 24, shadowErguido, alert dialog semantics | `app/test/core/design_system/confirm_dialog_test.dart:57` (`[true]`), `:77` (`[false]`), `:105` (`danger`), `:121-122` (rSheet 24, `erguido`), `:164-167` (`SemanticsRole.alertDialog`, scopesRoute, namesRoute) | ✅ PASS |
| COMP-14 | 10 glyphs, 24 grid, 22 px, color inherited | `app/test/core/design_system/icons/jot_icon_test.dart:75-86` (10 glyphs), `:94` (`Size(22, 22)`), `:101` (scale `22/24`), `:114` (IconTheme color) | ✅ PASS |
| COMP-15 | components read colors, styles, spacing, radii, shadows only from tokens | Colors and fonts are enforced by `app/test/core/theme/jot_theme_test.dart:114`. Spacing, radii and weights are not enforced by any test. Components derive off-table styles with `copyWith` + literal `FontWeight.w400/w500/w600` and `height: 1.2` (`jot_button.dart:89`, `jot_segmented_control.dart:58,62`, `jot_text_field.dart:31`, `jot_search_field.dart:22`, `jot_top_bar.dart:83`, `notebook_cover.dart:77-78`, `notebook_cover_picker.dart:29`, `confirm_dialog.dart:86-87`) | ⚠️ Spec-precision gap: the typography table has no tokens for these canvas styles |
| COMP-16 | each component has a widget test; design.md maps components | 18 `lib/core/design_system/**` files ↔ 18 test files (STRUCT-03 test enforces this); `app/.claude/docs/design.md:40-57` | ✅ PASS |

### P2: Commit message check

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| COMMIT-01 | POSIX sh hook in `.githooks/`, only sh/grep/sed | `.githooks/commit-msg:1` `#!/bin/sh`, mode `-rwxr-xr-x`, external tools: `sed` only | ✅ PASS (inspection) |
| COMMIT-02 | valid header with allowed type/scope → exit 0 | `.github/scripts/commit-msg_test.sh:29-40` - `assert_accepts "feat(app): x"`, `"fix!: x"`, `"refactor(infra)!: x"`, comment after header | ✅ PASS |
| COMMIT-03 | bad type → non-zero **and print format + allowed types** | `.github/scripts/commit-msg_test.sh:53` - `assert_rejects "feature: x"` (exit code); `:55` - `assert_rejects_with_help "feature: x" "Expected format:"`; `:56` - `... "Allowed types:"` (stderr captured at `:31`, `grep -qF` at `:34`). M6 killed | ✅ PASS (fixed in `fa78393`) |
| COMMIT-04 | bad scope → non-zero **and print allowed scopes** | `.github/scripts/commit-msg_test.sh:54` - `assert_rejects "feat(prd): x"`; `:57` - `assert_rejects_with_help "feat(prd): x" "Allowed scopes"`. M6b killed | ✅ PASS (fixed in `fa78393`) |
| COMMIT-05 | header > 100 chars or empty description → non-zero | `.github/scripts/commit-msg_test.sh:59` (`"feat: "` rejected); `:64-65` - `assert_accepts` on exactly 100 chars; `:67-68` - `assert_rejects` on exactly 101 chars; `:61-62` (106 chars rejected). M5 (`-ge 100`) and M5b (`-gt 101`) killed | ✅ PASS (fixed in `fa78393`) |
| COMMIT-06 | `Merge …` / `Revert "…"` → exit 0 | `.github/scripts/commit-msg_test.sh:33-34` | ✅ PASS |
| COMMIT-07 | CI runs the script on every new commit and fails on rejection | `.github/workflows/commits.yml:3-5, 19-31`; `.github/scripts/check-commits.sh:19-29`; local `check-commits.sh main..HEAD` → "All commits ... pass" | ✅ PASS (inspection + local run) |
| COMMIT-08 | hook test runs in CI | `.github/workflows/commits.yml:17` - `sh .github/scripts/commit-msg_test.sh` | ✅ PASS (inspection) |
| COMMIT-09 | README + root CLAUDE.md document convention and hooksPath | `README.md:73,76`; `CLAUDE.md:63` | ✅ PASS (inspection) |

### P3: Preferences, License, ADRs

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| PREF-01 | hive initialized and box opened before first frame | `app/lib/main.dart:11` - `await openPreferencesStore()` before `runApp` at `:12`; default opener `app/lib/core/preferences/open_preferences_store.dart:25-28` | ✅ PASS (inspection, as planned in T19) |
| PREF-02 | store exposed via an overridable provider | `app/test/core/preferences/preferences_provider_test.dart:14` - `same(fake)` | ✅ PASS |
| PREF-03 | write, reopen → same value | `app/test/core/preferences/hive_preferences_store_test.dart:32` - `reopened.lastOpenedNotebookId, 'notebook-1'` | ✅ PASS |
| PREF-04 | never written / cleared → null | `app/test/core/preferences/hive_preferences_store_test.dart:40, 50` - `isNull` | ✅ PASS |
| PREF-05 | only `lastOpenedNotebookId` key | `app/test/core/preferences/hive_preferences_store_test.dart:59` - `box.keys, ['lastOpenedNotebookId']` | ✅ PASS |
| PREF-06 | open failure → app starts, reads null, file not deleted | `app/test/core/preferences/open_preferences_store_test.dart:37` (`UnavailablePreferencesStore`), `:47-49` (null before/after write), `:60` (`boxFile.existsSync(), isTrue`); `app/test/app_test.dart:26` (root Scaffold renders) | ✅ PASS |
| LIC-01 | MIT text + `Copyright (c) 2026 Jonatas Sennas` | `LICENSE:1,3` | ✅ PASS (inspection) |
| LIC-02 | README License = MIT + link | `README.md:100` - `MIT — see [LICENSE](LICENSE).` | ✅ PASS (inspection) |
| ADR-01 | six ADRs 0017–0022, PT, Contexto/Decisão/Consequências | `docs/adr/0017…0022`, each with the 3 sections (grep count 3/3) | ✅ PASS (inspection) |
| ADR-02 | index lists each | `docs/adr/README.md:23-28` | ✅ PASS (inspection) |

**Status**: ⚠️ Spec-precision gaps flagged. 76/78 ACs have evidence that matches the spec outcome. COMMIT-03/04/05 were closed in iteration 1. 2 ⚠️ spec-precision gaps (STRUCT-06, COMP-15) remain open as non-blocking notes. They are about the spec's own wording, not implementation bugs.

COMP-01/COMP-08 at narrow width (iteration 1): `app/test/core/design_system/notebook_color_picker_test.dart:155-184` shows that at 280 px each option keeps a touch target of at least 44 × 44, the selected option keeps the 2 px `ink1` ring and `isSelected: true`, and nothing overflows.

---

## Discrimination Sensor

Scratch: `git worktree add --detach <scratchpad>/wt HEAD`, then `pub get` + `build_runner` there. The baseline in the scratch was green (181 passed). Each mutant was reverted with `git checkout -- .` inside the worktree.

| Mutation | File:line | Description | Killed? |
| -------- | --------- | ----------- | ------- |
| M1 | `app/lib/core/preferences/open_preferences_store.dart:21` | Failure path `return UnavailablePreferencesStore();` → `rethrow;` | ✅ Killed (`test/core/preferences`: +7 −3) |
| M2 | `app/lib/core/theme/jot_colors.dart` (bgMesa) | `0xFFF3F2EE` → `0xFFF3F2EF` | ✅ Killed (`test/core/theme` + `app_test`: +37 −3) |
| M3 | `app/lib/core/theme/jot_theme.dart:11` | Removed `scaffoldBackgroundColor: colors.bgMesa` from `buildJotTheme()` | ✅ Killed (+38 −2) |
| M4 | `app/test/core/theme/jot_theme_test.dart:11` | THEME-09 scan regex `\bColors\.` → `\bColours\.` | ✅ Killed (fixture test fails: +7 −1) |
| M5 | `.githooks/commit-msg:35` | Off-by-one `-gt 100` → `-ge 100` (rejects a valid 100-char header; confirmed: the mutant exits 1 on a 100-char header and the real hook exits 0) | ❌ Survived → Fix 2 |
| M6 | `.githooks/commit-msg:60` | Removed `print_help` after "Type ... is not allowed" (COMMIT-03 output) | ❌ Survived → Fix 1 |

**First-run result (at `c284341`)**: 4/6 killed - FAIL ❌

### Re-verification (iteration 1, at `e2cbea8`)

Scratch: `git worktree add --detach <scratchpad>/wt HEAD`. Each mutant was reverted with `git checkout -- .` inside the worktree. The app mutants ran after `pub get` + `build_runner`, with `fvm flutter test test/core/design_system/notebook_color_picker_test.dart`.

| Mutation | File:line | Description | Killed? |
| -------- | --------- | ----------- | ------- |
| M5 (re-run) | `.githooks/commit-msg:35` | `-gt 100` → `-ge 100` | ✅ Killed: `FAIL (expected accept)` on the 100-char header (`commit-msg_test.sh:65`), exit 1 |
| M5b (new) | `.githooks/commit-msg:35` | `-gt 100` → `-gt 101` | ✅ Killed: `FAIL (expected reject)` on the 101-char header (`commit-msg_test.sh:68`), exit 1 |
| M6 (re-run) | `.githooks/commit-msg:60` | Removed `print_help` in the invalid-type branch | ✅ Killed: `FAIL (expected 'Expected format:' …)` and `FAIL (expected 'Allowed types:' …)`, exit 1 |
| M6b (new) | `.githooks/commit-msg:71` | Removed `print_help` in the invalid-scope branch | ✅ Killed: `FAIL (expected 'Allowed scopes' in output): feat(prd): x`, exit 1 |
| M7 (new) | `app/lib/core/design_system/notebook_color_picker.dart` | Reverted the file to `e2cbea8^` (fixed 48 px options, no `LayoutBuilder`) | ✅ Killed: `COMP-08: 280 px width fits all six options without overflow` fails with `A RenderFlex overflowed by 8.0 pixels on the right` (+5 −1) |
| M8 (new) | `app/lib/core/design_system/notebook_color_picker.dart:25` | `available.clamp(minOptionSize, optionSize)` → `... - 4.0` (touch target below 44 px) | ✅ Killed: `Expected: >= 44, Actual: 42.67` at the 280 px test, and `Size(48, 48)` vs `Size(44, 44)` at the 360 px test (+4 −2) |

**Sensor depth**: lightweight. M1–M4 are the orchestrator's targets. M5–M6 were added in the first run because the hook is the main gate on commit history. M5b–M8 were added in iteration 1 to confirm the fixes.
**Isolation**: `git status --porcelain` on the real tree matched the baseline before and after `git worktree remove --force` (only the three untracked `.specs` files). `git worktree list` shows only the main tree. The first run had the same result.
**Result (iteration 1)**: 6/6 re-checked mutations killed. Cumulative: 10/10 (M1–M4 killed in the first run, and the code they cover did not change). PASS ✅

Extra layout probe in the same scratch (not a mutant): `NotebookColorPicker` overflows at widths below 288 px. It overflows by 8 px at 280 and by 16 px at 272, and works at 288 and 320. See adjudication 6.

---

## Adjudication of implementer open questions

| # | Question | Verdict | Reason (against spec.md) |
| - | -------- | ------- | ------------------------ |
| 1 | Icon stroke 1.8 vs canvas 2 for `novo`/`voltar` | **Acceptable** | COMP-14 sets no stroke width. design.md fixes "1.8 standard, 1.4 in EmptyState" (`app/lib/core/design_system/icons/jot_icon.dart:19`). A per-glyph stroke would be a design change for the user to decide, not a spec violation. |
| 2 | `JotButton.destructive` requires non-null `onPressed` (design said nullable) | **Acceptable** | COMP-02 requires a disabled state only for primary, pill and text. The destructive variant has no spec'd disabled state, so the stricter API is consistent with the spec. It is documented with `///` at `app/lib/core/design_system/jot_button.dart:12`. It is a small design.md drift, so record it in STATE/design if desired. |
| 3 | Text styles built with `copyWith` from the nearest token | **Acceptable, flagged as spec-precision gap** | The colors and families still come from tokens (THEME-09 scan is green). The overridden weights and sizes are canvas values that the typography table lacks. A future spec should add tokens for these styles or allow derivation explicitly (COMP-15 row). |
| 4 | "Cancelar" 16/600 at 44 px vs canvas 16/500 at 48 px | **Acceptable (cosmetic)** | COMP-10/COMP-13 require only a text action from l10n, and the test checks that it comes from l10n. Weight and height are cosmetic UAT items, not AC failures. |
| 5 | `moveItem`, `cancel` added to `app_pt.arb` outside the task file list | **Acceptable** | design.md lists both under "Initial keys". The task "Where" fields are primary files, not exhaustive. Note: the design's `search`/`back`/`options` keys were not added. No component needs them, because semantic labels are constructor parameters. |
| 6 | `NotebookColorPicker` 6×48 px row with no responsive handling | **Resolved in `e2cbea8` (iteration 1)**: options shrink to between 44 and 48 px, and the test at `notebook_color_picker_test.dart:155-184` covers 280 px (M7 killed). *First-run finding:* real layout risk, not caught by tests, not a spec AC violation | The text-scale 2.0 test (`app/test/core/design_system/notebook_color_picker_test.dart:148-151`) runs at width 360, and text scale does not affect this text-free row. The probe shows a `RenderFlex` overflow below 288 px. `showJotBottomSheet` pads by `JotSpace.space5` on each side (`app/lib/core/design_system/jot_bottom_sheet.dart:61-64`), so a 320 dp phone leaves 280 px and the picker overflows by 8 px. No AC sets a minimum width, so this does not fail the spec. Fix 3 recommends it, and the user decides the layout (shrink the swatches vs wrap). |
| 7 | T6 "first green run" left open | **Expected, not a gap** | It waits on push authorization. Every workflow step command passed locally in this gate run. |

---

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code | ✅ Components are single-purpose. No speculative parameters beyond design.md (`NotebookCover.mini` serves the pickers and the archived row) |
| Surgical changes | ✅ The diff is limited to the files design.md lists, plus the planned docs |
| No scope creep | ✅ No Drift tables, screens, dark theme or editor visuals. The l10n keys match design.md |
| Matches patterns | ✅ Feature-first `lib/core/**`, `Jot` prefix, token access through `context.colors/textStyles/shadows`, no explanatory comments (only `///`), no `// ignore:` |
| Spec-anchored outcome check (asserted values match spec) | ✅ App ACs match exactly (hex, sizes, weights, semantics). Since `fa78393`, the hook test asserts the stderr help and the 100/101 boundary |
| Per-layer Coverage Expectation met | ✅ Theme 1:1, preferences, database, components (each has a text-scale 2.0 test, and the components with titles have an ellipsis test). Shell layer: COMMIT-02…06 are covered on exit codes and on output |
| Every test maps to a spec requirement | ✅ Test names start with the requirement code. Unprefixed tests map to Done-when items (successful opener, unoverridden provider throws) or to the spec edge cases (text scale, long title) |
| Documented guidelines followed: `app/.claude/docs/testes.md`, `docs/adr/0015`, `docs/adr/0016`, `app/CLAUDE.md` | ✅ In-memory Drift per test, `ProviderContainer.test`, `pumpJot` overrides, English identifiers, PT commits |

Spot-checked: `open_preferences_store.dart`, `jot_theme.dart`, `jot_spacing.dart`, `notebook_palette.dart`, `jot_button.dart`, `notebook_color_picker.dart`, `confirm_dialog.dart`, `.githooks/commit-msg`, `check-commits.sh`, both workflows.

---

## Edge Cases

- [x] Text scale 2.0, no RenderFlex overflow: every component test file has a `text scale 2.0` test and all pass. The width-driven overflow of the color picker was fixed in `e2cbea8` and is covered at 280 px (see adjudication 6).
- [x] Empty or comments-only commit message → non-zero: `.github/scripts/commit-msg_test.sh:50-60`
- [x] build_runner fails in CI → job fails before analyze: step order at `.github/workflows/app.yml:43-47`
- [x] PR touching `app/` and `docs/` → one run: one workflow with one job (`.github/workflows/app.yml:18-19`)
- [x] Long title → ellipsis: `jot_top_bar_test.dart:169-170`, `notebook_cover_test.dart:310-311`, `notebook_cover_tile_test.dart:115-117`, `page_row_test.dart:125-126`, `dragging_page_row_test.dart:116-117`, `archived_notebook_row_test.dart:130-131`, `jot_bottom_sheet_test.dart:174-175`, `confirm_dialog_test.dart:179-180`

---

## Gate Check

- **Gate command**: `cd app && fvm flutter pub get && fvm dart run build_runner build --delete-conflicting-outputs && fvm flutter analyze && fvm dart format --output=none --set-exit-if-changed $(git ls-files '*.dart') && fvm flutter test` (exit 0)
- **Analyze**: `No issues found!`
- **Format**: `Formatted 69 files (0 changed)`
- **Result (iteration 1, at `e2cbea8`)**: 182 passed, 0 failed, 0 skipped (`+182: All tests passed!`). First run: 181.
- **Hook gate**: `sh .github/scripts/commit-msg_test.sh` → "All commit-msg hook cases passed." (exit 0)
- **Commit check**: `sh .github/scripts/check-commits.sh main..HEAD` → all 48 pass
- **Test count before feature**: 1 (template `test/widget_test.dart`)
- **Test count after feature**: 182 (plus 18 shell cases in the hook test, up from 13)
- **Delta**: +181. The template test was removed as STRUCT-04 requires. No tests were removed or weakened by the fix commits; they are additions only.
- **Skipped tests**: none
- **Failures**: none

---

## Fix Plans

Iteration 1 status: Fix 1 ✅ done (`fa78393`, M6/M6b killed) · Fix 2 ✅ done (`fa78393`, M5/M5b killed) · Fix 3 ✅ done (`e2cbea8`, M7/M8 killed) · Fix 4 still optional and open (cosmetic, non-blocking).

### Fix 1: Hook test does not assert the printed help (COMMIT-03, COMMIT-04)

- **Root cause**: `assert_rejects` in `.github/scripts/commit-msg_test.sh:21-27` discards stderr, so the test does not check the spec'd output ("print the expected format and allowed types" / "print the allowed scopes"). Mutant M6 survived.
- **Fix task**: In `.github/scripts/commit-msg_test.sh`, add a stderr-capturing assertion. For `feature: x`, stderr must contain `Expected format:` and `Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`. For `feat(prd): x`, stderr must contain `Allowed scopes (optional): app, server, docs, infra`. Use only `sh`/`grep`.
- **Verify**: `sh .github/scripts/commit-msg_test.sh` passes. Deleting `print_help` from the type branch or the scope branch of `.githooks/commit-msg`, in a scratch worktree, makes it fail.
- **Done when**: M6 and its scope-branch twin are killed.
- **Priority**: Major (AC evidence gap)

### Fix 2: Hook test does not pin the 100-character boundary (COMMIT-05)

- **Root cause**: The only length case is a 106-character header (`.github/scripts/commit-msg_test.sh:47`). It does not discriminate `> 100` from `>= 100` or `> 105`. tasks.md T4 called for a 101-char header. Mutant M5 survived.
- **Fix task**: Add `assert_accepts` on a header of exactly 100 characters, and change the reject case to exactly 101 characters (`feat: ` + 95 `x`).
- **Verify**: The hook test passes on the real hook. In a scratch worktree, `-gt 100` → `-ge 100` and `-gt 100` → `-gt 101` both fail the test.
- **Done when**: M5 is killed.
- **Priority**: Major (weak boundary test)

### Fix 3 (recommended, needs a user decision): `NotebookColorPicker` overflows below 288 px

- **Root cause**: `app/lib/core/design_system/notebook_color_picker.dart:174-209` lays out six fixed 48 px options in a `Row`. Inside the bottom sheet's 20 px side padding on a 320 dp phone, the content width is 280 px, which overflows by 8 px.
- **Fix task**: Ask the user which layout the canvas allows at narrow widths (shrink options proportionally with a ≥44 px touch target, or a `Wrap`). Implement it and add a widget test at width 280 that asserts `tester.takeException()` is null.
- **Priority**: Minor. It is not a spec AC, but it will show on small phones once the notebook-creation sheet ships.

### Fix 4 (optional, low): RVP-02 test is tautological

- **Root cause**: `app/test/app_test.dart:79-85` pumps its own `ProviderScope` and asserts it exists, so it never exercises `main()`. The real wiring (`app/lib/main.dart:12-16`) is verified only by inspection, the same way PREF-01 is.
- **Fix task**: Either accept inspection, as T19 did for PREF-01, and rename or drop the claim, or extract the root-widget builder from `main()` into a testable function.
- **Priority**: Cosmetic

---

## Requirement Traceability Update

Proposed statuses. The orchestrator should apply them to spec.md, since this Verifier is read-only over the real tree.

| Requirement | Previous Status | New Status |
| ----------- | --------------- | ---------- |
| LINT-01…06, STRUCT-01…05, STRUCT-07…08, RVP-01…03, TEST-01…07, THEME-01…10, COMP-01…14, COMP-16, COMMIT-01…09, PREF-01…06, LIC-01…02, ADR-01…02 | Pending | ✅ Verified |
| CI-01…09 | Pending | ✅ Verified locally (first GitHub run pending push) |
| STRUCT-06 | Pending | ⚠️ Verified with spec-precision gap (`pt` vs `pt_BR`) |
| COMP-15 | Pending | ⚠️ Verified with spec-precision gap (derived styles) |
COMMIT-03, COMMIT-04 and COMMIT-05 were "❌ Needs Fix" in the first run. They are ✅ Verified after `fa78393` (iteration 1).

---

## Summary

**Overall**: ✅ Ready (iteration 1). Only the two spec-precision notes remain open, and they do not block.

**Spec-anchored check**: 76/78 ACs matched the spec outcome. 2 spec-precision gaps (STRUCT-06 `pt` vs `pt_BR`; COMP-15 derived styles) remain open as non-blocking notes for the user or a future spec.
**Sensor**: 6/6 re-checked mutations killed in iteration 1 (M5, M5b, M6, M6b, M7, M8). Cumulative: 10/10.
**Gate**: 182 passed, 0 failed. Analyze 0, format 0 changed, hook test green (18 cases), commit check green (48 commits).

*First run (at `c284341`)*: 73/78, sensor 4/6, 181 tests. Not Ready.

**What works**: The app shell, lint set, theme tokens (every hex, style, spacing, radius and shadow pinned 1:1 to the spec tables), literal scans (proven against fixtures and by M4), preferences with the failure path (killed M1), the in-memory DB helper, all 18 design-system components with semantics, callback, disabled, text-scale and ellipsis tests, the CI workflows, the license, the six ADRs and the docs.

**Issues found**: Fixes 1–3 were found in the first run and closed in iteration 1. Still open and non-blocking: Fix 4 (tautological RVP-02 test, cosmetic), the STRUCT-06 and COMP-15 spec-precision notes, and the residual notes under Fix Verification (picker floor of 264 px; the help-text grep matches only the label prefix).

**Next steps**: Apply the traceability statuses to spec.md. Ask the user about the STRUCT-06 locale wording (`pt` vs `pt_BR`) and about COMP-15 tokens for derived styles. The first green CI run on GitHub waits for push authorization (T6).
