# M04 Block Editor Specification

GitHub milestone [#04 - Block editor](https://github.com/djotanas/jotline/milestone/5) — issues #22, #23 and #24; #25 moved to #05. Phase 1. Decisions taken in discussion: [context.md](context.md).

## Problem Statement

M03 left every page on a minimal screen with a title and an empty body: nothing can be written in a page yet. RF-03 (Must) asks for a block editor with rich text, headings, lists and checklist, and ADR 0005 requires each block to be its own `blocks` row so that phase 2 resolves conflicts per block. The editor library is still open (PRD §11), so this milestone first runs the 1-week spike that picks it, then builds the editor on the page screen from the "Editor de blocos" artboard and saves every block locally while the user types (RF-03, RF-04, RNF-01).

## Goals

- [x] An ADR records the editor library chosen by a spike that compared `flutter_quill`, `appflowy_editor` and `super_editor` against the block model (#22).
- [x] A user with no account and no network can write paragraphs, headings, bulleted lists and checklists with bold and italic in a page, and every block is stored as one `blocks` row (RF-03, RF-04, ADR 0005).
- [x] No edit is lost when the app goes to background or is closed from the app switcher mid-typing, and the UI never waits on a write (#24, RNF-01).
- [x] The page list shows each page's excerpt and a "last edited" date that includes block edits.
- [x] The time from tapping the app icon to a new page open with the editor is measured and recorded (PRD §2, #21 follow-up).

## Out of Scope

| Feature | Reason |
| --- | --- |
| Freehand drawing block and the "Desenho" bar button (#25, RF-06 Could) | User decision: the "Fase 1 — telas" canvas has no drawing mode; #25 moves to milestone #05 |
| Images and attachments | RF-11, phase 2 |
| Editor undo/redo | Not in the canvas bar; the bar is the only editing UI drawn |
| Numbered lists, nested lists, more than one heading level | The canvas draws one heading style and one bulleted list |
| Trash and restore for single blocks | No block trash in the canvas; the page trash (M03) is the way back for a page |
| Local search over block content and the "Buscar" button | #26 (M05) |
| 10,000-page load test (RNF-06) | #27 (M05) |
| Rendering block types written by other app versions | Phase 1 has a single writer of blocks; mixed versions only exist with sync (phase 2) |
| Rich-text paste (formatting from other apps) | Not in RF-03; paste keeps only the text |
| Sync, `version` handling beyond keeping it unchanged | Phase 2 (ADR 0013) |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear. Rows were decided by the user in discussion or proposed and confirmed on spec review (2026-10-12).

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| `.specs/` language | English | Same as M01–M03 | y |
| Spec scope with the editor still open | The whole milestone; behavior is library-independent; the spike is the first P1 story; Design starts after the editor ADR | User decision | y |
| Block granularity | One `blocks` row per paragraph, heading, list item and checklist item | User decision; ADR 0005: different items of the same list never conflict | y |
| Page "last edited" | Latest of `pages.updated_at`, and of `updated_at` and `deleted_at` of the page's blocks, computed at query time; block writes never touch the page row | User decision; keeps M02 REPO-17; `moveToTrash` on a block writes only `deleted_at` | y |
| Drawing block (#25) | Out of M04; "Desenho" hidden in the bar | User decision: no drawing-mode artboard in "Fase 1 — telas" | y |
| Which milestone receives #25 | #05 - Search and Gate 1 | User decision on spec review | y |
| Source of layout and copy | The "Jotline design" canvas, version `1791837644-ae99` (2026-10-12): "Editor de blocos (RF-03, RF-06)", "Componentes" → "Blocos do editor · RF-03" and "Barra de blocos", "Páginas do caderno (RF-02)", "Páginas sem trecho, M03" | `app/.claude/docs/design.md`: the canvas wins | y |
| Block types | Four: text (paragraph), heading, bulleted list item, checklist item; persisted `type` identifiers fixed in the block model ADR | The canvas bar without "Desenho"; one heading style (19 px, 600) and one bulleted list drawn | y |
| `content_json` format | Our own JSON per block (text plus bold/italic ranges, and `checked` for checklist items), not the library's internal document format; plain text is extractable without the editor library | Changing the library later must not migrate data; search (#26) and the excerpt read text without the editor; RNF-12 spirit | y |
| Marks on headings | Bold and italic apply to every block type | The bar does not disable them for "Título" | y |
| Enter | At the end of a block: new block below; a list or checklist item continues the same type (unchecked), any other type continues as text. In the middle: splits the block, the text after the cursor goes to the new block. On an empty list or checklist item: turns it into text | Common editor convention; the canvas does not draw it | y |
| Backspace at the start of a block | A list item, checklist item or heading turns into text; a text block merges into the block above (that block keeps its id, this one is soft-deleted); on the first block it does nothing | Common editor convention; keeps the surviving id stable for phase 2 | y |
| Empty page | No block row exists until the user types the first character; the body shows no placeholder text; tapping the empty area below the title puts the cursor in an empty text block | Canvas has no empty-editor state; avoids inventing copy; no empty rows synced in phase 2 | y |
| Title → body | Enter in the title moves the cursor to the start of the first block (an empty text block on an empty page) | Natural flow after "Nova página" focuses the title (M03 PGLIST-05) | y |
| Block bar visibility | Shown while a block has the cursor, docked above the keyboard; hidden while the title has focus or nothing has focus | The bar acts on the block with the cursor; the canvas draws it with a block in edit | y |
| Save timing | 500 ms after the last change in the page, and immediately when leaving the page or when the app goes to background | Same rule as the M03 page title; closing from the app switcher always passes through background | y |
| Page excerpt | Plain text of the first block in `position` order, not deleted, of type text, list item or checklist item, with non-empty text after trimming; one line with ellipsis; no excerpt line when none exists | The canvas excerpt of "Roteiro — dia 2" skips the "Manhã" heading; "Páginas sem trecho" shows the row without the line | y |
| Moving a block | Long press on the drag handle of the block with the cursor drags it; the drop saves one row through `Placement` | The canvas draws the handle on the block in edit; ADR 0029 | y |
| Selection across blocks | Deleting or typing over a selection that spans blocks updates the first block with the joined text and soft-deletes every other block in the selection | User decision after the spike (2026-10-12): it is how `super_editor` merges; no physical delete (RNF-05) | y |
| Paste | Pasted text keeps line breaks as separate text blocks and drops outside formatting | Plain paste only (Out of Scope) | y |
| Drag handle size | As drawn in the canvas, inside the 12 px bleed of the block in edit, even though its touch target is below 44 × 44 | User decision after the spike (2026-10-12): the canvas layout wins over the touch-target minimum | y |
| Drag handle label | "Mover bloco" | The canvas handle is decorative (`aria-hidden`); page rows use "Mover <title>", which a block has no equivalent for | y |
| Empty new block of any type | No row until its first character, for list and checklist items too; an empty item left untyped is gone on reopen | User decision on design review (2026-10-12): one rule for every type | y |
| Save debounce scope | One 500 ms timer per page; every edit restarts it; one flush writes every changed block in one transaction | User decision on design review (2026-10-12): a split or merge is saved atomically | y |
| Checkbox drawing | 22 × 22 with existing tokens: unchecked 1.5 px `lineForte` border, radius `rEtiqueta`, on `bgFolha`; checked `accent` fill with the check glyph in `bgFolha` | User decision on design review (2026-10-12): the canvas draws a native checkbox with no tokens | y |
| Text length | No limit per block or per page in phase 1 | RF-03 sets none; the 10,000-page load is tested in #27 | y |
| Spike code | Prototypes live on a spike branch that is not merged; only the ADR, the `app/CLAUDE.md` editor line and the comparison go to `main` | The issue asks for a decision, not code; avoids shipping two editors | y |
| Spike outcome when no candidate meets every mandatory criterion | The ADR records the gap and the user decides before #23 starts (another library or a custom editor) | CLAUDE.md: ask before inferring | y |
| SPIKE-06 without iOS or physical Android | ADR 0035 accepted with iOS not verified and Android only on the emulator; the manual checklist runs in #67 (milestone #05, before Gate 1); a failure leads to a new ADR | User decision after the spike (2026-10-12): no device available | y |
| PERF-01 repeat | From the icon tap to a new page open with the editor rendered and the title focused, in profile mode on the same mid-range Android device as M03 | M03 context: "repeated to the editor cursor in M04" | y |
| ADRs | In Portuguese, from 0035: (1) editor library (spike result); (2) block model: one row per item, type identifiers, `content_json` format; (3) page "last edited" derived from blocks | Each issue's DoD; ADR 0005 and 0013 are not edited | y |

**Open questions:** none - all resolved and confirmed.

---

## Canvas references

| Area | Artboards / sections |
| --- | --- |
| Editor | Editor de blocos (RF-03, RF-06) |
| Components | Componentes → Blocos do editor · RF-03 · Barra de blocos |
| Page list | Páginas do caderno (RF-02) · Páginas sem trecho, M03 |

Not drawn and covered by assumptions: empty page with the editor, block being dragged, bar above the keyboard.

---

## User Stories

### P1: Editor library spike ⭐ MVP

**User Story**: As the developer, I want to compare the three candidate editors against the block model in a time-boxed spike so that the editor choice is recorded before any editor code ships (#22, PRD §11).

**Why P1**: #23 and #24 depend on the chosen library; the CLAUDE.md forbids adopting one without an ADR.

**Acceptance Criteria**:

1. The spike SHALL evaluate `flutter_quill`, `appflowy_editor` and `super_editor`, each with a prototype on the pinned Flutter version (`.fvmrc`), within 5 working days. (SPIKE-01)
2. The spike SHALL record, per candidate, whether its document can be read from and written to one row per block, keeping a block's id when its text changes, giving a new id to the block created by a split, and keeping the upper block's id on a merge. (SPIKE-02)
3. The spike SHALL record, per candidate, whether the change of a single block can be detected without serializing the whole page. (SPIKE-03)
4. The spike SHALL record, per candidate, whether each block round-trips through our `content_json` format with no loss of text, bold, italic, type and `checked`. (SPIKE-04)
5. The spike SHALL record, per candidate, whether the four block types, bold, italic, checklist toggling and a custom block widget (needed by #25 later) are supported. (SPIKE-05)
6. The spike SHALL record, per candidate, whether typing accented pt-BR text with autocorrect and composing input works on an Android device and on an iOS simulator. (SPIKE-06)
7. The spike SHALL record, per candidate, the license, the date of the latest release and whether the canvas block styling (in-edit background, drag handle, checked style) can be applied. (SPIKE-07)
8. WHEN the spike ends THEN the repository SHALL have an ADR in Portuguese with the comparison table, the chosen library and the reasons. (SPIKE-08)
9. WHEN the editor ADR is accepted THEN the "Block editor" line of `app/CLAUDE.md` SHALL name the chosen library and the ADR. (SPIKE-09)
10. IF no candidate meets SPIKE-02, SPIKE-04 and SPIKE-06 on the devices available THEN the ADR SHALL record the gap and #23 SHALL NOT start until the user decides the next step; criteria not verifiable for lack of a device SHALL be recorded as not verified and tracked in an issue. (SPIKE-10)
11. The spike prototypes SHALL NOT be merged into `main`. (SPIKE-11)

**Independent Test**: Review: the ADR exists with one row per candidate covering SPIKE-02 to SPIKE-07; `app/CLAUDE.md` names the library; `git log main` has no prototype code.

---

### P1: Write in a page ⭐ MVP

**User Story**: As a user, I want to write text in a page below its title so that the page holds my notes (RF-03, RF-04).

**Why P1**: The core of the product; replaces the M03 empty body.

**Acceptance Criteria**:

1. The page screen SHALL show, below the title and the "Editada" line, the page's blocks not deleted, ordered by `position` then `id`, keeping the M03 header (back button with the notebook title, ⋯). (EDIT-01)
2. WHILE a block has the cursor it SHALL be drawn with the canvas in-edit style: Realce background, radius `r.bloco` (10), bleeding 12 px past the text, and the drag handle at its left. (EDIT-02)
3. Text blocks SHALL use the canvas paragraph style (Literata 17, line height 1.55) and headings the canvas heading style (Schibsted Grotesk 19, weight 600). (EDIT-03)
4. WHEN the user taps the empty area below the last block, or below the title on an empty page, THEN the cursor SHALL be placed in an empty text block at the end of the page. (EDIT-04)
5. WHILE a new block of any type has not received any character no `blocks` row SHALL exist for it. (EDIT-05)
6. WHEN the user presses Enter in the title THEN the cursor SHALL move to the start of the first block, or to an empty text block on an empty page. (EDIT-06)
7. WHEN the user presses Enter at the end of a text or heading block THEN a new text block SHALL be created below it with the cursor in it. (EDIT-07)
8. WHEN the user presses Enter in the middle of a block THEN the block SHALL be split: the text before the cursor stays in the block and the text after it goes to a new block of the same type below. (EDIT-08)
9. WHEN the user presses Backspace at the start of a text block that has a block above THEN the two blocks SHALL be merged into the upper one, with the cursor at the junction. (EDIT-09)
10. WHEN the user presses Backspace at the start of the first block THEN nothing SHALL change. (EDIT-10)
11. WHEN the user pastes text with line breaks THEN each line SHALL become a text block, with no formatting from the source. (EDIT-11)
12. The page screen SHALL keep the M03 title, "Editada" line and options behavior (PAGE-01, PAGE-03 to PAGE-07, PGOPT-01 to PGOPT-05). (EDIT-12)

**Independent Test**: Widget test with an in-memory database: new page → no block rows; tap the body and type "Olá" → one text row; Enter in the middle → two rows with the split text; Backspace at the start of the second → one row, the second soft-deleted.

---

### P1: Block bar and block types ⭐ MVP

**User Story**: As a user, I want a bar to turn a block into a heading, a list item or a checklist item and to apply bold and italic so that my notes have structure (RF-03).

**Why P1**: RF-03 Must: "texto rico, títulos, listas, checklist".

**Acceptance Criteria**:

1. WHILE a block has the cursor the system SHALL show the block bar from the canvas above the keyboard, with "Texto", "Título", "Lista", "Checklist", "Negrito" and "Itálico", each 48 × 48 with its accessible label. (BAR-01)
2. WHILE the title has focus or nothing has focus the block bar SHALL be hidden. (BAR-02)
3. The block bar SHALL NOT show the "Desenho" button in this milestone. (BAR-03)
4. The type button matching the block with the cursor SHALL be drawn as active (Tinta clara background, icon in Tinta funda) and exposed as pressed to accessibility; the other type buttons SHALL be inactive. (BAR-04)
5. WHEN the user taps a type button THEN the block with the cursor SHALL change to that type, keeping its text, marks and id. (BAR-05)
6. WHEN a block changes from checklist item to another type THEN its `checked` state SHALL be dropped. (BAR-06)
7. WHEN the user taps "Negrito" or "Itálico" with text selected THEN the mark SHALL be toggled on the selected range. (BAR-07)
8. WHEN the user taps "Negrito" or "Itálico" with no selection THEN the mark SHALL be toggled for the text typed next at the cursor. (BAR-08)
9. WHILE the cursor or the whole selection is inside bold or italic text the matching button SHALL be drawn as active and exposed as pressed. (BAR-09)
10. Bold text SHALL use weight 600 and italic text the Literata italic face, as in the canvas. (BAR-10)
11. Bulleted list items SHALL be drawn with a bullet and a 24 px indent; consecutive list items SHALL be drawn 4 px apart, as in the canvas. (BAR-11)

**Independent Test**: Widget test: type "Manhã", tap "Título" → same row, heading type, "Título" pressed; select a word, tap "Negrito" → `content_json` has a bold range over it and "Negrito" pressed.

---

### P1: Checklist ⭐ MVP

**User Story**: As a user, I want checklist items I can tick so that I track small tasks inside a page (RF-03).

**Why P1**: RF-03 Must.

**Acceptance Criteria**:

1. Each checklist item SHALL show a 22 × 22 checkbox before its text inside a row at least 44 px tall. (CHECK-01)
2. WHEN the user taps the checkbox THEN the item's `checked` state SHALL toggle and be saved, without moving the cursor into the text. (CHECK-02)
3. WHILE an item is checked its text SHALL be drawn in the Riscado color with a strikethrough. (CHECK-03)
4. WHEN the user presses Enter at the end of a checklist item THEN a new unchecked checklist item SHALL be created below it. (CHECK-04)
5. WHEN the user presses Enter at the end of a list item THEN a new list item SHALL be created below it. (CHECK-05)
6. WHEN the user presses Enter or Backspace on an empty list or checklist item THEN that block SHALL turn into a text block. (CHECK-06)
7. WHEN the user presses Backspace at the start of a non-empty list item, checklist item or heading THEN that block SHALL turn into a text block, keeping its text. (CHECK-07)
8. Each checkbox SHALL expose its item text and checked state to accessibility. (CHECK-08)

**Independent Test**: Widget test: three checklist items, tap the second checkbox → only that row's `content_json` changes, `checked` true, strikethrough shown.

---

### P1: Block persistence ⭐ MVP

**User Story**: As a user, I want everything I write to be saved on the device as I type so that nothing is lost when I close the app (#24, RF-04, RNF-01).

**Why P1**: Without it the editor is a scratchpad.

**Acceptance Criteria**:

1. Each paragraph, heading, list item and checklist item SHALL be stored as exactly one `blocks` row of the page. (SAVE-01)
2. WHEN 500 ms pass after the last change in the page THEN the system SHALL save the `type` and `content_json` of every block changed since the last save through the block repository, in one transaction. (SAVE-02)
3. WHEN the user leaves the page or the app goes to background with unsaved changes THEN the system SHALL save them before the screen closes. (SAVE-03)
4. WHEN a block is saved THEN its `updated_at` SHALL be `clock.now()` and its `updated_by` the local user, and its `version` SHALL keep its previous value (ADR 0013). (SAVE-04)
5. WHEN the user edits one block THEN no other `blocks` row and no `pages` row SHALL change. (SAVE-05)
6. WHEN a block is split THEN the original row SHALL keep its id and a new row SHALL be inserted right after it with `Placement` between it and its next sibling. (SAVE-06)
7. WHEN two blocks are merged THEN the upper row SHALL keep its id with the joined content and the lower row SHALL get `deleted_at`. (SAVE-07)
8. WHEN a selection spanning several blocks is deleted or typed over THEN the first block SHALL be updated with the joined text and every other block in the selection SHALL get `deleted_at`. (SAVE-08)
9. The editor SHALL NOT issue a physical delete on `blocks`. (SAVE-09)
10. The `content_json` of every block SHALL be our own format holding the text, the bold and italic ranges and, for checklist items, `checked`, with no field from the editor library's internal model. (SAVE-10)
11. WHEN a page is opened again THEN its blocks SHALL show the same types, text, marks, `checked` states and order as when it was left. (SAVE-11)
12. While the user types, no frame SHALL wait on a database write. (SAVE-12)
13. WHEN the app is closed from the app switcher right after typing THEN the next launch SHALL show the typed text. (SAVE-13)

**Independent Test**: Widget test with a fake clock: type in block A, pump 500 ms → only A's row updated, `version` unchanged, page row byte-identical; type again and send the app to background at once → row has the latest text; rebuild the screen → same content.

---

### P1: Page "last edited" from blocks ⭐ MVP

**User Story**: As a user, I want a page's "Editada" date to change when I write in it so that recent pages come first (RF-01, RF-02).

**Why P1**: Without it, writing in a page leaves its date and the notebook order stale.

**Acceptance Criteria**:

1. A page's last edited instant SHALL be the latest of its `pages.updated_at` and the `updated_at` and `deleted_at` of all its blocks, including deleted ones. (EDITED-01)
2. The "Editada" line, the page row date, the "Opções da página" sheet date and the notebook "last edited" meta SHALL use the page's last edited instant. (EDITED-02)
3. WHILE "Editados recentemente" is selected the notebooks SHALL be ordered by the latest last edited instant among their pages not in the trash, or `created_at` with none (replaces the date used by M03 SORT-03). (EDITED-03)
4. WHEN a block is created, updated, moved or deleted THEN every date in EDITED-02 SHALL update without leaving the screen. (EDITED-04)
5. The page list order SHALL stay by `position`, not by last edited. (EDITED-05)

**Independent Test**: Database test: page edited yesterday, a block saved today → the page and its notebook report today; the `pages` row is unchanged.

---

### P2: Page excerpt in the list

**User Story**: As a user, I want to see the first line of each page in the notebook so that I find a page without opening it (RF-02).

**Why P2**: Drawn in the canvas; the list works without it (M03).

**Acceptance Criteria**:

1. Each `PageRow` SHALL show, below the title and date, the excerpt: the trimmed plain text of the first block by `position`, not deleted, of type text, list item or checklist item, whose trimmed text is not empty. (EXCERPT-01)
2. The excerpt SHALL be one line in the canvas excerpt style (Literata 14, muted), cut with an ellipsis. (EXCERPT-02)
3. IF a page has no such block THEN its row SHALL show no excerpt line, as in "Páginas sem trecho, M03". (EXCERPT-03)
4. The excerpt SHALL skip heading blocks. (EXCERPT-04)
5. WHEN the first qualifying block changes THEN the excerpt SHALL update without leaving the list. (EXCERPT-05)

**Independent Test**: Widget test: page with heading "Manhã" then text "Belém cedo" → excerpt "Belém cedo"; page with only a heading → no excerpt line.

---

### P2: Move a block

**User Story**: As a user, I want to drag a block to another place in the page so that I reorganize my notes (RF-03).

**Why P2**: Drawn in the canvas (drag handle); writing works without it.

**Acceptance Criteria**:

1. WHILE a block has the cursor its drag handle SHALL be visible with the accessible label "Mover bloco". (BMOVE-01)
2. WHEN the user long-presses the handle and drops the block in a new place THEN the system SHALL save the move through the block repository with a `Placement` relative to its new neighbors, changing only that row. (BMOVE-02)
3. WHEN the user drops the block where it started THEN the system SHALL write nothing. (BMOVE-03)
4. WHILE a block is being dragged it SHALL be drawn with `shadow.erguido`. (BMOVE-04)

**Independent Test**: Widget test: three blocks, drag the last to the top → only its `position` changed; reopen → new order.

---

### P2: Offline flows and launch time

**User Story**: As a user, I want the editor to work with no network and the app to open a new page fast so that I can write anywhere (RF-04, PRD §2).

**Why P2**: The P1 stories cover behavior; this story adds the end-to-end proof and the measurement.

**Acceptance Criteria**:

1. The `integration_test/` folder SHALL have an e2e test, run with no network access, that creates a page, writes a heading, a paragraph with bold and italic, a list and a checklist, ticks an item, leaves and reopens the page, and finds the same content (RF-03). (E2E-01)
2. WHEN the e2e flows run THEN no screen SHALL wait on or call the network (RNF-01). (E2E-02)
3. The time from tapping the app icon to a new page open with the editor rendered and the title focused SHALL be measured in profile mode on a mid-range Android device and recorded in the M04 PR with the device model. (PERF-01)
4. IF the measured time is 1 second or more THEN the PR SHALL open a follow-up issue with the measurement. (PERF-02)

**Independent Test**: `fvm flutter test integration_test` on an emulator in airplane mode; manual measurement recorded in the PR.

---

### P3: Decision records and docs

**User Story**: As the developer, I want this milestone's decisions recorded so that the next milestones do not reopen them.

**Why P3**: Documentation; the code does not depend on it.

**Acceptance Criteria**:

1. The repository SHALL have new ADRs in Portuguese, numbered from 0035, for: the editor library (SPIKE-08); the block model (one row per item, type identifiers, `content_json` format); the page last edited derived from blocks. (ADR-01)
2. The `app/.claude/docs/design.md` component table SHALL list the "Blocos do editor" and "Barra de blocos" widgets, and drop the note that keeps them out of scope, in the same commit as the widgets. (DOC-01)
3. The `app/.claude/docs/testes.md` e2e table SHALL list the editor flow (RF-03) in the same commit as its test. (DOC-02)
4. The PRD §11 open question "Qual editor de blocos adotar?" SHALL be marked resolved, citing the editor ADR. (DOC-03)

**Independent Test**: Review the files; `ls docs/adr` shows the new ADRs.

---

## Edge Cases

- IF the page open in the editor is deleted while it is open THEN the screen SHALL save pending block changes and return to the notebook page list (M03 EDGE-03). (EDGE-01)
- WHILE the page's notebook is archived the user SHALL be able to edit its blocks (M03 ARCH-05). (EDGE-02)
- IF a block's text contains emoji or other multi-code-unit characters THEN splitting, merging and applying marks SHALL never cut a grapheme cluster. (EDGE-03)
- IF all the text of a block is deleted THEN the block SHALL stay as an empty row until it is merged or removed with Backspace, not be deleted on its own. (EDGE-04)
- WHEN the user deletes every block of a page THEN the page SHALL show the empty state of EDIT-04 and its excerpt SHALL disappear. (EDGE-05)
- IF a page in the trash is restored (M03 TRASH-08) THEN its blocks SHALL reappear unchanged. (EDGE-06)
- IF a block's text has leading or trailing spaces THEN they SHALL be stored as typed; only the excerpt trims them. (EDGE-07)

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| SPIKE-01 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-02 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-03 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-04 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-05 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-06 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-07 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-08 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-09 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-10 | P1: Editor library spike | Spike | ✅ Verified |
| SPIKE-11 | P1: Editor library spike | Spike | ✅ Verified |
| EDIT-01 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-02 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-03 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-04 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-05 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-06 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-07 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-08 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-09 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-10 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-11 | P1: Write in a page | Execute | ✅ Verified |
| EDIT-12 | P1: Write in a page | Execute | ✅ Verified |
| BAR-01 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-02 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-03 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-04 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-05 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-06 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-07 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-08 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-09 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-10 | P1: Block bar and block types | Execute | ✅ Verified |
| BAR-11 | P1: Block bar and block types | Execute | ✅ Verified |
| CHECK-01 | P1: Checklist | Execute | ✅ Verified |
| CHECK-02 | P1: Checklist | Execute | ✅ Verified |
| CHECK-03 | P1: Checklist | Execute | ✅ Verified |
| CHECK-04 | P1: Checklist | Execute | ✅ Verified |
| CHECK-05 | P1: Checklist | Execute | ✅ Verified |
| CHECK-06 | P1: Checklist | Execute | ✅ Verified |
| CHECK-07 | P1: Checklist | Execute | ✅ Verified |
| CHECK-08 | P1: Checklist | Execute | ✅ Verified |
| SAVE-01 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-02 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-03 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-04 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-05 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-06 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-07 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-08 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-09 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-10 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-11 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-12 | P1: Block persistence | Execute | ✅ Verified |
| SAVE-13 | P1: Block persistence | Execute | ✅ Verified |
| EDITED-01 | P1: Page "last edited" from blocks | Execute | ✅ Verified |
| EDITED-02 | P1: Page "last edited" from blocks | Execute | ✅ Verified |
| EDITED-03 | P1: Page "last edited" from blocks | Execute | ✅ Verified |
| EDITED-04 | P1: Page "last edited" from blocks | Execute | ✅ Verified |
| EDITED-05 | P1: Page "last edited" from blocks | Execute | ✅ Verified |
| EXCERPT-01 | P2: Page excerpt in the list | Execute | ✅ Verified |
| EXCERPT-02 | P2: Page excerpt in the list | Execute | ✅ Verified |
| EXCERPT-03 | P2: Page excerpt in the list | Execute | ✅ Verified |
| EXCERPT-04 | P2: Page excerpt in the list | Execute | ✅ Verified |
| EXCERPT-05 | P2: Page excerpt in the list | Execute | ✅ Verified |
| BMOVE-01 | P2: Move a block | Execute | ✅ Verified |
| BMOVE-02 | P2: Move a block | Execute | ✅ Verified |
| BMOVE-03 | P2: Move a block | Execute | ✅ Verified |
| BMOVE-04 | P2: Move a block | Execute | ✅ Verified |
| E2E-01 | P2: Offline flows and launch time | Execute | ✅ Verified |
| E2E-02 | P2: Offline flows and launch time | Execute | ✅ Verified |
| PERF-01 | P2: Offline flows and launch time | Execute | ✅ Verified |
| PERF-02 | P2: Offline flows and launch time | Execute | ✅ Verified |
| ADR-01 | P3: Decision records and docs | Execute | ✅ Verified |
| DOC-01 | P3: Decision records and docs | Execute | ✅ Verified |
| DOC-02 | P3: Decision records and docs | Execute | ✅ Verified |
| DOC-03 | P3: Decision records and docs | Execute | ✅ Verified |
| EDGE-01 | Edge cases | Execute | ✅ Verified |
| EDGE-02 | Edge cases | Execute | ✅ Verified |
| EDGE-03 | Edge cases | Execute | ✅ Verified |
| EDGE-04 | Edge cases | Execute | ✅ Verified |
| EDGE-05 | Edge cases | Execute | ✅ Verified |
| EDGE-06 | Edge cases | Execute | ✅ Verified |
| EDGE-07 | Edge cases | Execute | ✅ Verified |

**Coverage:** 84 total, 84 mapped (see `tasks.md`), 84 verified (`validation.md`)

---

## Success Criteria

- [x] The editor ADR is accepted before any editor code is merged.
- [x] The E2E-01 flow passes on an emulator with no network.
- [x] Zero physical `DELETE` statements in `app/lib/` (RNF-05) and zero writes to `blocks.version` by the app (ADR 0013).
- [ ] Every artboard in "Canvas references" has a screen or state that matches it.
- [ ] The launch-to-new-page time with the editor is recorded in the M04 PR.
