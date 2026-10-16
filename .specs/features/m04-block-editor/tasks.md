# M04 Block Editor Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Spec**: `.specs/features/m04-block-editor/spec.md`
**Design**: `.specs/features/m04-block-editor/design.md`
**Status**: Draft

These project rules apply to every task:

- **Branch:** work happens on `milestone/m04-block-editor`, created from `main`, and merged back via PR. The ADRs written as tasks (T3, T7) go on the branch.
- **Already done before this file:** SPIKE-01…SPIKE-11 (ADR 0035, `fd0e811`), ADR 0035 of ADR-01, and DOC-03 (PRD §11 marked resolved in `fd0e811`).
- **Language:** code, file names and test descriptions in English. UI strings only in `app_pt.arb`, with English keys.
- **Comments:** none that explain code. `///` is allowed; ask before adding `// ignore:` or `TODO`.
- **Test names:** requirement code first, e.g. `testWidgets('SAVE-06: ...')`.
- **Layout:** values and copy from the canvas artboards listed in the spec's "Canvas references". Any value missing from the theme becomes a token first (lesson L-004); no literal color or font outside `lib/core/theme/` (THEME-09).
- **Editor boundary:** only `lib/features/blocks/presentation/editor/` imports `package:super_editor` (T1 enforces it).
- **Spike code:** ported from `spike/22-block-editor:spikes/m04-editor/super_editor/`, rewritten to the app's lints, Drift and `IdGenerator`; the spike branch is never merged (SPIKE-11).
- **Library APIs:** checked in Context7 (`/flutter-bounty-hunters/super_editor`, Drift, Riverpod) and in the `super_editor 0.3.0-dev.52` source at the versions in `pubspec.lock` before writing code.
- **Commits:** messages in Portuguese, Conventional Commits, scopes `app` / `docs`, no Claude co-authorship.

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec - confirm before Execute. Guidelines found:
> - `app/.claude/docs/testes.md`: real in-memory Drift, streams asserted, a widget test for every screen and component with logic, e2e per main flow
> - `docs/adr/0015-estrategia-de-testes-do-app.md`
> - `app/CLAUDE.md` ("all new code comes with a unit or widget test; anything touching Drift, with an in-memory database test; main flows, with e2e")
>
> Samples: `app/test/features/*/data/*_test.dart`, `app/test/features/pages/presentation/page_screen_test.dart`, `app/test/core/design_system/*_test.dart`, `app/test/core/theme/jot_text_styles_test.dart`, `app/test/app_test.dart` (lib scans), `app/integration_test/pages_flow_test.dart`.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Pure model (`block_content.dart`, `page_summary.dart`) | unit | 1:1 to SAVE-10 / BAR-06; every normalization branch; accents, flag emoji, empty text (EDGE-03, EDGE-07) | `app/test/features/*/data/*_test.dart` | `fvm flutter test test/features` |
| Repositories (`*_repository.dart`) | Drift (in-memory) with `FakeClock` + `SequentialIdGenerator` | Every SAVE / EDITED / EXCERPT AC the method serves; rollback; `version` and `pages` row unchanged; streams asserted to re-emit on block writes | `app/test/features/*/data/*_repository_test.dart` | `fvm flutter test test/features` |
| Providers (`*_providers.dart`) | unit (`ProviderContainer.test`) | New element type; errors surface as `AsyncError` | `app/test/features/*/data/*_providers_test.dart` | `fvm flutter test test/features` |
| Theme tokens and icons (`lib/core/theme/`, `icons/`) | unit / widget | Every new token's value from the canvas; every new glyph renders | `app/test/core/theme/*_test.dart`, `app/test/core/design_system/icons/*_test.dart` | `fvm flutter test test/core` |
| Design system widgets (`lib/core/design_system/`) | widget (`pumpJot`) | Every state the canvas draws and every AC the widget serves (sizes, active, semantics, absent button) | `app/test/core/design_system/*_test.dart` | `fvm flutter test test/core/design_system` |
| Editor layer (`lib/features/blocks/presentation/editor/`) | unit with a real `Editor` + widget with `SuperEditor`; `BlockSync` also with in-memory Drift | 1:1 to SAVE-01…SAVE-10, EDIT-02/03/07…11, CHECK-01…08, BAR-10/11; every `BlockSync` branch; rows asserted after each action | `app/test/features/blocks/presentation/editor/**/*_test.dart` | `fvm flutter test test/features/blocks` |
| Screens and sheets (`lib/features/*/presentation/`) | widget with in-memory database, `FakeClock` | Every AC of the screen's stories, happy + empty + edge cases; DB rows asserted after each action | `app/test/features/*/presentation/*_test.dart` | `fvm flutter test test/features` |
| Main flows and perf | e2e (`integration_test`), no network | E2E-01 end to end on an emulator; any HTTP attempt fails the run (E2E-02); perf test reaches the editor frame | `app/integration_test/**/*_test.dart` | `fvm flutter test integration_test -d <emulator>` |
| Build config, ADRs, `CLAUDE.md`, `.claude/docs`, measurement record | none | - (build gate only) | - | Build gate |

## Gate Check Commands

