# M01 Foundation Context

**Gathered:** 2026-10-11
**Spec:** `.specs/features/m01-foundation/spec.md`
**Status:** Ready for design

---

## Feature Boundary

GitHub milestone "#01 - Foundation" (issues #4–#12): lint set, `lib/` structure, Riverpod style, test foundation, CI for `app/`, commit message check, license, theme + design system (tokens and the base components from the canvas "Componentes" artboard), and the `hive_ce` preferences store. No notebook, page or block feature ships here.

---

## Implementation Decisions

### Spec artifacts language

- `.specs/` artifacts are written in English, like `CLAUDE.md` and `.claude/docs` (agent-facing; EARS keywords are English).

### Lint set (#4)

- Adopt `very_good_analysis`, replacing `flutter_lints`.

### `lib/` organization (#5)

- Feature-first: `lib/core/` for cross-feature code (database, theme, design system widgets, preferences, l10n) and `lib/features/<feature>/{data,presentation}/` for each feature. No per-feature `domain/` layer.
- `test/` mirrors `lib/` file by file.

### Riverpod (#6)

- No code generation: providers declared by hand. No `riverpod_annotation` / `riverpod_generator`.

### License (#10)

- MIT.

### Commit message check (#9)

- POSIX shell `commit-msg` hook versioned in `.githooks/`, enabled with `git config core.hooksPath .githooks`, plus a GitHub Actions job on push and pull request running the same script. No Node, no extra tooling.

### Theme and design system (#11)

- Milestone delivers tokens + `ThemeData` + **all** components of the canvas "Componentes" artboard, each with widget tests.
- Dotted canvas token names become flat camelCase fields on a `ThemeExtension`: `bg.mesa` → `bgMesa`, `ink.1` → `ink1`, `accent.traco` → `accentTraco`.

### Home screen

- No temporary screen without a canvas design: until the notebooks screen exists, the app opens on an empty `Scaffold` with background `bgMesa`.

### Agent's Discretion

None explicitly delegated.

### Declined / Undiscussed Gray Areas → Assumptions

Proposed as assumptions and confirmed by the user on 2026-10-11 (spec "Assumptions & Open Questions"): editor block visuals left out, empty `AppDatabase`, fonts bundled, `public_member_api_docs` off, CI Android-only debug build, commit types/scopes/header length, theme preference deferred, notebook color/cover identifiers, one ADR per decision, preferences box failure behavior.

---

## Specific References

- Canvas "Jotline design" (`app/.claude/docs/design.md`): artboards "Fundamentos e cores", "Tipografia", "Espaço, forma, elevação e ícones", "Componentes" — the token values and component specs in the spec were copied from these artboards on 2026-10-11.

---

## Deferred Ideas

None - discussion stayed within feature scope.
