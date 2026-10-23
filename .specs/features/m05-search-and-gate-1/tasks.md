# M05 Search and Gate 1 Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Spec**: `.specs/features/m05-search-and-gate-1/spec.md`
**Design**: `.specs/features/m05-search-and-gate-1/design.md`
**Status**: Draft

These project rules apply to every task:

- **Branch:** the work happens on `milestone/m05-search-and-gate-1`, created from `main` and merged back via PR. ADRs written as tasks go on the branch. The encryption spike (T36) lives on `spike/28-local-encryption` and is never merged (CRYPT-01).
- **Language:** code, file names and test descriptions are in English. UI strings live only in `app_pt.arb`, with English keys. ADRs and the gate review are in Portuguese.
- **Comments:** no comments that explain code. `///` is allowed. Ask before adding `// ignore:` or `TODO`.
- **Test names:** the requirement code comes first, e.g. `test('SRCH-04: ...')`.
- **Layout:** values and copy come from the artboards in the spec's "Canvas references" (canvas version `1792290140-31c0`). A value missing from the theme becomes a token first (L-004). No literal color or font outside `lib/core/theme/`.
- **Editor boundary:** only `lib/features/blocks/presentation/editor/` imports `package:super_editor`. `perfect_freehand` is imported only by `lib/features/blocks/presentation/drawing/`.
- **Library APIs:** check Context7 (Drift, Riverpod) and the pub cache sources at the `pubspec.lock` versions before writing code.
- **Missed RNF-06 target (LOAD-09, user decision):** the work stops after one index attempt. The user gets the values, the targets, the query plans and the friction, and decides the next step. No optimization loop.
- **Tasks that depend on the user** (a device, the 2-week internal use, #67): before handing the procedure over, a subagent runs it end to end on an emulator and checks it.
- **Commits:** messages in Portuguese, Conventional Commits, scopes `app` / `docs`, no Claude co-authorship.

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec - confirm before Execute. Guidelines found:
> - `app/.claude/docs/testes.md`: real in-memory Drift with streams asserted; a widget test for every screen and component with logic; e2e per main flow; `@Tags(['perf'])` for the 10k load
> - `docs/adr/0015-estrategia-de-testes-do-app.md`
> - `app/CLAUDE.md`
>
> Samples: `app/test/features/*/data/*_repository_test.dart`, `app/test/features/blocks/presentation/editor/block_sync_test.dart`, `app/test/core/design_system/*_test.dart`, `app/test/drift/app_database/migration_test.dart`, `app/integration_test/editor_flow_test.dart`, `app/integration_test/perf/launch_to_new_page_test.dart`, `.github/scripts/commit-msg_test.sh`.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Schema, triggers, migrations (`lib/core/database/`) | Drift (in-memory) + `SchemaVerifier` | Every trigger path; v2 → v3 with data surviving and indexed (SRCH-19); query plans (LOAD-07) | `app/test/core/database/*_test.dart`, `app/test/drift/**` | `fvm flutter test test/core test/drift` |
| Pure models and parsers (`match_query`, `search_excerpt`, `drawing_content`, `drawing_session`, `block_content`) | unit | 1:1 to their ACs; every branch; EDGE-01…04, EDGE-06, EDGE-07; boundary values (L-002) | `app/test/features/**/data/*_test.dart`, `app/test/features/blocks/presentation/drawing/*_test.dart` | `fvm flutter test test/features` |
| Repositories and checks (`search_repository`, `block_repository`, `integrity_check`, `integrity_log`) | Drift (in-memory) with `FakeClock` + `SequentialIdGenerator`; temp directory for files | Every AC served; streams asserted to re-emit; invariant failures with ids | `app/test/**/*_test.dart` | `fvm flutter test` |
| Providers | unit (`ProviderContainer.test`) | Family keys and auto-dispose; errors as `AsyncError` | `app/test/features/*/data/*_providers_test.dart` | `fvm flutter test test/features` |
| Icons and design system widgets (`lib/core/design_system/`) | widget (`pumpJot`) | Every new glyph renders; every new parameter and state | `app/test/core/design_system/**/*_test.dart` | `fvm flutter test test/core/design_system` |
| Editor layer (`lib/features/blocks/presentation/editor/`) | unit with a real `Editor` + widget with `SuperEditor`; `BlockSync` with in-memory Drift | Drawing round trip; insert/replace/delete rows asserted; `version` unchanged; Backspace never deletes a drawing | `app/test/features/blocks/presentation/editor/**/*_test.dart` | `fvm flutter test test/features/blocks` |
| Screens (`lib/features/*/presentation/`, `lib/app.dart`) | widget with in-memory database and `FakeClock` | Every AC of the story, happy + empty + edge; DB rows asserted after actions | `app/test/features/*/presentation/*_test.dart`, `app/test/app_test.dart` | `fvm flutter test test/features test/app_test.dart` |
| Main flows | e2e (`integration_test`), no network | Search flow (RF-05) and drawing within the editor flow | `app/integration_test/*_flow_test.dart` | `fvm flutter test integration_test -d <emulator>` |
| Perf and kill harness (`integration_test/perf/`, `integration_test/kill/`) | e2e on device/emulator; host `perf`-tagged test for the seed | Seed counts and invariants; each LOAD target reported; kill verify logic | `app/integration_test/perf/*`, `app/integration_test/kill/*`, `app/test/perf/*` | `fvm flutter drive … --profile`, `fvm flutter test --tags perf --run-skipped` |
| Shell scripts (`app/tool/*.sh`) | shell test (bash) | Exit code **and** printed message text (L-001) | `app/tool/*_test.sh` | `bash app/tool/kill_test_test.sh` |
| ADRs, gate review, `CLAUDE.md`, `.claude/docs`, measurement records | none | - (build gate only) | - | Build gate |

## Gate Check Commands

> Generated from codebase (`.github/workflows/app.yml`) - confirm before Execute. App commands run from `app/`.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | After tasks with unit, Drift or widget tests | `cd app && fvm flutter test` |
| Full | After tasks with e2e tests | `cd app && fvm flutter test && fvm flutter test integration_test -d <emulator>` |
| Build | After config/docs-only tasks and at the end of each phase | `cd app && fvm flutter pub get && fvm dart run build_runner build --delete-conflicting-outputs && fvm flutter analyze && fvm dart format --output=none --set-exit-if-changed $(git ls-files '*.dart') && fvm flutter test && fvm flutter build apk --debug` |

---

## Execution Plan

Phases run in order, and so do the tasks inside a phase. Arrows are real dependencies inside the phase; dependencies on earlier phases are listed in each task.

### Phase 1: Search index and query

```
T1 → T2
T3
T4
T5
T2 → T6
T6 → T7
```

### Phase 2: Search UI

```
T8
T9
T8 → T10
T10 → T11
T9 → T11
T11 → T12
T12 → T13
```

### Phase 3: Load (measure first)

```
T14
T15 → T16
T16 → T17
```

### Phase 4: Integrity and kill test

```
T18 → T19
T19 → T20
T19 → T21
T21 → T22
T22 → T23
```

### Phase 5: Drawing data and editor

```
T24
T25 → T26
T26 → T27
T25 → T28
T27 → T29
T28 → T30
T29 → T30
T30 → T31
```

### Phase 6: Drawing mode

```
T32 → T33
T33 → T34
T34 → T35
```

### Phase 7: Encryption, docs and Gate 1

```
T36
T37
T38 → T39
T39 → T40
```

---

## Task Breakdown

### Phase 1: Search index and query

#### T1: ADR 0038 — busca local

**What**: Write `docs/adr/0038-busca-local.md`, in Portuguese, with status Proposta. It covers one FTS5 row per page (`title`, `body`), `unicode61 remove_diacritics 2`, word-prefix `AND` matching, triggers on `pages`/`blocks`, deleted rows kept in the index, the rowid = `pages.rowid` rule (no `VACUUM` without a re-index), highlights loaded per visible row, the phase 2 caveat (PowerSync views and triggers) and the rejected alternatives (per block, `LIKE`). Add its row to `docs/adr/README.md`.
**Where**: `docs/adr/0038-busca-local.md`
**Depends on**: None
**Reuses**: ADR 0036 format; design "Tech Decisions"
**Requirement**: ADR-01

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR has Contexto, Decisão, Alternativas descartadas and Consequências, and cites SRCH-04, SRCH-08, SRCH-18 and RNF-06
- [x] `docs/adr/README.md` lists 0038
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0038 proposta, busca local com FTS5 (#26)`

---

#### T2: FTS5 index, triggers and schema v3

**What**:
- Add `sql: {dialect: sqlite, options: {modules: [json1, fts5]}}` to `build.yaml`.
- Create `lib/core/database/search.drift` with `page_search` and the five triggers from the design, and include it in `@DriftDatabase`.
- Bump `schemaVersion` to 3. Run `make-migrations`.
- Write `from2To3`: create the table and the triggers, then backfill every page in one `INSERT … SELECT`.
- Complete the generated migration test with v2 rows that become searchable in v3.
- Add `test/core/database/search_index_test.dart`: insert, update, soft delete and type change of blocks; drawing excluded; page rename; page with no blocks.

**Where**: `app/lib/core/database/search.drift`
**Depends on**: T1
**Reuses**: `from1To2` pattern; `app/.claude/docs/testes.md` "Migrations"
**Requirement**: SRCH-18, SRCH-19, DOC-01, SRCH-09 (drawing excluded from the body)

**Tools**:

- MCP: `context7` (Drift `.drift` files, FTS5, `make-migrations`)
- Skill: NONE

**Done when**:

- [x] `drift_schemas/app_database/drift_schema_v3.json` and `test/drift/…/schema_v3.dart` are generated and committed
- [x] Migration test: a v2 database with 2 pages and 3 blocks opens as v3, and `page_search` matches both pages by title and by block text
- [x] Trigger tests pass for every case listed
- [x] Quick gate passes (≥ 8 new tests, none removed)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): índice FTS5 das páginas e schema v3 (SRCH-18, SRCH-19)`

---

#### T3: Shared "last edited" SQL

**What**: Move the "last edited" expression from `PageRepository._summaries` to `lib/core/database/last_edited_sql.dart` (a `const String` fragment on alias `p`). `PageRepository` uses it with no behavior change.
**Where**: `app/lib/core/database/last_edited_sql.dart`
**Depends on**: None
**Reuses**: `app/lib/features/pages/data/page_repository.dart:166-175`
**Requirement**: SRCH-10 (one ordering for both)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Every existing EDITED-* test in `page_repository_test.dart` passes unchanged
- [x] Quick gate passes (test count unchanged)

**Tests**: Drift
**Gate**: quick
**Commit**: `refactor(app): extrai o SQL de última edição da página`

---

#### T4: MatchQuery

**What**: Add `SearchScope` and `MatchQuery.parse` / `expression(scope)` per the design (word split on non-`\p{L}\p{N}`, `"word"*`, `"` doubled, ` AND `, `{title}`/`{body}` filters).
**Where**: `app/lib/features/search/data/match_query.dart`
**Depends on**: None
**Reuses**: —
**Requirement**: SRCH-04, SRCH-05, SRCH-06, SRCH-07, SRCH-08, EDGE-01, EDGE-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests cover accents, case, several words, punctuation only (empty query), spaces only, `"`, `*`, `-`, `OR`, `NEAR` as words, emoji and each scope's exact expression string
- [x] Quick gate passes (≥ 12 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): monta a consulta FTS5 a partir do termo (SRCH-04, SRCH-05)`

---

#### T5: SearchExcerpt

**What**: Parse ``/`` markers into plain and marked spans for the title. Pick the first U+2029 segment with a marker as the excerpt, and cut it from up to 40 characters before the first marker, at word boundaries, with "…" only on a cut side.
**Where**: `app/lib/features/search/data/search_excerpt.dart`
**Depends on**: None
**Reuses**: —
**Requirement**: SRCH-13, SRCH-14, EDGE-03, EDGE-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests cover:
  - a match at the start, in the middle and at the end of a block;
  - a match exactly 40 characters in, and 41 characters in (L-002);
  - several marks;
  - a match in the second block only;
  - no marker, which gives a `null` excerpt;
  - "…" only on the cut side.
- [x] Quick gate passes (≥ 10 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): trecho e destaque dos resultados da busca (SRCH-13, SRCH-14)`

---

#### T6: SearchRepository

**What**: Add `watchHits(query, scope)` and `snippet(pageId, query, scope)` per the design. Joins: pages, notebooks, the local user's member row (archived included); filters out deleted pages and notebooks; orders by the T3 fragment `DESC`, then `id`. `readsFrom: {pages, blocks, notebooks, notebookMembers}`. The SQL is exposed through a `@visibleForTesting` getter for T14. Add the `SearchHit` and `SearchSnippet` models.
**Where**: `app/lib/features/search/data/search_repository.dart`
**Depends on**: T2
**Reuses**: `PageRepository` customSelect pattern; `LocalUserRepository`; `NotebookColor`
**Requirement**: SRCH-04…SRCH-10, SRCH-18, SRCH-20, SRCH-21

**Tools**:

- MCP: `context7` (Drift `customSelect`, `readsFrom`)
- Skill: NONE

**Done when**:

- [x] Tests with the spec's Independent Test data:
  - "bele" returns 3 pages in "last edited" order, and "Títulos" returns 1;
  - trashed pages, pages of trashed notebooks, deleted blocks and drawings are never returned;
  - archived pages are returned;
  - the stream re-emits after a block save and after a rename (SRCH-18, SRCH-20);
  - `snippet` returns the marked title and the excerpt.
- [x] Quick gate passes (≥ 10 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): repositório da busca local (RF-05, SRCH-09, SRCH-10)`

---

### Phase 2: Search UI

```
T8
T9
T8 → T10
T10 → T11
T9 → T11
T11 → T12
T12 → T13
```

### Phase 3: Load (measure first)

```
T14
T15 → T16
T16 → T17
```

### Phase 4: Integrity and kill test

```
T18 → T19
T19 → T20
T19 → T21
T21 → T22
T22 → T23
```

### Phase 5: Drawing data and editor

```
T24
T25 → T26
T26 → T27
T25 → T28
T27 → T29
T28 → T30
T29 → T30
T30 → T31
```

### Phase 6: Drawing mode

```
T32 → T33
T33 → T34
T34 → T35
```

### Phase 7: Encryption, docs and Gate 1

```
T36
T37
T38 → T39
T39 → T40
```

---

## Task Breakdown

### Phase 1: Search index and query

#### T1: ADR 0038 — busca local

**What**: Write `docs/adr/0038-busca-local.md`, in Portuguese, with status Proposta. It covers one FTS5 row per page (`title`, `body`), `unicode61 remove_diacritics 2`, word-prefix `AND` matching, triggers on `pages`/`blocks`, deleted rows kept in the index, the rowid = `pages.rowid` rule (no `VACUUM` without a re-index), highlights loaded per visible row, the phase 2 caveat (PowerSync views and triggers) and the rejected alternatives (per block, `LIKE`). Add its row to `docs/adr/README.md`.
**Where**: `docs/adr/0038-busca-local.md`
**Depends on**: None
**Reuses**: ADR 0036 format; design "Tech Decisions"
**Requirement**: ADR-01

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR has Contexto, Decisão, Alternativas descartadas and Consequências, and cites SRCH-04, SRCH-08, SRCH-18 and RNF-06
- [x] `docs/adr/README.md` lists 0038
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0038 proposta, busca local com FTS5 (#26)`

---

#### T2: FTS5 index, triggers and schema v3

**What**:
- Add `sql: {dialect: sqlite, options: {modules: [json1, fts5]}}` to `build.yaml`.
- Create `lib/core/database/search.drift` with `page_search` and the five triggers from the design, and include it in `@DriftDatabase`.
- Bump `schemaVersion` to 3. Run `make-migrations`.
- Write `from2To3`: create the table and the triggers, then backfill every page in one `INSERT … SELECT`.
- Complete the generated migration test with v2 rows that become searchable in v3.
- Add `test/core/database/search_index_test.dart`: insert, update, soft delete and type change of blocks; drawing excluded; page rename; page with no blocks.

**Where**: `app/lib/core/database/search.drift`
**Depends on**: T1
**Reuses**: `from1To2` pattern; `app/.claude/docs/testes.md` "Migrations"
**Requirement**: SRCH-18, SRCH-19, DOC-01, SRCH-09 (drawing excluded from the body)

**Tools**:

- MCP: `context7` (Drift `.drift` files, FTS5, `make-migrations`)
- Skill: NONE

**Done when**:

- [x] `drift_schemas/app_database/drift_schema_v3.json` and `test/drift/…/schema_v3.dart` are generated and committed
- [x] Migration test: a v2 database with 2 pages and 3 blocks opens as v3, and `page_search` matches both pages by title and by block text
- [x] Trigger tests pass for every case listed
- [x] Quick gate passes (≥ 8 new tests, none removed)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): índice FTS5 das páginas e schema v3 (SRCH-18, SRCH-19)`

---

#### T3: Shared "last edited" SQL

**What**: Move the "last edited" expression from `PageRepository._summaries` to `lib/core/database/last_edited_sql.dart` (a `const String` fragment on alias `p`). `PageRepository` uses it with no behavior change.
**Where**: `app/lib/core/database/last_edited_sql.dart`
**Depends on**: None
**Reuses**: `app/lib/features/pages/data/page_repository.dart:166-175`
**Requirement**: SRCH-10 (one ordering for both)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Every existing EDITED-* test in `page_repository_test.dart` passes unchanged
- [x] Quick gate passes (test count unchanged)

**Tests**: Drift
**Gate**: quick
**Commit**: `refactor(app): extrai o SQL de última edição da página`

---

#### T4: MatchQuery

**What**: Add `SearchScope` and `MatchQuery.parse` / `expression(scope)` per the design (word split on non-`\p{L}\p{N}`, `"word"*`, `"` doubled, ` AND `, `{title}`/`{body}` filters).
**Where**: `app/lib/features/search/data/match_query.dart`
**Depends on**: None
**Reuses**: —
**Requirement**: SRCH-04, SRCH-05, SRCH-06, SRCH-07, SRCH-08, EDGE-01, EDGE-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests cover accents, case, several words, punctuation only (empty query), spaces only, `"`, `*`, `-`, `OR`, `NEAR` as words, emoji and each scope's exact expression string
- [x] Quick gate passes (≥ 12 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): monta a consulta FTS5 a partir do termo (SRCH-04, SRCH-05)`

---

#### T5: SearchExcerpt

**What**: Parse ``/`` markers into plain and marked spans for the title. Pick the first U+2029 segment with a marker as the excerpt, and cut it from up to 40 characters before the first marker, at word boundaries, with "…" only on a cut side.
**Where**: `app/lib/features/search/data/search_excerpt.dart`
**Depends on**: None
**Reuses**: —
**Requirement**: SRCH-13, SRCH-14, EDGE-03, EDGE-04

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests cover:
  - a match at the start, in the middle and at the end of a block;
  - a match exactly 40 characters in, and 41 characters in (L-002);
  - several marks;
  - a match in the second block only;
  - no marker, which gives a `null` excerpt;
  - "…" only on the cut side.
- [x] Quick gate passes (≥ 10 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): trecho e destaque dos resultados da busca (SRCH-13, SRCH-14)`