> Generated from codebase (`.github/workflows/app.yml`) - confirm before Execute. App commands run from `app/`.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | After tasks with unit, Drift or widget tests | `cd app && fvm flutter test` |
| Full | After tasks with e2e tests | `cd app && fvm flutter test && fvm flutter test integration_test -d <emulator>` |
| Build | After config/docs-only tasks and at the end of each phase | `cd app && fvm flutter pub get && fvm dart run build_runner build --delete-conflicting-outputs && fvm flutter analyze && fvm dart format --output=none --set-exit-if-changed $(git ls-files '*.dart') && fvm flutter test && fvm flutter build apk --debug` |

---

## Execution Plan

Phases run in order; tasks inside a phase run in order. Arrows are real dependencies inside the phase; dependencies on earlier phases are listed in each task.

### Phase 1: Dependency and data

```
T1
T2 → T4
T3
T5
T6
T7
```

### Phase 2: Lists and design system

```
T8
T9
T10 → T12
T11 → T12
```

### Phase 3: Editor layer

```
T13 → T14
T15 → T16
T16 → T17
T16 → T18
T16 → T19
```

### Phase 4: Page screen

```
T20 → T21
T20 → T22
T20 → T23
```

### Phase 5: E2E and measurement

```
T24
T25 → T26
```

---

## Task Breakdown

### Phase 1: Dependency and data

#### T1: super_editor dependency and import boundary

**What**: Add `super_editor: 0.3.0-dev.52` (exact) to `pubspec.yaml`, set `compileSdk = 36` in `android/app/build.gradle.kts` (ADR 0035), and add a lib scan to `test/app_test.dart` that fails when any file outside `lib/features/blocks/presentation/editor/` imports `package:super_editor` or its `super_*` companions.
**Where**: `app/pubspec.yaml`
**Depends on**: None
**Reuses**: `libSources()` (`test/helpers/lib_scan.dart`), existing scans in `test/app_test.dart`
**Requirement**: SPIKE-09 (library adopted as recorded), design "Import boundary"

**Tools**:

- MCP: `context7` (super_editor install)
- Skill: NONE

**Done when**:

- [x] `pubspec.lock` resolves `super_editor 0.3.0-dev.52`; debug APK builds
- [x] The scan fails on a scratch file that imports `package:super_editor` outside the editor folder (checked, then discarded) and passes on the tree
- [x] Build gate passes (≥ 1 new test, none removed)

**Tests**: unit
**Gate**: build
**Commit**: `build(app): adiciona super_editor 0.3.0-dev.52 e isola o import (ADR 0035)`
**Status**: ✅ Done

---

#### T2: Block content format and types

**What**: Create `BlockType` (four ids, unknown → `text`), `MarkType`, `Mark` and `BlockContent` (`fromJson`, `toJson`, `forType`), with marks normalized on read and write.
**Where**: `app/lib/features/blocks/data/block_content.dart`
**Depends on**: None
**Reuses**: spike `BlockContent` / `normalizeMarks`
**Requirement**: SAVE-10, BAR-06, EDGE-03, EDGE-07

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `test/features/blocks/data/block_content_test.dart` covers:
  - round trip with overlapping bold + italic, accents, a flag emoji and empty text
  - normalization: unsorted, overlapping, adjacent and empty ranges
  - `checked` written only when non-null; `forType` drops it off checklist and defaults it to `false` on checklist
  - unknown type id reads `text`; unknown mark type ignored
  - leading and trailing spaces kept (EDGE-07)
  - exact JSON shape from the design (no extra field, SAVE-10)
- [x] Quick gate passes (≥ 10 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): formato content_json e tipos de bloco (SAVE-10)`
**Status**: ✅ Done

---

#### T3: ADR 0036 — block model

**What**: Write ADR 0036 in Portuguese: one row per paragraph, heading, list item and checklist item; the four `type` ids; the `content_json` shape; UTF-16 offsets with exclusive end; unknown type read as text. Add it to `docs/adr/README.md`.
**Where**: `docs/adr/0036-modelo-de-blocos.md`
**Depends on**: None
**Reuses**: ADR 0005, ADR 0035, design "Data Models"
**Requirement**: ADR-01

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR has Context, Decision, Consequences and cites ADR 0005 and 0035; index line added
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0036, modelo de blocos (#23)`
**Status**: ✅ Done

---

#### T4: Block repository batch writes

**What**: Add `loadPage(pageId)`, the sealed `BlockChange` (`Insert`, `Update`, `Trash`, `Move`) and `applyChanges(pageId, changes)` in one transaction returning the new id per `Insert.key`. Remove `updateContent` and move its M02 tests to `Update`.
**Where**: `app/lib/features/blocks/data/block_repository.dart`
**Depends on**: T2
**Reuses**: `PositionAllocator`, `Placement` (`After`, `AtStart`), existing `create` / `move` / `moveToTrash` writes
**Requirement**: SAVE-01, SAVE-02, SAVE-04, SAVE-05, SAVE-06, SAVE-07, SAVE-09, EDIT-01, BAR-05

**Tools**:

- MCP: `context7` (Drift `transaction`)
- Skill: NONE

**Done when**:

