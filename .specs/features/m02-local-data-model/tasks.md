# M02 Local Data Model Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user - do not proceed without it.**

---

**Spec**: `.specs/features/m02-local-data-model/spec.md`
**Design**: `.specs/features/m02-local-data-model/design.md`
**Status**: Done

These project rules apply to every task:

- Code, file names and test descriptions in English.
- No explanatory comments. `///` is allowed; ask before adding `// ignore:` or `TODO`.
- Requirement code first in test names (`test('POS-05: ...')`); invariant tests also cite the RNF/ADR.
- Library APIs checked in Context7 at the versions in `pubspec.lock` before writing code.
- Commit messages in Portuguese, Conventional Commits, scopes `app` / `server` / `docs` / `infra`, no Claude co-authorship.
- Work happens on the branch `milestone/m02-local-data-model`, merged via PR.

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec - confirm before Execute. Guidelines found: `app/.claude/docs/testes.md` (real in-memory Drift, no DB mocks, streams tested with `emitsInOrder`, `make-migrations` tests, fixed invariant tests), `docs/adr/0015-estrategia-de-testes-do-app.md`, `app/CLAUDE.md` ("anything touching Drift, with an in-memory database test; schema changes, with a tested migration"). Samples: `app/test/core/database/*_test.dart`, `app/test/core/preferences/*_test.dart`, `app/test/app_test.dart`.

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Pure primitives (`lib/core/clock`, `ids`, `ordering`, `text`) | unit | 1:1 to spec ACs (TIME, ID, POS-01…08, TITLE); exact boundaries (50 / 51 clusters, L-002) | `app/test/core/{clock,ids,ordering,text}/*_test.dart` | `fvm flutter test test/core` |
| Schema and migrations (`lib/core/database/app_database.dart`, `tables/`) | Drift (in-memory SQLite) + `SchemaVerifier` | Every DB and SCHEMA AC: each invalid insert rejected by SQLite itself (raw SQL); v1 → v2 validated; fresh v2 validated; text dates round-trip | `app/test/core/database/app_database_test.dart`, `app/test/drift/app_database/*_test.dart` | `fvm flutter test test/core/database test/drift` |
| Database services (`local_user_repository.dart`, `position_allocator.dart`) | Drift (in-memory; file-backed for USER-03) | Every USER-01…05 AC including concurrency; every `Placement` branch, deleted siblings counted, error paths | `app/test/core/database/*_test.dart` | `fvm flutter test test/core/database` |
| Repositories (`lib/features/*/data/*_repository.dart`) | Drift (in-memory) with `FakeClock` + `SequentialIdGenerator` | Every REPO, DEL, TITLE (row unchanged on rejection) and USER-05 AC for that repository; every spec edge case; streams asserted with `emitsInOrder` | `app/test/features/*/data/*_repository_test.dart` | `fvm flutter test test/features` |
| Providers (`lib/features/*/data/*_providers.dart`) | unit (`ProviderContainer.test`) | REPO-19: built only from the three overridden base providers; stream providers emit the repository streams; errors surface as `AsyncError` | `app/test/features/*/data/*_providers_test.dart` | `fvm flutter test test/features` |
| Source / manifest scans (ID-04, TIME-03, DEL-03, NET-01, NET-02, USER-06) | unit | Each scan fails when the forbidden pattern is planted (checked once by hand during the task) | next to the guarded file (see design) | `fvm flutter test` |
| Build config, exported schemas, ADRs, PRD, `CLAUDE.md`, docs | none | - (build gate only) | - | Build gate |

## Gate Check Commands

> Generated from codebase - confirm before Execute. App commands run from `app/`.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | After tasks with unit / Drift tests | `cd app && fvm flutter test` |
| Build | After config/docs-only tasks and at the end of each phase | `cd app && fvm flutter pub get && fvm dart run build_runner build --delete-conflicting-outputs && fvm flutter analyze && fvm dart format --output=none --set-exit-if-changed $(git ls-files '*.dart') && fvm flutter test` |

---

## Execution Plan

Phases run in order; tasks inside a phase run in order. Arrows are real dependencies inside the phase; dependencies on earlier phases are listed in each task.

### Phase 1: Primitives

```
T1 → T2
T3
T4
```

### Phase 2: Database

```
T5 → T6 → T7
T6 → T8
```

### Phase 3: Repositories and providers

```
T9 → T10
T9 → T11 → T12
T11 → T13 → T14
T15
```

### Phase 4: Decisions and docs

