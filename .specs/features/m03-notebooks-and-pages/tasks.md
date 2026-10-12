# M03 Notebooks and Pages Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Spec**: `.specs/features/m03-notebooks-and-pages/spec.md`
**Design**: `.specs/features/m03-notebooks-and-pages/design.md`
**Status**: Draft

These project rules apply to every task:

- **Branch:** work happens on `milestone/m03-notebooks-and-pages`, created from `main` after the M02 PR is merged, and merged back via PR.
- **Language:** code, file names and test descriptions in English. UI strings only in `app_pt.arb`, with English keys.
- **Comments:** none that explain code. `///` is allowed; ask before adding `// ignore:` or `TODO`.
- **Test names:** requirement code first, e.g. `testWidgets('SORT-04: ...')`.
- **Layout:** values and copy from the canvas artboards listed in the spec's "Canvas references". Any value missing from the theme becomes a token first (lesson L-004); no literal color or font outside `lib/core/theme/` (THEME-09).
- **Library APIs:** checked in Context7 at the versions in `pubspec.lock` before writing code.
- **Commits:** messages in Portuguese, Conventional Commits, scopes `app` / `docs`, no Claude co-authorship.

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec - confirm before Execute. Guidelines found:
> - `app/.claude/docs/testes.md`: real in-memory Drift, streams asserted, a widget test for every screen and component with logic, e2e per main flow
> - `docs/adr/0015-estrategia-de-testes-do-app.md`
> - `app/CLAUDE.md` ("all new code comes with a unit or widget test; anything touching Drift, with an in-memory database test; main flows, with e2e")
>
> Samples: `app/test/features/*/data/*_test.dart`, `app/test/core/design_system/*_test.dart`, `app/test/core/preferences/*_test.dart`, `app/test/helpers/pump_jot.dart`.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Pure logic (`lib/core/text/relative_dates.dart`, `notebook_summary.dart`) | unit | 1:1 to DATE and SORT ACs; every date branch at its exact boundary (day 1 vs 2, 6 vs 7, Dec 31 vs Jan 1; L-002) | `app/test/core/text/*_test.dart`, `app/test/features/notebooks/data/*_test.dart` | `fvm flutter test test/core test/features` |
| Preferences (`lib/core/preferences/`) | unit (real Hive box in a temp dir, like M01) | Read/write/reopen of `notebookSort`, unavailable store, updated PREF-05 / USER-06 key set | `app/test/core/preferences/*_test.dart` | `fvm flutter test test/core/preferences` |
| Repositories (`lib/features/*/data/*_repository.dart`) | Drift (in-memory) with `FakeClock` + `SequentialIdGenerator` | Every AC the method serves, every spec edge case on data; streams asserted to re-emit on page / member / notebook changes | `app/test/features/*/data/*_repository_test.dart` | `fvm flutter test test/features` |
| Providers (`*_providers.dart`, `notebook_sort_provider.dart`) | unit (`ProviderContainer.test`) | Built from overridden base providers; sorted output follows the notifier; errors surface as `AsyncError` | `app/test/features/*/data/*_test.dart` | `fvm flutter test test/features` |
| Design system widgets (`lib/core/design_system/`) | widget (`pumpJot`) | Every state the canvas draws and every AC the widget serves (limits, counter, timer, hold, disabled, semantics) | `app/test/core/design_system/*_test.dart` | `fvm flutter test test/core/design_system` |
| Screens and sheets (`lib/features/*/presentation/`) | widget with in-memory database, `FakeClock`, fake preferences | Every AC of the screen's stories, happy + empty + edge cases; DB rows asserted after each action | `app/test/features/*/presentation/*_test.dart` | `fvm flutter test test/features` |
| Main flows | e2e (`integration_test`), no network | E2E-01 flows end to end on an emulator; any HTTP attempt fails the run (E2E-02) | `app/integration_test/*_flow_test.dart` | `fvm flutter test integration_test -d <emulator>` |
| ADRs, `CLAUDE.md`, `.claude/docs` | none | - (build gate only) | - | Build gate |

## Gate Check Commands

> Generated from codebase (`.github/workflows/app.yml`) - confirm before Execute. App commands run from `app/`.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | After tasks with unit, Drift or widget tests | `cd app && fvm flutter test` |
| Full | After tasks with e2e tests | `cd app && fvm flutter test && fvm flutter test integration_test -d <emulator>` |
| Build | After docs-only tasks and at the end of each phase | `cd app && fvm flutter pub get && fvm dart run build_runner build --delete-conflicting-outputs && fvm flutter analyze && fvm dart format --output=none --set-exit-if-changed $(git ls-files '*.dart') && fvm flutter test` |

---

## Execution Plan

Phases run in order; tasks inside a phase run in order. Arrows are real dependencies inside the phase; dependencies on earlier phases are listed in each task.

### Phase 1: Primitives

```
T1
T2
T3
```

### Phase 2: Data

```
T4 → T5
T6
T7
T4 → T8
T5 → T8
T7 → T8
T6 → T9
```

### Phase 3: Design system

```
T10 → T13
T11 → T14
T12
T15
T16
```

### Phase 4: Page and notebook screens

```
T17 → T18
T19
T20
T21
T18 → T22
T19 → T22
T20 → T22
T21 → T22
```

### Phase 5: Top-level screens

```
T23
T24 → T25
T23 → T25
```

### Phase 6: E2E, measurement and decisions

```
T26 → T27 → T28
T29
T30
T31
T26 → T32
```

---

## Task Breakdown

