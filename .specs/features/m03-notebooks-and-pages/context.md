# M03 Notebooks and Pages Context

**Gathered:** 2026-10-12
**Spec:** `.specs/features/m03-notebooks-and-pages/spec.md`
**Status:** Confirmed on 2026-10-12 (spec review)

---

## Feature Boundary

GitHub milestone "#03 - Notebooks and pages" (issues #19, #20, #21, #61): notebook, page and trash screens on top of the M02 repositories, fully offline and without an account. A page opens on a minimal screen (title only); the block editor body comes in M04. No search screen, no load test, no "empty trash".

---

## Implementation Decisions

### Page screen before the editor

- Minimal page screen: back to the notebook, ⋯ options, inline title, "Editada …" line, empty body. M04 replaces only the body.

### Canvas gaps (2026-10-12)

- The user updated the canvas before the spec. New artboards: "Cadernos: primeira abertura", "Arquivados vazio", "Ordenar cadernos", "Após arquivar: desfazer", "Após excluir caderno: desfazer", "Novo caderno: nome perto do limite", "Capa e cor: edição", "Renomear caderno", "Caderno arquivado aberto", "Opções: desarquivar", "Caderno sem páginas", "Páginas sem trecho, M03", "Página mínima, sem editor (M03)", "Renomear página", "Lixeira: restaurado, desfazer".
- Rename: dialogs ("Renomear caderno", "Renomear página") plus the inline page title; cover and color reuse the "Novo caderno" sheet as "Capa e cor".
- Sorting: the "Ordenar" button was only an icon before (M01 COMP-14) and a fixed order in M02; the canvas now defines three options for both tabs, stored on the device.

### Trash

- The "Páginas" section lists only pages deleted on their own whose notebook is not in the trash. Restoring a page never touches its notebook.

### Undo toast

- 3 seconds, paused while the user holds the toast.

### Notebook last edited date

- Latest `pages.updated_at` of the notebook's pages; `created_at` when it has none.

### Spec review (2026-10-12)

- App always opens on "Cadernos"; the last opened notebook is not reopened in M03.
- "Buscar" button hidden until #26.
- One relative date rule for every screen, no zero padding.
- Page title: 50 characters with the "N/50" counter from 40, same as the notebook name.

### #21 measurement

- Measured to the minimal page in M03; repeated to the editor cursor in M04.

### Agent's Discretion

None explicitly delegated.

### Declined / Undiscussed Gray Areas → Assumptions

Proposed as assumptions in the spec's "Assumptions & Open Questions" and confirmed on spec review: default sort, name collation, sort preference storage, page count text, inline title save timing, "Nova página" behavior, reorder counting as an edit, undo of a restore, "Desarquivar" from the options sheet, trash order, toast lifetime across screens, navigation, ADR list.

---

## Specific References

- Canvas "Jotline design" version `1791824928-b73d`, page "Fase 1 — telas".
- ADRs 0012, 0023, 0024, 0025, 0027; M01 PREF stories; M02 repositories.

---

## Deferred Ideas

- Reopening the last opened notebook on launch (M01 PREF story intent): user decided the app always opens on "Cadernos" in M03; `lastOpenedNotebookId` is only written.
- Search button behavior: #26.