```
T16 → T23
T17 → T23
T18 → T22
T19
T20
T21
```

---

## Task Breakdown

### Phase 1: Primitives

#### T1: UTC clock

**What**: Create `Clock`, `SystemClock` (UTC, microseconds dropped) and `clockProvider`. Add the `test/helpers/lib_scan.dart` helper (yields `lib/**/*.dart` minus `*.g.dart`, `*.steps.dart` and `lib/l10n/app_localizations*.dart`) and `test/helpers/fakes.dart` with `FakeClock`, which rejects non-millisecond-aligned values.
**Where**: `app/lib/core/clock/clock.dart`
**Depends on**: None
**Reuses**: Provider style of `app/lib/core/database/database_provider.dart`
**Requirement**: TIME-01, TIME-03, TIME-04

**Tools**:

- MCP: `context7` (Riverpod `Provider`)
- Skill: NONE

**Done when**:

- [x] `test/core/clock/clock_test.dart`:
  - TIME-01: `now().isUtc`
  - TIME-04: `now().microsecond == 0`
  - TIME-03: no `DateTime.now(` in `lib/` outside `clock.dart`
  - `clockProvider` returns a `SystemClock`
- [x] TIME-03 scan seen failing once with a planted `DateTime.now()` in another `lib/` file, then reverted
- [x] Quick gate passes: `cd app && fvm flutter test` (≥ 4 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): relógio UTC atrás de provider`

---

#### T2: UUID v7 id generator

**What**: Create `IdGenerator`, `UuidV7Generator` (wraps `Uuid().v7()`) and `idGeneratorProvider`. Add `SequentialIdGenerator` to `test/helpers/fakes.dart`; it returns deterministic ids that still have the v7 shape.
**Where**: `app/lib/core/ids/id_generator.dart`
**Depends on**: T1
**Reuses**: `lib_scan.dart` from T1; `uuid` 4.6.0 already in `pubspec.yaml`
**Requirement**: ID-01, ID-02, ID-04

**Tools**:

- MCP: `context7` (uuid v7)
- Skill: NONE

**Done when**:

- [x] `test/core/ids/id_generator_test.dart`:
  - ID-01: regex `^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`, length 36
  - ID-02: 10,000 distinct
  - ID-04: `Uuid` referenced only in `id_generator.dart`
  - Provider default is `UuidV7Generator`
- [x] ID-04 scan seen failing once with a planted `Uuid()` elsewhere in `lib/`, then reverted
- [x] Quick gate passes (≥ 4 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): gerador de ids UUID v7 (RNF-04)`

---

#### T3: Fractional index key generator

**What**: Port rocicorp/fractional-indexing (CC0-1.0) to `FractionalIndex.keyBetween(String? a, String? b)` with base-62 digits `0-9A-Za-z`. It throws `ArgumentError` on `a >= b` or a malformed key.
**Where**: `app/lib/core/ordering/fractional_index.dart`
**Depends on**: None
**Reuses**: Algorithm and test vectors of rocicorp/fractional-indexing
**Requirement**: POS-01 (byte order of keys), POS-02, POS-03, POS-04, POS-05, POS-06, POS-07, POS-08

**Tools**:

- MCP: `github` (read rocicorp source and tests)
- Skill: NONE

**Done when**:

- [x] `test/core/ordering/fractional_index_test.dart`:
  - One test per POS-02…POS-08
  - POS-06 / POS-07: 1,000 keys each, distinct and in the expected order
  - Known vectors from rocicorp: `(null, null)` → `a0`, `(a0, null)` → `a1`, `(null, a0)` → `Zz`, `(a1, a2)` → `a1V`
  - Every generated key compares the same with `compareTo` and with its UTF-8 bytes
- [x] Quick gate passes (≥ 10 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): gerador de chaves de índice fracionário`

---

#### T4: Title rules

**What**: Add `characters` to `dependencies`. Create `maxTitleLength = 50`, `notebookTitle(raw)` (trim; empty or > 50 clusters → `ArgumentError`) and `pageTitle(raw)` (trim; > 50 clusters → `ArgumentError`).
**Where**: `app/lib/core/text/title_rules.dart`
**Depends on**: None
**Reuses**: `characters` 1.4.1 already resolved through Flutter
**Requirement**: TITLE-01, TITLE-02, TITLE-03, TITLE-04, TITLE-05

**Tools**:

- MCP: `context7` (characters)
- Skill: NONE

**Done when**:

- [x] `test/core/text/title_rules_test.dart`. For both functions:
  - Surrounding spaces, tabs and newlines removed (TITLE-01)
  - Exactly 50 clusters accepted, with `👍🏽` making UTF-16 length > 50 (TITLE-05)
  - 51 rejected (TITLE-03)
  - 50 clusters plus surrounding whitespace accepted
- [x] Also in that file:
  - Notebook: empty / whitespace-only rejected (TITLE-02)
  - Page: empty / whitespace-only returns `''` (TITLE-04)
- [x] Quick gate passes (≥ 9 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): regras de título de caderno e página`

