# M03 Notebooks and Pages Specification

GitHub milestone [#03 - Notebooks and pages](https://github.com/djotanas/jotline/milestone/4) — issues #19, #20, #21 and #61. Phase 1. Decisions taken in discussion: [context.md](context.md).

## Problem Statement

M02 left the local data model and its repositories ready, but the app still opens on an empty `Scaffold`: there is no way to create, open, rename, archive, delete or restore a notebook or a page. This milestone builds the phase 1 notebook, page and trash screens from the "Jotline design" canvas on top of the M02 repositories, fully offline and without an account (RF-01, RF-02, RF-04, RF-12). The block editor is not decided yet (#22), so a page opens on a minimal screen that M04 completes.

## Goals

- [ ] A user with no account and no network can create, rename, recolor, archive, unarchive, sort and delete notebooks, and create, rename, reorder and delete pages, with every change stored in the local database (RF-01, RF-02, RF-04).
- [ ] Every deletion is reversible, by the undo toast or from the trash, and nothing is physically deleted (RF-12, RNF-05).
- [ ] Every screen and state in scope matches its canvas artboard, and every main flow has an e2e test (ADR 0015).
- [ ] The time from tapping the app icon to a new page being open is measured and recorded (PRD §2, #21).

## Out of Scope

| Feature | Reason |
| --- | --- |
| Block editor, page body, block bar, page excerpt in the list | M04 (#22–#24); the editor ADR comes first |
| Local search screen and the "Buscar" button behavior | #26 (Local search) |
| 10,000-page load test (RNF-06) | #27 |
| "Empty trash" and physical deletion | ADR 0023: does not exist in phase 1; server cleanup is #47 |
| Trash for blocks | No block UI before M04 |
| Moving a page to another notebook | Not in RF-02 or in the canvas |
| Sync status, account and login screens | Phase 2 |
| Dark theme | Only the light theme exists (M01) |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear. Rows were decided by the user in discussion, come straight from the updated canvas, or were proposed and confirmed on spec review (2026-10-12).

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| `.specs/` language | English | Same as M01 and M02 | y |
| Source of layout and copy | The "Jotline design" canvas, version `1791824928-b73d` (2026-10-12), artboards listed in "Canvas references" | `app/.claude/docs/design.md`: the canvas wins; the canvas was updated for this milestone before the spec | y |
| What opens a page before the editor exists | Minimal page screen (artboard "Página mínima, sem editor (M03)"): back to the notebook, ⋯ options, inline title, "Editada …" line, empty body | User decision; M04 replaces only the body | y |
| Rename UI | Notebook: "Renomear caderno" dialog; page: inline title on the minimal page and "Renomear página" dialog; cover and color: the "Novo caderno" sheet in edit mode ("Capa e cor") | Drawn in the updated canvas | y |
| Trash "Páginas" section | Lists only pages deleted on their own whose notebook is not in the trash; restoring a page never touches its notebook | User decision; answers the open question of ADR 0023 / ADR 0027, recorded in a new ADR | y |
| Undo toast duration | 3 seconds, paused while the user holds a finger on the toast | User decision; answers the open question of ADR 0024, recorded in a new ADR | y |
| Which actions show an undo toast | Delete page, delete notebook (after the dialog), archive, unarchive, restore from the trash | Drawn in the updated canvas (artboards "Após arquivar", "Após excluir caderno", "Lixeira: restaurado") | y |
| Notebook "last edited" date | The latest `pages.updated_at` among the notebook's pages not in the trash; `notebooks.created_at` when it has none | User decision; `notebooks` has no `updated_at` (M02) | y |
| #21 measurement | Measured from the icon tap to the minimal page of a new page being open; repeated to the editor cursor in M04 | User decision | y |
| Sort options | "Editados recentemente" (last edited, newest first), "Nome (A–Z)", "Data de criação" (newest first); one choice for both tabs; stored on the device | Drawn in the updated canvas ("Ordenar cadernos"); replaces the M02 fixed order | y |
| Default sort | "Editados recentemente" | It is the initial state of the canvas sheet | y |
| Name order | Case- and accent-insensitive (pt-BR): "árvore" sorts with "arvore", before "Bloco"; ties by `id` | The canvas prototype uses `localeCompare(..., 'pt-BR')` | y |
| Sort preference storage | A second `hive_ce` key next to `lastOpenedNotebookId`; an unknown or missing value falls back to the default | `app/CLAUDE.md` puts device-only UI preferences in `hive_ce`; M01's PREF-05 ("only `lastOpenedNotebookId`") is extended by this milestone, not edited | y |
| What the app opens on launch | The "Cadernos" screen; `lastOpenedNotebookId` is written when a notebook opens but not used to reopen it in M03 | Issue #21: "App opens straight into notebooks"; reopening the last notebook is deferred (user decision on spec review) | y |
| "Buscar" button in the header | Hidden until #26 | A button that does nothing breaks "no dead ends"; search ships in #26 | y |
| Relative dates | Device local time, pt-BR: same day "hoje"; previous day "ontem"; 2–6 days ago the weekday abbreviation ("seg", "ter", "qua", "qui", "sex", "sáb", "dom"); older in the same year "d MMM" with no zero padding ("2 out"); other years "d MMM yyyy" ("2 out 2025"). With a verb: "hoje" and "ontem" follow the verb directly ("arquivado hoje"), the others take "em" ("criado em 2 out", "excluído em seg") | The canvas mixes "2 out", "08 out" and "arquivado em ago"; one rule keeps every screen consistent | y |
| Page count text | "nenhuma página", "1 página", "N páginas" | Canvas shows "nenhuma página" and "12 páginas"; singular added | y |
| Page title field limit | The inline title and the "Renomear página" field stop at 50 characters and show the "N/50" counter from 40, like the notebook name | The canvas draws the counter only for notebooks; the repository rejects page titles over 50 (M02) | y |
| When the inline page title is saved | 500 ms after the last keystroke, and immediately when leaving the screen or the app goes to background | No text is lost if the app is killed; avoids one write per keystroke | y |
| "Nova página" | Creates the page at the end of the notebook with an empty title, opens the minimal page with the title focused; an untitled page stays as "Sem título" | Canvas: "Nova página" leads to the minimal page with the title in edit; RF-04: nothing waits for input to be stored | y |
| Reordering and "last edited" | Moving a page updates its `updated_at` (M02 repository), so it counts as an edit for the page date and the "Editados recentemente" order | M02 decision: a move is a write that phase 2 syncs | y |
| Undo of a restore | Puts the item back in the trash with its original `deleted_at` | The trash shows when the item was deleted; undo must not change it | y |
| "Desarquivar" in the options sheet | Returns to "Cadernos" on the "Ativos" tab with the toast "Caderno de volta à lista principal" | The canvas links the option to "Cadernos" and shows that toast for the list button | y |
| Trash order | Each section by `deleted_at` desc, then `id` desc | Most recent deletion first, same rule as the canvas example | y |
| Undo after the screen changes | The toast belongs to the screen where it appears; leaving that screen dismisses it without undoing | Undo stays where the user acted; the trash is the way back afterwards | y |
| Navigation | Chosen in Design (Navigator or a router package) | Technical decision; no ADR yet | y |
| ADRs | In Portuguese, from 0032: (1) undo toast: 3 s, paused while held, and the actions that show it; (2) trash "Páginas" section; (3) notebook sorting: options, default, storage | Each issue's DoD; ADRs 0023, 0024 and 0027 are not edited | y |

**Open questions:** none - all resolved and confirmed.

---

## Canvas references

| Area | Artboards |
| --- | --- |
| Cadernos | Cadernos (RF-01) · Cadernos: primeira abertura · Arquivados vazio · Ordenar cadernos · Após arquivar: desfazer · Após excluir caderno: desfazer |
| Novo caderno | Novo caderno: capa e cor · Novo caderno: nome perto do limite · Capa e cor: edição |
| Caderno | Páginas do caderno (RF-02) · Opções do caderno · Renomear caderno · Caderno arquivado aberto · Opções: desarquivar · Caderno sem páginas · Páginas sem trecho, M03 · Página excluída: desfazer |
| Página | Página mínima, sem editor (M03) · Opções da página · Renomear página |
| Lixeira | Lixeira local (RF-12) · Lixeira: restaurado, desfazer |

---

## User Stories

### P1: Notebooks screen ⭐ MVP

**User Story**: As a user without an account, I want to open the app straight into my notebooks so that I can start writing with no login and no network (RF-01, RF-04).

**Why P1**: Every other screen starts here.

**Acceptance Criteria**:

1. WHEN the app starts THEN the system SHALL show the "Cadernos" screen as the first screen, with no login or onboarding screen before it. (NBLIST-01)
2. WHILE the user has at least one notebook (active or archived) the "Cadernos" screen SHALL show the "Ativos · N" and "Arquivados · N" tabs, where N is the number of notebooks in each list. (NBLIST-02)
3. WHILE the "Ativos" tab is selected the screen SHALL show every active notebook not in the trash as a `NotebookCoverTile` in a two-column grid, with its cover, color, title and the meta "<page count> · <last edited>". (NBLIST-03)
4. WHILE the "Arquivados" tab is selected the screen SHALL show the explanation "Arquivar tira o caderno da lista principal sem apagar nada. As páginas continuam na busca." and every archived notebook not in the trash as an `ArchivedNotebookRow` with the meta "<page count> · arquivado <date>" and a "Desarquivar" button. (NBLIST-04)
5. IF the user has no notebook THEN the screen SHALL show the empty state "Nenhum caderno ainda" / "Crie o primeiro para começar a escrever. Tudo fica neste aparelho, mesmo sem internet." and SHALL hide the tabs and the "Ordenar" button. (NBLIST-05)
6. IF the "Arquivados" tab is selected and there is no archived notebook THEN the screen SHALL show the empty state "Nenhum caderno arquivado" / "Arquivar tira um caderno da lista sem apagar nada. Use as opções do caderno, no ⋯.". (NBLIST-06)
7. WHEN a notebook, page or membership row changes in the database THEN the grid, the rows, the tab counts and the metas SHALL update without leaving the screen. (NBLIST-07)
8. WHEN the user taps an active tile or an archived row THEN the system SHALL open that notebook's page list. (NBLIST-08)
9. WHEN the user taps the trash button in the header THEN the system SHALL open the "Lixeira" screen. (NBLIST-09)
10. The header SHALL NOT show the "Buscar" button in this milestone. (NBLIST-10)

**Independent Test**: Widget test with an in-memory database: no rows → empty state; insert notebooks and archive one → tab counts, grid and archived row; tap a tile → page list.

---

### P1: Create a notebook ⭐ MVP

**User Story**: As a user, I want to create a notebook with a name, a color and a cover so that I can organize my pages like paper notebooks (RF-01).

**Why P1**: Without it, there is nothing to put pages in.

**Acceptance Criteria**:

1. WHEN the user taps "Novo caderno" THEN the system SHALL open the "Novo caderno" sheet with an empty "Nome" field, "Azul tinta" selected under "Cor", "Lisa" selected under "Capa", and a cover preview labeled "Nome do caderno". (NBNEW-01)
2. WHEN the user types a name, picks a color or picks a cover THEN the preview SHALL show that name, color and cover. (NBNEW-02)
3. WHILE the trimmed name is empty the "Criar caderno" button SHALL be disabled. (NBNEW-03)
4. The "Nome" field SHALL accept at most 50 grapheme clusters. (NBNEW-04)
5. WHILE the name has 40 or more characters the sheet SHALL show the counter "N/50" next to the "Nome" label. (NBNEW-05)
6. WHEN the user taps "Criar caderno" THEN the system SHALL create the notebook with the trimmed name, the chosen color and cover, and the local user as owner, and SHALL open the new notebook's page list. (NBNEW-06)
7. WHEN the user taps "Cancelar" or outside the sheet THEN the system SHALL close the sheet and write nothing. (NBNEW-07)

**Independent Test**: Widget test: open the sheet, check defaults, type 40 characters → counter, type spaces only → disabled, create → one `notebooks` row and one `owner` member row, page list open.

---

### P1: Notebook page list ⭐ MVP

**User Story**: As a user, I want to see, create and open the pages of a notebook so that I can write in it (RF-02).

**Why P1**: The core of the notebook.

**Acceptance Criteria**:

1. WHEN a notebook opens THEN the screen SHALL show the back button "Cadernos", the "Reordenar" and ⋯ buttons, the notebook cover, its title and the page count, and its pages not in the trash as `PageRow`s ordered by `position`. (PGLIST-01)
2. Each `PageRow` SHALL show the page title, or "Sem título" in the muted style when the title is empty, and the page's `updated_at` as a relative date, with no excerpt. (PGLIST-02)
3. IF the notebook has no pages THEN the screen SHALL show the empty state "Nenhuma página ainda" / "Toque em Nova página para começar.", the count "nenhuma página", and SHALL hide the "Reordenar" button. (PGLIST-03)
4. WHILE the notebook is archived the header SHALL show the "Arquivado" badge below the page count. (PGLIST-04)
5. WHEN the user taps "Nova página" THEN the system SHALL create a page with an empty title at the end of the notebook and SHALL open it on the minimal page screen with the title field focused. (PGLIST-05)
6. WHEN the user taps a page row THEN the system SHALL open that page on the minimal page screen. (PGLIST-06)
7. WHEN a notebook opens THEN the system SHALL write its id to `lastOpenedNotebookId`. (PGLIST-07)
8. WHEN the user taps "Cadernos" THEN the system SHALL return to the "Cadernos" screen. (PGLIST-08)

**Independent Test**: Widget test: notebook with no pages → empty state; tap "Nova página" → one page row at the end and the minimal page open; go back → "Sem título" row with "hoje".

---

### P1: Reorder pages ⭐ MVP

**User Story**: As a user, I want to drag pages into the order I want so that the notebook reads like I organized it (RF-02).

**Why P1**: RF-02 Must.

**Acceptance Criteria**:

1. WHEN the user taps "Reordenar" THEN the screen SHALL enter reorder mode: the button reads "Concluir", the hint "Arraste pela alça para mudar a ordem." appears, each row shows a drag handle labeled "Mover <title>", and "Nova página" is hidden. (REORDER-01)
2. WHILE a row is being dragged it SHALL be drawn as a `DraggingPageRow`. (REORDER-02)
3. WHEN the user drops a page in a new place THEN the system SHALL save the move through the page repository with a `Placement` relative to its new neighbors, changing only that page's row. (REORDER-03)
4. WHEN the user drops a page in the place it started THEN the system SHALL write nothing. (REORDER-04)
5. WHEN the user taps "Concluir" THEN the screen SHALL leave reorder mode and the order SHALL stay as dropped. (REORDER-05)
6. WHEN the notebook page list is opened again THEN the pages SHALL appear in the order left by the last move. (REORDER-06)

**Independent Test**: Widget test: three pages, drag the last to the first place → only that row's `position` changed, list reads in the new order after reopening.

---

### P1: Minimal page screen ⭐ MVP

**User Story**: As a user, I want to open a page and give it a title so that I can create and name pages before the editor arrives (RF-02).

**Why P1**: Pages need a screen to open on; M04 adds the body.

**Acceptance Criteria**:

1. The minimal page screen SHALL show a back button with the notebook title, the ⋯ options button, the page title field with the placeholder "Sem título", and the line "Editada <relative date>, HH:mm" from the page's `updated_at`. (PAGE-01)
2. The minimal page screen SHALL NOT show the block bar or any block. (PAGE-02)
3. WHEN the user edits the title and stops typing for 500 ms THEN the system SHALL save the trimmed title through the page repository. (PAGE-03)
4. WHEN the user leaves the screen or the app goes to background with an unsaved title THEN the system SHALL save it before the screen closes. (PAGE-04)
5. The title field SHALL accept at most 50 grapheme clusters and SHALL show the counter "N/50" from 40 characters. (PAGE-05)
6. WHEN the title is saved THEN the "Editada" line SHALL show the new `updated_at`. (PAGE-06)
7. WHEN the user taps the back button THEN the system SHALL return to the notebook page list. (PAGE-07)

**Independent Test**: Widget test with a fake clock: type a title, pump 500 ms → row updated; type again and pop at once → row has the latest title.

---

### P1: Notebook options ⭐ MVP

**User Story**: As a user, I want to rename a notebook and change its color and cover so that it stays recognizable (RF-01).

**Why P1**: RF-01 Must.

**Acceptance Criteria**:

1. WHEN the user taps ⋯ on an active notebook THEN the system SHALL open the "Opções do caderno" sheet with the mini cover, the title, the meta "<page count> · criado <date>", and the options "Renomear", "Mudar capa e cor", "Arquivar" (with "Sai da lista principal; nada é apagado") and "Excluir caderno". (NBOPT-01)
2. WHEN the user taps ⋯ on an archived notebook THEN the sheet SHALL show the meta "<page count> · arquivado <date>" and "Desarquivar" (with "Volta para a lista principal") in place of "Arquivar". (NBOPT-02)
3. WHEN the user taps "Renomear" THEN the system SHALL open the "Renomear caderno" dialog with the "Nome" field filled with the current title, the placeholder "Nome do caderno", "Cancelar" and "Salvar". (NBOPT-03)
4. WHILE the trimmed name in the rename dialog is empty "Salvar" SHALL be disabled. (NBOPT-04)
5. The rename field SHALL accept at most 50 grapheme clusters and SHALL show the counter "N/50" from 40 characters. (NBOPT-05)
6. WHEN the user taps "Salvar" in the rename dialog THEN the system SHALL save the trimmed title and return to the notebook page list showing it. (NBOPT-06)
7. WHEN the user taps "Mudar capa e cor" THEN the system SHALL open the sheet titled "Capa e cor", without the name field, with the notebook's current color and cover selected and the button "Salvar". (NBOPT-07)
8. WHEN the user taps "Salvar" in "Capa e cor" THEN the system SHALL save the chosen color and cover and return to the notebook page list. (NBOPT-08)
9. WHEN the user taps "Cancelar" in any of these dialogs or sheets THEN the system SHALL write nothing. (NBOPT-09)

**Independent Test**: Widget test: rename to a new title → row updated and header shows it; change color to "Musgo" → `notebooks.color` = `musgo`.

---

### P1: Archive and unarchive ⭐ MVP

**User Story**: As a user, I want to archive notebooks I am not using so that my main list stays short without deleting anything (RF-01, ADR 0012).

**Why P1**: RF-01 Must.

**Acceptance Criteria**:

1. WHEN the user taps "Arquivar" in the notebook options THEN the system SHALL set `archived_at` on the local user's `notebook_members` row, return to "Cadernos" on the "Ativos" tab, and show the toast "Caderno arquivado" with "Desfazer". (ARCH-01)
2. WHEN the user taps "Desarquivar" on an archived row or in the archived notebook options THEN the system SHALL clear `archived_at` on the local user's member row, show "Cadernos" on the "Ativos" tab, and show the toast "Caderno de volta à lista principal" with "Desfazer". (ARCH-02)
3. WHEN the user taps "Desfazer" on an archive or unarchive toast THEN the system SHALL restore the previous `archived_at` value. (ARCH-03)
4. The archive and unarchive actions SHALL NOT write `deleted_at`. (ARCH-04)
5. WHILE a notebook is archived the user SHALL be able to open it and create, rename, reorder and delete its pages. (ARCH-05)

**Independent Test**: Widget test: archive → member row has `archived_at`, notebook moves to "Arquivados · 1", toast shown; tap "Desfazer" → back in "Ativos".

---

### P1: Sort notebooks ⭐ MVP

**User Story**: As a user, I want to choose how my notebooks are ordered so that I find the one I need fast (RF-01).

**Why P1**: Drawn in the canvas; replaces the M02 fixed order.

**Acceptance Criteria**:

1. WHEN the user taps "Ordenar" THEN the system SHALL open the "Ordenar por" sheet with the options "Editados recentemente", "Nome (A–Z)" and "Data de criação", the current one checked, and the note "Vale para Ativos e Arquivados, e fica salvo neste aparelho.". (SORT-01)
2. WHEN the user picks an option THEN the system SHALL close the sheet, order both tabs by it, and store it on the device. (SORT-02)
3. WHILE "Editados recentemente" is selected the notebooks SHALL be ordered by last edited date (latest page `updated_at`, or `created_at` with no pages) descending, then by `id` descending. (SORT-03)
4. WHILE "Nome (A–Z)" is selected the notebooks SHALL be ordered by title ascending, ignoring case and accents, then by `id` ascending. (SORT-04)
5. WHILE "Data de criação" is selected the notebooks SHALL be ordered by `created_at` descending, then by `id` descending. (SORT-05)
6. WHEN the app starts THEN the notebooks SHALL be ordered by the stored option. (SORT-06)
7. IF no option is stored or the stored value is unknown THEN the system SHALL use "Editados recentemente". (SORT-07)

**Independent Test**: Widget test with three notebooks ("Bloco", "árvore", "Caderno") and a fake preferences store: pick "Nome (A–Z)" → "árvore", "Bloco", "Caderno"; restart the widget → same order.

---

### P1: Delete a notebook ⭐ MVP

**User Story**: As a user, I want to delete a notebook with a confirmation so that a mistake does not take all its pages away (RF-01, RF-12, ADR 0024).

**Why P1**: RF-01 Must.

**Acceptance Criteria**:

1. WHEN the user taps "Excluir caderno" THEN the system SHALL open the confirmation dialog "Excluir “<title>”?" with "O caderno vai para a lixeira deste aparelho, com as páginas. Dá para desfazer logo depois ou restaurá-lo pela lixeira.", "Mover para a lixeira" and "Cancelar". (NBDEL-01)
2. WHEN the user taps "Mover para a lixeira" THEN the system SHALL set only `notebooks.deleted_at`, return to "Cadernos", and show the toast "Caderno movido para a lixeira" with "Desfazer". (NBDEL-02)
3. WHEN the user taps "Cancelar" THEN the system SHALL close the dialog and write nothing. (NBDEL-03)
4. WHEN the user taps "Desfazer" on that toast THEN the system SHALL clear `notebooks.deleted_at` and the notebook SHALL reappear in its list. (NBDEL-04)
5. The notebook deletion SHALL NOT write any `pages` or `blocks` row (ADR 0027). (NBDEL-05)

**Independent Test**: Widget test: delete → only `notebooks.deleted_at` set, tile gone, toast shown; "Desfazer" → tile back.

---

### P1: Page options and delete ⭐ MVP

**User Story**: As a user, I want to rename or delete a page from the page screen, with undo, so that a wrong tap costs nothing (RF-02, RF-12, ADR 0024).

**Why P1**: RF-12 delete path for pages.

**Acceptance Criteria**:

1. WHEN the user taps ⋯ on the minimal page THEN the system SHALL open the "Opções da página" sheet with the page title (or "Sem título"), the notebook color chip and title, "editada <relative date>, HH:mm", "Renomear" and "Excluir página" with "Vai para a lixeira; dá para desfazer". (PGOPT-01)
2. WHEN the user taps "Renomear" THEN the system SHALL open the "Renomear página" dialog with the "Título" field filled with the current title, the placeholder "Sem título", the help "Opcional. Sem título, a página aparece como “Sem título”.", "Cancelar" and "Salvar". (PGOPT-02)
3. WHEN the user taps "Salvar" in the rename dialog THEN the system SHALL save the trimmed title, an empty one included, and return to the minimal page. (PGOPT-03)
4. WHEN the user taps "Excluir página" THEN the system SHALL set the page's `deleted_at` with no confirmation, return to the notebook page list without that page, and show the toast "Página movida para a lixeira" with "Desfazer". (PGOPT-04)
5. WHEN the user taps "Desfazer" on that toast THEN the system SHALL clear the page's `deleted_at` and the page SHALL reappear in its previous position. (PGOPT-05)

**Independent Test**: Widget test: delete the second of three pages → list has two rows and the toast; "Desfazer" → three rows in the original order.

---

### P1: Undo toast ⭐ MVP

**User Story**: As a user, I want a short undo after each reversible action so that I can take back a mistake without opening the trash (ADR 0024).

**Why P1**: Shared by archive, delete and restore.

**Acceptance Criteria**:

1. The undo toast SHALL show the action text and a "Desfazer" button, with the layout of the canvas toast. (TOAST-01)
2. WHEN 3 seconds pass with no finger on the toast THEN the toast SHALL disappear and the action SHALL stay applied. (TOAST-02)
3. WHILE the user holds a finger on the toast the 3-second countdown SHALL be paused, and it SHALL restart from 3 seconds when the finger is lifted. (TOAST-03)
4. WHEN the user taps "Desfazer" THEN the system SHALL revert the action and hide the toast. (TOAST-04)
5. WHEN a new toast is shown while another is visible THEN the new one SHALL replace the old one, and the old action SHALL stay applied. (TOAST-05)
6. WHEN the user leaves the screen where the toast appeared THEN the toast SHALL disappear without reverting the action. (TOAST-06)

**Independent Test**: Widget test with fake time: toast gone after 3 s; hold for 5 s → still shown; release and wait 3 s → gone.

---

### P2: Local trash

**User Story**: As a user, I want to see what I deleted on this device and restore it so that no deletion is final (RF-12, ADR 0023, ADR 0027).

**Why P2**: RF-12 is Should; the undo toast already covers the immediate mistake.

**Acceptance Criteria**:

1. The "Lixeira" screen SHALL show the back button "Cadernos", the title "Lixeira" and the text "O que você exclui fica aqui, neste aparelho, e pode ser restaurado.". (TRASH-01)
2. WHILE at least one notebook is in the trash the screen SHALL show the "Cadernos" section with one row per notebook in the trash: mini cover, title, "<page count> · excluído <date>" and "Restaurar". (TRASH-02)
3. The page count of a notebook in the trash SHALL count only its pages not deleted on their own. (TRASH-03)
4. WHILE at least one page deleted on its own belongs to a notebook not in the trash the screen SHALL show the "Páginas" section with one row per such page: title (or "Sem título"), the notebook color chip and title, the relative deletion date, and "Restaurar". (TRASH-04)
5. The "Páginas" section SHALL NOT list pages of a notebook that is in the trash. (TRASH-05)
6. IF the trash has no notebook and no listed page THEN the screen SHALL show the empty state "A lixeira está vazia" / "O que você excluir fica aqui, neste aparelho, e pode ser restaurado.". (TRASH-06)
7. WHEN the user restores a notebook THEN the system SHALL clear only `notebooks.deleted_at`, and the notebook SHALL return to the list it was in (active or archived) with the pages that were not deleted on their own; the toast SHALL read "Caderno restaurado". (TRASH-07)
8. WHEN the user restores a page THEN the system SHALL clear only that page's `deleted_at`, and the toast SHALL read "Restaurado em <notebook title>". (TRASH-08)
9. WHEN the user taps "Desfazer" after a restore THEN the item SHALL return to the trash with its original `deleted_at`. (TRASH-09)
10. WHEN a notebook in the trash is restored THEN its pages deleted on their own before it SHALL appear in the "Páginas" section. (TRASH-10)
11. Each section SHALL be ordered by `deleted_at` descending, then by `id` descending. (TRASH-11)
12. The trash SHALL NOT offer "empty trash" or any physical deletion. (TRASH-12)

**Independent Test**: Database + widget test: delete page A, then delete its notebook → "Cadernos" has the notebook with count excluding A, "Páginas" is empty; restore the notebook → A appears under "Páginas"; restore A → trash empty state.

---

### P2: Dates and counts

**User Story**: As a user, I want dates and counts written the same way on every screen so that the app reads like one product.

**Why P2**: Shared by every meta line; low risk on its own.

**Acceptance Criteria**:

1. The system SHALL format a date relative to the device's local today as: "hoje" (same day), "ontem" (previous day), the weekday abbreviation "seg", "ter", "qua", "qui", "sex", "sáb" or "dom" (2 to 6 days before), "d MMM" with no zero padding (older, same year, e.g. "2 out"), "d MMM yyyy" (other year, e.g. "2 out 2025"). (DATE-01)
2. WHEN a relative date follows a verb THEN "hoje" and "ontem" SHALL follow it directly ("arquivado hoje") and the other forms SHALL take "em" ("criado em 2 out"). (DATE-02)
3. The system SHALL convert stored UTC dates to the device time zone before formatting. (DATE-03)
4. The page count SHALL read "nenhuma página" for 0, "1 página" for 1 and "N páginas" otherwise. (DATE-04)

**Independent Test**: Unit test with a fixed clock and the `America/Sao_Paulo` offset covering each branch, including a UTC instant that falls on the previous local day.

---

### P2: Offline flows and launch time

**User Story**: As a user, I want every notebook and page flow to work with no network, and the app to open fast, so that I can write anywhere (RF-04, PRD §2).

**Why P2**: The flows are covered by the P1 stories; this story adds the end-to-end proof and the measurement.

**Acceptance Criteria**:

1. The `integration_test/` folder SHALL have one e2e test per flow, each run with no network access: create, rename, archive and delete a notebook (RF-01); create and reorder pages (RF-02); delete a page and a notebook and restore both from the trash (RF-12). (E2E-01)
2. WHEN the e2e flows run THEN no screen SHALL wait on or call the network (RNF-01). (E2E-02)
3. The time from tapping the app icon to the minimal page of a new page being open SHALL be measured in profile mode on a mid-range Android device and recorded in the #21 PR with the device model. (PERF-01)
4. IF the measured time is 1 second or more THEN the PR SHALL open a follow-up issue with the measurement. (PERF-02)

**Independent Test**: `fvm flutter test integration_test` on an emulator in airplane mode; manual measurement recorded in the PR.

---

### P3: Decision records and docs

**User Story**: As the developer, I want this milestone's decisions recorded so that the next milestones do not reopen them.

**Why P3**: Documentation; the code does not depend on it.

**Acceptance Criteria**:

1. The repository SHALL have new ADRs, in Portuguese and numbered from 0032, for: the undo toast (duration, pause, actions); the trash "Páginas" section; notebook sorting (options, default, storage). (ADR-01)
2. The `app/.claude/docs/testes.md` e2e table SHALL list the trash flow (RF-12) in the same commit as its test. (DOC-01)
3. The `app/.claude/docs/design.md` component table SHALL list every new reusable widget built in this milestone, in the same commit as the widget. (DOC-02)

**Independent Test**: Review the files; `ls docs/adr` shows the new ADRs.

---

## Edge Cases

- IF a notebook's only pages are all in the trash THEN its tile SHALL show "nenhuma página" and its last edited date SHALL be `created_at`. (EDGE-01)
- IF a title has leading or trailing spaces THEN the stored title and the rendered title SHALL be trimmed. (EDGE-02)
- IF the page open on the minimal page screen is deleted while it is open THEN the screen SHALL return to the notebook page list. (EDGE-03)
- IF the user taps "Excluir caderno" on an archived notebook THEN the notebook SHALL go to the trash and, when restored, SHALL return to "Arquivados". (EDGE-04)
- WHEN the user restores a page whose notebook is archived THEN the page SHALL reappear in that archived notebook. (EDGE-05)
- IF the preferences box failed to open (PREF-06) THEN sorting SHALL use "Editados recentemente" and choosing an option SHALL still reorder the lists for the session. (EDGE-06)
- IF a title has 50 grapheme clusters made of multi-code-unit characters (emoji) THEN the field SHALL accept it and the repository SHALL store it. (EDGE-07)

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| NBLIST-01 | P1: Notebooks screen | - | Pending |
| NBLIST-02 | P1: Notebooks screen | - | Pending |
| NBLIST-03 | P1: Notebooks screen | - | Pending |
| NBLIST-04 | P1: Notebooks screen | - | Pending |
| NBLIST-05 | P1: Notebooks screen | - | Pending |
| NBLIST-06 | P1: Notebooks screen | - | Pending |
| NBLIST-07 | P1: Notebooks screen | - | Pending |
| NBLIST-08 | P1: Notebooks screen | - | Pending |
| NBLIST-09 | P1: Notebooks screen | - | Pending |
| NBLIST-10 | P1: Notebooks screen | - | Pending |
| NBNEW-01 | P1: Create a notebook | - | Pending |
| NBNEW-02 | P1: Create a notebook | - | Pending |
| NBNEW-03 | P1: Create a notebook | - | Pending |
| NBNEW-04 | P1: Create a notebook | - | Pending |
| NBNEW-05 | P1: Create a notebook | - | Pending |
| NBNEW-06 | P1: Create a notebook | - | Pending |
| NBNEW-07 | P1: Create a notebook | - | Pending |
| PGLIST-01 | P1: Notebook page list | - | Pending |
| PGLIST-02 | P1: Notebook page list | - | Pending |
| PGLIST-03 | P1: Notebook page list | - | Pending |
| PGLIST-04 | P1: Notebook page list | - | Pending |
| PGLIST-05 | P1: Notebook page list | - | Pending |
| PGLIST-06 | P1: Notebook page list | - | Pending |
| PGLIST-07 | P1: Notebook page list | - | Pending |
| PGLIST-08 | P1: Notebook page list | - | Pending |
| REORDER-01 | P1: Reorder pages | - | Pending |
| REORDER-02 | P1: Reorder pages | - | Pending |
| REORDER-03 | P1: Reorder pages | - | Pending |
| REORDER-04 | P1: Reorder pages | - | Pending |
| REORDER-05 | P1: Reorder pages | - | Pending |
| REORDER-06 | P1: Reorder pages | - | Pending |
| PAGE-01 | P1: Minimal page screen | - | Pending |
| PAGE-02 | P1: Minimal page screen | - | Pending |
| PAGE-03 | P1: Minimal page screen | - | Pending |
| PAGE-04 | P1: Minimal page screen | - | Pending |
| PAGE-05 | P1: Minimal page screen | - | Pending |
| PAGE-06 | P1: Minimal page screen | - | Pending |
| PAGE-07 | P1: Minimal page screen | - | Pending |
| NBOPT-01 | P1: Notebook options | - | Pending |
| NBOPT-02 | P1: Notebook options | - | Pending |
| NBOPT-03 | P1: Notebook options | - | Pending |
| NBOPT-04 | P1: Notebook options | - | Pending |
| NBOPT-05 | P1: Notebook options | - | Pending |
| NBOPT-06 | P1: Notebook options | - | Pending |
| NBOPT-07 | P1: Notebook options | - | Pending |
| NBOPT-08 | P1: Notebook options | - | Pending |
| NBOPT-09 | P1: Notebook options | - | Pending |
| ARCH-01 | P1: Archive and unarchive | - | Pending |
| ARCH-02 | P1: Archive and unarchive | - | Pending |
| ARCH-03 | P1: Archive and unarchive | - | Pending |
| ARCH-04 | P1: Archive and unarchive | - | Pending |
| ARCH-05 | P1: Archive and unarchive | - | Pending |
| SORT-01 | P1: Sort notebooks | - | Pending |
| SORT-02 | P1: Sort notebooks | - | Pending |
| SORT-03 | P1: Sort notebooks | - | Pending |
| SORT-04 | P1: Sort notebooks | - | Pending |
| SORT-05 | P1: Sort notebooks | - | Pending |
| SORT-06 | P1: Sort notebooks | - | Pending |
| SORT-07 | P1: Sort notebooks | - | Pending |
| NBDEL-01 | P1: Delete a notebook | - | Pending |
| NBDEL-02 | P1: Delete a notebook | - | Pending |
| NBDEL-03 | P1: Delete a notebook | - | Pending |
| NBDEL-04 | P1: Delete a notebook | - | Pending |
| NBDEL-05 | P1: Delete a notebook | - | Pending |
| PGOPT-01 | P1: Page options and delete | - | Pending |
| PGOPT-02 | P1: Page options and delete | - | Pending |
| PGOPT-03 | P1: Page options and delete | - | Pending |
| PGOPT-04 | P1: Page options and delete | - | Pending |
| PGOPT-05 | P1: Page options and delete | - | Pending |
| TOAST-01 | P1: Undo toast | - | Pending |
| TOAST-02 | P1: Undo toast | - | Pending |
| TOAST-03 | P1: Undo toast | - | Pending |
| TOAST-04 | P1: Undo toast | - | Pending |
| TOAST-05 | P1: Undo toast | - | Pending |
| TOAST-06 | P1: Undo toast | - | Pending |
| TRASH-01 | P2: Local trash | - | Pending |
| TRASH-02 | P2: Local trash | - | Pending |
| TRASH-03 | P2: Local trash | - | Pending |
| TRASH-04 | P2: Local trash | - | Pending |
| TRASH-05 | P2: Local trash | - | Pending |
| TRASH-06 | P2: Local trash | - | Pending |
| TRASH-07 | P2: Local trash | - | Pending |
| TRASH-08 | P2: Local trash | - | Pending |
| TRASH-09 | P2: Local trash | - | Pending |
| TRASH-10 | P2: Local trash | - | Pending |
| TRASH-11 | P2: Local trash | - | Pending |
| TRASH-12 | P2: Local trash | - | Pending |
| DATE-01 | P2: Dates and counts | - | Pending |
| DATE-02 | P2: Dates and counts | - | Pending |
| DATE-03 | P2: Dates and counts | - | Pending |
| DATE-04 | P2: Dates and counts | - | Pending |
| E2E-01 | P2: Offline flows and launch time | - | Pending |
| E2E-02 | P2: Offline flows and launch time | - | Pending |
| PERF-01 | P2: Offline flows and launch time | - | Pending |
| PERF-02 | P2: Offline flows and launch time | - | Pending |
| ADR-01 | P3: Decision records and docs | - | Pending |
| DOC-01 | P3: Decision records and docs | - | Pending |
| DOC-02 | P3: Decision records and docs | - | Pending |
| EDGE-01 | Edge cases | - | Pending |
| EDGE-02 | Edge cases | - | Pending |
| EDGE-03 | Edge cases | - | Pending |
| EDGE-04 | Edge cases | - | Pending |
| EDGE-05 | Edge cases | - | Pending |
| EDGE-06 | Edge cases | - | Pending |
| EDGE-07 | Edge cases | - | Pending |

**Coverage:** 107 total, 0 mapped to tasks, 107 unmapped ⚠️ (tasks come after design)

---

## Success Criteria

- [ ] Every flow in E2E-01 passes on an emulator with no network.
- [ ] Zero physical `DELETE` statements in `app/lib/` (RNF-05).
- [ ] Every artboard in "Canvas references" has a screen or state that matches it.
- [ ] The #21 launch-to-new-page time is recorded in the PR.