---

#### T6: SearchRepository

**What**: Add `watchHits(query, scope)` and `snippet(pageId, query, scope)` per the design. Joins: pages, notebooks, the local user's member row (archived included); filters out deleted pages and notebooks; orders by the T3 fragment `DESC`, then `id`. `readsFrom: {pages, blocks, notebooks, notebookMembers}`. The SQL is exposed through a `@visibleForTesting` getter for T14. Add the `SearchHit` and `SearchSnippet` models.
**Where**: `app/lib/features/search/data/search_repository.dart`
**Depends on**: T2
**Reuses**: `PageRepository` customSelect pattern; `LocalUserRepository`; `NotebookColor`
**Requirement**: SRCH-04…SRCH-10, SRCH-18, SRCH-20, SRCH-21

**Tools**:

- MCP: `context7` (Drift `customSelect`, `readsFrom`)
- Skill: NONE

**Done when**:

- [x] Tests with the spec's Independent Test data:
  - "bele" returns 3 pages in "last edited" order, and "Títulos" returns 1;
  - trashed pages, pages of trashed notebooks, deleted blocks and drawings are never returned;
  - archived pages are returned;
  - the stream re-emits after a block save and after a rename (SRCH-18, SRCH-20);
  - `snippet` returns the marked title and the excerpt.