- [x] `test/features/blocks/data/block_repository_test.dart` covers:
  - `loadPage` order (`position`, `id`) and deleted filter, same as `watchByPage`
  - a failing change rolls back the whole batch
  - an `After` pointing to an `Insert` of the same batch lands right after it, before the next sibling
  - `Update` writes `type` and `content_json`; same values write nothing
  - every write sets `updated_at = clock.now()` and `updated_by` = local user; `version` unchanged
  - `Trash` writes only `deleted_at`
  - the `pages` row is byte-identical after any batch (SAVE-05, REPO-17)
  - no physical `DELETE` (SAVE-09)
- [x] Removed `updateContent` tests replaced 1:1, listed in the commit body
- [x] Quick gate passes (≥ 9 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): gravação em lote de blocos numa transação (SAVE-02, SAVE-06)`
**Status**: ✅ Done

---

#### T5: Page summary queries and providers

**What**: Create `PageSummary` (`page`, `lastEditedAt`, `excerpt`) and change `watchByNotebook` / `watchOne` to one `customSelect` each with `readsFrom: {pages, blocks, notebooks}`. `pagesProvider` and `pageProvider` change element type; consumers (`PageList`, `PageScreen`, `PageOptionsSheet`) read `.page` with no visible change.
**Where**: `app/lib/features/pages/data/page_repository.dart`
**Depends on**: None
**Reuses**: design page summary SQL; `blocks_page_position` index
**Requirement**: EDITED-01, EDITED-04, EDITED-05, EXCERPT-01, EXCERPT-03, EXCERPT-04, EXCERPT-05, EDGE-05, EDGE-07

**Tools**:

- MCP: `context7` (Drift `customSelect`, `readsFrom`)
- Skill: NONE

**Done when**:

- [x] `test/features/pages/data/page_repository_test.dart` covers:
  - page edited yesterday + block saved today → today; `pages` row unchanged
  - a deleted block's `deleted_at` counts; a page with no blocks → `pages.updated_at`
  - excerpt skips a heading, an empty block, a whitespace-only block and a deleted block; trims the result
  - no qualifying block → `null`; every block deleted → `null` (EDGE-05)
  - order stays `position, id` after a block write (EDITED-05)
  - the stream re-emits on a block insert, update, move and trash
- [x] `page_providers_test.dart` updated to `PageSummary`
- [x] Existing page widget tests still pass unchanged
- [x] Quick gate passes (≥ 9 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): resumo da página com última edição e trecho (EDITED-01, EXCERPT-01)`
**Status**: ✅ Done

---

#### T6: Notebook last edited from blocks

**What**: Change `NotebookRepository._watchSummaries` to `LEFT OUTER JOIN blocks`, `COUNT(DISTINCT pages.id)` and `lastEditedAt` = max of pages and blocks dates, falling back to `created_at`.
**Where**: `app/lib/features/notebooks/data/notebook_repository.dart`
**Depends on**: None
**Reuses**: M03 summary query
**Requirement**: EDITED-01, EDITED-02, EDITED-03, EDITED-04

**Tools**:

- MCP: `context7` (Drift joins and aggregates)
- Skill: NONE

**Done when**:

- [x] Drift tests cover:
  - a notebook whose only change is a block write today sorts first under `lastEdited`
  - a block's `deleted_at` counts
  - blocks of a trashed page do not count
  - `pageCount` unchanged with many blocks per page
  - the stream re-emits on a block write
- [x] Quick gate passes (≥ 5 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): última edição do caderno inclui os blocos (EDITED-03)`
**Status**: ✅ Done

---

#### T7: ADR 0037 — page last edited derived from blocks

**What**: Write ADR 0037 in Portuguese: the last edited expression, no page write on a block write (REPO-17 kept), the notebook aggregate and the replacement of the M03 SORT-03 date. Add it to `docs/adr/README.md`.
**Where**: `docs/adr/0037-ultima-edicao-derivada-dos-blocos.md`
**Depends on**: None
**Reuses**: ADR 0030, ADR 0034, design "Data Models"
**Requirement**: ADR-01

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR has Context, Decision, Consequences; index line added
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0037, última edição da página derivada dos blocos (#24)`
**Status**: ✅ Done

---

### Phase 2: Lists and design system

#### T8: Page list date and excerpt

**What**: `PageList` feeds `PageRow` with `dates.day(summary.lastEditedAt)` and `excerpt: summary.excerpt`; the optimistic reorder copy works on `PageSummary`.
**Where**: `app/lib/features/pages/presentation/page_list.dart`
**Depends on**: None in phase (T5 earlier)
**Reuses**: `PageRow(excerpt:)`, `RelativeDates.day`
**Requirement**: EDITED-02, EDITED-04, EXCERPT-01, EXCERPT-02, EXCERPT-03, EXCERPT-04, EXCERPT-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `page_list_test.dart` covers:
  - heading "Manhã" then text "Belém cedo" → excerpt "Belém cedo"
  - only a heading → no excerpt line
  - a block saved today on a page from yesterday → row shows "hoje" without leaving the list
  - editing the first qualifying block updates the excerpt in place
  - excerpt is one line with ellipsis in `itemTrecho`
  - reorder still moves one row