---

### Phase 2: Database

#### T5: Register the database in `build.yaml` and export schema v1

**What**:

- Create `app/build.yaml` with `drift_dev` options `databases: app_database: lib/core/database/app_database.dart` and `store_date_time_values_as_text: true`.
- Run `fvm dart run drift_dev make-migrations` while `schemaVersion` is still 1, exporting the empty v1 schema.
- In `testes.md` "Migrations", replace step 1 ("once `AppDatabase` exists") with the actual `build.yaml` entry.

**Where**: `app/build.yaml`
**Depends on**: None
**Reuses**: Existing `AppDatabase` (v1, no tables)
**Requirement**: DB-02, DB-03 (v1 export), DOC-03

**Tools**:

- MCP: `context7` (drift_dev make-migrations, build options)
- Skill: NONE

**Done when**:

- [x] `drift_schemas/app_database/drift_schema_v1.json` exists, untouched by hand
- [x] `build_runner build` succeeds with the new options
- [x] `testes.md` no longer says "once `AppDatabase` exists"
- [x] Build gate passes (test count unchanged)

**Tests**: none
**Gate**: build
**Commit**: `build(app): registra o banco no drift_dev e exporta o schema v1`

---

#### T6: Schema v2 with migration

**What**:

- Create the tables in `lib/core/database/tables/`: `notebooks.dart`, `notebook_members.dart`, `member_role.dart`, `pages.dart` (`@DataClassName('NotebookPage')`), `blocks.dart` and `local_user.dart`. Indexes, checks and the unique key follow the design's Data Models.
- In `AppDatabase`, list the tables, set `schemaVersion` 2 and write `migration`: `onCreate`, `stepByStep(from1To2)` creating `schema.entities`, and `beforeOpen` with `PRAGMA foreign_keys = ON`.
- Run `make-migrations` and complete the generated `test/drift/app_database/` test. Commit `app_database.steps.dart` and the v2 schema.
- Update STRUCT-03 in `test/app_test.dart` to skip `test/drift/`, and note that exemption in `testes.md`.
- Add analyzer excludes only if `flutter analyze` flags generated files.

**Where**: `app/lib/core/database/app_database.dart`
**Depends on**: T5
**Reuses**: `createTestDatabase()`; `NotebookColor` / `CoverPattern` as `textEnum`
**Requirement**: DB-01, DB-03, DB-04, DB-05, DB-06, SCHEMA-01…SCHEMA-10, TIME-02, USER-01 (table), DEL-03

**Tools**:

- MCP: `context7` (Drift tables, `textEnum`, `check`, `uniqueKeys`, `@TableIndex`, step-by-step migrations, `SchemaVerifier`, `validateDatabaseSchema`)
- Skill: NONE

**Done when**:

- [x] `test/core/database/app_database_test.dart` replaces M01's `TEST-01` with these tests:
  - DB-01
  - DB-06 (`PRAGMA foreign_keys` = 1)
  - SCHEMA-01…04: columns, types and nullability read from `PRAGMA table_info`
  - SCHEMA-05: bad role rejected
  - SCHEMA-06: each null author column rejected
  - SCHEMA-07: each missing parent rejected
  - SCHEMA-08: duplicate member rejected
  - SCHEMA-09: stored `pautada` / `azulTinta`
  - SCHEMA-10: `PRAGMA index_list`
  - USER-01: `local_user` rejects `slot = 2`
  - TIME-02: round-trip of `DateTime.utc(2026, 10, 11, 12, 0, 0, 123)` is UTC and equal
  - DEL-03: scan of drift-importing `lib/` files
- [x] `test/drift/app_database/migration_test.dart`: v1 → v2 `migrateAndValidate` (DB-04); a fresh v2 database passes `validateDatabaseSchema()` (DB-05)
- [x] DEL-03 scan seen failing once with a planted `delete(notebooks)`, then reverted
- [x] `test/core/database/database_provider_test.dart` still passes
- [x] Build gate passes (≥ 20 new tests; M01 `TEST-01` replaced, not deleted silently)