- [x] Quick gate passes (≥ 10 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): repositório da busca local (RF-05, SRCH-09, SRCH-10)`

---

#### T7: Search providers

**What**: Add a `searchRepositoryProvider`, a `searchHitsProvider` (`StreamProvider.family.autoDispose` keyed by `(MatchQuery, SearchScope)`) and a `searchSnippetProvider` (`FutureProvider.family.autoDispose` keyed by `(pageId, MatchQuery, SearchScope)`). `MatchQuery` gets value equality.
**Where**: `app/lib/features/search/data/search_providers.dart`
**Depends on**: T6
**Reuses**: `block_providers.dart`, `page_providers.dart` patterns
**Requirement**: SRCH-03, SRCH-20, EDGE-05

**Tools**:

- MCP: `context7` (Riverpod 3 family + autoDispose)
- Skill: NONE

**Done when**:

- [x] Tests:
  - same key → same provider;
  - auto-dispose after the last listener goes away;
  - a repository error surfaces as `AsyncError`;
  - an empty query emits an empty list with no SQL run.
- [x] Quick gate passes (≥ 4 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): providers da busca local (SRCH-03)`

---

### Phase 2: Search UI

#### T8: Canvas icons for search and drawing

**What**: Add `JotIconGlyph` values `searchNone`, `undo`, `redo`, `pen`, `highlighter` and `eraser`, with the paths traced from the "Busca — sem resultado" and "Modo desenho: tela cheia" SVGs.
**Where**: `app/lib/core/design_system/icons/jot_icon.dart`
**Depends on**: None
**Reuses**: existing glyph painter
**Requirement**: SRCH-15, DRAW-04, DRAW-08 (glyphs)

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] The icon test renders every new glyph at 22 px
- [x] Quick gate passes (≥ 6 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): ícones de busca vazia e do modo desenho`

---

#### T9: JotSearchField options

**What**: Add `autofocus`, `placeholder` and `semanticLabel` parameters, as the "Busca local" field needs ("Buscar em todos os cadernos", "Buscar em títulos e conteúdo").
**Where**: `app/lib/core/design_system/jot_search_field.dart`
**Depends on**: None
**Reuses**: current widget
**Requirement**: SRCH-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests: focused on first frame when `autofocus`; placeholder shown when empty; semantics label
- [x] Quick gate passes (≥ 3 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): campo de busca com foco e placeholder (SRCH-01)`

---

#### T10: SearchResultRow

