# M05 Search and Gate 1 Specification

GitHub milestone [#05 - Search and Gate 1](https://github.com/djotanas/jotline/milestone/6) — issues #25, #26, #27, #28, #29 and #67. Phase 1, last milestone before Gate 1. Decisions taken in discussion: [context.md](context.md).

## Problem Statement

M04 delivered the block editor, but nothing written can be found again except by opening notebooks one by one: RF-05 (Should) asks for local search by title and content. RNF-06 promises no noticeable loading with 10,000 local pages and has never been measured. Gate 1 requires the editor spike done, the schema with members and blocks closed and no data loss in internal use; no automated evidence of "no data loss" exists yet. The drawing block (RF-06, Could) moved here from M04 and now has its own canvas artboard. Local database encryption (RNF-10) must be evaluated before phase 2.

## Goals

- [ ] A user with no account and no network finds any page by words of its title or its text blocks, in every notebook including archived ones, from the "Buscar" button (RF-05, RF-04).
- [ ] With 10,000 local pages, the notebook list, the page list, opening a page and search results show data in less than 100 ms on a mid-range Android device in profile mode (RNF-06).
- [ ] An integrity check runs on every app start and an automated kill test runs 100 times with zero divergence (Gate 1).
- [ ] An ADR decides whether local database encryption enters phase 2 or later, based on a spike with Drift and PowerSync (#28, RNF-10).
- [ ] A user can add, edit and remove a freehand drawing block in a page, saved as JSON in `content_json` (#25, RF-06).
- [ ] The Gate 1 review is recorded in `docs/` with the evidence of each gate criterion (#29).

## Out of Scope

| Feature | Reason |
| --- | --- |
| Searching inside drawings, images or attachments | Drawings hold no text; attachments are phase 2 (RF-11) |
| Search history, suggestions, typo tolerance, ranking by relevance | Not in RF-05 nor in the canvas |
| Search scoped to one notebook | The canvas has a single global search from "Cadernos" |
| Searching pages or notebooks in the trash | The trash has its own screen (RF-12); trashed items stay hidden everywhere else |
| Turning on database encryption in the app | User decision: #28 is spike + ADR only; implementation, if approved, goes to a phase 2 milestone |
| Shape recognition, text in drawings, more colors or widths, zoom and pan in the drawing area | Not in the "Modo desenho: tela cheia" artboard |
| Moving a drawing block with the drag handle | The canvas draws no handle on the drawing card (see Assumptions) |
| Any sync, upload or server work | Phase 2 |
| Kill test on iOS | `adb force-stop` has no iOS equivalent in CI; iOS is covered by the #67 manual checklist |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear. Rows were decided by the user in discussion or proposed and confirmed on spec review (2026-10-17).

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| `.specs/` language | English | Same as M01–M04 | y |
| Drawing block (#25) | In M05, after the user added "Modo desenho: tela cheia" to the canvas | User decision | y |
| Gate 1 (#29) and #67 in the spec | Kill test and startup integrity check are code in the spec; the 2-week internal use, #67 and the gate review in `docs/` are manual exit criteria | User decision | y |
| Encryption (#28) | Spike + ADR; spike code stays on a spike branch, nothing changes in the app on `main` | User decision | y |
| Search matching | Case-insensitive and accent-insensitive, by word prefix: "bele" finds "Belém", "lém" does not | User decision; fits a full-text index with 10,000 pages | y |
| Search empty states | Drawn in the canvas: "Busca — sem termo" and "Busca — sem resultado" | User decision: added to the canvas | y |
| Eraser | Removes the whole stroke it touches | User decision; content stays a list of strokes | y |
| Drawing card on the page | Page width, same aspect ratio as the drawing area, whole drawing scaled with no crop | User decision | y |
| "Cancelar" in drawing mode | Discards the session's changes with no confirmation | User decision; the canvas draws no confirmation | y |
| Removing a drawing block | Erase every stroke and tap "Concluir": the block is soft-deleted | User decision; no new control outside the canvas | y |
| RNF-06 target | Data on screen in < 100 ms after the navigation or query; page list scroll with average frame build time < 16 ms | User decision | y |
| 10,000-page seed | One notebook with 10,000 pages plus 20 notebooks with 100 pages each (12,000 pages); every page has 20 text blocks of ~200 characters | User chose "1 notebook with 10k + 20 notebooks"; the option text did not fix the counts of the 20 | y |
| Several words in the query | Every word must prefix-match a word of the searched fields of the same page (AND); punctuation is ignored | Narrows results as the user types more, like common note apps | y |
| What "Tudo", "Títulos" and "Conteúdo" search | "Títulos": the page title. "Conteúdo": the text of the page's blocks. "Tudo": title and blocks together, so words may be split between them | The canvas script returns every row for "Conteúdo"; that is a mock shortcut, not a rule | y |
| Search start | Results update 150 ms after the last keystroke; the term is trimmed; an empty term shows "sem termo" | Below the 100 ms + debounce budget; avoids a query per keystroke | y |
| Results order and refresh | Most recent "last edited" first (ADR 0037), then `id`; the list is a reactive stream and refreshes when data changes | House rule: the UI consumes reactive streams | y |
| Result date | Same short date format as the page rows' meta ("hoje", "04 out") | The canvas result rows use the page-row style | y |
| Highlight | Every whole word that matched a query word is highlighted with `accent.busca` (the canvas `mark`), in the title and in the excerpt | The canvas marks the whole word "Belém" | y |
| Result excerpt | Shown in "Tudo" and "Conteúdo" only when a block matched: plain text of the first matching block in `position` order, cut around the first match, with "…" at cut ends, at most 2 lines | The canvas shows "…a pastelaria abre às 8h; Belém fica cheio…" | y |
| Untitled page in results | "Sem título" in the muted style, as in the page rows | M03 rule | y |
| Back from a result | Returns to the search with the term, the filter and the scroll position kept | Common search flow; the canvas links result → page only | y |
| Drawing area size | Logical area of 390 × 560 (the artboard's drawing area); on screen it is fitted, centered, into the space between header and tools; stroke points are stored in logical coordinates | Same drawing on every screen size; matches the user's "aspect ratio of the area" choice | y |
| Drawing tools and defaults | Caneta (default), Marca-texto, Borracha; widths fino 3, médio 6, grosso 12 (default fino); colors Tinta preta `ink.1`, Azul `accent`, Terracota `danger` (default Tinta preta); Marca-texto draws 3× the width at 35 % opacity | Values from the artboard; the three colors match existing tokens | y |
| Persisted drawing identifiers | Block `type` `drawing`; tool ids `pen`, `highlighter`; color ids `ink`, `accent`, `danger`; recorded in a new ADR that extends ADR 0036 | Persisted values need stable ids; ADR 0036 cannot be edited | y |
| Where a new drawing goes | "Desenho" in the block bar opens the drawing mode; on "Concluir" with at least one stroke, the drawing block is inserted after the block with the cursor, or in its place if that block is an empty block with no row | Same insertion rule as other block types | y |
| Undo / redo in drawing mode | One step per stroke drawn or erased; history lives only while the drawing mode is open | The artboard has "Desfazer traço" and "Refazer traço" | y |
| App goes to background in drawing mode | The current strokes are saved (except a new drawing with no stroke); a later "Cancelar" writes back the content the drawing had when the mode opened | Gate 1: no data loss; keeps "Cancelar" meaning "discard this session" | y |
| Drawing card label | "Desenho" for screen readers | The artboard label describes its sample drawing; the app cannot describe a user drawing | y |
| Kill test expectation | After a force-stop and relaunch, every block whose save had completed before the kill is present and identical, no row is partially written, and the integrity check passes; text typed in the last 500 ms before the kill may be missing | A force-stop skips the background flush (M04 SAVE rules), so the debounce window is the expected loss | y |
| Kill test runner | A host script on Android (emulator in CI, or device) using `adb shell am force-stop` at a random delay, 100 iterations | `integration_test` cannot kill and relaunch its own process | y |
| Integrity check output | Runs after the first frame, never blocks the UI; writes one line per run (date UTC, app version, pass/fail, violated invariant and ids) to a local log file in the app support directory; no UI | Issue #29: "logged locally"; RNF-01 | y |
| A missed RNF-06 target | No fix loop: work on the target stops, and the user gets a report of each missed measurement, what was tried and the friction found; the user decides the next step | User decision (2026-10-17) | y |
| Gate review document | `docs/gates/gate-1.md`, in Portuguese, one section per gate criterion with evidence links | PRD and ADRs are in Portuguese; `docs/` holds project documents | y |
| ADRs | In Portuguese, from 0038: (1) local search approach; (2) drawing block format; (3) local database encryption | Each issue's DoD; existing ADRs are not edited | y |

**Open questions:** none - all resolved and confirmed.

---

## Canvas references

Canvas "Jotline design", version `1792290140-31c0` (2026-10-17).

| Area | Artboards |
| --- | --- |
| Entry point | Cadernos (RF-01) → "Buscar" icon button in the top bar |
| Search | Busca local (RF-05) · Busca — sem termo · Busca — sem resultado |
| Drawing | Modo desenho: tela cheia · Editor de blocos (RF-03, RF-06) → drawing card and "Desenho" bar button |

---

## User Stories

### P1: Local search ⭐ MVP

**User Story**: As a user, I want to search every notebook by words in page titles and content so that I find a note without remembering where I wrote it (RF-05, RF-04).

**Why P1**: The milestone's main user feature; the "Buscar" button and the archived-notebook copy ("As páginas continuam na busca") already promise it.

**Acceptance Criteria**:

1. WHEN the user taps "Buscar" on the Cadernos screen THEN the system SHALL open the search screen with the field focused, empty, with the placeholder "Buscar em todos os cadernos" and the "Tudo" filter selected. (SRCH-01)
2. WHILE the trimmed term is empty the search screen SHALL show the "Busque em todos os cadernos" empty state from the canvas and no count line. (SRCH-02)
3. WHEN 150 ms pass after the last change of a non-empty term THEN the system SHALL show the matching pages and the count line "1 página" or "N páginas". (SRCH-03)
4. The system SHALL match each query word against the start of words, ignoring case and diacritics, so that "bele" and "BELEM" find "Belém" and "lém" does not. (SRCH-04)
5. WHEN the term has several words THEN the system SHALL return only pages where every word matches within the selected filter's fields. (SRCH-05)
6. WHILE "Títulos" is selected the system SHALL match only the page title and SHALL show no excerpt line. (SRCH-06)
7. WHILE "Conteúdo" is selected the system SHALL match only the text of the page's blocks. (SRCH-07)
8. WHILE "Tudo" is selected the system SHALL match the title and the blocks' text of the page together. (SRCH-08)
9. The search SHALL include pages of archived notebooks and SHALL exclude deleted pages, pages of deleted notebooks, deleted blocks and drawing blocks. (SRCH-09)
10. The results SHALL be ordered by the page's "last edited" (ADR 0037), most recent first, then by `id`. (SRCH-10)
11. Each result row SHALL show the notebook color spine, the notebook title, "·", the page's "last edited" date in the page-row date format, and the page title, as drawn in "Busca local". (SRCH-11)
12. WHEN a page has no title THEN its result row SHALL show "Sem título" in the muted style. (SRCH-12)
13. WHEN a block of the page matched and the filter is "Tudo" or "Conteúdo" THEN the row SHALL show an excerpt of at most 2 lines from the first matching block in `position` order, cut around the first match with "…" at each cut end. (SRCH-13)
14. The system SHALL highlight every whole word that matched a query word, in the title and in the excerpt, with the `accent.busca` mark style. (SRCH-14)
15. WHEN no page matches THEN the screen SHALL show the "Nenhuma página encontrada" empty state with the term quoted in its text, as in "Busca — sem resultado". (SRCH-15)
16. WHEN the user taps a result THEN the system SHALL open that page in the editor, and going back SHALL return to the search with the same term, filter and scroll position. (SRCH-16)
17. WHEN the user taps "Cancelar" THEN the system SHALL return to the Cadernos screen. (SRCH-17)
18. WHEN a block or title is saved THEN a search started afterwards SHALL find the page by the new text and SHALL NOT find it by text that was removed. (SRCH-18)
19. WHEN the app upgrades from schema version 2 THEN every existing page SHALL be searchable without the user editing it. (SRCH-19)
20. WHILE the search screen is open and the matching data changes THEN the result list SHALL refresh without a new keystroke. (SRCH-20)
21. The search SHALL read only the local database and SHALL work with no network (RNF-01). (SRCH-21)

**Independent Test**: Repository test with an in-memory database: pages "Onde comer em Belém", a page with a block "Belém cedo", one in an archived notebook and one in the trash → "bele" returns three pages in "last edited" order, "Títulos" returns one, the trashed one never. Widget test: type "belém", pump 150 ms → count "3 páginas", marks on "Belém"; type "passaporte" → "Nenhuma página encontrada".

---

### P1: Performance with 10,000 pages ⭐ MVP

**User Story**: As a heavy user, I want lists, pages and search to open instantly with thousands of pages so that the app never makes me wait (RNF-06).

**Why P1**: RNF-06 is a phase 1 promise; search adds a new query path that must meet it too.

**Acceptance Criteria**:

1. The repository SHALL have a seed tool, outside the release app, that fills a local database with one notebook of 10,000 pages and 20 notebooks of 100 pages, each page with 20 text blocks of about 200 characters, through the same tables and invariants as the app. (LOAD-01)
2. WHEN the seeded app opens THEN the notebook list SHALL show data in less than 100 ms after the first frame, measured in profile mode on a mid-range Android device. (LOAD-02)
3. WHEN the user opens the 10,000-page notebook THEN the page list SHALL show data in less than 100 ms after the navigation, measured in the same setup. (LOAD-03)
4. WHILE the user scrolls the 10,000-page list the average frame build time SHALL be below 16 ms, measured in the same setup. (LOAD-04)
5. WHEN the user opens a page of the seeded database THEN its blocks SHALL be rendered in less than 100 ms after the navigation, measured in the same setup. (LOAD-05)
6. WHEN the user searches a word present in every page THEN the first results SHALL be shown in less than 100 ms after the 150 ms debounce, measured in the same setup. (LOAD-06)
7. The query plans of the notebook list, page list, page open and search queries SHALL use an index and SHALL NOT scan the `pages` or `blocks` tables in full, checked by a test with `EXPLAIN QUERY PLAN`. (LOAD-07)
8. The measurements SHALL be recorded in the M05 PR with the device model and Android version. (LOAD-08)
9. IF a measurement misses its target THEN work on that target SHALL stop and the user SHALL receive a report with the measured value, the target, what was tried and the friction found, and the next step SHALL be the user's decision. (LOAD-09)

**Independent Test**: Run the seed tool, then the profile-mode perf driver on the device: the timeline summary shows each target met; the `EXPLAIN QUERY PLAN` test passes in CI.

---

### P1: Startup integrity check ⭐ MVP

**User Story**: As the developer, I want the app to verify its database on every start so that any corruption or broken invariant in internal use leaves evidence (Gate 1, #29).

**Why P1**: Gate 1 cannot pass on "no data loss" without a detector.

**Acceptance Criteria**:

1. WHEN the app starts THEN the system SHALL run `PRAGMA integrity_check` and the invariant checks after the first frame, without delaying it. (INTEG-01)
2. The check SHALL fail when a notebook not deleted has no `owner` row in `notebook_members`. (INTEG-02)
3. The check SHALL fail when a page references a notebook that does not exist. (INTEG-03)
4. The check SHALL fail when a block references a page that does not exist. (INTEG-04)
5. The check SHALL fail when two pages not deleted of the same notebook, or two blocks not deleted of the same page, have the same `position`. (INTEG-05)
6. WHEN the check ends THEN the system SHALL append one line to the local integrity log with the UTC date, app version, `pass` or `fail`, and for each failure the invariant name and the ids involved. (INTEG-06)
7. IF the check itself throws THEN the system SHALL log the error as a failure line and the app SHALL keep running. (INTEG-07)
8. The integrity check SHALL NOT write to any synced table. (INTEG-08)

**Independent Test**: Database test: a clean database → one `pass` line; insert a page with an unknown `notebook_id` and two blocks with the same `position` → one `fail` line naming `orphan_page` and `duplicate_position` with their ids.

---

### P1: Automated kill test ⭐ MVP

**User Story**: As the developer, I want to kill the app at random moments while it writes and compare the database after relaunch so that data loss is caught before anyone uses the app (Gate 1, #29).

**Why P1**: Gate 1 criterion; manual use alone does not cover random kill timing.

**Acceptance Criteria**:

1. The repository SHALL have a kill test that, on Android, launches an instrumented build that types scripted text into pages, force-stops it with `adb shell am force-stop` at a random delay, relaunches it and compares the database with the expected content. (KILL-01)
2. The expected content SHALL be every block whose save completed before the kill, with its `type` and `content_json` identical. (KILL-02)
3. WHEN the app relaunches after a kill THEN the integrity check SHALL pass. (KILL-03)
4. The kill test SHALL run 100 iterations and report the number of divergences, the seed of each random delay and, for each divergence, the expected and actual content. (KILL-04)
5. IF any iteration diverges THEN the kill test SHALL exit with a non-zero code. (KILL-05)
6. The kill test SHALL record its 100-iteration result in the M05 PR. (KILL-06)

**Independent Test**: Run the script on an emulator: "100/100 iterations, 0 divergences"; inject a fault that drops a saved block on startup → the script exits non-zero and prints the divergent block.

---

### P1: Gate 1 review

**User Story**: As the product owner, I want a recorded review of every Gate 1 criterion so that phase 2 starts on evidence, not memory (#29, PRD §9).

**Why P1**: Closing phase 1 is the milestone's name.

**Acceptance Criteria**:

1. The repository SHALL have `docs/gates/gate-1.md`, in Portuguese, with one section per Gate 1 criterion: editor spike done, schema with members and blocks closed, no data loss in internal use. (GATE-01)
2. The "no data loss" section SHALL link the kill test result, the integrity log summary of the internal-use period, the period dates and device, and the list of issues labeled `data-loss` with their outcome. (GATE-02)
3. The "editor spike" section SHALL link ADR 0035 and the #67 results on iPhone and physical Android. (GATE-03)
4. The "schema closed" section SHALL list the schema version and the ADRs that define notebooks, members, pages and blocks, including the drawing block format. (GATE-04)
5. IF a criterion is not met THEN the document SHALL say so and Gate 1 SHALL NOT be marked as passed. (GATE-05)
6. WHEN #67 finds a failure in the SPIKE-06 checklist THEN a new ADR SHALL supersede ADR 0035 before Gate 1 is marked as passed. (GATE-06)

**Independent Test**: Review: the document exists with three sections, every link resolves, and the verdict matches the evidence.

---

### P2: Local database encryption evaluation

**User Story**: As the product owner, I want a recorded evaluation of encrypting the local database so that phase 2 knows whether to include it (#28, RNF-10, PRD §11).

**Why P2**: A decision before phase 2, with no user-facing change now.

**Acceptance Criteria**:

1. The spike SHALL evaluate SQLCipher (or an equivalent the spike finds) with the pinned Drift version, on a spike branch that is not merged into `main`. (CRYPT-01)
2. The spike SHALL record whether the chosen option works with PowerSync's SQLite setup on Flutter, citing the PowerSync documentation or a prototype. (CRYPT-02)
3. The spike SHALL record the cost of migrating an existing unencrypted database, the key storage option, the app size increase and the time of LOAD-03 and LOAD-06 with the 10,000-page seed encrypted and not encrypted. (CRYPT-03)
4. WHEN the spike ends THEN the repository SHALL have an ADR in Portuguese deciding whether encryption enters phase 2 or later, and PRD §11's open question SHALL be marked with that ADR. (CRYPT-04)
5. The app on `main` SHALL keep its unencrypted database in M05. (CRYPT-05)

**Independent Test**: Review: the ADR has a table with CRYPT-02 and CRYPT-03 per option; `git log main -- app/pubspec.yaml` shows no encryption dependency.

---

### P3: Freehand drawing block

**User Story**: As a user, I want to draw by hand in a page so that I can sketch maps and diagrams next to my notes (RF-06, #25).

**Why P3**: RF-06 is Could; it reuses the editor and the block model without changing them.

**Acceptance Criteria**:

1. The block bar SHALL show the "Desenho" button, as drawn in "Editor de blocos". (DRAW-01)
2. WHEN the user taps "Desenho" THEN the system SHALL open the full-screen drawing mode from "Modo desenho: tela cheia" with an empty drawing area. (DRAW-02)
3. The drawing area SHALL have a logical size of 390 × 560, fitted and centered in the space between the header and the tools, and stroke points SHALL be stored in logical coordinates. (DRAW-03)
4. The drawing mode SHALL offer the tools Caneta, Marca-texto and Borracha, the widths fino 3, médio 6 and grosso 12, and the colors Tinta preta (`ink.1`), Azul (`accent`) and Terracota (`danger`), with Caneta, fino and Tinta preta selected when it opens. (DRAW-04)
5. WHEN the user drags a finger or stylus with Caneta THEN the system SHALL draw a stroke with `perfect_freehand` in the selected color and width. (DRAW-05)
6. WHEN the user drags with Marca-texto THEN the stroke SHALL be drawn at 3 times the selected width with 35 % opacity. (DRAW-06)
7. WHEN the Borracha touches a stroke THEN the whole stroke SHALL be removed. (DRAW-07)
8. WHEN the user taps "Desfazer traço" THEN the last stroke drawn or erased in the session SHALL be undone, and "Refazer traço" SHALL redo it. (DRAW-08)
9. WHILE there is nothing to undo or redo the matching button SHALL be disabled, as drawn for "Refazer traço". (DRAW-09) This supersedes COMP-03 (M01): `JotIconButton` renders the disabled state, in `inkDeco`, when `onPressed` is null.
10. WHEN the user taps "Concluir" on a new drawing with at least one stroke THEN the system SHALL insert a `drawing` block after the block with the cursor, or in its place if that block is empty and has no row, in one write. (DRAW-10)
11. WHEN the user taps "Concluir" on a new drawing with no stroke THEN no block SHALL be created. (DRAW-11)
12. The page SHALL show a drawing block as a card at page width with the drawing area's aspect ratio, the whole drawing scaled with no crop, styled as the drawing card in "Editor de blocos", labeled "Desenho" for screen readers. (DRAW-12)
13. WHEN the user taps a drawing card THEN the system SHALL open the drawing mode with that drawing's strokes. (DRAW-13)
14. WHEN the user taps "Concluir" on an existing drawing that has strokes THEN the system SHALL update the block's `content_json` and `updated_at` and SHALL NOT change `version`. (DRAW-14)
15. WHEN the user taps "Concluir" on an existing drawing with every stroke removed THEN the system SHALL soft-delete the block. (DRAW-15)
16. WHEN the user taps "Cancelar" THEN the system SHALL leave the drawing as it was when the mode opened, with no confirmation. (DRAW-16)
17. WHEN the app goes to background in drawing mode THEN the system SHALL save the current strokes, except for a new drawing with no stroke. (DRAW-17)
18. WHEN the user taps "Cancelar" after a background save THEN the system SHALL write back the content the drawing had when the mode opened, or soft-delete the block if the drawing was new. (DRAW-18)
19. The drawing `content_json` SHALL contain only the list of strokes, each with tool id, color id, width and points `[x, y, pressure]` in logical coordinates, with no field from the drawing library. (DRAW-19)
20. The page excerpt and the search SHALL ignore drawing blocks. (DRAW-20)

**Independent Test**: Widget test with an in-memory database: tap "Desenho", draw two strokes, erase one, tap "Concluir" → one `drawing` row with one stroke in logical coordinates; tap the card, erase it, "Concluir" → row soft-deleted; reopen a drawing, draw, "Cancelar" → `content_json` unchanged.

---

### P3: Decision records and docs

**User Story**: As the developer, I want the milestone's decisions recorded so that phase 2 builds on them (#26, #25, #28 DoD).

**Why P3**: Process requirement; no user behavior.

**Acceptance Criteria**:

1. The repository SHALL have an ADR in Portuguese for the local search approach (index, normalization, prefix matching, how it stays current), linked from the search code's design. (ADR-01)
2. The repository SHALL have an ADR in Portuguese for the drawing block: type `drawing`, the stroke format of DRAW-19 and the persisted tool and color ids. (ADR-02)
3. WHEN a schema change is made THEN `schemaVersion` SHALL be bumped with a tested migration from version 2 (ADR 0015). (DOC-01)
4. WHEN M05 adds a doc under `app/.claude/docs/` THEN `app/CLAUDE.md` "References" SHALL list it in the same commit (ADR 0014). (DOC-02)
5. The `app/CLAUDE.md` commands SHALL list how to run the seed tool, the RNF-06 perf driver and the kill test. (DOC-03)

**Independent Test**: Review: ADRs exist and are linked; migration test passes; `app/CLAUDE.md` lists the new commands.

---

## Edge Cases

- IF the term has only punctuation or spaces between words THEN the search SHALL treat it as the words it contains, and as an empty term when it contains none. (EDGE-01)
- IF the term contains characters that the full-text query syntax treats as operators (`"`, `*`, `-`, `OR`, `NEAR`) THEN the search SHALL treat them as plain text and SHALL NOT throw. (EDGE-02)
- WHEN a matching word appears in a bold or italic range THEN the excerpt SHALL show it as plain text with the highlight. (EDGE-03)
- WHEN the first match is in the first or last characters of a long block THEN the excerpt SHALL show no "…" on the side that is not cut. (EDGE-04)
- IF the user taps "Cancelar" in search while results are loading THEN no error SHALL be shown. (EDGE-05)
- WHEN a drawing has a stroke with a single point THEN it SHALL be drawn as a dot. (EDGE-06)
- IF a drawing block's `content_json` cannot be parsed THEN the card SHALL show an empty drawing area and SHALL NOT crash the page. (EDGE-07)
- WHEN the integrity log file does not exist THEN the check SHALL create it. (EDGE-08)

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| SRCH-01 | P1: Local search | Design | Pending |
| SRCH-02 | P1: Local search | Design | Pending |
| SRCH-03 | P1: Local search | Design | Pending |
| SRCH-04 | P1: Local search | Design | Pending |
| SRCH-05 | P1: Local search | Design | Pending |
| SRCH-06 | P1: Local search | Design | Pending |
| SRCH-07 | P1: Local search | Design | Pending |
| SRCH-08 | P1: Local search | Design | Pending |
| SRCH-09 | P1: Local search | Execute | Implementing |
| SRCH-10 | P1: Local search | Execute | Implementing |
| SRCH-11 | P1: Local search | Design | Pending |
| SRCH-12 | P1: Local search | Design | Pending |
| SRCH-13 | P1: Local search | Design | Pending |
| SRCH-14 | P1: Local search | Design | Pending |
| SRCH-15 | P1: Local search | Design | Pending |
| SRCH-16 | P1: Local search | Design | Pending |
| SRCH-17 | P1: Local search | Design | Pending |
| SRCH-18 | P1: Local search | Execute | Implementing |
| SRCH-19 | P1: Local search | Execute | Implementing |
| SRCH-20 | P1: Local search | Design | Pending |
| SRCH-21 | P1: Local search | Design | Pending |
| LOAD-01 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-02 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-03 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-04 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-05 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-06 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-07 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-08 | P1: Performance with 10,000 pages | Design | Pending |
| LOAD-09 | P1: Performance with 10,000 pages | Design | Pending |
| INTEG-01 | P1: Startup integrity check | Design | Pending |
| INTEG-02 | P1: Startup integrity check | Design | Pending |
| INTEG-03 | P1: Startup integrity check | Design | Pending |
| INTEG-04 | P1: Startup integrity check | Design | Pending |
| INTEG-05 | P1: Startup integrity check | Design | Pending |
| INTEG-06 | P1: Startup integrity check | Design | Pending |
| INTEG-07 | P1: Startup integrity check | Design | Pending |
| INTEG-08 | P1: Startup integrity check | Design | Pending |
| KILL-01 | P1: Automated kill test | Design | Pending |
| KILL-02 | P1: Automated kill test | Design | Pending |
| KILL-03 | P1: Automated kill test | Design | Pending |
| KILL-04 | P1: Automated kill test | Design | Pending |
| KILL-05 | P1: Automated kill test | Design | Pending |
| KILL-06 | P1: Automated kill test | Design | Pending |
| GATE-01 | P1: Gate 1 review | - | Pending |
| GATE-02 | P1: Gate 1 review | - | Pending |
| GATE-03 | P1: Gate 1 review | - | Pending |
| GATE-04 | P1: Gate 1 review | - | Pending |
| GATE-05 | P1: Gate 1 review | - | Pending |
| GATE-06 | P1: Gate 1 review | - | Pending |
| CRYPT-01 | P2: Local database encryption evaluation | - | Pending |
| CRYPT-02 | P2: Local database encryption evaluation | - | Pending |
| CRYPT-03 | P2: Local database encryption evaluation | - | Pending |
| CRYPT-04 | P2: Local database encryption evaluation | - | Pending |
| CRYPT-05 | P2: Local database encryption evaluation | - | Pending |
| DRAW-01 | P3: Freehand drawing block | Design | Pending |
| DRAW-02 | P3: Freehand drawing block | Design | Pending |
| DRAW-03 | P3: Freehand drawing block | Design | Pending |
| DRAW-04 | P3: Freehand drawing block | Design | Pending |
| DRAW-05 | P3: Freehand drawing block | Design | Pending |
| DRAW-06 | P3: Freehand drawing block | Design | Pending |
| DRAW-07 | P3: Freehand drawing block | Design | Pending |
| DRAW-08 | P3: Freehand drawing block | Design | Pending |
| DRAW-09 | P3: Freehand drawing block | Design | Pending |
| DRAW-10 | P3: Freehand drawing block | Design | Pending |
| DRAW-11 | P3: Freehand drawing block | Design | Pending |
| DRAW-12 | P3: Freehand drawing block | Design | Pending |
| DRAW-13 | P3: Freehand drawing block | Design | Pending |
| DRAW-14 | P3: Freehand drawing block | Design | Pending |
| DRAW-15 | P3: Freehand drawing block | Design | Pending |
| DRAW-16 | P3: Freehand drawing block | Design | Pending |
| DRAW-17 | P3: Freehand drawing block | Design | Pending |
| DRAW-18 | P3: Freehand drawing block | Design | Pending |
| DRAW-19 | P3: Freehand drawing block | Design | Pending |
| DRAW-20 | P3: Freehand drawing block | Design | Pending |
| ADR-01 | P3: Decision records and docs | - | Pending |
| ADR-02 | P3: Decision records and docs | - | Pending |
| DOC-01 | P3: Decision records and docs | Execute | Implementing |
| DOC-02 | P3: Decision records and docs | - | Pending |
| DOC-03 | P3: Decision records and docs | - | Pending |
| EDGE-01 | Edge cases | Design | Pending |
| EDGE-02 | Edge cases | Design | Pending |
| EDGE-03 | Edge cases | Design | Pending |
| EDGE-04 | Edge cases | Design | Pending |
| EDGE-05 | Edge cases | Design | Pending |
| EDGE-06 | Edge cases | Design | Pending |
| EDGE-07 | Edge cases | Design | Pending |
| EDGE-08 | Edge cases | Design | Pending |

**Coverage:** 88 total, 0 mapped to tasks, 88 unmapped ⚠️ (tasks come after Design)

---

## Success Criteria

- [ ] "bele" finds "Belém" in titles and content across active and archived notebooks, offline.
- [ ] Every RNF-06 target is met and recorded with the device model, or each miss is reported to the user with its friction and a decision recorded.
- [ ] Kill test: 100/100 iterations with 0 divergences.
- [ ] Two weeks of internal use with zero confirmed `data-loss` issues and only `pass` lines in the integrity log.
- [ ] An encryption ADR answers PRD §11's open question.
- [ ] A drawing survives "Concluir", reopening the app and editing again.
- [ ] `docs/gates/gate-1.md` records Gate 1 as passed, or says which criterion is missing.