**Tests**: Drift + SchemaVerifier
**Gate**: build
**Commit**: `feat(app): schema v2 com cadernos, membros, páginas, blocos e usuário local`

---

#### T7: Anonymous local user

**What**: Create `LocalUserRepository.id()` with these rules:

- Transaction that runs `INSERT OR IGNORE` on `(slot: 1, id: ids.newId())`, then selects the row.
- The future is cached per instance.

Also create `localUserRepositoryProvider`, built from `databaseProvider` and `idGeneratorProvider`. Add a file-backed database helper for USER-03 in `test/helpers/test_database.dart`.

**Where**: `app/lib/core/database/local_user_repository.dart`
**Depends on**: T6
**Reuses**: `IdGenerator` (T2), `SequentialIdGenerator`, `createTestDatabase()`
**Requirement**: USER-01, USER-02, USER-03, USER-04

**Tools**:

- MCP: `context7` (Drift `InsertMode.insertOrIgnore`, transactions, `NativeDatabase` file)
- Skill: NONE

**Done when**:

- [x] `test/core/database/local_user_repository_test.dart`:
  - USER-02: empty table → id from the generator, row stored
  - USER-03: same id after closing and reopening a temp-file database
  - USER-04: `Future.wait` on two separate instances → one row, same id
  - USER-01: never more than one row
  - Provider wiring with overrides
- [x] Quick gate passes (≥ 5 new tests, none removed)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): usuário local anônimo no Drift (ADR 0011)`

---

#### T8: Placement and position allocator

**What**:

- Create `Placement` (`AtStart`, `AtEnd`, `After(id)`) in `lib/core/ordering/placement.dart`.
- Create `PositionAllocator.keyFor(OrderedTable, {parentId, at, movingId})`. It aggregates over all siblings (deleted included), excludes `movingId`, and finds the next key strictly greater than the anchor. An anchor that is missing or under another parent → `ArgumentError`.

**Where**: `app/lib/core/database/position_allocator.dart`
**Depends on**: T6
**Reuses**: `FractionalIndex` (T3)
**Requirement**: POS-01, POS-02 (first key), assumption "Keys of deleted rows"

**Tools**:

- MCP: `context7` (Drift `customSelect` with variables)
- Skill: NONE

**Done when**:

- [x] `test/core/database/position_allocator_test.dart`, for both `pages` and `blocks`:
  - Empty parent → `a0`
  - `AtEnd` > max, including a deleted row holding the max
  - `AtStart` < min
  - `After(x)` strictly between `x` and the next sibling
  - `movingId` ignored
  - Anchor from another parent → `ArgumentError`
  - Anchor missing → `ArgumentError`
- [x] Build gate passes (≥ 8 new tests, none removed)

**Tests**: Drift
**Gate**: build
**Commit**: `feat(app): alocação de posição por índice fracionário`

---

### Phase 3: Repositories and providers

#### T9: Notebook repository

**What**: Create `NotebookRepository` with `create`, `update`, `archive`, `unarchive`, `moveToTrash`, `watchActive` and `watchArchived`, exactly as in the design. The constructor takes `AppDatabase`, `Clock`, `IdGenerator` and `LocalUserRepository`.
**Where**: `app/lib/features/notebooks/data/notebook_repository.dart`
**Depends on**: None
**Reuses**: T1, T2, T4, T7 (earlier phases); `FakeClock`, `SequentialIdGenerator`
**Requirement**: REPO-01…REPO-07, REPO-18, DEL-01, DEL-02, DEL-04, ID-03, USER-05, TITLE-01, TITLE-02, TITLE-03, SCHEMA-09; edge cases "archived then deleted" and "database closed while listening"

**Tools**:

- MCP: `context7` (Drift joins, `watch`, transactions, companions)
- Skill: NONE

**Done when**:

- [x] `test/features/notebooks/data/notebook_repository_test.dart`:
  - REPO-01: notebook row plus an `owner` member row, with `user_id` = `added_by` = local user and `archived_at` null
  - REPO-02: a forced member-insert failure leaves no notebook row (e.g. a pre-seeded duplicate member id from the fake generator)
  - REPO-03: only that row changes
  - REPO-04 / REPO-05: only `archived_at` on the local user's member row; `deleted_at` stays null
  - REPO-06 / REPO-07: ordering, including the `id` tie-break
  - REPO-18: `emitsInOrder` across create, rename, archive, delete
  - DEL-01 / DEL-02: `deleted_at` set once; a second delete keeps it
  - DEL-04: trashed notebook in neither stream; archived then deleted notebook in neither stream
  - ID-03: row ids come from the fake generator
  - USER-05: `created_by`, `user_id`, `added_by`
  - TITLE-01 / 02 / 03: trimmed, or rejected with the row unchanged
  - Closing the database completes the stream without an error
- [x] Quick gate passes (≥ 15 new tests, none removed)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): repositório de cadernos com membros e arquivamento (ADR 0004, ADR 0012)`