**What**: Build the result card from "Busca local":
- notebook spine (10 × 14, notebook color), notebook title, "·", date with `RelativeDates.day`;
- title with marks in `accentBusca` and radius `rEtiqueta`; "Sem título" muted;
- optional excerpt in Literata 14, `maxLines: 2`, ellipsis.

It reads `searchSnippetProvider`, and shows the plain title while the snippet loads.
**Where**: `app/lib/features/search/presentation/search_result_row.dart`
**Depends on**: T8
**Reuses**: `PageRow` styles, `RelativeDates`, theme tokens; T5 spans; T7 provider
**Requirement**: SRCH-11, SRCH-12, SRCH-13, SRCH-14

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget tests:
  - spine color and date text;
  - marked words carry the `accentBusca` background;
  - "Sem título" is muted;
  - no excerpt line when the snippet has none;
  - the excerpt is limited to 2 lines.
- [x] Any missing text style becomes a token first (L-004)
- [x] Quick gate passes (≥ 6 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): linha de resultado da busca (SRCH-11, SRCH-14)`

---

#### T11: SearchScreen

**What**: Build the search screen from "Busca local":
- the field (T9), "Cancelar" and the Tudo/Títulos/Conteúdo segments;
- a 150 ms debounce on the trimmed term;
- the "sem termo" empty state, the count line ("1 página" / "N páginas", plural ARB) and the result list;
- the "sem resultado" state with the term quoted;
- tapping a row pushes `PageScreen`.

Add the l10n keys from the design.
**Where**: `app/lib/features/search/presentation/search_screen.dart`
**Depends on**: T10, T9
**Reuses**: `JotSegmentedControl`, `EmptyState`, `FakeClock`, `pumpJot`
**Requirement**: SRCH-01, SRCH-02, SRCH-03, SRCH-15, SRCH-16, SRCH-17, EDGE-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget tests with an in-memory database:
  - the empty state on open;
  - nothing at 149 ms and results at 150 ms;
  - "3 páginas";
  - switching the segment filters the results;
  - "Nenhuma página encontrada" with “passaporte”;
  - tap → `PageScreen`, then back → same term, segment and scroll offset;
  - "Cancelar" pops;
  - popping mid-query throws nothing.
- [x] Quick gate passes (≥ 9 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): tela de busca local (RF-05, SRCH-01, SRCH-15)`

---

#### T12: "Buscar" button on Cadernos

**What**: Add the "Buscar" `JotIconButton` as the first top-bar action of `NotebooksScreen`, always shown (also with no notebooks, as in the canvas), pushing `SearchScreen`.
**Where**: `app/lib/features/notebooks/presentation/notebooks_screen.dart`
**Depends on**: T11
**Reuses**: the trash button pattern
**Requirement**: SRCH-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget tests: the button is first, with label "Buscar", shown with zero notebooks, and tapping it opens the search screen with the field focused
- [x] Quick gate passes (≥ 2 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): botão Buscar na tela de cadernos (SRCH-01)`

---

#### T13: Search e2e flow

**What**: Add an e2e test, with no network:
1. Create two notebooks and archive one.
2. Write "Belém cedo" in a page and title another "Onde comer em Belém".
3. Search "bele" → 2 results.
4. Open one, go back → same results.
5. "Títulos" → 1 result.
6. Trash one page → 1 result.

**Where**: `app/integration_test/search_flow_test.dart`
**Depends on**: T12
**Reuses**: `integration_test/helpers/flows.dart`, `no_network.dart`
**Requirement**: SRCH-09, SRCH-16, SRCH-21, RF-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] The flow passes on an emulator; any HTTP attempt fails it
- [x] Full gate passes

**Tests**: e2e
**Gate**: full
**Commit**: `test(app): fluxo e2e da busca local (RF-05)`

---

### Phase 3: Load (measure first)

#### T14: Query plan test

**What**: Expose the SQL of the notebook summaries, page summaries, page block load, search hits and snippet through `@visibleForTesting` getters. Run `EXPLAIN QUERY PLAN` on each over a small seed, and fail on `SCAN pages` / `SCAN blocks` with no `USING INDEX`; FTS5 scans are allowed. **If a plan fails:** make one index attempt (a new `@TableIndex`, migration v3 → v4 with its test). If it still fails, stop and report to the user (LOAD-09).
**Where**: `app/test/core/database/query_plan_test.dart`
**Depends on**: None
**Reuses**: `createTestDatabase`
**Requirement**: LOAD-07, LOAD-09

**Tools**:

- MCP: `context7` (SQLite `EXPLAIN QUERY PLAN` via Drift `customSelect`)
- Skill: NONE

**Done when**:

- [x] 5 plan tests pass, or a report with the failing plan has been delivered to the user and the task is marked blocked
- [x] Quick gate passes

**Tests**: Drift
**Gate**: quick
**Commit**: `test(app): planos de consulta sem varredura de pages e blocks (LOAD-07)`

---

#### T15: 10,000-page seed

**What**: Add `seedLibrary(AppDatabase, {Random})`: 1 notebook × 10,000 pages + 20 notebooks × 100 pages, with owner members and 20 `text` blocks of ~200 characters per page (fixed pt-BR word list, "belém" once per page). It uses batched inserts in one transaction, with real `FractionalIndex` keys. Add the host test `test/perf/seed_library_test.dart` with `@Tags(['perf'])`, and declare the `perf` tag with `skip` in `dart_test.yaml`.
**Where**: `app/integration_test/perf/seed_library.dart`
**Depends on**: None
**Reuses**: `FractionalIndex`, `IdGenerator`; T19 `IntegrityCheck` is not available yet, so the test checks the invariants with direct queries
**Requirement**: LOAD-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `fvm flutter test --tags perf --run-skipped` passes:
  - exact counts of 21 notebooks, 12,000 pages and 240,000 blocks;
  - no duplicate positions;
  - `page_search` has 12,000 rows.
- [x] `fvm flutter test` (default) skips it
- [x] Quick gate passes

**Tests**: e2e
**Gate**: quick
**Commit**: `test(app): seed de 10 mil páginas (LOAD-01)`

---

#### T16: Large-library perf test

**What**: Seed a file database (T15) once, then measure in profile mode:
- LOAD-02, notebook list first data;
- LOAD-03, opening the 10,000-page notebook;
- LOAD-04, `traceAction` scroll over 2,000 rows and `average_frame_build_time_millis`;
- LOAD-05, opening a page;
- LOAD-06, "belém" results after the debounce.

Each value goes into `reportData`. `perf_driver.dart` takes the output file name from the report, and the PERF-01 command keeps working.
**Where**: `app/integration_test/perf/large_library_test.dart`
**Depends on**: T15
**Reuses**: `_pumpUntil` from `launch_to_new_page_test.dart`, `perf_driver.dart`
**Requirement**: LOAD-02…LOAD-06

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] A subagent runs it on an emulator in profile mode and it reports 5 values plus the frame build average (the emulator values are not the record)
- [x] The PERF-01 drive command still produces `launch_to_new_page`
- [x] Full gate passes

**SPEC_DEVIATION (LOAD-04 measurement):** the scroll is measured with `SchedulerBinding.addTimingsCallback` (`integration_test/perf/frame_stats.dart`) and `FrameTimingSummarizer`, not `binding.traceAction` and a timeline summary. Reason: `traceAction` and `watchPerformance` both open the VM service from the device, which wireless adb cannot reach (`Failed to connect to VM Service`). The key `average_frame_build_time_millis` is the same one the timeline summary uses and the 16 ms target is unchanged. Spec-precision gap: the spec names the metric through the timeline summary, and the two sources count frames differently. `perf_driver.dart` no longer needs `flutter_driver`.

**Tests**: e2e
**Gate**: full
**Commit**: `test(app): medição com 10 mil páginas no perfil (LOAD-02…LOAD-06)`

---

#### T17: Device measurement and decision point

**What**: The user runs T16 on the mid-range Android device. Record the device, Android version and every value against its target in `.specs/features/m05-search-and-gate-1/load-results.md`, which is copied into the PR (LOAD-08). **If any target is missed:** one index attempt, then re-measure. If it is still missed, stop. The user gets the values, the targets, the query plans and the friction, and decides (LOAD-09).
**Where**: `.specs/features/m05-search-and-gate-1/load-results.md`
**Depends on**: T16
**Reuses**: M04 PERF-01 record format
**Requirement**: LOAD-08, LOAD-09

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] The record has every target with value, device model and Android version
- [x] Either every target is met, or the friction report has been delivered and the user's decision is recorded in the file
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs(app): medição de desempenho com 10 mil páginas (RNF-06)`