### Phase 1: Primitives

#### T1: Relative dates and page count

**What**: Create `RelativeDates` (`day`, `withVerb`, `withTime`, injectable `toLocal`) and add the ARB keys `today`, `yesterday`, `onDate`, `weekdayShort` (`select` 1–7), `monthShort` (`select` 1–12) and `pageCount` (ICU plural).
**Where**: `app/lib/core/text/relative_dates.dart`
**Depends on**: None
**Reuses**: `AppLocalizations`; `FakeClock`
**Requirement**: DATE-01, DATE-02, DATE-03, DATE-04

**Tools**:

- MCP: `context7` (Flutter gen-l10n `select` and `plural`)
- Skill: NONE

**Done when**:

- [x] `test/core/text/relative_dates_test.dart` covers:
  - every DATE-01 branch at its boundaries: same day, 1 day, 2 days, 6 days, 7 days, Dec 31 vs Jan 1 of the next year, other year
  - DATE-02 for "hoje", "ontem" and "em …"
  - `withTime` padding ("09:05")
  - DATE-03 with a −03:00 `toLocal` where `2026-10-12T02:00Z` reads "ontem" on local Oct 12
  - DATE-04 for 0, 1 and 12
- [x] No `DateTime.now()` (TIME-03 scan still green)
- [x] Quick gate passes (≥ 12 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): datas relativas e contagem de páginas em pt-BR`

---

#### T2: Notebook sort key in preferences

**What**: Add `notebookSort` / `setNotebookSort` to `PreferencesStore`, `HivePreferencesStore` (key `notebookSort`) and `UnavailablePreferencesStore`. Update the PREF-05 and USER-06 tests to the key set `{lastOpenedNotebookId, notebookSort}`.
**Where**: `app/lib/core/preferences/preferences_store.dart` (+ the two implementations)
**Depends on**: None
**Reuses**: M01 Hive test setup
**Requirement**: SORT-02, SORT-06, EDGE-06

**Tools**:

- MCP: `context7` (hive_ce `Box.put`/`get`)
- Skill: NONE

**Done when**:

- [x] Write, reopen and read return the value; never written returns `null`; the unavailable store returns `null` and ignores writes
- [x] PREF-05 / USER-06 assert the two-key set
- [x] Quick gate passes (≥ 3 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): preferência de ordenação dos cadernos no hive_ce`

---

#### T3: Notebook summary and sort

**What**: Create `NotebookSummary`, `enum NotebookSort { lastEdited, name, createdAt }`, `sortNotebooks` and `foldForSort`.
**Where**: `app/lib/features/notebooks/data/notebook_summary.dart`
**Depends on**: None
**Reuses**: generated `Notebook` row class
**Requirement**: SORT-03, SORT-04, SORT-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `test/features/notebooks/data/notebook_summary_test.dart` covers:
  - each sort option, including ties broken by `id`
  - "árvore" < "Bloco" < "Caderno" under `name`
  - `foldForSort('ÁÇÃo')` == `'acao'`
- [x] Quick gate passes (≥ 6 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): resumo e ordenação de cadernos`

---

### Phase 2: Data

#### T4: Notebook summaries, restore and undo writes

**What**: Add `watchSummaries({archived})`, `watchOne(id)`, `setArchivedAt`, `restore` and `putBackInTrash` to `NotebookRepository`, and make `archive`/`unarchive` delegate to `setArchivedAt`. Remove `watchActive`/`watchArchived`; migrate their assertions (`notebook_repository_test.dart`, `block_repository_test.dart:256`) to `watchSummaries`.
**Where**: `app/lib/features/notebooks/data/notebook_repository.dart`
**Depends on**: None in phase (T3 earlier)
**Reuses**: M02 join with the local user's member row; Drift `count()` / `max()` + `groupBy`
**Requirement**: NBLIST-03, NBLIST-04, NBLIST-07, ARCH-03, ARCH-04, NBDEL-04, NBDEL-05, EDGE-01

**Tools**:

- MCP: `context7` (Drift aggregates with `LEFT OUTER JOIN`, `useColumns: false`)
- Skill: NONE

**Done when**:

- [x] Drift tests cover:
  - `pageCount` excludes trashed pages
  - `lastEditedAt` = max page `updated_at`, else `created_at` (EDGE-01)
  - archived filter
  - re-emission on page insert, page rename, archive and member change (NBLIST-07)
  - `watchOne` emits `null` after `moveToTrash`
  - `setArchivedAt` restores the previous value
  - `restore` clears only `notebooks.deleted_at`, and no `pages`/`blocks` row changes (NBDEL-05)
  - `putBackInTrash` writes the given date
- [x] Migrated M02 tests still assert the same behavior through the new API
- [x] Quick gate passes (≥ 10 new tests; removed tests only those replaced 1:1, listed in the commit body)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): resumo de cadernos, restauração e desfazer no repositório`

---

#### T5: Trashed notebooks query

**What**: Add `TrashedNotebook` and `NotebookRepository.watchTrashed()`.
**Where**: `app/lib/features/notebooks/data/notebook_repository.dart`
**Depends on**: T4
**Reuses**: T4 aggregate
**Requirement**: TRASH-02, TRASH-03, TRASH-11

**Tools**:

- MCP: `context7` (Drift)
- Skill: NONE

**Done when**:

- [x] Drift tests cover:
  - only trashed notebooks
  - count excludes pages deleted on their own (TRASH-03)
  - `archivedAt` carried
  - order `deleted_at` desc then `id` desc