---

#### T10: Notebook providers

**What**: Create `notebookRepositoryProvider`, `activeNotebooksProvider` and `archivedNotebooksProvider` (`StreamProvider.autoDispose`, `retry` returning null).
**Where**: `app/lib/features/notebooks/data/notebook_providers.dart`
**Depends on**: T9
**Reuses**: `databaseProvider`, `clockProvider`, `idGeneratorProvider`, `localUserRepositoryProvider`
**Requirement**: REPO-19, REPO-06, REPO-07

**Tools**:

- MCP: `context7` (Riverpod 3 `StreamProvider.autoDispose`, `retry`, `ProviderContainer.test`)
- Skill: NONE

**Done when**:

- [x] `test/features/notebooks/data/notebook_providers_test.dart`:
  - REPO-19: a container overriding only the three base providers builds the repository and both streams
  - A notebook created through the repository provider shows in `activeNotebooksProvider`
  - A closed database surfaces as `AsyncError` without a retry timer
- [x] Quick gate passes (≥ 3 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): providers de cadernos`

---

#### T11: Page repository

**What**: Create `PageRepository` with `create`, `rename`, `move`, `moveToTrash` and `watchByNotebook`, exactly as in the design.
**Where**: `app/lib/features/pages/data/page_repository.dart`
**Depends on**: T9
**Reuses**: `PositionAllocator` (T8), `pageTitle` (T4), `NotebookRepository` for test setup
**Requirement**: REPO-08…REPO-12, REPO-18, POS-01, POS-09, DEL-01, DEL-02, DEL-05, DEL-06, ID-03, USER-05, TITLE-01, TITLE-03, TITLE-04; edge cases "unknown notebook", "first page", "after deleted highest page"

**Tools**:

- MCP: `context7` (Drift joins, `watch`, update companions)
- Skill: NONE

**Done when**:

- [x] `test/features/pages/data/page_repository_test.dart`:
  - REPO-08: position > all, including deleted; `updated_*`
  - REPO-09: rename
  - REPO-10: move to start / end / between, then stream order
  - POS-09: moving the 3rd of 5 changes exactly one row (all rows compared before and after)
  - REPO-11: stream excludes deleted pages; ordered by position then id, with a forced tie
  - REPO-12: notebook row byte-identical after create, rename, move, delete
  - DEL-05: trashed page gone from the stream
  - DEL-06: trashed notebook → empty page stream
  - DEL-02: second delete keeps the timestamp
  - ID-03 / USER-05
  - TITLE-01 / 03 / 04, rejected writes leaving the row unchanged
  - Edge cases: unknown notebook throws with no row; first page `a0`; page after a deleted highest page sorts above it
  - REPO-18: `emitsInOrder`
- [x] Quick gate passes (≥ 15 new tests, none removed)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): repositório de páginas com ordem fracionária (RF-02)`

---

#### T12: Page providers

**What**: Create `pageRepositoryProvider` and `pagesProvider` (`StreamProvider.autoDispose.family<List<NotebookPage>, String>`, `retry` returning null).
**Where**: `app/lib/features/pages/data/page_providers.dart`
**Depends on**: T11
**Reuses**: Pattern of T10
**Requirement**: REPO-19, REPO-11

**Tools**:

- MCP: `context7` (Riverpod 3 family providers)
- Skill: NONE

**Done when**:

- [x] `test/features/pages/data/page_providers_test.dart`:
  - REPO-19 overrides only
  - `pagesProvider(notebookId)` emits that notebook's pages and not another's
  - Errors surface as `AsyncError`