---

### Phase 4: Integrity and kill test

#### T18: IntegrityLog

**What**: Add `package_info_plus`. `IntegrityLog.append(IntegrityReport, {required String appVersion, required DateTime at})` writes one line to `<support dir>/integrity.log` and creates the file when it is missing. It never throws; an error goes to `developer.log`.
**Where**: `app/lib/core/database/integrity_log.dart`
**Depends on**: None
**Reuses**: `path_provider`
**Requirement**: INTEG-06, EDGE-08

**Tools**:

- MCP: `context7` (`package_info_plus`)
- Skill: NONE

**Done when**:

- [x] Tests with a temp directory:
  - the exact line format for pass and for fail with ids;
  - the file is created when missing;
  - lines are appended, not replaced;
  - a write error does not throw.
- [x] Quick gate passes (≥ 4 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): log local da verificação de integridade (INTEG-06)`

---

#### T19: IntegrityCheck

**What**: Implement `run()`: `PRAGMA integrity_check`, plus the invariants `notebook_without_owner`, `orphan_page`, `orphan_block` and `duplicate_position` (pages and blocks, non-deleted only). Exceptions become `check_error`. It only reads, and it appends to `IntegrityLog`.
**Where**: `app/lib/core/database/integrity_check.dart`
**Depends on**: T18
**Reuses**: `createTestDatabase`; raw inserts with `PRAGMA foreign_keys = OFF` to build the broken states
**Requirement**: INTEG-02…INTEG-05, INTEG-07, INTEG-08

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests:
  - a clean database gives one `pass`;
  - each invariant fails alone, with its ids;
  - two failures in one line;
  - a deleted duplicate is not a failure;
  - a thrown error gives `check_error`;
  - no table changed (row counts and `max(updated_at)` equal).
- [x] Quick gate passes (≥ 8 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): verificação de integridade do banco local (INTEG-02…INTEG-05)`

---

#### T20: Run the check after the first frame

**What**: Add `integrityCheckProvider`. `JotlineApp` schedules `unawaited(check.run())` in one `addPostFrameCallback`.
**Where**: `app/lib/app.dart`
**Depends on**: T19
**Reuses**: providers pattern
**Requirement**: INTEG-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget tests: the first frame is built before `run()` starts (a fake check records the frame count); the check runs once per app start, not per rebuild
- [x] Quick gate passes (≥ 2 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): roda a verificação de integridade ao abrir (INTEG-01)`

---

#### T21: Kill test app

**What**: Add an entry point on the production database. On start it runs the verify step: the page's blocks must equal the last `ack` snapshot or the `pending` snapshot after it, and `IntegrityCheck` must pass. The result goes to `kill/results.jsonl`. Then it types seeded bursts through `PageEditor`, appending `pending` before and `ack` after each `flush()`. Pure verify logic lives in `integration_test/kill/kill_verify.dart`, with a host test.
**Where**: `app/integration_test/kill/kill_app.dart`
**Depends on**: T19
**Reuses**: `PageEditor`, `IntegrityCheck`, `BlockMapper`
**Requirement**: KILL-01, KILL-02, KILL-03

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Host tests for `kill_verify.dart`: DB equal to the last ack passes; equal to the pending passes; missing a saved block fails with expected and actual; integrity fail fails
- [x] `fvm flutter build apk --profile -t integration_test/kill/kill_app.dart` builds
- [x] Quick gate passes (≥ 4 new tests)

**Tests**: e2e
**Gate**: quick
**Commit**: `test(app): app instrumentado do kill test (KILL-01, KILL-02)`

---

#### T22: Kill test script

**What**: Write a script that:
1. Builds and installs the T21 APK.
2. Runs 100 iterations of start → random 0.5–6 s sleep (seed printed) → `force-stop` → relaunch.
3. Pulls `results.jsonl` via `run-as`.
4. Prints `N/100 iterations, D divergences` and each divergence's seed, expected and actual content.
5. Exits 1 on any divergence.

Add `app/tool/kill_test_test.sh` for the result parser, asserting the exit code and the printed text (L-001).
**Where**: `app/tool/kill_test.sh`
**Depends on**: T21
**Reuses**: `.github/scripts/commit-msg_test.sh` assert helpers style
**Requirement**: KILL-04, KILL-05

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `bash app/tool/kill_test_test.sh` passes: a passing file prints `100/100 iterations, 0 divergences` and exits 0; a failing file prints the divergent block and exits 1
- [x] A subagent runs 5 iterations on an emulator successfully
- [x] Build gate passes

**Tests**: shell
**Gate**: build
**Commit**: `test(app): script do kill test com 100 iterações (KILL-04, KILL-05)`

---

#### T23: Kill test run and record

**What**: Run `app/tool/kill_test.sh` with 100 iterations on an emulator, or the device. Run the fault-injection check once (a scratch change that drops a saved block on start, then discarded) and record that the script exits 1. Record both in `.specs/features/m05-search-and-gate-1/kill-results.md`, which is copied into the PR.
**Where**: `.specs/features/m05-search-and-gate-1/kill-results.md`
**Depends on**: T22
**Reuses**: —
**Requirement**: KILL-06

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] The record shows `100/100 iterations, 0 divergences` with device or emulator details, plus the fault-injection result; any divergence becomes a `data-loss` issue and stops the phase
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs(app): resultado do kill test (KILL-06)`

---

### Phase 5: Drawing data and editor

#### T24: ADR 0039 — bloco de desenho

**What**: Write `docs/adr/0039-bloco-de-desenho.md` (Portuguese, Proposta). It covers:
- type `drawing`;
- the strokes format of DRAW-19, with tool ids `pen`/`highlighter`, color ids `ink`/`accent`/`danger` and widths 3/6/12;
- the logical 390 × 560 area and rounding;
- whole-stroke eraser;
- that it extends ADR 0036;
- the rejected alternatives: storing `perfect_freehand` output, and pixel images.