- [x] Quick gate passes (≥ 4 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): consulta de cadernos na lixeira`

---

#### T6: Page watch, restore and trash query

**What**: Add `watchOne`, `restore`, `putBackInTrash`, `TrashedPage` and `watchTrashed` to `PageRepository`.
**Where**: `app/lib/features/pages/data/page_repository.dart`
**Depends on**: None in phase
**Reuses**: M02 join that hides pages of trashed notebooks
**Requirement**: EDGE-03, PGOPT-05, TRASH-04, TRASH-05, TRASH-08, TRASH-09, TRASH-10, TRASH-11, EDGE-05

**Tools**:

- MCP: `context7` (Drift)
- Skill: NONE

**Done when**:

- [x] Drift tests cover:
  - `watchOne` emits `null` when the page or its notebook is trashed
  - `restore` keeps `position`, so the page returns to its slot (PGOPT-05)
  - `watchTrashed` excludes pages of trashed notebooks (TRASH-05) and includes them again after the notebook is restored (TRASH-10)
  - notebook title and color joined
  - order by `deleted_at` desc
  - a page restored into an archived notebook shows in `watchByNotebook` (EDGE-05)
- [x] Quick gate passes (≥ 7 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): página observável, restauração e consulta da lixeira`

---

#### T7: Notebook sort notifier

**What**: Create `NotebookSortNotifier` and `notebookSortProvider`.
**Where**: `app/lib/features/notebooks/data/notebook_sort_provider.dart`
**Depends on**: None in phase (T2, T3 earlier)
**Reuses**: `preferencesStoreProvider`
**Requirement**: SORT-02, SORT-06, SORT-07, EDGE-06

**Tools**:

- MCP: `context7` (Riverpod 3 `Notifier`)
- Skill: NONE

**Done when**:

- [x] Unit tests cover:
  - default `lastEdited` with nothing stored
  - unknown stored value falls back to the default (SORT-07)
  - stored value read on build (SORT-06)
  - `select` updates state and writes the name
  - with `UnavailablePreferencesStore` the state still changes (EDGE-06)
- [x] Quick gate passes (≥ 5 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): estado da ordenação dos cadernos`

---

#### T8: Notebook providers

**What**: Replace `activeNotebooksProvider`/`archivedNotebooksProvider` with `notebookSummariesProvider` (family `bool`, sorted by `notebookSortProvider`). Add `notebookProvider` and `trashedNotebooksProvider`.
**Where**: `app/lib/features/notebooks/data/notebook_providers.dart`
**Depends on**: T4, T5, T7
**Reuses**: M02 provider style, `retry: (_, _) => null`
**Requirement**: NBLIST-07, SORT-02, SORT-03

**Tools**:

- MCP: `context7` (Riverpod 3 family stream providers)
- Skill: NONE

**Done when**:

- [x] `ProviderContainer.test` tests cover:
  - order follows the notifier and changes when it changes
  - `notebookProvider` emits `null` after trashing
  - errors surface as `AsyncError`
- [x] Quick gate passes (≥ 4 new tests; replaced provider tests listed in the commit body)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): providers de resumo, caderno e lixeira`

---

#### T9: Page providers

**What**: Add `pageProvider` (family `String`) and `trashedPagesProvider`.
**Where**: `app/lib/features/pages/data/page_providers.dart`
**Depends on**: T6
**Reuses**: `pagesProvider` style
**Requirement**: EDGE-03, TRASH-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests cover: both providers emit the repository streams; `pageProvider` emits `null` after trashing
- [x] Quick gate passes (≥ 2 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): providers de página e de páginas na lixeira`

---

### Phase 3: Design system

Each task adds its row to the component table in `app/.claude/docs/design.md` in the same commit (DOC-02).

#### T10: New icon glyphs

**What**: Add `edit`, `cover`, `archive`, `unarchive`, `check`, `page` and `notebook` to `JotIconGlyph`, painting the canvas SVG paths (24 grid, round caps).
**Where**: `app/lib/core/design_system/icons/jot_icon.dart`
**Depends on**: None
**Reuses**: existing glyph painter
**Requirement**: NBOPT-01, PGOPT-01, SORT-01, NBLIST-05, PGLIST-03

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget test renders each new glyph at 22 px without exceptions and inherits the text color
- [x] Quick gate passes (≥ 7 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): ícones de editar, capa, arquivar, desarquivar, check, página e caderno`

---

#### T11: Text field limit, counter, placeholder and help

**What**: Extend `JotTextField` with `maxLength`, `counterFrom`, `hintText`, `helperText`, `autofocus` and `focusNode`. The counter "N/50" sits right of the label, in `danger` at the limit; the built-in counter is hidden.
**Where**: `app/lib/core/design_system/jot_text_field.dart`
**Depends on**: None
**Reuses**: `maxTitleLength` from `title_rules.dart`
**Requirement**: NBNEW-04, NBNEW-05, NBOPT-05, PAGE-05, EDGE-07

**Tools**:

- MCP: `context7` (Flutter `TextField.maxLength`, `MaxLengthEnforcement`)
- Skill: NONE

**Done when**:

- [x] Widget tests cover:
  - the counter is hidden at 39 and shown at 40
  - 50 accepted, the 51st character blocked
  - 50 `👍🏽` clusters accepted (EDGE-07)
  - hint and helper shown
  - danger color at 50