- [x] Quick gate passes (≥ 6 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): trecho e data de edição nas linhas de página (EXCERPT-01, EDITED-02)`
**Status**: ✅ Done

---

#### T9: Page options sheet date

**What**: `PageOptionsSheet` shows `lastEditedAt` instead of `pages.updated_at`.
**Where**: `app/lib/features/pages/presentation/page_options_sheet.dart`
**Depends on**: None in phase (T5 earlier)
**Reuses**: `RelativeDates.withTime`
**Requirement**: EDITED-02, EDITED-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `page_options_sheet_test.dart`: a block saved after the page row → the sheet date is the block's
- [x] Quick gate passes (≥ 1 new test)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): data de edição da página nas opções vem dos blocos (EDITED-02)`
**Status**: ✅ Done

---

#### T10: Bar glyph text styles

**What**: Add `barNegrito` (UI 18/700) and `barItalico` (Literata 19 italic) to `JotTextStyles`, values from the canvas "Barra de blocos".
**Where**: `app/lib/core/theme/jot_text_styles.dart`
**Depends on**: None
**Reuses**: existing text style tokens
**Requirement**: BAR-01, THEME-09 (lesson L-004)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `jot_text_styles_test.dart` asserts family, size, weight and style of both tokens
- [x] Quick gate passes (≥ 2 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): estilos dos glifos B e I da barra de blocos`
**Status**: ✅ Done

---

#### T11: Text and list icon glyphs

**What**: Add `JotIconGlyph.text` (T) and `JotIconGlyph.list` (bullets) from the canvas bar SVGs.
**Where**: `app/lib/core/design_system/icons/jot_icon.dart`
**Depends on**: None
**Reuses**: existing glyph pattern (`heading`, `checklist`)
**Requirement**: BAR-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Icon test renders both glyphs at the bar size in the given color
- [x] Quick gate passes (≥ 2 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): ícones texto e lista`
**Status**: ✅ Done

---

#### T12: Block bar

**What**: Create `BlockBar` and `JotBlockBarButton` (`BlockBarType` mirrors `BlockType`), the l10n keys `blockTypeText`, `blockTypeHeading`, `blockTypeList`, `blockTypeChecklist`, `markBold`, `markItalic`, `blockBarLabel`, and the "Barra de blocos" row in `app/.claude/docs/design.md`.
**Where**: `app/lib/core/design_system/block_bar.dart`
**Depends on**: T10, T11
**Reuses**: `JotIcon`, `context.colors`, `JotRadius.rCampo`, `JotSpace`
**Requirement**: BAR-01, BAR-03, BAR-04, BAR-09, DOC-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] `test/core/design_system/block_bar_test.dart` covers:
  - six buttons, each 48 × 48 with its label, in canvas order
  - no "Desenho" button (BAR-03)
  - the active type button has `accentSoft` background, icon in `accentPress` and `toggled: true`; the others are inactive
  - bold / italic active state and `toggled`
  - each tap calls its callback with the right value
  - `bgMesa` background and `bgTrilho` top border
- [ ] `design.md` row added; no `super_editor` import (T1 scan)
- [ ] Quick gate passes (≥ 7 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): barra de blocos no design system (BAR-01, BAR-04)`

---

### Phase 3: Editor layer

#### T13: Block mapper

**What**: Create `BlockMapper` (`toDocument`, `toNode`, `fromNode`) from the spike.
**Where**: `app/lib/features/blocks/presentation/editor/block_mapper.dart`
**Depends on**: None in phase (T1, T2 earlier)
**Reuses**: spike `BlockMapper`
**Requirement**: SAVE-10, SAVE-11, EDIT-04, EDIT-05, EDGE-03

**Tools**:

- MCP: `context7` (super_editor `ParagraphNode`, `ListItemNode`, `TaskNode`, `AttributedText`)
- Skill: NONE

**Done when**:

- [ ] `block_mapper_test.dart` covers:
  - each of the four types round-trips with text, bold, italic and `checked`; loaded node id = block id
  - empty row list → one empty paragraph whose id is not a block id
  - inclusive span ↔ exclusive end at text edges
  - flag emoji with marks around it
  - list / task indent dropped; link attribution dropped; unknown node → text
- [ ] Quick gate passes (≥ 9 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): mapeamento entre linhas de bloco e nós do editor (SAVE-10)`

---

#### T14: Block sync

**What**: Create `BlockSync`: edit listener collecting touched node ids, one 500 ms page timer, `flush()` serialized on a `Future` chain, document-order `BlockChange` batch, LIS moves, error path that re-queues the batch.
**Where**: `app/lib/features/blocks/presentation/editor/block_sync.dart`
**Depends on**: T13
**Reuses**: spike `BlockSync` (LIS, `_previousPersisted`), `BlockRepository.applyChanges`
**Requirement**: SAVE-01, SAVE-02, SAVE-04, SAVE-05, SAVE-06, SAVE-07, SAVE-08, SAVE-09, SAVE-12, EDIT-05, BMOVE-02, BMOVE-03, EDGE-04

**Tools**:

- MCP: `context7` (super_editor `EditListener`, `DocumentChangeLog`, `NodeMovedEvent`)
- Skill: NONE

**Done when**:

- [ ] `block_sync_test.dart` (real `Editor`, in-memory Drift, fake timer) covers:
  - type in A, 499 ms → no write; 500 ms → only A updated (SAVE-02, SAVE-05)
  - every edit restarts the page timer; two blocks touched → one transaction
  - split → original id kept, new row after it before the next sibling (SAVE-06)
  - merge → upper updated, lower trashed (SAVE-07)
  - cross-block delete → first updated, others trashed (SAVE-08)
  - empty new block of each type → no row until its first character (EDIT-05)
  - all text deleted → row stays, empty (EDGE-04)
  - move → one `position` changed; same-place move → no write
  - flush during an in-flight flush → applied in order, new ids known
  - `applyChanges` failure → pending ids kept, next flush writes them
  - `flush()` with nothing pending writes nothing
- [ ] Quick gate passes (≥ 12 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): sincronização do editor com as linhas de bloco (SAVE-02, SAVE-08)`

---

#### T15: Plain paste command

**What**: Create `PlainPasteCommand`: split on `\r\n|\r|\n`, first line into the caret block, other lines as new paragraphs, no attributions, expanded selection deleted first.
**Where**: `app/lib/features/blocks/presentation/editor/plain_paste.dart`
**Depends on**: None in phase (T1 earlier)
**Reuses**: super_editor delete-selection request
**Requirement**: EDIT-11, SAVE-08

**Tools**:

- MCP: `context7` (super_editor `EditCommand`, `PasteEditorRequest`)
- Skill: NONE

**Done when**:

- [ ] `plain_paste_test.dart` covers:
  - three lines into "Ab|c" → "Ab1", "2", "3c" as paragraphs, no marks
  - `\r\n` and `\r` separators
  - pasted URL → plain text, no link attribution
  - paste over a cross-block selection deletes it first
- [ ] Quick gate passes (≥ 4 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): colar sem formatação no editor (EDIT-11)`

---

#### T16: Editor setup and stylesheet

**What**: Create `createBlockEditor` (reactions reduced to `UpdateComposerTextStylesReaction`, `PlainPasteCommand` ahead of the defaults, no Tab indent), `BlockEditor` sliver widget and `blockStylesheet` (paragraph, `header1`, gaps, list indent and bullet, bold, italic, caret) from theme tokens.
**Where**: `app/lib/features/blocks/presentation/editor/block_editor.dart`
**Depends on**: T15
**Reuses**: spike stylesheet; `context.textStyles` (`blocoTexto`, `blocoTitulo`), `context.colors`, `JotSpace`
**Requirement**: EDIT-03, EDIT-11, BAR-10, BAR-11, E2E-02

**Tools**:

- MCP: `context7` (super_editor `createDefaultDocumentEditor`, `Stylesheet`, `SuperEditor` sliver)
- Skill: NONE

**Done when**:

- [ ] `block_editor_test.dart` covers:
  - paragraph in `blocoTexto`, heading in `blocoTitulo` (EDIT-03)
  - bold → w600, italic → italic style (BAR-10)
  - list item 24 px indent with a bullet; consecutive list items 4 px apart (BAR-11)
  - "# " and "- " typed stay text
  - pasted URL creates no image node and makes no HTTP call (throwing `HttpOverrides`)
- [ ] No literal color or font (THEME-09 scan green)
- [ ] Quick gate passes (≥ 6 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): configuração e estilo do editor de blocos (EDIT-03, BAR-10)`

---

#### T17: Editing key rules

**What**: Make Enter and Backspace follow the spec: end of text/heading → new text; middle → split, same type; end of list/checklist → same type, unchecked; empty list/checklist → text; Backspace at start of list/checklist/heading → text; text → merge up; first block → nothing.
**Where**: `app/lib/features/blocks/presentation/editor/block_editor.dart` (modify)
**Depends on**: T16
**Reuses**: spike `editing_rules_test.dart`; super_editor default keyboard and IME actions
**Requirement**: EDIT-07, EDIT-08, EDIT-09, EDIT-10, CHECK-04, CHECK-05, CHECK-06, CHECK-07, EDGE-03

**Tools**:

- MCP: `context7` (super_editor keyboard actions, IME delta handling)
- Skill: NONE

**Done when**:

- [ ] `editing_rules_test.dart` (widget, through the IME path) covers one test per AC listed, plus a split next to a flag emoji (EDGE-03)
- [ ] Quick gate passes (≥ 10 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): regras de Enter e Backspace nos blocos (EDIT-07…EDIT-10, CHECK-04…CHECK-07)`

---

#### T18: In-edit block and drag handle glyph

**What**: Create `ActiveBlockBuilder`: in-edit box (`accentWash`, `rBloco`, 12 px bleed) inside `IgnorePointer` behind the text of the node with the selection, plus a static `BlockDragHandle` (`dragHandle` glyph in `inkDeco`, `Semantics(label: 'Mover bloco')`) at x = 0. Add the `moveBlock` l10n key.
**Where**: `app/lib/features/blocks/presentation/editor/components/active_block_builder.dart`
**Depends on**: T16
**Reuses**: spike `ActiveBlockBuilder`; `JotIcon`
**Requirement**: EDIT-02, BMOVE-01

**Tools**:

- MCP: `context7` (super_editor `ComponentBuilder`, view models)
- Skill: NONE

**Done when**:

- [ ] `active_block_builder_test.dart` covers:
  - only the block with the caret has the box, radius 10, 12 px past the text
  - a tap through the box places the caret
  - handle visible only on the block with the caret, label "Mover bloco"