Add its row to `docs/adr/README.md`.
**Where**: `docs/adr/0039-bloco-de-desenho.md`
**Depends on**: None
**Reuses**: ADR 0036 format
**Requirement**: ADR-02

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR has the JSON example and the persisted ids; README lists 0039
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0039 proposta, formato do bloco de desenho (#25)`

---

#### T25: DrawingContent and perfect_freehand dependency

**What**: Add `perfect_freehand: 2.5.2+1` (exact), and add a lib scan in `test/app_test.dart` that allows it only under `lib/features/blocks/presentation/drawing/`. Implement `DrawingTool`, `DrawingColor`, `StrokeWidth`, `StrokePoint`, `Stroke` and `DrawingContent` per the design: rounding, unknown ids → `pen`/`ink`, invalid JSON → no strokes.
**Where**: `app/lib/features/blocks/data/drawing_content.dart`
**Depends on**: None
**Reuses**: `BlockContent.fromJson` logging pattern
**Requirement**: DRAW-19, EDGE-06, EDGE-07

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests:
  - round trip;
  - coordinates rounded to 0.1 at the exact boundaries (x.05, x.04);
  - pressure rounded to 0.01;
  - unknown tool and color ids;
  - invalid JSON;
  - a single-point stroke;
  - no field outside the ADR in `toJson`.
- [x] Import scan passes on the tree and fails on a scratch file (checked, then discarded)
- [x] Build gate passes (≥ 9 new tests)

**Tests**: unit
**Gate**: build
**Commit**: `feat(app): conteúdo do bloco de desenho (DRAW-19)`

---

#### T26: StoredContent and BlockType.drawing

**What**: Add `StoredContent`, implemented by `BlockContent` and `DrawingContent`, and `BlockType.drawing`. `Insert` and `Update` take `StoredContent`; `applyChanges` calls `forType` only on a `BlockContent`.
**Where**: `app/lib/features/blocks/data/block_repository.dart`
**Depends on**: T25
**Reuses**: current `applyChanges`
**Requirement**: DRAW-10, DRAW-14 (storage), DRAW-20

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Drift tests:
  - an `Insert` of a drawing writes type `drawing` with the JSON as-is;
  - an `Update` keeps `version`;
  - the page excerpt ignores a drawing that comes first;
  - every existing `BlockRepository` test passes.
- [x] Quick gate passes (≥ 3 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): tipo de bloco drawing no repositório (DRAW-20)`

---

#### T27: DrawingNode and BlockMapper

**What**: Add `DrawingNode extends BlockNode` (`isDeletable: false`, `hasEquivalentContent` on the content). `BlockMapper.toNode` and `fromNode` handle drawings, and `fromNode` returns `(BlockType, StoredContent)`.
**Where**: `app/lib/features/blocks/presentation/editor/block_mapper.dart`
**Depends on**: T26
**Reuses**: `HorizontalRuleNode` shape from super_editor
**Requirement**: DRAW-10, DRAW-13 (node), DRAW-19

**Tools**:

- MCP: `context7` (super_editor custom `BlockNode`)
- Skill: NONE

**Done when**:

- [x] Tests: row → node → (type, content) round trip for a drawing; the node is not deletable; text types unchanged
- [x] Quick gate passes (≥ 3 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): nó de desenho no editor (DRAW-19)`

---

#### T28: DrawingPainter

**What**: Build `DrawingPainter`. Each stroke goes through `getStroke` into a filled path, with logical → screen scale, color token map, highlighter ×3 at 35 % alpha and a single-point dot. It is shared by the card and the screen.
**Where**: `app/lib/features/blocks/presentation/drawing/drawing_painter.dart`
**Depends on**: T25
**Reuses**: theme tokens `ink1`, `accent`, `danger`
**Requirement**: DRAW-05, DRAW-06, DRAW-12 (scaling), EDGE-06

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Tests:
  - the painted path bounds scale with size;
  - the highlighter uses 3× width and alpha 0.35;
  - the color comes from the theme;
  - a one-point stroke paints a non-empty dot;
  - `shouldRepaint` is true only when content or scale changes.
- [x] Quick gate passes (≥ 5 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): pintura dos traços com perfect_freehand (DRAW-05, DRAW-06)`

---

#### T29: BlockSync with drawings

**What**: `BlockSync` defers an insert only for a `BlockContent` with empty text. A `ReplaceNodeRequest` with the same id becomes an `Update`, and a `DeleteNodeRequest` on a drawing becomes a `Trash`.
**Where**: `app/lib/features/blocks/presentation/editor/block_sync.dart`
**Depends on**: T27
**Reuses**: current `_write`
**Requirement**: DRAW-10, DRAW-14, DRAW-15

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Drift tests:
  - inserting a drawing node writes one `drawing` row after the given block;
  - a replace keeps the block id and updates `content_json` and `updated_at`, with `version` unchanged;
  - a delete soft-deletes;
  - every existing `BlockSync` test passes.
- [x] Quick gate passes (≥ 3 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): sync de blocos de desenho (DRAW-10, DRAW-14, DRAW-15)`

---

#### T30: Drawing card in the editor

**What**: Add `DrawingComponentBuilder` and `DrawingCard`: `AspectRatio(390 / 560)`, 1 px `bgTrilho` border, radius `rCard`, on `bgFolha`, `DrawingPainter`, and `Semantics(label: "Desenho", button: true)`. A tap calls `onOpen(nodeId)`. It is registered in `BlockEditor`, and `ActiveBlockBuilder` hides the drag handle for drawings.
**Where**: `app/lib/features/blocks/presentation/editor/components/drawing_block.dart`
**Depends on**: T28, T29
**Reuses**: `ActiveBlockBuilder`, `ChecklistItemBuilder` pattern
**Requirement**: DRAW-12, DRAW-13

**Tools**:

- MCP: `context7` (super_editor `ComponentBuilder`)
- Skill: NONE

**Done when**:

- [x] Widget tests:
  - the card is at page width with a 390:560 ratio;
  - border, radius and colors come from the tokens;
  - the semantics label is "Desenho";
  - a tap calls `onOpen` with the node id;
  - no drag handle;
  - Backspace at the start of the block below, and Delete at the end of the block above, leave the drawing row untouched.
- [x] Quick gate passes (≥ 6 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): card do desenho na página (DRAW-12, DRAW-13)`

---

#### T31: PageEditor drawing operations

**What**: Add the drawing operations to `PageEditor`, each followed by `flush()`:
- `drawingOf(nodeId)`;
- `insertDrawing(content)`: after the caret block, or in place of an empty text block with no row;
- `replaceDrawing(nodeId, content)`;
- `removeDrawing(nodeId)`.

`PageEditor` implements `DrawingSink` (`save`, `remove`) and exposes `onOpenDrawing`.
**Where**: `app/lib/features/blocks/presentation/editor/page_editor.dart`
**Depends on**: T30
**Reuses**: `focusEnd` insertion logic
**Requirement**: DRAW-10, DRAW-14, DRAW-15

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Drift + editor tests:
  - an insert after a text block;
  - an insert in place of an empty no-row block, with no extra row;
  - `save(null, …)` returns a node id and writes at once, with no 500 ms wait;
  - `save(id, …)` updates the row;
  - `remove` soft-deletes.
- [x] Quick gate passes (≥ 5 new tests)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): inserir, editar e remover desenho na página (DRAW-10, DRAW-15)`

---

### Phase 6: Drawing mode

#### T32: DrawingSession

**What**: Implement the drawing logic: tool, width and color with their defaults; start, extend and end a stroke; erase within `width / 2 + 10` logical units; per-action undo and redo, with the redo stack cleared on a new action; `content`; `isEmpty`.
**Where**: `app/lib/features/blocks/presentation/drawing/drawing_session.dart`
**Depends on**: None
**Reuses**: T25 model
**Requirement**: DRAW-04, DRAW-05, DRAW-06, DRAW-07, DRAW-08, DRAW-09

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Unit tests:
  - the defaults (pen, thin, ink);
  - the highlighter stores the selected width;
  - the eraser removes a stroke whose segment passes at exactly `width / 2 + 10`, and keeps one at `+ 10.1` (L-002);
  - one eraser drag removes several strokes, and undo restores them together;
  - redo is cleared after a new stroke;
  - `canUndo` and `canRedo`.
- [x] Quick gate passes (≥ 10 new tests)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): sessão do modo desenho com desfazer e borracha (DRAW-07, DRAW-08)`

---

#### T33: DrawingScreen

**What**: Build the "Modo desenho: tela cheia" screen:
- the header ("Cancelar", undo, redo, "Concluir");
- the canvas fitted in the logical 390 × 560 area, converting pointers to logical coordinates;
- the tool, width and color rows, with their l10n keys.

`openDrawing(context, target)` handles the outcomes:
- "Concluir" with strokes: save;
- "Concluir" with none: remove, or nothing for a new drawing;
- "Cancelar": write back or remove, only after a background save;
- the app going to background: save, keeping the node id.

**Where**: `app/lib/features/blocks/presentation/drawing/drawing_screen.dart`
**Depends on**: T32
**Reuses**: T8 icons, `DrawingPainter`, `AppLifecycleListener` pattern of `PageScreen`
**Requirement**: DRAW-02, DRAW-03, DRAW-04, DRAW-09, DRAW-11, DRAW-15, DRAW-16, DRAW-17, DRAW-18

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget tests with a fake `DrawingSink`:
  - controls and labels match the artboard;
  - redo is disabled at start;
  - a drag on a 2× screen stores logical points;
  - "Concluir" with 0 strokes on a new drawing → no `save`;
  - with every stroke erased on an existing drawing → `remove`;
  - "Cancelar" → no call;
  - background → `save`, then "Cancelar" → `save(original)` for an existing drawing, or `remove` for a new one.
- [x] Quick gate passes (≥ 9 new tests)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): tela do modo desenho (DRAW-02, DRAW-16, DRAW-17)`