- [x] Existing `jot_text_field_test.dart` tests unchanged and green
- [x] Quick gate passes (≥ 6 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): campo de texto com limite, contador e ajuda`

---

#### T12: Undo toast

**What**: Create `JotUndoToast` with a 3 s timer, pause on pointer down and restart on pointer up or cancel, a "Desfazer" button and live-region semantics.
**Where**: `app/lib/core/design_system/jot_undo_toast.dart`
**Depends on**: None
**Reuses**: canvas toast tokens (`ink1`, `bgPapel`, `accentTraco`, `JotShadows`)
**Requirement**: TOAST-01, TOAST-02, TOAST-03, TOAST-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget tests cover:
  - `onTimeout` fires after exactly 3 s and not at 2.9 s
  - holding 5 s, then releasing, fires 3 s after release
  - tapping "Desfazer" calls `onUndo` and never `onTimeout`
  - dispose cancels the timer
  - semantics live region
- [x] Quick gate passes (≥ 5 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): aviso de desfazer com pausa ao segurar`

---

#### T13: Options sheet

**What**: Create `JotOptionsSheet`, `JotOptionRow<T>` (icon, label, subtitle, destructive, checked) and `showJotOptionsSheet<T>`.
**Where**: `app/lib/core/design_system/jot_options_sheet.dart`
**Depends on**: T10
**Reuses**: `JotBottomSheet` barrier and handle
**Requirement**: NBOPT-01, NBOPT-02, PGOPT-01, SORT-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests cover:
  - grouped rows render in white cards
  - a destructive row uses `danger`
  - a `checked` row shows the check glyph and selected semantics
  - tapping a row resolves the future with its value
  - tapping the barrier resolves `null`
- [ ] Quick gate passes (≥ 5 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): bottom sheet de opções`

---

#### T14: Text input dialog

**What**: Create `JotTextInputDialog` and `showTextInputDialog` (title, label, initial value, hint, helper, `allowEmpty`, limit 50 with counter from 40).
**Where**: `app/lib/core/design_system/jot_text_input_dialog.dart`
**Depends on**: T11
**Reuses**: `ConfirmDialog` frame; `JotTextField` from T11
**Requirement**: NBOPT-03, NBOPT-04, NBOPT-05, PGOPT-02, PGOPT-03

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests cover:
  - field prefilled
  - "Salvar" disabled on blank text when `!allowEmpty`, enabled when `allowEmpty`
  - "Salvar" returns the text
  - "Cancelar" returns `null`
- [ ] Quick gate passes (≥ 5 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): diálogo de texto para renomear`

---

#### T15: Badge

**What**: Create `JotBadge` ("Arquivado" style from the canvas).
**Where**: `app/lib/core/design_system/jot_badge.dart`
**Depends on**: None
**Reuses**: theme tokens
**Requirement**: PGLIST-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget test checks the text, background `bgTrilho` and text color `inkCorpo`
- [ ] Quick gate passes (≥ 1 new test)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): selo de estado`

---

#### T16: Muted page row title

**What**: Add a `muted` flag to `PageRow` for "Sem título" (weight 500, `inkFeito`), per "Páginas sem trecho, M03".
**Where**: `app/lib/core/design_system/page_row.dart`
**Depends on**: None
**Reuses**: `PageRow`
**Requirement**: PGLIST-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests: muted style when `muted`, default style otherwise, no excerpt line when `excerpt` is null
- [ ] Quick gate passes (≥ 2 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): linha de página sem título`

---

### Phase 4: Page and notebook screens

#### T17: Page options sheet

**What**: Create `showPageOptionsSheet(context, page, notebook)`, resolving to `PageAction.rename` / `PageAction.delete`. It has the header (title or "Sem título", color chip, notebook title, "editada …"), "Renomear", and "Excluir página" with its subtitle.
**Where**: `app/lib/features/pages/presentation/page_options_sheet.dart`
**Depends on**: None in phase (T1, T13 earlier)
**Reuses**: `showJotOptionsSheet`, `RelativeDates`
**Requirement**: PGOPT-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests: header content with a fixed clock; each row returns its action
- [ ] Quick gate passes (≥ 3 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): opções da página`

---

#### T18: Minimal page screen

**What**: Create `PageScreen` and `PageOutcome`:
- back label from the notebook
- inline title with limit and counter, saved on a 500 ms debounce, flushed on pop and on hide/pause
- the "Editada …" line
- options: rename via `showTextInputDialog(allowEmpty: true)`; delete flushes, trashes and pops `PageOutcome.trashed`
- pops when the page becomes `null`
- no blocks
**Where**: `app/lib/features/pages/presentation/page_screen.dart`
**Depends on**: T17
**Reuses**: `pageProvider`, `notebookProvider`, `PageRepository.rename` / `moveToTrash`, `JotTopBar.back`
**Requirement**: PAGE-01…PAGE-07, PGOPT-02, PGOPT-03, PGOPT-04, EDGE-02, EDGE-03

**Tools**:

- MCP: `context7` (Flutter `PopScope.onPopInvokedWithResult`, `AppLifecycleListener`)
- Skill: NONE

**Done when**:

- [ ] Widget tests with an in-memory DB and `FakeClock` cover:
  - type and pump 499 ms → no write; pump to 500 ms → row updated (PAGE-03)
  - type and pop at once → row has the text (PAGE-04)
  - lifecycle `hidden` flushes (PAGE-04)
  - spaces trimmed (EDGE-02)
  - the "Editada" line updates after save (PAGE-06)
  - no block widgets (PAGE-02)
  - rename dialog saves an empty title (PGOPT-03)
  - delete pops with `PageOutcome.trashed` and sets `deleted_at` (PGOPT-04)
  - trashing from outside pops the screen (EDGE-03)
- [ ] Quick gate passes (≥ 10 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): página mínima com título e opções (RF-02)`

