# M04 Block Editor Context

**Gathered:** 2026-10-12
**Spec:** `.specs/features/m04-block-editor/spec.md`
**Status:** Confirmed on 2026-10-12 (spec review)

---

## Feature Boundary

GitHub milestone "#04 - Block editor" (issues #22, #23, #24): the editor library spike and its ADR, then the block editor on the page screen (text, heading, bulleted list, checklist, bold, italic) with one `blocks` row per block, saved locally while the user types. Fully offline and without an account. The freehand drawing block (#25) moves to milestone #05.

---

## Implementation Decisions

### Spike and spec scope

- The spec covers the whole milestone. Behavior comes from the canvas and does not depend on the library; the spike (#22) is the first P1 story, with the evaluation criteria. Design starts only after the editor ADR is accepted.

### Block granularity

- One `blocks` row per paragraph, heading, list item and checklist item. Two devices checking different items of the same checklist do not conflict (ADR 0005).

### Page "last edited"

- Derived at query time: the latest of `pages.updated_at` and the `updated_at` / `deleted_at` of the page's blocks. A block write still never touches its page row (M02 REPO-17 stays).

### Drawing block (#25)

- Out of M04: the "Fase 1 — telas" canvas has no drawing mode (only a finished drawing inside "Editor de blocos", the "Desenho" bar button, the icon and the `accent.traco` token). The "Desenho" button is hidden in M04. #25 moves to milestone #05 (user decision on spec review).

### Agent's Discretion

None explicitly delegated.

### Declined / Undiscussed Gray Areas → Assumptions

Proposed as assumptions in the spec's "Assumptions & Open Questions" and confirmed on spec review: heading levels, list kinds, editing keys (Enter, Backspace), empty page, title → body focus, block bar visibility, marks on headings, save timing, `content_json` format, page excerpt, block drag, undo/redo, paste, spike branch, ADR list.

---

## Specific References

- Canvas artboard "Editor de blocos (RF-03, RF-06)" (`project/Pagina.dc.html`) and the "Componentes" sections "Blocos do editor · RF-03" and "Barra de blocos".
- Bar notes in the canvas: block in edit has the Realce background, radius 10, bleeding 12 px past the text; cursor 2 px in Tinta; checked item is Riscado + strikethrough and stays readable; active tool is Tinta clara with the icon in Tinta funda plus `aria-pressed`.
- "Páginas do caderno (RF-02)" shows the one-line excerpt under the title; "Páginas sem trecho, M03" shows a row without it.

---

## Deferred Ideas

- Freehand drawing block (#25): milestone #05; needs a drawing-mode artboard first.
- Editor undo/redo, numbered lists, nested lists, more heading levels: not in RF-03 as drawn in the canvas.