---

#### T34: "Desenho" in the block bar

**What**: `BlockBar` shows "Desenho" after "Checklist" (canvas order), never active, with an `onDrawing` callback. The BAR-03 test changes accordingly.
**Where**: `app/lib/core/design_system/block_bar.dart`
**Depends on**: T33
**Reuses**: `JotBlockBarButton`, `JotIconGlyph.drawing`
**Requirement**: DRAW-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget tests: the button order, label "Desenho", never pressed state, and the tap calls `onDrawing`
- [x] Quick gate passes (≥ 2 new tests, BAR-03 updated, not removed)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(app): botão Desenho na barra de blocos (DRAW-01)`

---

#### T35: Page screen wiring and drawing e2e

**What**: `PageScreen` connects the bar's `onDrawing` and the card's `onOpenDrawing` to `openDrawing` with the `PageEditor` as `DrawingSink`. Extend `integration_test/editor_flow_test.dart`:
1. Draw two strokes and tap "Concluir".
2. Close and reopen the app; the card is there.
3. Open it, erase everything, tap "Concluir"; no card remains.

**Where**: `app/lib/features/pages/presentation/page_screen.dart`
**Depends on**: T34
**Reuses**: `openDrawing`, `PageEditor`
**Requirement**: DRAW-02, DRAW-10, DRAW-13, DRAW-15, RF-06

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Widget test: bar → drawing mode → "Concluir" → one `drawing` row after the caret block
- [x] The e2e flow passes on an emulator, with no network
- [x] Full gate passes

**Tests**: e2e
**Gate**: full
**Commit**: `feat(app): desenho à mão livre na página (RF-06)`

---

### Phase 7: Encryption, docs and Gate 1

#### T36: Encryption spike and ADR 0040

**What**: On `spike/28-local-encryption`:
- try `hooks.user_defines.sqlite3.source: sqlite3mc` and `sqlcipher` with Drift and `PRAGMA key`;
- check PowerSync's SQLCipher support (Context7 or prototype);
- measure the migration from an unencrypted database, key storage, APK size and LOAD-03/LOAD-06 with the seed, encrypted and not.

On the milestone branch: write `docs/adr/0040-criptografia-do-banco-local.md` (Portuguese) with the decision on phase 2 or later, mark the PRD §11 checkbox with the ADR, and add the README row.
**Where**: `docs/adr/0040-criptografia-do-banco-local.md`
**Depends on**: None
**Reuses**: `sqlite3` `doc/hook.md`; T15 seed; T16 measurement
**Requirement**: CRYPT-01…CRYPT-05

**Tools**:

- MCP: `context7` (PowerSync Flutter SQLCipher, Drift encryption)
- Skill: `create-adr`

**Done when**:

- [ ] The ADR table covers CRYPT-02 and CRYPT-03 per option
- [ ] `git diff main -- app/pubspec.yaml` on the milestone branch has no encryption dependency (CRYPT-05)
- [ ] The spike branch is pushed only with the user's go-ahead and is never merged
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0040, criptografia do banco local (#28, RNF-10)`

---

#### T37: app/CLAUDE.md and test docs

**What**: Update the docs:
- `app/CLAUDE.md` commands gain the seed, the RNF-06 drive command, `fvm flutter test --tags perf --run-skipped`, the kill test build and script, and `bash tool/kill_test_test.sh`; the Drawing stack line names `perfect_freehand 2.5.2+1` and ADR 0039; the References table lists any new `.claude/docs` file in the same commit (DOC-02).
- `app/.claude/docs/testes.md` gets the search and drawing flows and the kill test.
- ADRs 0038 and 0039 become Aceita.

**Where**: `app/CLAUDE.md`
**Depends on**: None
**Reuses**: —
**Requirement**: DOC-02, DOC-03, ADR-01, ADR-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] Every new command runs as written (checked by a subagent)
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs(app): comandos de desempenho, kill test e desenho no CLAUDE.md`

---

#### T38: Start the internal-use period and #67

**What**: Prepare the manual Gate 1 criteria:
- create the `data-loss` label (needs the user's go-ahead for the GitHub write);
- write `docs/gates/uso-interno.md` (Portuguese): installing a profile build on the physical Android, pulling `integrity.log` via `adb run-as`, how to open a `data-loss` issue, and the 2-week period;
- link the #67 checklist (spike branch `REPORT.md`).

A subagent runs the procedure on an emulator before it is handed to the user. The user then runs the internal use and #67 on the iPhone and the physical Android.
**Where**: `docs/gates/uso-interno.md`
**Depends on**: None
**Reuses**: `spikes/m04-editor/REPORT.md` "Manual checklist"
**Requirement**: GATE-02, GATE-03, GATE-06

**Tools**:

- MCP: `github` (label, issue comment)
- Skill: NONE

**Done when**:

- [ ] The procedure is validated on an emulator by a subagent
- [ ] The label exists
- [ ] The period start date is recorded
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: roteiro do uso interno do Gate 1 (#29, #67)`

---

#### T39: #67 result and editor ADR check

**What**: Record the #67 results (device, OS, keyboard, per step) on issue #67. **If any SPIKE-06 item fails:** stop, and propose a new ADR superseding 0035 for the user to decide (GATE-06).
**Where**: `docs/gates/uso-interno.md`
**Depends on**: T38
**Reuses**: —
**Requirement**: GATE-03, GATE-06

**Tools**:

- MCP: `github`
- Skill: NONE

**Done when**:

- [ ] Issue #67 has the per-step results for both devices
- [ ] Either all items pass, or a superseding ADR is accepted
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: resultado da verificação do editor em aparelhos (#67)`

---

#### T40: Gate 1 review

**What**: After the 2-week period, write `docs/gates/gate-1.md` (Portuguese). It has three sections:
- the spike: ADR 0035 and #67;
- the schema: v3 and ADRs 0004, 0005, 0013, 0036 and 0039;
- no data loss: T23 result, `integrity.log` summary, period dates, device, and the `data-loss` issues with their outcome.

It ends with the verdict. A missing criterion says "não atendido" and the gate is not passed.
**Where**: `docs/gates/gate-1.md`
**Depends on**: T39
**Reuses**: T17, T23 records
**Requirement**: GATE-01, GATE-02, GATE-04, GATE-05

**Tools**:

- MCP: `github` (`data-loss` issue search)
- Skill: NONE

**Done when**:

- [ ] Every link resolves, and the verdict matches the evidence
- [ ] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: revisão do Gate 1 (#29)`

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7
```

Execution is strictly sequential: one task at a time, in order T1 … T40. The 40 tasks pack into 6 batches of whole phases:

| Batch | Phases | Tasks | Note |
| --- | --- | --- | --- |
| A | 1 | T1–T7 | |
| B | 2 | T8–T13 | e2e needs an emulator |
| C | 3 + 4 | T14–T23 | T17 needs the user's device; a miss stops here for the user's decision |
| D | 5 | T24–T31 | |
| E | 6 | T32–T35 | e2e needs an emulator |
| F | 7 | T36–T40 | T38–T40 span the 2-week internal use and need the user |

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1, T24, T36 | one ADR + README row (T36 also the spike, off `main`) | ✅ |
| T2 | `.drift` file + version bump + migration + generated test | ⚠️ Cohesive (a schema change ships with its migration, ADR 0015) |
| T3, T4, T5, T9, T18, T19, T20, T27, T28, T29, T32, T34 | one file + its test | ✅ |
| T6 | one repository + its two models | ⚠️ Cohesive (models exist only as its return types) |
| T7 | one providers file | ✅ |
| T8 | one icon file, six glyphs | ⚠️ Cohesive (same painter, same test) |
| T10, T11 | one widget + its l10n keys | ⚠️ Cohesive |
| T12 | one button on one screen | ✅ |
| T13, T16 | one e2e/perf test (T16 also the driver output name) | ✅ |
| T14 | one test + SQL getters (+ index only if it fails) | ⚠️ Cohesive (the getters exist for this test) |
| T15 | seed + its perf-tagged test + tag config | ⚠️ Cohesive (testes.md: tag declared with the first perf test) |
| T17, T23 | one measurement record | ✅ |
| T21 | entry point + its pure verify file | ⚠️ Cohesive (verify is testable only apart) |
| T22 | script + its shell test | ✅ |
| T25 | dependency + model + import scan | ⚠️ Cohesive (the dependency is not adopted without its boundary) |
| T26 | interface + enum value + repository | ⚠️ Cohesive (a type change must compile in its writer) |
| T30 | builder + card + registration | ⚠️ Cohesive (the card exists only inside the editor) |
| T31 | one class, four operations | ⚠️ Cohesive |
| T33 | one screen + l10n keys | ⚠️ Cohesive |
| T35 | wiring + e2e extension | ⚠️ Cohesive (the flow proves the wiring) |
| T37 | docs only | ✅ |
| T38, T39, T40 | one doc each | ✅ |

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1, T3, T4, T5 | None | — | ✅ |
| T2 | T1 | T1 → T2 | ✅ |
| T6 | T2 | T2 → T6 | ✅ |
| T7 | T6 | T6 → T7 | ✅ |
| T8, T9 | None | — | ✅ |
| T10 | T8 | T8 → T10 | ✅ |
| T11 | T10, T9 | T10 → T11, T9 → T11 | ✅ |
| T12 | T11 | T11 → T12 | ✅ |
| T13 | T12 | T12 → T13 | ✅ |
| T14, T15 | None | — | ✅ |
| T16 | T15 | T15 → T16 | ✅ |
| T17 | T16 | T16 → T17 | ✅ |
| T18 | None | — | ✅ |
| T19 | T18 | T18 → T19 | ✅ |
| T20, T21 | T19 | T19 → T20, T19 → T21 | ✅ |
| T22 | T21 | T21 → T22 | ✅ |
| T23 | T22 | T22 → T23 | ✅ |
| T24, T25 | None | — | ✅ |
| T26 | T25 | T25 → T26 | ✅ |
| T27 | T26 | T26 → T27 | ✅ |
| T28 | T25 | T25 → T28 | ✅ |
| T29 | T27 | T27 → T29 | ✅ |
| T30 | T28, T29 | T28 → T30, T29 → T30 | ✅ |
| T31 | T30 | T30 → T31 | ✅ |
| T32 | None | — | ✅ |
| T33 | T32 | T32 → T33 | ✅ |
| T34 | T33 | T33 → T34 | ✅ |
| T35 | T34 | T34 → T35 | ✅ |
| T36, T37, T38 | None | — | ✅ |
| T39 | T38 | T38 → T39 | ✅ |
| T40 | T39 | T39 → T40 | ✅ |

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1, T24, T36, T37, T38, T39, T40 | ADRs and docs | none | none | ✅ |
| T2, T3, T14 | Schema, triggers, migrations, SQL | Drift | Drift | ✅ |
| T4, T5, T25, T27, T32 | Pure models and parsers (T27 editor mapping, no widget) | unit | unit | ✅ |
| T6, T19, T26, T29, T31 | Repositories, checks, `BlockSync` with Drift | Drift | Drift | ✅ |
| T7 | Providers | unit | unit | ✅ |
| T18 | Integrity log (file I/O) | unit (temp dir) | unit | ✅ |
| T8, T9, T34 | Icons and design system widgets | widget | widget | ✅ |
| T10, T11, T12, T20, T33 | Screens and screen widgets | widget | widget | ✅ |
| T28, T30 | Editor/drawing widgets | widget | widget | ✅ |
| T13, T35 | Main flows | e2e | e2e | ✅ |
| T15, T16, T21 | Perf and kill harness | e2e (+ host tests) | e2e | ✅ |
| T22 | Shell script | shell | shell | ✅ |
| T17, T23 | Measurement records | none | none | ✅ |

## Requirement Coverage

| Requirement | Task(s) |
| --- | --- |
| SRCH-01 | T9, T11, T12 |
| SRCH-02, SRCH-03, SRCH-15, SRCH-17 | T11 (T7 for SRCH-03) |
| SRCH-04, SRCH-05 | T4, T6 |
| SRCH-06, SRCH-07, SRCH-08 | T4, T6 |
| SRCH-09, SRCH-10 | T6 (T3 for SRCH-10), T13 |
| SRCH-11, SRCH-12 | T10 |
| SRCH-13, SRCH-14 | T5, T10 |
| SRCH-16 | T11, T13 |
| SRCH-18 | T2, T6 |
| SRCH-19 | T2 |
| SRCH-20 | T6, T7 |
| SRCH-21 | T6, T13 |
| LOAD-01 | T15 |
| LOAD-02…LOAD-06 | T16, T17 |
| LOAD-07 | T14 |
| LOAD-08, LOAD-09 | T17 (T14 for LOAD-09 on plans) |
| INTEG-01 | T20 |
| INTEG-02…INTEG-05, INTEG-07, INTEG-08 | T19 |
| INTEG-06 | T18 |
| KILL-01…KILL-03 | T21 |
| KILL-04, KILL-05 | T22 |
| KILL-06 | T23 |
| GATE-01, GATE-04, GATE-05 | T40 |
| GATE-02 | T38, T40 |
| GATE-03, GATE-06 | T38, T39 |
| CRYPT-01…CRYPT-05 | T36 |
| DRAW-01 | T34 |
| DRAW-02 | T33, T35 |
| DRAW-03, DRAW-09, DRAW-11, DRAW-16…DRAW-18 | T33 |
| DRAW-04 | T32, T33 |
| DRAW-05, DRAW-06 | T28, T32 |
| DRAW-07, DRAW-08 | T32 |
| DRAW-10 | T26, T27, T29, T31, T35 |
| DRAW-12 | T28, T30 |
| DRAW-13 | T27, T30, T35 |
| DRAW-14 | T26, T29, T31 |
| DRAW-15 | T29, T31, T33, T35 |
| DRAW-19 | T25, T27 |
| DRAW-20 | T2, T26 |
| ADR-01 | T1, T37 |
| ADR-02 | T24, T37 |
| DOC-01 | T2 |
| DOC-02, DOC-03 | T37 |
| EDGE-01, EDGE-02 | T4 |
| EDGE-03, EDGE-04 | T5 |
| EDGE-05 | T7, T11 |
| EDGE-06 | T25, T28 |
| EDGE-07 | T25 |
| EDGE-08 | T18 |

**Coverage:** 88 requirements, 88 mapped, 0 unmapped.