---

#### T19: Reorderable page list

**What**: Create `PageList`: rows (title or muted "Sem título", relative `updated_at`, no excerpt) and reorder mode. Reorder mode uses `ReorderableListView.builder` with `buildDefaultDragHandles: false`, a handle labeled "Mover …", a `DraggingPageRow` proxy and `onReorderItem` → `Placement` → `move`. It does nothing on a same-index drop and keeps an optimistic local order.
**Where**: `app/lib/features/pages/presentation/page_list.dart`
**Depends on**: None in phase (T16 earlier)
**Reuses**: `PageRow`, `DraggingPageRow`, `PageRepository.move`
**Requirement**: PGLIST-02, PGLIST-06, REORDER-01…REORDER-06

**Tools**:

- MCP: `context7` (Flutter `ReorderableListView.builder`, `onReorderItem`, `ReorderableDragStartListener`)
- Skill: NONE

**Done when**:

- [ ] Widget tests with an in-memory DB cover:
  - handles only in reorder mode
  - dragging the last of three to the top changes only that row's `position` (REORDER-03)
  - drop in place writes nothing (REORDER-04)
  - new order after rebuild from the DB (REORDER-06)
  - "Sem título" for an empty title (PGLIST-02)
  - tap calls `onOpen` (PGLIST-06)
- [ ] Quick gate passes (≥ 6 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): lista de páginas reordenável (RF-02)`

---

#### T20: Notebook options sheet

**What**: Create `showNotebookOptionsSheet(context, summary)` resolving to `NotebookAction` (`rename`, `cover`, `archive`/`unarchive`, `delete`). The header shows the mini cover, the title and "<count> · criado …" or "· arquivado …".
**Where**: `app/lib/features/notebooks/presentation/notebook_options_sheet.dart`
**Depends on**: None in phase (T1, T13 earlier)
**Reuses**: `showJotOptionsSheet`, `NotebookCover`, `RelativeDates`
**Requirement**: NBOPT-01, NBOPT-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests cover:
  - an active notebook shows "Arquivar" and its subtitle
  - an archived notebook shows "Desarquivar" and the "arquivado" meta
  - each row returns its action
- [ ] Quick gate passes (≥ 4 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): opções do caderno (RF-01)`

---

#### T21: Notebook form sheet

**What**: Create `showNewNotebookSheet` and `showCoverSheet`.
- **New:** "Novo caderno" with name (hint, limit, counter), defaults `azulTinta` + `lisa`, a live preview, and "Criar caderno" disabled on a blank name; it creates through the repository and returns the id.
- **Cover:** "Capa e cor" without the name field, current values selected, "Salvar" → `update`.
**Where**: `app/lib/features/notebooks/presentation/notebook_form_sheet.dart`
**Depends on**: None in phase (T11 earlier)
**Reuses**: `showJotBottomSheet`, `NotebookColorPicker`, `NotebookCoverPicker`, `NotebookCover`
**Requirement**: NBNEW-01…NBNEW-07, NBOPT-07, NBOPT-08, NBOPT-09

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests with an in-memory DB cover:
  - defaults (NBNEW-01)
  - the preview follows input (NBNEW-02)
  - disabled on spaces (NBNEW-03)
  - create → one notebook + one owner row with the trimmed name (NBNEW-06)
  - "Cancelar" writes nothing (NBNEW-07, NBOPT-09)
  - cover sheet preselects the current values and saves `musgo` + `quadriculada` (NBOPT-07, NBOPT-08)
- [ ] Quick gate passes (≥ 7 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): sheet de novo caderno e de capa e cor (RF-01)`

---

#### T22: Notebook screen

**What**: Create `NotebookScreen` and `NotebookOutcome`:
- writes `lastOpenedNotebookId` on open
- header: cover, title, count, "Arquivado" badge
- "Reordenar"/"Concluir", the empty state, and "Nova página" (create, then push `PageScreen` with the title focused)
- options actions: rename dialog; cover sheet; archive/unarchive, which pops the outcome; delete, which confirms, trashes and pops `trashed`
- an undo toast for `PageOutcome.trashed` with `restore`
- pops when the notebook becomes `null`
**Where**: `app/lib/features/notebooks/presentation/notebook_screen.dart`
**Depends on**: T18, T19, T20, T21
**Reuses**: `PageList`, `PageScreen`, `JotUndoToast`, `JotBadge`, `EmptyState`, `showConfirmDialog`, `showTextInputDialog`
**Requirement**: PGLIST-01, PGLIST-03, PGLIST-04, PGLIST-05, PGLIST-07, PGLIST-08, NBOPT-03, NBOPT-04, NBOPT-06, ARCH-01, ARCH-05, NBDEL-01, NBDEL-02, NBDEL-03, NBDEL-05, PGOPT-04, PGOPT-05, TOAST-05, TOAST-06, EDGE-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests with an in-memory DB, `FakeClock` and a recording preferences fake cover:
  - `lastOpenedNotebookId` written (PGLIST-07)
  - empty state, "nenhuma página" and "Reordenar" hidden (PGLIST-03)
  - badge on an archived notebook (PGLIST-04)
  - "Nova página" creates at the end and opens the page with the title focused (PGLIST-05)
  - pages can be created in an archived notebook (ARCH-05)
  - rename saves and the header updates (NBOPT-06)
  - archive pops `Archived` with the previous value (ARCH-01)
  - the delete dialog copy (NBDEL-01)
  - "Mover para a lixeira" sets only `notebooks.deleted_at` and pops `Trashed` (NBDEL-02, NBDEL-05)
  - "Cancelar" writes nothing (NBDEL-03)
  - deleting a page from `PageScreen` shows "Página movida para a lixeira", and "Desfazer" restores it in place (PGOPT-04, PGOPT-05)
  - a second toast replaces the first without undoing it (TOAST-05)
  - leaving the screen dismisses the toast without undo (TOAST-06)
- [ ] Quick gate passes (≥ 13 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): tela do caderno com páginas, opções e desfazer (RF-01, RF-02, RF-12)`