- [x] Quick gate passes (≥ 3 new tests, none removed)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(app): providers de páginas`

---

#### T13: Block repository

**What**: Create `BlockRepository` with `create` (default `AtEnd`), `updateContent`, `move`, `moveToTrash` and `watchByPage`, exactly as in the design. No companion ever writes `version`.
**Where**: `app/lib/features/blocks/data/block_repository.dart`
**Depends on**: T11
**Reuses**: `PositionAllocator`, `PageRepository` / `NotebookRepository` for test setup
**Requirement**: REPO-13…REPO-18, POS-01, POS-09, DEL-01, DEL-02, DEL-05, DEL-06, DEL-07, DEL-08, ID-03, USER-05

**Tools**:

- MCP: `context7` (Drift joins over three tables, `watch`)
- Skill: NONE

**Done when**:

- [x] `test/features/blocks/data/block_repository_test.dart`:
  - REPO-13: at end and between neighbors; `version` 0
  - REPO-14 / REPO-15: `version` unchanged after a manual `UPDATE … SET version = 7`, then update / move (ADR 0013)
  - REPO-16: deleted excluded, order
  - REPO-17: page row byte-identical
  - POS-09: one row changed on move
  - DEL-08: trashed block excluded
  - DEL-05 / DEL-06: trashed page or notebook → empty block stream
  - DEL-07: notebook with 2 pages and 3 blocks deleted; page and block rows byte-identical, and every stream excludes them
  - DEL-02 / ID-03 / USER-05
  - REPO-18: `emitsInOrder`
- [x] Quick gate passes (≥ 13 new tests, none removed)

**Tests**: Drift
**Gate**: quick
**Commit**: `feat(app): repositório de blocos sem incrementar version (ADR 0013)`

---

#### T14: Block providers

**What**: Create `blockRepositoryProvider` and `blocksProvider` (`StreamProvider.autoDispose.family<List<Block>, String>`, `retry` returning null).
**Where**: `app/lib/features/blocks/data/block_providers.dart`
**Depends on**: T13
**Reuses**: Pattern of T12
**Requirement**: REPO-19, REPO-16

**Tools**:

- MCP: `context7` (Riverpod 3 family providers)
- Skill: NONE

**Done when**:

- [x] `test/features/blocks/data/block_providers_test.dart`:
  - REPO-19 overrides only
  - `blocksProvider(pageId)` emits that page's blocks only
  - Errors surface as `AsyncError`
- [x] Build gate passes (≥ 3 new tests, none removed)

**Tests**: unit
**Gate**: build
**Commit**: `feat(app): providers de blocos`

---

#### T15: App-wide invariant scans

**What**:

- Add NET-01 (no `package:http`, `package:dio` or `HttpClient` in `lib/`) and NET-02 (no `http` / `dio` under `dependencies` in `pubspec.yaml`) to `test/app_test.dart`.
- Add USER-06 to the preferences store test: after every write the store offers, the box keys ⊆ `{lastOpenedNotebookId}`.

**Where**: `app/test/app_test.dart`
**Depends on**: None
**Reuses**: `lib_scan.dart` (T1); `test/core/preferences/hive_preferences_store_test.dart` setup
**Requirement**: NET-01, NET-02, USER-06

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] NET-01 seen failing once with a planted `import 'package:http/http.dart';` in a repository, then reverted
- [x] NET-02 parses `pubspec.yaml` `dependencies` keys (not a substring match)
- [x] USER-06 test in `test/core/preferences/hive_preferences_store_test.dart`
- [x] Build gate passes (≥ 3 new tests, none removed)

**Tests**: unit
**Gate**: build
**Commit**: `test(app): invariantes sem rede e preferências sem usuário (RNF-01)`

---

### Phase 4: Decisions and docs

All ADRs are in Portuguese, in the Contexto / Decisão / Alternativas descartadas / Consequências format of `docs/adr/0023-lixeira-local-da-fase-1.md`. Each is added to `docs/adr/README.md` in the same commit (ADR-01, ADR-02).

#### T16: ADR 0026 — local user in Drift

**What**: Record that the anonymous user lives in the Drift `local_user` table, which is local-only, single-row and never synced, instead of in `hive_ce`.
**Where**: `docs/adr/0026-usuario-local-no-drift.md`
**Depends on**: None
**Reuses**: context.md "Anonymous local user storage"; ADR 0011
**Requirement**: ADR-01, ADR-02

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR file plus its index line in `docs/adr/README.md`
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0026 — usuário local anônimo numa tabela do Drift`

---

#### T17: ADR 0027 — derived notebook deletion

