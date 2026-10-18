# M05 Search and Gate 1 Context

**Gathered:** 2026-10-17
**Spec:** `.specs/features/m05-search-and-gate-1/spec.md`
**Status:** Confirmed on 2026-10-17 (spec review)

---

## Feature Boundary

GitHub milestone "#05 - Search and Gate 1" (issues #25, #26, #27, #28, #29, #67): local search by title and content, performance with 10,000 pages, the local encryption spike and ADR, the freehand drawing block, and the Gate 1 evidence (startup integrity check, automated kill test, manual internal use, #67 device checklist, gate review). Fully offline and without an account.

---

## Implementation Decisions

### Drawing block (#25)

- In M05. The user added "Modo desenho: tela cheia" to the "Fase 1 — telas" canvas.
- The eraser removes the whole stroke it touches.
- The page shows the drawing at page width with the drawing area's aspect ratio, no crop.
- "Cancelar" discards the session with no confirmation.
- A drawing is removed by erasing every stroke and tapping "Concluir" (soft delete).

### Gate 1 (#29) and #67

- In the spec as code: the startup integrity check and the automated kill test.
- Manual exit criteria: 2 weeks of internal use on a physical Android device, the #67 checklist on iPhone and physical Android, and the gate review in `docs/`.

### Encryption (#28)

- Spike + ADR only. Spike code stays on a spike branch; the app on `main` keeps an unencrypted database in M05.

### Search (#26)

- Case-insensitive, accent-insensitive, word-prefix matching.
- Empty states "sem termo" and "sem resultado" were added to the canvas by the user.

### Performance (#27)

- Target: data on screen in < 100 ms after navigation or query; average frame build < 16 ms while scrolling; profile mode, mid-range Android.
- Seed: one notebook with 10,000 pages plus 20 other notebooks (counts of the 20 proposed in the spec).

### Agent's Discretion

None explicitly delegated.

### Declined / Undiscussed Gray Areas → Assumptions

Proposed as assumptions in the spec's "Assumptions & Open Questions" and confirmed on spec review: seed counts, multi-word queries, filter fields, debounce, results order, date format, highlight, excerpt, back navigation, drawing area size, tool defaults, persisted ids, insertion point, undo scope, background save in drawing mode, card label, kill test expectation and runner, integrity log, missed perf target, gate document path, ADR list.