---

### Phase 5: Top-level screens

#### T23: Trash screen

**What**: Create `TrashScreen`:
- "Cadernos" section (mini cover rows, "<count> · excluído …", "Restaurar")
- "Páginas" section (title or "Sem título", color chip, notebook title, date, "Restaurar")
- the empty state
- restore toasts ("Caderno restaurado", "Restaurado em <caderno>"), whose undo calls `putBackInTrash` with the original date
**Where**: `app/lib/features/trash/presentation/trash_screen.dart`
**Depends on**: None in phase (T8, T9, T12 earlier)
**Reuses**: `ArchivedNotebookRow`, `JotButton.pill`, `EmptyState`, `JotUndoToast`, `RelativeDates`
**Requirement**: TRASH-01…TRASH-12, EDGE-04, EDGE-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests with an in-memory DB cover:
  - header copy (TRASH-01)
  - notebook row and count (TRASH-02, TRASH-03)
  - pages of a trashed notebook hidden, then shown after restoring it (TRASH-05, TRASH-10)
  - empty state copy (TRASH-06)
  - restoring a notebook returns it to its list, archived included (TRASH-07, EDGE-04)
  - "Restaurado em …" toast (TRASH-08)
  - undo puts back the original `deleted_at` (TRASH-09)
  - order (TRASH-11)
  - no "empty trash" action (TRASH-12)
- [ ] Quick gate passes (≥ 10 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): lixeira local com restauração e desfazer (RF-12)`

---

#### T24: Notebook sort sheet

**What**: Create `showNotebookSortSheet(context, current)`: "Ordenar por", the three `checked` rows and the note text. Picking a row calls `notebookSortProvider.select` and closes the sheet.
**Where**: `app/lib/features/notebooks/presentation/notebook_sort_sheet.dart`
**Depends on**: None in phase (T7, T13 earlier)
**Reuses**: `showJotOptionsSheet`
**Requirement**: SORT-01, SORT-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests: the current option is checked; picking "Nome (A–Z)" updates the provider and closes the sheet; the note text is shown
- [ ] Quick gate passes (≥ 3 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): ordenação dos cadernos (RF-01)`

---

#### T25: Notebooks screen and app home

**What**: Create `NotebooksScreen` and set it as `JotlineApp.home`:
- header "Cadernos" with "Ordenar" (hidden with no notebooks) and "Lixeira", and no "Buscar"
- tabs with counts
- grid of tiles with the meta, and archived rows with the meta and "Desarquivar"
- both empty states and the "Novo caderno" FAB
- outcome handling with toasts: archived, unarchived, trashed, each with undo
**Where**: `app/lib/features/notebooks/presentation/notebooks_screen.dart`
**Depends on**: T23, T24
**Reuses**: `NotebookCoverTile`, `ArchivedNotebookRow`, `JotSegmentedControl`, `JotTopBar.root`, `JotFab`, `EmptyState`, `JotUndoToast`, `NotebookScreen`, `TrashScreen`, `showNewNotebookSheet`
**Requirement**: NBLIST-01…NBLIST-10, ARCH-01, ARCH-02, ARCH-03, NBDEL-02, NBDEL-04, SORT-02, SORT-06, TOAST-05, TOAST-06

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Widget tests with an in-memory DB cover:
  - first screen is "Cadernos" (NBLIST-01)
  - tab counts (NBLIST-02)
  - tile meta "3 páginas · hoje" (NBLIST-03)
  - archived explanation and meta (NBLIST-04)
  - both empty states, with tabs and "Ordenar" hidden (NBLIST-05, NBLIST-06)
  - a page added elsewhere updates the count (NBLIST-07)
  - tap opens the notebook (NBLIST-08)
  - trash button opens "Lixeira" (NBLIST-09)
  - no "Buscar" (NBLIST-10)
  - after archive: "Ativos" tab, toast, and undo restores (ARCH-01, ARCH-03)
  - "Desarquivar" on a row: toast, and undo re-archives with the original date (ARCH-02, ARCH-03)
  - after delete: toast, and undo restores (NBDEL-02, NBDEL-04)
  - a stored sort applied on start (SORT-06)