- [ ] Quick gate passes (≥ 4 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): bloco em edição com alça de mover (EDIT-02, BMOVE-01)`

---

#### T19: Checklist item component

**What**: Create `ChecklistItemBuilder` + `ChecklistItemComponent` (44 px row, 22 × 22 checkbox drawn as design Q3, 12 gap, checked text in `inkFeito` with strikethrough, opaque tap on the checkbox), and the "Blocos do editor" row in `app/.claude/docs/design.md`, dropping the out-of-scope note.
**Where**: `app/lib/features/blocks/presentation/editor/components/checklist_item.dart`
**Depends on**: T16
**Reuses**: super_editor `TaskNode`, `ChangeTaskCompletionRequest`
**Requirement**: CHECK-01, CHECK-02, CHECK-03, CHECK-08, DOC-01

**Tools**:

- MCP: `context7` (super_editor task component)
- Skill: NONE

**Done when**:

- [ ] `checklist_item_test.dart` covers:
  - row ≥ 44 px, checkbox 22 × 22 with Q3 tokens (unchecked and checked)
  - tap on the checkbox toggles `isComplete` without moving the caret
  - checked text `inkFeito` + `lineThrough`
  - semantics expose the item text and checked state
- [ ] `design.md` row added, note dropped
- [ ] Quick gate passes (≥ 5 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): item de checklist no editor (CHECK-01…CHECK-03, CHECK-08)`

---

### Phase 4: Page screen

#### T20: Page screen hosts the editor

**What**: `PageScreen` becomes one `CustomScrollView` (header, title + "Editada" from `lastEditedAt`, `BlockEditor`, filler); loads blocks once with `loadPage`; owns `BlockSync`; `_flushAll()` on pop, before the options sheet, before trash, on `pageProvider` → `null`, and on `AppLifecycleListener` `onInactive` / `onHide` / `onPause`; fires a flush on dispose.
**Where**: `app/lib/features/pages/presentation/page_screen.dart`
**Depends on**: None in phase (T14, T16–T19 earlier)
**Reuses**: M03 500 ms title save pattern; `PopScope`
**Requirement**: EDIT-01, EDIT-12, EDITED-02, EDITED-04, SAVE-02, SAVE-03, SAVE-11, SAVE-12, SAVE-13, EDGE-01, EDGE-02, EDGE-06

**Tools**:

- MCP: `context7` (Flutter `AppLifecycleListener`, `SliverFillRemaining`)
- Skill: NONE

**Done when**:

- [ ] `page_screen_test.dart` covers:
  - stored blocks shown in `position, id` order with types, text, marks and `checked` (EDIT-01, SAVE-11)
  - M03 tests for title, "Editada" and options still pass (EDIT-12)
  - typing then 500 ms → row updated, page row unchanged; "Editada" updates on screen
  - typing then back → saved before pop; typing then `inactive` → saved at once (SAVE-03, SAVE-13)
  - page trashed while open → pending text saved, screen pops (EDGE-01); restore shows it (EDGE-06)
  - archived notebook page is editable (EDGE-02)
  - no frame awaits the write: a slow repository fake does not block pumping (SAVE-12)
- [ ] Quick gate passes (≥ 9 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): editor de blocos na tela da página com salvamento (SAVE-02, SAVE-03)`

---

#### T21: Empty page, tap below and title Enter

**What**: The filler sliver places the caret in an empty paragraph at the end (reused if the last node is one); Enter in the title moves the caret to the start of the first block.
**Where**: `app/lib/features/pages/presentation/page_screen.dart` (modify)
**Depends on**: T20
**Reuses**: `InsertNodeAtIndexRequest`, `ChangeSelectionRequest`
**Requirement**: EDIT-04, EDIT-05, EDIT-06, EDGE-05

**Tools**:

- MCP: `context7` (super_editor selection requests)
- Skill: NONE

**Done when**:

- [ ] `page_screen_test.dart` covers:
  - new page → no block rows, no placeholder; tap the body and type "Olá" → one text row
  - tap below the last block → caret in a new empty paragraph, no row until a character
  - tap below when the last block is already empty → no second empty block
  - Enter in the title → caret at the start of the first block; on an empty page, in the empty paragraph
  - every block deleted → empty state of EDIT-04 again (EDGE-05)
- [ ] Quick gate passes (≥ 5 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): página vazia e foco do título para o corpo (EDIT-04, EDIT-06)`

---

#### T22: Block bar on the page

**What**: Show `BlockBar` above the keyboard while the editor has focus and a selection; wire type changes (spike `setType` sequence), bold / italic on a range or for the next text, and the active states.
**Where**: `app/lib/features/pages/presentation/page_screen.dart` (modify)
**Depends on**: T20
**Reuses**: `BlockBar`; super_editor `ToggleTextAttributionsRequest`, composer preferences, conversion requests
**Requirement**: BAR-01, BAR-02, BAR-04, BAR-05, BAR-06, BAR-07, BAR-08, BAR-09

**Tools**:

- MCP: `context7` (super_editor attribution and conversion requests)
- Skill: NONE

**Done when**:

- [ ] `page_screen_test.dart` covers:
  - bar shown with the caret in a block; hidden with the title focused or no focus
  - type "Manhã", tap "Título" → same row id, `heading`, "Título" pressed
  - each type change keeps text, marks and id; checklist → text drops `checked`
  - select a word, "Negrito" → bold range in `content_json`, "Negrito" pressed
  - collapsed caret, "Itálico", type → new text italic
  - caret inside bold text → "Negrito" pressed
- [ ] Quick gate passes (≥ 8 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): barra de blocos na página com tipos e marcas (BAR-05, BAR-07)`

---

#### T23: Drag a block

**What**: Create `BlockDragController`: long press on the handle, overlay proxy with `shadow.erguido`, auto-scroll near edges, drop index from node rects, `MoveNodeRequest` on a new index and nothing on the same one. First step: check the handle wins the gesture arena against the editor's long-press selection; if it does not, apply the design fallback; if that fails, stop and ask.
**Where**: `app/lib/features/blocks/presentation/editor/block_drag_controller.dart`
**Depends on**: T20
**Reuses**: `BlockDragHandle` (T18), `DocumentLayout`, `MoveNodeRequest`, `BlockSync` LIS moves
**Requirement**: BMOVE-02, BMOVE-03, BMOVE-04

**Tools**:

- MCP: `context7` (Flutter `LongPressGestureRecognizer`, `OverlayEntry`; super_editor `DocumentLayout`)
- Skill: NONE

**Done when**:

- [ ] `block_drag_controller_test.dart` covers:
  - three blocks, drag the last to the top → only its `position` changed; reopen → new order
  - drop where it started → no write
  - proxy drawn with `shadow.erguido` while dragging
  - long press on the handle does not select a word
- [ ] Manual check on the emulator recorded in the commit body
- [ ] Quick gate passes (≥ 4 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): arrastar bloco pela alça (BMOVE-02…BMOVE-04)`

---

### Phase 5: E2E and measurement

#### T24: Editor flow e2e

**What**: Create `editor_flow_test.dart`: new page, title, heading, paragraph with bold and italic, list, checklist, tick an item, back, reopen, same content; throwing `HttpOverrides`. First step: check the M03 test text input against `SuperEditor`'s IME client (design risk). Update the `testes.md` e2e table (DOC-02).
**Where**: `app/integration_test/editor_flow_test.dart`
**Depends on**: None in phase (T21, T22 earlier)
**Reuses**: `integration_test/helpers/flows.dart`, `no_network.dart`
**Requirement**: E2E-01, E2E-02, DOC-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Flow passes on the emulator with no network; asserted steps type through the IME path
- [ ] `testes.md` RF-03 row kept and the "waits for the block editor ADR" sentence dropped
- [ ] Full gate passes (1 new e2e test)

**Tests**: e2e
**Gate**: full
**Commit**: `test(app): fluxo e2e do editor de blocos (RF-03, RF-04)`

---

#### T25: Launch-to-new-page perf test reaches the editor

**What**: The perf test stops at the first frame where `BlockEditor` is laid out and the title has focus.
**Where**: `app/integration_test/perf/launch_to_new_page_test.dart`
**Depends on**: None
**Reuses**: M03 perf driver
**Requirement**: PERF-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Test runs in profile on the emulator and reports the timeline up to the editor frame
- [ ] Full gate passes

**Tests**: e2e
**Gate**: full
**Commit**: `test(app): medição até o editor renderizado (PERF-01)`

---

#### T26: Launch-to-new-page measurement