**What**: Deleting a notebook writes only `notebooks.deleted_at`; page and block queries hide its rows. This answers ADR 0023's first open question: restoring brings back only the pages that were not trashed on their own. The ADR cites 0023 without editing it.
**Where**: `docs/adr/0027-exclusao-de-caderno-derivada.md`
**Depends on**: None
**Reuses**: ADR 0023, context.md "Deleting a notebook"
**Requirement**: ADR-01, ADR-02

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR file plus its index line
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0027 — exclusão de caderno derivada para páginas e blocos`

---

#### T18: ADR 0028 — columns beyond PRD §7

**What**: Record `blocks.deleted_at` (RNF-05) and `notebook_members.id` (PowerSync text PK, no composite keys). The consequences note that renaming an enum stored by `textEnum` requires a migration, and that FK/CHECK constraints are lost under PowerSync views in phase 2.
**Where**: `docs/adr/0028-colunas-alem-do-prd.md`
**Depends on**: None
**Reuses**: Spec assumptions; PowerSync "Primary Key" docs
**Requirement**: ADR-01, ADR-02

**Tools**:

- MCP: `context7` (PowerSync primary key requirement)
- Skill: `create-adr`

**Done when**:

- [x] ADR file plus its index line
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0028 — blocks.deleted_at e notebook_members.id`

---

#### T19: ADR 0029 — fractional index as text keys

**What**: Record variable-length base-62 text keys with byte-wise order and `id` tie-break, the own port of rocicorp (CC0), keys computed over deleted siblings, and no rebalancing in phase 1.
**Where**: `docs/adr/0029-indice-fracionario-em-texto.md`
**Depends on**: None
**Reuses**: design.md Fractional index and PositionAllocator
**Requirement**: ADR-01, ADR-02

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR file plus its index line
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0029 — índice fracionário em chaves texto base-62`

---

#### T20: ADR 0030 — dates as ISO-8601 text

**What**: Record `store_date_time_values_as_text: true`, UTC, with the clock truncated to milliseconds. The reason is that `toIso8601String()` writes microseconds only when they are non-zero, which breaks text order.
**Where**: `docs/adr/0030-datas-em-texto-iso-8601.md`
**Depends on**: None
**Reuses**: design.md Risks (date ordering)
**Requirement**: ADR-01, ADR-02

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR file plus its index line
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0030 — datas como texto ISO-8601 em UTC`

---

#### T21: ADR 0031 — step-by-step migrations

**What**: Record schema versioning with `drift_dev make-migrations`: committed exported schemas, a generated `.steps.dart`, `SchemaVerifier` tests in `test/drift/` (exempt from mirroring) and foreign keys on in `beforeOpen`.
**Where**: `docs/adr/0031-migracoes-passo-a-passo.md`
**Depends on**: None
**Reuses**: `testes.md` Migrations
**Requirement**: ADR-01, ADR-02

**Tools**:

- MCP: NONE
- Skill: `create-adr`

**Done when**:

- [x] ADR file plus its index line
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: ADR 0031 — versionamento do schema com migrações passo a passo`

---

#### T22: PRD §7 extra columns

**What**: Add `blocks.deleted_at` and `notebook_members.id` to the PRD §7 table, citing ADR 0028.
**Where**: `docs/prd/PRD.md`
**Depends on**: T18
**Reuses**: ADR 0028
**Requirement**: DOC-01

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] §7 rows for `notebook_members` and `blocks` list the new columns and cite ADR 0028
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs: PRD §7 com blocks.deleted_at e notebook_members.id`

---

#### T23: `app/CLAUDE.md` rules

**What**: Add these rules to "Rules":

- The anonymous local user lives in the Drift `local_user` table.
- A deleted notebook hides its pages and blocks without writing to them.
- Repositories trim titles: notebook titles are required, ≤ 50; page titles are optional, ≤ 50, counted in grapheme clusters.
- Writes take `Placement`, never raw keys.

**Where**: `app/CLAUDE.md`
**Depends on**: T16, T17
**Reuses**: ADRs 0026, 0027
**Requirement**: DOC-02

**Tools**:

- MCP: NONE
- Skill: NONE

**Done when**:

- [x] `grep local_user app/CLAUDE.md` matches; each rule is one line
- [x] Build gate passes