- [ ] `test/app_test.dart` updated for the new home
- [ ] Quick gate passes (≥ 15 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): tela de cadernos com abas, ordenação e desfazer (RF-01, RF-04)`

---

### Phase 6: E2E, measurement and decisions

#### T26: Notebook flow e2e

**What**: Create `integration_test/notebooks_flow_test.dart` (create, rename, archive, delete a notebook, RF-01) and the shared helper `integration_test/helpers/no_network.dart`. The helper installs `HttpOverrides.global` with a client that throws on any call, and pumps `JotlineApp` with an in-memory DB and the unavailable preferences store.
**Where**: `app/integration_test/notebooks_flow_test.dart`
**Depends on**: None in phase (T25 earlier)
**Reuses**: `createTestDatabase` pattern
**Requirement**: E2E-01, E2E-02

**Tools**:

- MCP: `context7` (Flutter `integration_test`)
- Skill: NONE

**Done when**:

- [ ] Flow passes on an emulator
- [ ] A planted `HttpClient().getUrl(...)` in the app makes it fail, then reverted (E2E-02)
- [ ] Full gate passes

**Tests**: e2e
**Gate**: full
**Commit**: `test(app): fluxo e2e de cadernos sem rede (RF-01, RF-04)`

---

#### T27: Page flow e2e

**What**: Create `integration_test/pages_flow_test.dart`: create pages, rename one inline, reorder by dragging, reopen the notebook and check the order (RF-02).
**Where**: `app/integration_test/pages_flow_test.dart`
**Depends on**: T26
**Reuses**: `no_network.dart`
**Requirement**: E2E-01, E2E-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Flow passes on an emulator
- [ ] Full gate passes

**Tests**: e2e
**Gate**: full
**Commit**: `test(app): fluxo e2e de páginas sem rede (RF-02, RF-04)`

---

#### T28: Trash flow e2e

**What**: Create `integration_test/trash_flow_test.dart`: delete a page (undo once, then let it expire), delete the notebook, restore both from the trash (RF-12). Add the flow's row to the e2e table in `app/.claude/docs/testes.md`.
**Where**: `app/integration_test/trash_flow_test.dart`
**Depends on**: T27
**Reuses**: `no_network.dart`
**Requirement**: E2E-01, E2E-02, DOC-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Flow passes on an emulator
- [ ] `testes.md` lists the flow in the same commit
- [ ] Full gate passes

**Tests**: e2e
**Gate**: full
**Commit**: `test(app): fluxo e2e da lixeira sem rede (RF-12, RF-04)`

---

#### T29: ADR 0032 — undo toast

**What**: Record the 3 s toast, paused while held, and the actions that show it (delete page, delete notebook after the dialog, archive, unarchive, restore). It answers ADR 0024's open question without editing it.
**Where**: `docs/adr/0032-aviso-de-desfazer.md`
**Depends on**: None
**Reuses**: context.md "Undo toast"; ADR 0024
**Requirement**: ADR-01

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [ ] ADR file plus its index line in `docs/adr/README.md`
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0032 — aviso de desfazer de 3 s com pausa ao segurar`

---

#### T30: ADR 0033 — trash "Páginas" section

**What**: Record that the "Páginas" section lists only pages deleted on their own whose notebook is not in the trash, and that restoring a page never touches its notebook. It answers the open question of ADRs 0023 and 0027.
**Where**: `docs/adr/0033-secao-paginas-da-lixeira.md`
**Depends on**: None
**Reuses**: context.md "Trash"; ADR 0023, ADR 0027
**Requirement**: ADR-01

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [ ] ADR file plus its index line
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0033 — seção Páginas da lixeira`

---

#### T31: ADR 0034 — notebook sorting

**What**: Record the three sort options, the default "Editados recentemente" (latest page `updated_at`, else `created_at`), accent-insensitive names, and storage in `hive_ce` as a second key. This extends M01's PREF-05 and replaces the M02 fixed order.
**Where**: `docs/adr/0034-ordenacao-dos-cadernos.md`
**Depends on**: None
**Reuses**: spec assumptions; M02 spec "Notebook list order"
**Requirement**: ADR-01

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [ ] ADR file plus its index line
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0034 — ordenação dos cadernos`

---

#### T32: Launch-to-new-page measurement

