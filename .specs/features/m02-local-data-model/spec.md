# M02 Local Data Model Specification

GitHub milestone [#02 - Local data model](https://github.com/djotanas/jotline/milestone/3) — issues #13–#18. Phase 1. Decisions taken in discussion: [context.md](context.md).

## Problem Statement

The app has an empty `AppDatabase` (`schemaVersion` 1, no tables), no id generator, no clock, no ordering scheme and no repositories. The notebook and page screens (#03), the block editor (#04) and search (#05) all read and write local data, and Gate 1 requires "schema with members and blocks closed". This milestone builds the phase 1 schema from PRD §7 with the phase 2–3 columns already in place (members, `version`, `updated_by`, per-member archive), the anonymous local user, UUID v7 ids, fractional ordering, soft delete and the reactive repositories the screens will consume.

## Goals

- [ ] The four PRD §7 phase 1 tables exist in Drift with a tested v1 → v2 migration, and every authorship column is filled by the anonymous local user (ADR 0011).
- [ ] Every root invariant that applies to the app's data has a fixed test: UUID v7 ids generated offline (RNF-04), soft delete only (RNF-05), owner row on creation (ADR 0004), per-member archive (ADR 0012), `blocks.version` never incremented by the app (ADR 0013), dates in UTC.
- [ ] Repositories for notebooks, pages and blocks expose `Stream`s through Riverpod providers, so #03 builds screens without touching SQL.
- [ ] No code under `app/lib/` can reach the network (RNF-01), enforced by an automated test.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Notebook, page and trash screens | Milestone #03 (#19, #20, #61) |
| Listing the trash and restoring notebooks or pages | #61 (Local trash) — user decision; this milestone only deletes |
| Block type set and `content_json` format | Defined by the block editor ADR after the spike (#22, #24) |
| Local search queries and full-text index | #26 (Local search) |
| 10,000-page load test (RNF-06) | #27; this milestone only adds the indexes it needs |
| Local database encryption | #28 (RNF-10) |
| Replacing the anonymous user id on login | Phase 2, #07 (RF-07, ADR 0011) |
| PowerSync, upload queue, sync contract | Phase 2, #08 |
| `attachments`, `invites`, `block_history`, `page_updates` tables | Phases 2–4 (PRD §7) |
| `notebooks.updated_at` / `updated_by`, `pages.created_at` / `created_by`, `blocks.created_at` / `created_by` | User decision: not added in phase 1 |
| Rebalancing fractional keys | Not needed at phase 1 volumes; revisited if keys grow (see assumptions) |
| "Empty trash" | ADR 0023: does not exist in phase 1 |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear. Rows decided in discussion on 2026-10-11 and confirmed on spec review on 2026-10-12 are marked `y`.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| `.specs/` language | English | Same as M01; agent-facing, EARS keywords are English | y |
| Where the anonymous local user id lives (#14) | Drift, local-only single-row table `local_user` | User decision: lives and dies with the data it signs; a failing `hive_ce` box (PREF-06) must not create a second author; PREF-05 keeps `hive_ce` to one key | y |
| Deleting a notebook vs its pages (ADR 0023) | Derived: only `notebooks.deleted_at` is set; page and block queries also exclude rows whose notebook (or page) is deleted | User decision: one write and one sync operation; restoring the notebook (#61) brings back only pages not deleted on their own, which answers ADR 0023's first open question | y |
| Columns beyond PRD §7 "campos principais" | Add only `blocks.deleted_at` | User decision: without it, deleting a block would be a physical `DELETE` (RNF-05) | y |
| Repository scope (#18) | Create, edit, reorder, archive, delete and watch active / archived lists; no trash listing or restore | User decision: trash queries ship with the trash screen in #61 | y |
| Primary key of `notebook_members` | `id` TEXT (UUID v7) plus `UNIQUE(notebook_id, user_id)` | PRD §7 convention "IDs em UUID v7"; PowerSync requires a text `id` column on every synced table and has no composite keys (PowerSync docs, "Primary Key") || y |
| Schema versioning (#13) | `schemaVersion` 2; v1 is the empty M01 schema; step-by-step migrations with `drift_dev make-migrations` and `SchemaVerifier` tests | `app/.claude/docs/testes.md`: every table change bumps the version and ships a tested migration; v1 already exists on dev devices || y |
| Date storage | `store_date_time_values_as_text: true` (ISO-8601 text, UTC) | Drift's default stores unix seconds with no sub-second precision; Drift recommends text for new projects; ordering by `updated_at` needs sub-second precision || y |
| UUID v7 source | `uuid` package (already in `pubspec.yaml`), behind an `IdGenerator` interface and provider | `testes.md`: id generator sits behind a provider and is overridden in tests || y |
| Clock | Own `Clock` interface with `now()` returning UTC truncated to milliseconds, behind `clockProvider` | `testes.md` already shows `Clock` / `clockProvider` in its examples; no direct `DateTime.now()` in business rules. Drift writes UTC dates with `toIso8601String()`, which appends microseconds only when non-zero (`.015Z` vs `.015123Z`), and mixed lengths do not sort as text || y |
| Fractional index format (#16) | Variable-length base-62 text keys compared byte-wise, ties broken by `id`; package or own implementation chosen in Design | Text keys never run out of precision, unlike `REAL` midpoints (~50 halvings); byte-wise order works the same in SQLite and Postgres (`COLLATE "C"`) || y |
| Keys of deleted rows | New positions are computed against all rows of the parent, including deleted ones | Restoring a deleted page in #61 must not collide with a key generated while it was in the trash || y |
| Initial `blocks.version` | `0`, meaning "never accepted by the server" | ADR 0013: phase 1 keeps the initial version; 0 lets phase 2 tell new blocks apart. Phase 2 may revisit when the sync contract is written (server first) || y |
| `blocks.type` and `content_json` | `type` is free text and `content_json` opaque text, both stored as given, not validated | Block editor still undecided (PRD §11); the editor ADR closes the set || y |
| Title validation | Repositories trim titles (`String.trim`) and count length in grapheme clusters (`package:characters`). Notebook title: required, at most 50 characters. Page title: optional (empty allowed), at most 50 characters. A title outside the rule throws `ArgumentError` and nothing is written | User decision on spec review. Rejecting instead of cutting never loses text silently; grapheme clusters match Flutter's `TextField.maxLength`, so a title the #03 sheet accepts is never rejected here | y |
| Notebook list order | Active: `created_at` desc, then `id` desc. Archived: `archived_at` desc, then `id` desc | The PRD has no notebook position column; newest first is the default until #03 defines sorting || y |
| Writes and parent rows | A block write never touches its page row; a page write never touches its notebook row | ADR 0005: the block is the unit of conflict; touching the parent would turn every block edit into a page-level conflict in phase 2 || y |
| Foreign keys | Declared in Drift and enforced with `PRAGMA foreign_keys = ON` | Catches orphan inserts in phase 1. Open for phase 2: PowerSync-managed views do not enforce constraints || y |
| Deleting twice | A second delete keeps the original `deleted_at` | The trash shows when the item was deleted; a repeat tap must not move it || y |
| ADRs | In Portuguese, numbered from 0026: (1) local user in Drift, (2) notebook deletion derived for pages, (3) `blocks.deleted_at` and `notebook_members.id` beyond PRD §7, (4) fractional index as text keys, (5) dates stored as ISO-8601 text, (6) schema versioning with step-by-step migrations | Each issue's DoD: "ADR created if a decision was made"; ADR 0023 is not edited, the new one answers its open question || y |
| Where tables, repositories and providers live | Tables, clock, id generator, local user and fractional index in `lib/core/`; repositories and providers in `lib/features/<feature>/data/` using Drift's query builder on `AppDatabase`, without DAOs | User decision on design review (see design.md) | y |

**Open questions:** none - all resolved and confirmed.

---

## User Stories

### P1: Drift setup and migrations ⭐ MVP

**User Story**: As the developer, I want the schema versioned with tested migrations so that a device with an older database never loses data on update.

**Why P1**: Every table in this milestone is a schema change from v1; Gate 1 forbids data loss.

**Acceptance Criteria**:

1. The `AppDatabase` SHALL declare `schemaVersion` 2. (DB-01)
2. The `app/build.yaml` SHALL register `AppDatabase` under `drift_dev` → `databases` and set `store_date_time_values_as_text: true`. (DB-02)
3. The repository SHALL contain the exported schemas for versions 1 and 2 and the migration test generated by `drift_dev make-migrations`, none edited by hand. (DB-03)
4. WHEN a version 1 database is opened by the app THEN the migration SHALL upgrade it to version 2 and the result SHALL match the exported version 2 schema. (DB-04)
5. WHEN a database is created from scratch THEN its schema SHALL match the exported version 2 schema. (DB-05)
6. WHEN the database opens THEN `PRAGMA foreign_keys` SHALL return 1. (DB-06)

**Independent Test**: The generated `SchemaVerifier` test migrates v1 → v2 and validates the schema; a test reads `PRAGMA foreign_keys` from the in-memory database.

---

### P1: Phase 1 schema ⭐ MVP

**User Story**: As the developer, I want the PRD §7 tables with members, versions and authorship from day one so that sharing, sync and history arrive without data migrations.

**Why P1**: Gate 1 requires the schema with members and blocks closed; everything else in phase 1 writes to it.

**Acceptance Criteria**:

1. The `notebooks` table SHALL have `id` TEXT primary key, `title` TEXT, `cover` TEXT, `color` TEXT, `created_by` TEXT, `created_at` datetime and nullable `deleted_at` datetime; every column except `deleted_at` SHALL be `NOT NULL`. (SCHEMA-01)
2. The `notebook_members` table SHALL have `id` TEXT primary key, `notebook_id` TEXT referencing `notebooks.id`, `user_id` TEXT, `role` TEXT, `added_by` TEXT, `created_at` datetime and nullable `archived_at` datetime, every other column `NOT NULL`, and a unique constraint on (`notebook_id`, `user_id`). (SCHEMA-02)
3. The `pages` table SHALL have `id` TEXT primary key, `notebook_id` TEXT referencing `notebooks.id`, `title` TEXT, `position` TEXT, `updated_at` datetime, `updated_by` TEXT and nullable `deleted_at` datetime, every other column `NOT NULL`. (SCHEMA-03)
4. The `blocks` table SHALL have `id` TEXT primary key, `page_id` TEXT referencing `pages.id`, `type` TEXT, `content_json` TEXT, `position` TEXT, `version` INTEGER with default 0, `updated_at` datetime, `updated_by` TEXT and nullable `deleted_at` datetime, every other column `NOT NULL`. (SCHEMA-04)
5. IF a `notebook_members` row is inserted with a `role` other than `owner`, `editor` or `viewer` THEN the database SHALL reject the insert. (SCHEMA-05)
6. IF a row is inserted with a null `created_by`, `user_id`, `added_by` or `updated_by` THEN the database SHALL reject the insert. (SCHEMA-06)
7. IF a `notebook_members`, `pages` or `blocks` row references a parent id that does not exist THEN the database SHALL reject the insert. (SCHEMA-07)
8. IF a second `notebook_members` row is inserted with the same (`notebook_id`, `user_id`) THEN the database SHALL reject the insert. (SCHEMA-08)
9. The `notebooks.cover` and `notebooks.color` columns SHALL store the `CoverPattern` and `NotebookColor` enum names (for example `pautada`, `azulTinta`). (SCHEMA-09)
10. The schema SHALL have an index on `pages(notebook_id, position)` and an index on `blocks(page_id, position)`. (SCHEMA-10)

**Independent Test**: In-memory database tests insert valid rows and assert each invalid insert (bad role, null author, missing parent, duplicate member) throws; `PRAGMA index_list` shows both indexes.

---

### P1: Client-side UUID v7 ids ⭐ MVP

**User Story**: As a user, I want everything I create to get its id on the device so that creating works with no network (RNF-04).

**Why P1**: Every insert in this milestone needs an id.

**Acceptance Criteria**:

1. The app SHALL provide an `IdGenerator` behind a Riverpod provider whose ids are lowercase, hyphenated, 36-character UUID strings with version nibble `7` and the RFC 9562 variant. (ID-01)
2. WHEN 10,000 ids are generated in a row THEN all SHALL be distinct. (ID-02)
3. WHEN a repository inserts a notebook, member, page or block THEN the row's `id` SHALL be the value returned by the `IdGenerator` provider. (ID-03)
4. The files under `app/lib/` other than the `IdGenerator` implementation SHALL NOT reference `Uuid`, enforced by an automated test that scans `lib/`. (ID-04)

**Independent Test**: Unit test parses generated ids and checks version and variant; a repository test with a fake generator finds the fake id in the inserted row.

---

### P1: UTC clock ⭐ MVP

**User Story**: As the developer, I want one source of time in UTC so that dates are deterministic in tests and comparable across devices.

**Why P1**: Every write stamps a date; root invariant "dates in UTC".

**Acceptance Criteria**:

1. The app SHALL provide a `Clock` behind `clockProvider` whose `now()` returns a `DateTime` with `isUtc == true`. (TIME-01)
2. WHEN a `DateTime` is written to any table and read back THEN it SHALL have `isUtc == true` and SHALL equal the written instant to the millisecond. (TIME-02)
3. The files under `app/lib/` other than the `Clock` implementation SHALL NOT call `DateTime.now()`, enforced by an automated test that scans `lib/`. (TIME-03)
4. WHEN the production `Clock` returns a time THEN its microsecond component SHALL be 0, so every stored date has the same text length and text order matches time order. (TIME-04)

**Independent Test**: Write a row with `DateTime.utc(2026, 10, 11, 12, 0, 0, 123)`, read it back and compare; the scan test fails if `DateTime.now()` is added to a repository.

---

### P1: Anonymous local user ⭐ MVP

**User Story**: As a user without an account, I want everything I create signed by one stable local author so that my data moves to my account intact in phase 2 (ADR 0011).

**Why P1**: Authorship columns are `NOT NULL`; no row can be inserted without it.

**Acceptance Criteria**:

1. The schema SHALL include a local-only table `local_user` that holds at most one row with the anonymous user id. (USER-01)
2. WHEN the local user is requested on a database with no `local_user` row THEN the app SHALL generate a UUID v7 with the `IdGenerator`, store it and return it. (USER-02)
3. WHEN the local user is requested again, including after closing and reopening the same database file, THEN the app SHALL return the same id. (USER-03)
4. WHEN two requests for the local user run concurrently on a database with no `local_user` row THEN exactly one row SHALL exist afterwards and both requests SHALL return its id. (USER-04)
5. WHEN a repository writes a row THEN every authorship column it fills (`created_by`, `user_id`, `added_by`, `updated_by`) SHALL hold the local user id. (USER-05)
6. The local user id SHALL NOT be stored in `hive_ce`; the preferences store SHALL keep only `lastOpenedNotebookId` (PREF-05). (USER-06)

**Independent Test**: A file-backed database in a temp directory returns the same id across close and reopen; `Future.wait` on two requests leaves one row.

---

### P1: Fractional index ordering ⭐ MVP

**User Story**: As a user, I want to reorder pages and blocks so that moving one item changes only that item (RF-02).

**Why P1**: Pages are created in order now and reordered in #03; blocks need the same scheme.

**Acceptance Criteria**:

1. The `position` of pages and blocks SHALL be a text key, and lists SHALL be ordered by `position` compared byte-wise, then by `id`. (POS-01)
2. WHEN a key is generated with no neighbors THEN the generator SHALL return a non-empty key. (POS-02)
3. WHEN a key is generated after a key `a` with no right neighbor THEN the new key SHALL be greater than `a`. (POS-03)
4. WHEN a key is generated before a key `b` with no left neighbor THEN the new key SHALL be less than `b`. (POS-04)
5. WHEN a key is generated between keys `a < b` THEN the new key SHALL satisfy `a < key < b`. (POS-05)
6. WHEN 1,000 keys are generated in a row, each between the same left neighbor and the previously generated key, THEN all 1,000 keys SHALL be distinct and SHALL sort in the reverse order of generation. (POS-06)
7. WHEN 1,000 keys are generated in a row, each after the previously generated key, THEN all keys SHALL be distinct and SHALL sort in generation order. (POS-07)
8. IF the generator receives `a >= b` THEN it SHALL throw an `ArgumentError`. (POS-08)
9. WHEN a page or block is moved THEN exactly one row SHALL be updated. (POS-09)

**Independent Test**: Unit tests on the generator for each case; a repository test moves the third of five pages to the first spot and counts one changed row.

---

### P1: Soft delete ⭐ MVP

**User Story**: As a user, I want deleted items to stay recoverable so that the trash (#61) can restore them and phase 2 can sync deletions (RNF-05).

**Why P1**: Root invariant; #61 depends on it.

**Acceptance Criteria**:

1. WHEN a notebook, page or block is deleted THEN the app SHALL set its `deleted_at` to `clock.now()` and the row SHALL remain in its table. (DEL-01)
2. IF an already deleted notebook, page or block is deleted again THEN its `deleted_at` SHALL keep its original value. (DEL-02)
3. The files under `app/lib/` SHALL NOT issue a physical delete on `notebooks`, `notebook_members`, `pages` or `blocks` (Drift `delete`, `deleteWhere`, `deleteAll` or `DELETE FROM`), enforced by an automated test that scans `lib/`. (DEL-03)
4. WHILE a notebook's `deleted_at` is set the active and archived notebook streams SHALL NOT include it. (DEL-04)
5. WHILE a page's `deleted_at` is set the page stream of its notebook SHALL NOT include it and the block stream of that page SHALL be empty. (DEL-05)
6. WHILE a notebook's `deleted_at` is set the page stream of that notebook SHALL be empty and the block streams of its pages SHALL be empty. (DEL-06)
7. WHEN a notebook is deleted THEN no row in `pages` or `blocks` SHALL change. (DEL-07)
8. WHILE a block's `deleted_at` is set the block stream of its page SHALL NOT include it. (DEL-08)

**Independent Test**: Delete a notebook with two pages and three blocks; the notebook row has `deleted_at`, the page and block rows are byte-identical to before, and every stream excludes them.

---

### P1: Repositories and reactive queries ⭐ MVP

**User Story**: As the developer building #03 and #04, I want repositories that expose streams and write through the local database so that screens never touch SQL or the network (RNF-01).

**Why P1**: The screens of #03 and the block persistence of #04 consume them.

**Acceptance Criteria**:

Notebooks:

1. WHEN a notebook is created with a title, cover and color THEN the app SHALL insert, in one transaction, the `notebooks` row and a `notebook_members` row with `role = owner`, `user_id` and `added_by` equal to the local user, and `archived_at` null. (REPO-01)
2. IF the member insert fails while creating a notebook THEN no `notebooks` row SHALL remain. (REPO-02)
3. WHEN a notebook is renamed or its cover or color changes THEN only that notebook's row SHALL change. (REPO-03)
4. WHEN a notebook is archived THEN the app SHALL set `archived_at` to `clock.now()` on the local user's `notebook_members` row and `notebooks.deleted_at` SHALL stay null. (REPO-04)
5. WHEN a notebook is unarchived THEN the app SHALL set `archived_at` to null on the local user's `notebook_members` row. (REPO-05)
6. The active notebooks stream SHALL emit the notebooks with `deleted_at` null whose local user member row has `archived_at` null, ordered by `created_at` descending, then `id` descending. (REPO-06)
7. The archived notebooks stream SHALL emit the notebooks with `deleted_at` null whose local user member row has `archived_at` set, ordered by `archived_at` descending, then `id` descending. (REPO-07)

Pages:

8. WHEN a page is created in a notebook THEN the app SHALL insert it with a position greater than every existing page position in that notebook, deleted pages included, `updated_at` equal to `clock.now()` and `updated_by` equal to the local user. (REPO-08)
9. WHEN a page is renamed THEN the app SHALL update its `title`, `updated_at` and `updated_by`. (REPO-09)
10. WHEN a page is moved to the start, the end or between two pages of its notebook THEN its `position`, `updated_at` and `updated_by` SHALL change and it SHALL appear at that place in the page stream. (REPO-10)
11. The page stream of a notebook SHALL emit its pages with `deleted_at` null, ordered as in POS-01. (REPO-11)
12. WHEN a page is created, renamed, moved or deleted THEN its notebook's row SHALL NOT change. (REPO-12)

Blocks:

13. WHEN a block is created in a page with a `type` and `content_json` THEN the app SHALL insert it at the end of the page, or between the given neighbors, with `version` 0, `updated_at` equal to `clock.now()` and `updated_by` equal to the local user. (REPO-13)
14. WHEN a block's `content_json` is updated THEN the app SHALL update `content_json`, `updated_at` and `updated_by`, and `version` SHALL keep its previous value. (REPO-14)
15. WHEN a block is moved THEN its `version` SHALL keep its previous value. (REPO-15)
16. The block stream of a page SHALL emit its blocks with `deleted_at` null, ordered as in POS-01. (REPO-16)
17. WHEN a block is created, updated, moved or deleted THEN its page's row SHALL NOT change. (REPO-17)

Reactivity and wiring:

18. WHEN a write changes the rows a stream covers THEN that stream SHALL emit the updated list. (REPO-18)
19. The app SHALL expose each repository and each stream through hand-written Riverpod providers built on `databaseProvider`, `clockProvider` and the `IdGenerator` provider, so tests override only those three. (REPO-19)

Titles:

20. WHEN a notebook or page is created or renamed THEN the repository SHALL store the title with leading and trailing whitespace removed. (TITLE-01)
21. IF a notebook is created or renamed with a title that is empty after trimming THEN the repository SHALL throw an `ArgumentError` and no row SHALL change. (TITLE-02)
22. IF a notebook or page is created or renamed with a title longer than 50 grapheme clusters after trimming THEN the repository SHALL throw an `ArgumentError` and no row SHALL change. (TITLE-03)
23. WHEN a page is created or renamed with a title that is empty after trimming THEN the repository SHALL store an empty title. (TITLE-04)
24. WHEN a notebook or page title has exactly 50 grapheme clusters after trimming, including clusters made of several code units (for example `👍🏽`) THEN the repository SHALL store it. (TITLE-05)

**Independent Test**: `expectLater(stream, emitsInOrder([...]))` around create, rename, move, archive and delete, against the in-memory database with a fake clock and id generator.

---

### P1: No network in the app ⭐ MVP

**User Story**: As a user, I want the app never to wait on the network so that it works the same offline (RNF-01).

**Why P1**: Issue #18 checklist; root invariant.

**Acceptance Criteria**:

1. The files under `app/lib/` SHALL NOT import `package:http`, `package:dio` or `dart:io`'s `HttpClient`, enforced by an automated test that scans `lib/`. (NET-01)
2. The `app/pubspec.yaml` SHALL NOT list `http` or `dio` under `dependencies`. (NET-02)

**Independent Test**: Adding `import 'package:http/http.dart';` to a repository makes the scan test fail.

---

### P2: Decision records and docs

**User Story**: As a future contributor, I want each decision in this milestone recorded so that I know why the schema looks this way.

**Why P2**: Required by each issue's DoD; written alongside the implementation.

**Acceptance Criteria**:

1. The `docs/adr/` SHALL contain one new ADR, in Portuguese, in the Contexto/Decisão/Consequências format, for each decision in the "ADRs" assumption row, numbered from 0026. (ADR-01)
2. The `docs/adr/README.md` index SHALL list each new ADR. (ADR-02)
3. The PRD §7 table SHALL list `blocks.deleted_at` and `notebook_members.id`, citing the ADR that adds them. (DOC-01)
4. The `app/CLAUDE.md` "Rules" section SHALL state that the anonymous local user lives in the Drift `local_user` table and that a deleted notebook hides its pages and blocks without writing to them. (DOC-02)
5. The `app/.claude/docs/testes.md` "Migrations" section SHALL no longer say to configure `build.yaml` "once `AppDatabase` exists". (DOC-03)

**Independent Test**: `ls docs/adr/002[6-9]* docs/adr/003[01]*` lists six files linked from the index; `grep local_user app/CLAUDE.md` matches.

---

## Edge Cases

- IF a page is created in a notebook id that does not exist THEN the repository SHALL throw and no row SHALL be inserted.
- WHEN the first page of a notebook is created THEN its position SHALL be the key POS-02 returns.
- WHEN a page is created after the notebook's highest-position page was deleted THEN its position SHALL be greater than the deleted page's position.
- WHEN a notebook is archived and then deleted THEN it SHALL appear in neither the active nor the archived stream.
- IF the database file is closed while a stream is listened to THEN the stream SHALL close without an error event.

---

## Requirement Traceability

| Requirement ID | Story | Tasks | Status |
| --- | --- | --- | --- |
| DB-01 | P1: Drift setup and migrations | T6 | Pending |
| DB-02 | P1: Drift setup and migrations | T5 | Pending |
| DB-03 | P1: Drift setup and migrations | T5, T6 | Pending |
| DB-04 | P1: Drift setup and migrations | T6 | Pending |
| DB-05 | P1: Drift setup and migrations | T6 | Pending |
| DB-06 | P1: Drift setup and migrations | T6 | Pending |
| SCHEMA-01 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-02 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-03 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-04 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-05 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-06 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-07 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-08 | P1: Phase 1 schema | T6 | Pending |
| SCHEMA-09 | P1: Phase 1 schema | T6, T9 | Pending |
| SCHEMA-10 | P1: Phase 1 schema | T6 | Pending |
| ID-01 | P1: UUID v7 ids | T2 | Pending |
| ID-02 | P1: UUID v7 ids | T2 | Pending |
| ID-03 | P1: UUID v7 ids | T9, T11, T13 | Pending |
| ID-04 | P1: UUID v7 ids | T2 | Pending |
| TIME-01 | P1: UTC clock | T1 | Pending |
| TIME-02 | P1: UTC clock | T6 | Pending |
| TIME-03 | P1: UTC clock | T1 | Pending |
| TIME-04 | P1: UTC clock | T1 | Pending |
| USER-01 | P1: Anonymous local user | T6, T7 | Pending |
| USER-02 | P1: Anonymous local user | T7 | Pending |
| USER-03 | P1: Anonymous local user | T7 | Pending |
| USER-04 | P1: Anonymous local user | T7 | Pending |
| USER-05 | P1: Anonymous local user | T9, T11, T13 | Pending |
| USER-06 | P1: Anonymous local user | T15 | Pending |
| POS-01 | P1: Fractional index | T3, T8, T11, T13 | Pending |
| POS-02 | P1: Fractional index | T3, T8 | Pending |
| POS-03 | P1: Fractional index | T3 | Pending |
| POS-04 | P1: Fractional index | T3 | Pending |
| POS-05 | P1: Fractional index | T3 | Pending |
| POS-06 | P1: Fractional index | T3 | Pending |
| POS-07 | P1: Fractional index | T3 | Pending |
| POS-08 | P1: Fractional index | T3 | Pending |
| POS-09 | P1: Fractional index | T11, T13 | Pending |
| DEL-01 | P1: Soft delete | T9, T11, T13 | Pending |
| DEL-02 | P1: Soft delete | T9, T11, T13 | Pending |
| DEL-03 | P1: Soft delete | T6 | Pending |
| DEL-04 | P1: Soft delete | T9 | Pending |
| DEL-05 | P1: Soft delete | T11, T13 | Pending |
| DEL-06 | P1: Soft delete | T11, T13 | Pending |
| DEL-07 | P1: Soft delete | T13 | Pending |
| DEL-08 | P1: Soft delete | T13 | Pending |
| REPO-01 | P1: Repositories | T9 | Pending |
| REPO-02 | P1: Repositories | T9 | Pending |
| REPO-03 | P1: Repositories | T9 | Pending |
| REPO-04 | P1: Repositories | T9 | Pending |
| REPO-05 | P1: Repositories | T9 | Pending |
| REPO-06 | P1: Repositories | T9, T10 | Pending |
| REPO-07 | P1: Repositories | T9, T10 | Pending |
| REPO-08 | P1: Repositories | T11 | Pending |
| REPO-09 | P1: Repositories | T11 | Pending |
| REPO-10 | P1: Repositories | T11 | Pending |
| REPO-11 | P1: Repositories | T11, T12 | Pending |
| REPO-12 | P1: Repositories | T11 | Pending |
| REPO-13 | P1: Repositories | T13 | Pending |
| REPO-14 | P1: Repositories | T13 | Pending |
| REPO-15 | P1: Repositories | T13 | Pending |
| REPO-16 | P1: Repositories | T13, T14 | Pending |
| REPO-17 | P1: Repositories | T13 | Pending |
| REPO-18 | P1: Repositories | T9, T11, T13 | Pending |
| REPO-19 | P1: Repositories | T10, T12, T14 | Pending |
| TITLE-01 | P1: Repositories | T4, T9, T11 | Pending |
| TITLE-02 | P1: Repositories | T4, T9 | Pending |
| TITLE-03 | P1: Repositories | T4, T9, T11 | Pending |
| TITLE-04 | P1: Repositories | T4, T11 | Pending |
| TITLE-05 | P1: Repositories | T4 | Pending |
| NET-01 | P1: No network | T15 | Pending |
| NET-02 | P1: No network | T15 | Pending |
| ADR-01 | P2: Decision records and docs | T16–T21 | Pending |
| ADR-02 | P2: Decision records and docs | T16–T21 | Pending |
| DOC-01 | P2: Decision records and docs | T22 | Pending |
| DOC-02 | P2: Decision records and docs | T23 | Pending |
| DOC-03 | P2: Decision records and docs | T5 | Pending |

**Issue map:** #13 → DB · #14 → SCHEMA, USER, TIME · #15 → ID · #16 → POS · #17 → DEL · #18 → REPO, TITLE, NET · all decision issues → ADR, DOC.

**Coverage:** 78 total, 78 mapped to tasks, 0 unmapped

---

## Success Criteria

- [ ] A v1 database from M01 opens on the new build and passes the v2 `SchemaVerifier` check.
- [ ] Each root invariant listed in `testes.md` "Invariants with a fixed test" that concerns data has a passing test citing its RNF or ADR.
- [ ] #03 can list, create, rename, reorder, archive and delete notebooks and pages using only repository providers.
- [ ] Milestone issues #13–#18 can be closed with their checklists complete.