**Tests**: none
**Gate**: build
**Commit**: `docs(app): regras do modelo de dados local no CLAUDE.md`

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 3 → Phase 4
```

Execution is strictly sequential: one task at a time, in order T1 … T23. 23 tasks pack into 3 batches of whole phases:

- Batch A: Phases 1 + 2 (T1–T8)
- Batch B: Phase 3 (T9–T15)
- Batch C: Phase 4 (T16–T23)

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1, T2 | one class + provider + its test (T1 also seeds two test helpers) | ⚠️ Cohesive |
| T3, T4 | one function/class each + its test | ✅ |
| T5 | build config + v1 export + the doc line it makes obsolete | ⚠️ Cohesive |
| T6 | schema v2: tables, database, migration and generated test are one schema change (`testes.md`: a table change ships with its migration) | ⚠️ Cohesive (cannot be split without intermediate schema versions) |
| T7, T8 | one service + its test | ✅ |
| T9, T11, T13 | one repository + its test | ✅ |
| T10, T12, T14 | one providers file + its test | ✅ |
| T15 | scan tests only | ✅ |
| T16–T21 | one ADR each + index line | ✅ |
| T22, T23 | one doc file each | ✅ |

## Diagram-Definition Cross-Check

| Task | Depends On (task body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1 | None | — | ✅ |
| T2 | T1 | T1 → T2 | ✅ |
| T3 | None | — | ✅ |
| T4 | None | — | ✅ |
| T5 | None | — | ✅ |
| T6 | T5 | T5 → T6 | ✅ |
| T7 | T6 | T6 → T7 | ✅ |
| T8 | T6 (T3 earlier phase) | T6 → T8 | ✅ |
| T9 | None in phase (T1, T2, T4, T7 earlier) | — | ✅ |
| T10 | T9 | T9 → T10 | ✅ |
| T11 | T9 (T8 earlier) | T9 → T11 | ✅ |
| T12 | T11 | T11 → T12 | ✅ |
| T13 | T11 | T11 → T13 | ✅ |
| T14 | T13 | T13 → T14 | ✅ |
| T15 | None (T1 earlier) | — | ✅ |
| T16–T21 | None | — | ✅ |
| T22 | T18 | T18 → T22 | ✅ |
| T23 | T16, T17 | T16 → T23, T17 → T23 | ✅ |

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1 | Pure primitive + scan | unit | unit | ✅ |
| T2 | Pure primitive + scan | unit | unit | ✅ |
| T3 | Pure primitive | unit | unit | ✅ |
| T4 | Pure primitive | unit | unit | ✅ |
| T5 | Build config, exported schema, docs | none | none | ✅ |
| T6 | Schema and migrations + scan | Drift + SchemaVerifier | Drift + SchemaVerifier | ✅ |
| T7 | Database service | Drift | Drift | ✅ |
| T8 | Database service | Drift | Drift | ✅ |
| T9 | Repository | Drift | Drift | ✅ |
| T10 | Providers | unit | unit | ✅ |
| T11 | Repository | Drift | Drift | ✅ |
| T12 | Providers | unit | unit | ✅ |
| T13 | Repository | Drift | Drift | ✅ |
| T14 | Providers | unit | unit | ✅ |
| T15 | Source / manifest scans | unit | unit | ✅ |
| T16–T23 | ADRs, PRD, `CLAUDE.md` | none | none | ✅ |

## Requirement Coverage

| Requirement | Task(s) |
| --- | --- |
| DB-01, DB-04, DB-05, DB-06 | T6 |
| DB-02 | T5 |
| DB-03 | T5, T6 |
| SCHEMA-01…SCHEMA-10 | T6 (SCHEMA-09 also T9) |
| ID-01, ID-02, ID-04 | T2 |
| ID-03 | T9, T11, T13 |
| TIME-01, TIME-03, TIME-04 | T1 |
| TIME-02 | T6 |
| USER-01 | T6, T7 |
| USER-02, USER-03, USER-04 | T7 |
| USER-05 | T9, T11, T13 |
| USER-06 | T15 |
| POS-01 | T3, T8, T11, T13 |
| POS-02…POS-08 | T3 (POS-02 also T8) |
| POS-09 | T11, T13 |
| DEL-01, DEL-02 | T9, T11, T13 |
| DEL-03 | T6 |
| DEL-04 | T9 |
| DEL-05, DEL-06 | T11, T13 |
| DEL-07, DEL-08 | T13 |
| REPO-01…REPO-07 | T9 (REPO-06/07 also T10) |
| REPO-08…REPO-12 | T11 (REPO-11 also T12) |
| REPO-13…REPO-17 | T13 (REPO-16 also T14) |
| REPO-18 | T9, T11, T13 |
| REPO-19 | T10, T12, T14 |
| TITLE-01…TITLE-05 | T4 (TITLE-01/02/03 also T9; TITLE-01/03/04 also T11) |
| NET-01, NET-02 | T15 |
| ADR-01, ADR-02 | T16–T21 |
| DOC-01 | T22 |
| DOC-02 | T23 |
| DOC-03 | T5 |