**What**: Measure the time from the icon tap to the minimal page of a new page being open (cold start → "Cadernos" → notebook → "Nova página"). Use profile mode (`fvm flutter run --profile`) on a mid-range Android device. Record the device model and the median of 5 runs in `validation.md` and in the #21 PR description. If the median is 1 s or more, draft a follow-up issue for the user to open.
**Where**: `.specs/features/m03-notebooks-and-pages/validation.md`
**Depends on**: T26
**Reuses**: PRD §2 target
**Requirement**: PERF-01, PERF-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Measurement with device model and 5 runs recorded (needs the user's device; the agent prepares the profile build and the steps)
- [ ] Follow-up issue text drafted if ≥ 1 s

**Tests**: none
**Gate**: build
**Commit**: `docs(app): medição do tempo até a página nova (#21)`

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
```

Execution is strictly sequential: one task at a time, in order T1 … T32. 32 tasks pack into 5 batches of whole phases:

- Batch A: Phase 1 + Phase 2 (T1–T9, 9 tasks; Phase 1 is three small pure tasks)
- Batch B: Phase 3 (T10–T16)
- Batch C: Phase 4 (T17–T22)
- Batch D: Phase 5 (T23–T25)
- Batch E: Phase 6 (T26–T32; e2e needs an emulator, T32 needs the user's device)

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1 | one class + ARB keys it reads | ⚠️ Cohesive (the formatter has no words without its keys) |
| T2 | one interface + its two implementations + the two tests pinned to its keys | ⚠️ Cohesive (an interface change must update every implementer) |
| T3, T7, T9 | one file + its test | ✅ |
| T4 | one repository: new methods + removal of the two it replaces, with migrated tests | ⚠️ Cohesive (removing API and moving its tests is one change) |
| T5, T6, T8 | one file + its test | ✅ |
| T10–T16 | one widget + its test + its row in `design.md` | ✅ |
| T17, T19, T20, T21, T24 | one presentation file + its test | ✅ |
| T18, T22 | one screen + its typed outcome + its test | ⚠️ Cohesive (the outcome type exists only for that screen's pop) |
| T23, T25 | one screen + its test (T25 also flips `app.dart` home) | ⚠️ Cohesive |
| T26–T28 | one e2e flow (T26 also the shared helper, T28 also the doc row) | ⚠️ Cohesive |
| T29–T31 | one ADR + index line | ✅ |
| T32 | one measurement record | ✅ |

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1, T2, T3 | None | — | ✅ |
| T4 | None in phase (T3 earlier) | — | ✅ |
| T5 | T4 | T4 → T5 | ✅ |
| T6 | None in phase | — | ✅ |
| T7 | None in phase (T2, T3 earlier) | — | ✅ |
| T8 | T4, T5, T7 | T4 → T8, T5 → T8, T7 → T8 | ✅ |
| T9 | T6 | T6 → T9 | ✅ |
| T10, T11, T12, T15, T16 | None | — | ✅ |
| T13 | T10 | T10 → T13 | ✅ |
| T14 | T11 | T11 → T14 | ✅ |
| T17 | None in phase (T1, T13 earlier) | — | ✅ |
| T18 | T17 | T17 → T18 | ✅ |
| T19, T20, T21 | None in phase | — | ✅ |
| T22 | T18, T19, T20, T21 | four arrows into T22 | ✅ |
| T23 | None in phase | — | ✅ |
| T24 | None in phase | — | ✅ |
| T25 | T23, T24 | T23 → T25, T24 → T25 | ✅ |
| T26 | None in phase (T25 earlier) | — | ✅ |
| T27 | T26 | T26 → T27 | ✅ |
| T28 | T27 | T27 → T28 | ✅ |
| T29, T30, T31 | None | — | ✅ |
| T32 | T26 | T26 → T32 | ✅ |

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1, T3 | Pure logic | unit | unit | ✅ |
| T2 | Preferences | unit | unit | ✅ |
| T4, T5, T6 | Repositories | Drift | Drift | ✅ |
| T7, T8, T9 | Providers | unit | unit | ✅ |
| T10–T16 | Design system widgets | widget | widget | ✅ |
| T17–T25 | Screens and sheets | widget | widget | ✅ |
| T26–T28 | Main flows | e2e | e2e | ✅ |
| T29–T31 | ADRs | none | none | ✅ |
| T32 | Measurement record (no code) | none | none | ✅ |

## Requirement Coverage

| Requirement | Task(s) |
| --- | --- |
| NBLIST-01, NBLIST-02, NBLIST-05, NBLIST-06, NBLIST-08, NBLIST-09, NBLIST-10 | T25 |
| NBLIST-03, NBLIST-04, NBLIST-07 | T4, T8, T25 |
| NBNEW-01…NBNEW-03, NBNEW-06, NBNEW-07 | T21 |
| NBNEW-04, NBNEW-05 | T11, T21 |
| PGLIST-01, PGLIST-03, PGLIST-04, PGLIST-05, PGLIST-07, PGLIST-08 | T22 (PGLIST-04 also T15) |
| PGLIST-02 | T16, T19 |
| PGLIST-06 | T19 |
| REORDER-01…REORDER-06 | T19 |
| PAGE-01…PAGE-07 | T18 (PAGE-05 also T11) |
| NBOPT-01, NBOPT-02 | T13, T20 |
| NBOPT-03…NBOPT-06 | T14, T22 (NBOPT-05 also T11) |
| NBOPT-07, NBOPT-08 | T21 |
| NBOPT-09 | T21 |
| ARCH-01 | T22, T25 |
| ARCH-02, ARCH-03 | T4, T25 |
| ARCH-04 | T4 |
| ARCH-05 | T22 |
| SORT-01 | T13, T24 |
| SORT-02 | T2, T7, T8, T24, T25 |
| SORT-03…SORT-05 | T3, T8 |
| SORT-06, SORT-07 | T2, T7, T25 |
| NBDEL-01, NBDEL-03 | T22 |
| NBDEL-02 | T22, T25 |
| NBDEL-04 | T4, T25 |
| NBDEL-05 | T4, T22 |
| PGOPT-01 | T13, T17 |
| PGOPT-02, PGOPT-03 | T14, T18 |
| PGOPT-04 | T18, T22 |
| PGOPT-05 | T6, T22 |
| TOAST-01…TOAST-04 | T12 |
| TOAST-05, TOAST-06 | T22, T25 |
| TRASH-01, TRASH-06, TRASH-07, TRASH-12 | T23 |
| TRASH-02, TRASH-03, TRASH-11 | T5, T23 |
| TRASH-04, TRASH-05, TRASH-08, TRASH-09, TRASH-10 | T6, T23 |
| DATE-01…DATE-04 | T1 |
| E2E-01, E2E-02 | T26, T27, T28 |
| PERF-01, PERF-02 | T32 |
| ADR-01 | T29, T30, T31 |
| DOC-01 | T28 |
| DOC-02 | T10–T16 |
| EDGE-01 | T4 |
| EDGE-02 | T18 |
| EDGE-03 | T6, T9, T18 |
| EDGE-04 | T22, T23 |
| EDGE-05 | T6, T23 |
| EDGE-06 | T2, T7 |
| EDGE-07 | T11 |

**Coverage:** 107 requirements, 107 mapped, 0 unmapped.