**What**: Prepare the profile build and the steps; validate them with a subagent on the emulator; the user measures on the M03 mid-range Android device (median of 5). Record the device model and numbers in `validation.md` and the PR. If ≥ 1 s, draft the follow-up issue text.
**Where**: `.specs/features/m04-block-editor/validation.md`
**Depends on**: T25
**Reuses**: M03 T32 steps
**Requirement**: PERF-01, PERF-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [ ] Steps validated by a subagent run (emulator numbers are not the measurement)
- [ ] Device model and 5 runs recorded (needs the user's device)
- [ ] Follow-up issue text drafted if ≥ 1 s

**Tests**: none
**Gate**: build
**Commit**: `docs(app): medição do tempo até a página nova com o editor (PERF-01)`

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
```

Execution is strictly sequential: one task at a time, in order T1 … T26. 26 tasks pack into 4 batches of whole phases:

- Batch A: Phase 1 (T1–T7)
- Batch B: Phase 2 (T8–T12)
- Batch C: Phase 3 (T13–T19)
- Batch D: Phase 4 + Phase 5 (T20–T26; e2e needs an emulator, T26 needs the user's device)

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1 | dependency + build setting + the scan that guards it | ⚠️ Cohesive (the dependency is not adopted without its boundary) |
| T2, T13, T14, T15 | one file + its test | ✅ |
| T3, T7 | one ADR + index line | ✅ |
| T4 | one repository: new methods + removal of `updateContent`, with migrated tests | ⚠️ Cohesive (removing API and moving its tests is one change) |
| T5 | one repository + its two providers + `.page` reads in three consumers | ⚠️ Cohesive (a return type change must compile in every reader) |
| T6, T8, T9, T10, T11 | one file + its test | ✅ |
| T12 | one widget + its l10n keys + its `design.md` row | ⚠️ Cohesive (DOC-01: row in the widget's commit) |
| T16 | editor setup + its stylesheet | ⚠️ Cohesive (the stylesheet has no use outside the editor widget) |
| T17 | one behavior in one file | ✅ |
| T18 | one builder + its handle glyph + l10n key | ⚠️ Cohesive (the handle exists only inside the in-edit block) |
| T19 | one component + its `design.md` row | ⚠️ Cohesive (DOC-01) |
| T20, T21, T22 | one screen behavior each | ✅ |
| T23 | one controller + handle gesture | ⚠️ Cohesive |
| T24 | one e2e flow + its `testes.md` row | ⚠️ Cohesive (DOC-02) |
| T25 | one test file | ✅ |
| T26 | one measurement record | ✅ |

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1, T2, T3, T5, T6, T7 | None | — | ✅ |
| T4 | T2 | T2 → T4 | ✅ |
| T8, T9 | None in phase (T5 earlier) | — | ✅ |
| T10, T11 | None | — | ✅ |
| T12 | T10, T11 | T10 → T12, T11 → T12 | ✅ |
| T13 | None in phase (T1, T2 earlier) | — | ✅ |
| T14 | T13 | T13 → T14 | ✅ |
| T15 | None in phase (T1 earlier) | — | ✅ |
| T16 | T15 | T15 → T16 | ✅ |
| T17, T18, T19 | T16 | T16 → T17, T16 → T18, T16 → T19 | ✅ |
| T20 | None in phase (T14, T16–T19 earlier) | — | ✅ |
| T21, T22, T23 | T20 | T20 → T21, T20 → T22, T20 → T23 | ✅ |
| T24 | None in phase (T21, T22 earlier) | — | ✅ |
| T25 | None | — | ✅ |
| T26 | T25 | T25 → T26 | ✅ |

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1 | Build config + lib scan | none (scan is a unit test) | unit | ✅ |
| T2 | Pure model | unit | unit | ✅ |
| T3, T7 | ADRs | none | none | ✅ |
| T4, T5, T6 | Repositories (+ providers in T5) | Drift | Drift | ✅ |
| T8, T9 | Screens and sheets | widget | widget | ✅ |
| T10 | Theme tokens | unit | unit | ✅ |
| T11 | Icons | widget | widget | ✅ |
| T12 | Design system widget | widget | widget | ✅ |
| T13, T15 | Editor layer (no widget) | unit | unit | ✅ |
| T14 | Editor layer + Drift | Drift | Drift | ✅ |
| T16–T19, T23 | Editor layer widgets | widget | widget | ✅ |
| T20–T22 | Screen | widget | widget | ✅ |
| T24, T25 | Main flows and perf | e2e | e2e | ✅ |
| T26 | Measurement record (no code) | none | none | ✅ |

## Requirement Coverage

| Requirement | Task(s) |
| --- | --- |
| SPIKE-01…SPIKE-11 | Done (ADR 0035, `fd0e811`); T1 adopts the library |
| EDIT-01 | T4, T20 |
| EDIT-02 | T18 |
| EDIT-03 | T16 |
| EDIT-04, EDIT-05 | T13, T21 (EDIT-05 also T14) |
| EDIT-06 | T21 |
| EDIT-07…EDIT-10 | T17 |
| EDIT-11 | T15, T16 |
| EDIT-12 | T20 |
| BAR-01 | T10, T11, T12, T22 |
| BAR-02 | T22 |
| BAR-03 | T12 |
| BAR-04, BAR-09 | T12, T22 |
| BAR-05 | T4, T22 |
| BAR-06 | T2, T22 |
| BAR-07, BAR-08 | T22 |
| BAR-10, BAR-11 | T16 |
| CHECK-01…CHECK-03, CHECK-08 | T19 |
| CHECK-04…CHECK-07 | T17 |
| SAVE-01, SAVE-04…SAVE-07, SAVE-09 | T4, T14 |
| SAVE-02 | T4, T14, T20 |
| SAVE-03, SAVE-13 | T20 |
| SAVE-08 | T14, T15 |
| SAVE-10 | T2, T13 |
| SAVE-11 | T13, T20 |
| SAVE-12 | T14, T20 |
| EDITED-01 | T5, T6 |
| EDITED-02 | T6, T8, T9, T20 |
| EDITED-03 | T6 |
| EDITED-04 | T5, T6, T8, T9, T20 |
| EDITED-05 | T5 |
| EXCERPT-01, EXCERPT-03…EXCERPT-05 | T5, T8 |
| EXCERPT-02 | T8 |
| BMOVE-01 | T18 |
| BMOVE-02, BMOVE-03 | T14, T23 |
| BMOVE-04 | T23 |
| E2E-01 | T24 |
| E2E-02 | T16, T24 |
| PERF-01 | T25, T26 |
| PERF-02 | T26 |
| ADR-01 | ADR 0035 done; T3, T7 |
| DOC-01 | T12, T19 |
| DOC-02 | T24 |
| DOC-03 | Done (`fd0e811`) |
| EDGE-01, EDGE-02, EDGE-06 | T20 |
| EDGE-03 | T2, T13, T17 |
| EDGE-04 | T14 |
| EDGE-05 | T5, T21 |
| EDGE-07 | T2, T5 |

**Coverage:** 84 requirements, 84 mapped (12 already done before this file), 0 unmapped.
