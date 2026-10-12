# M02 Local Data Model Context

**Gathered:** 2026-10-11
**Spec:** `.specs/features/m02-local-data-model/spec.md`
**Status:** Confirmed on 2026-10-12 (spec review); design in `design.md`

---

## Feature Boundary

GitHub milestone "#02 - Local data model" (issues #13–#18): Drift schema v2 with `notebooks`, `notebook_members`, `pages`, `blocks` and `local_user`; tested v1 → v2 migration; anonymous local user; UUID v7 id generator and UTC clock behind providers; fractional index for pages and blocks; soft delete; repositories and Riverpod stream providers. No screen ships here, and neither do trash listing or restore.

---

## Implementation Decisions

### Anonymous local user storage (#14)

- Stored in Drift, in a local-only single-row table `local_user`, not in `hive_ce`.

### Deleting a notebook (ADR 0023)

- Derived: only `notebooks.deleted_at` is written. Page and block queries exclude rows whose notebook or page is deleted.
- Consequence for #61: restoring a notebook brings back only the pages that were not deleted on their own (answers ADR 0023's first open question; recorded in a new ADR).

### Columns beyond PRD §7

- Add `blocks.deleted_at`.
- Do not add `notebooks.updated_at` / `updated_by`, `pages.created_at` / `created_by` or `blocks.created_at` / `created_by` in phase 1.

### Repository scope (#18)

- Create, edit, reorder, archive / unarchive, delete, and watch active and archived lists.
- Trash listing and restore ship with the trash screen in #61.

### Titles (spec review, 2026-10-12)

- Notebook title: trimmed, required, at most 50 characters.
- Page title: trimmed, optional, at most 50 characters.
- Over the limit: the repository throws and writes nothing (no silent cut).
- Length counted in grapheme clusters, the same unit as `TextField.maxLength`.

### ADR language (spec review, 2026-10-12)

- The new ADRs stay in Portuguese (ADR 0016 unchanged).

### Code location (design review, 2026-10-12)

- Tables, clock, id generator, local user and fractional index in `lib/core/`; repositories and providers in `lib/features/<feature>/data/`, Drift query builder without DAOs.
- Fractional index: own port of the rocicorp algorithm, no new package.

### Agent's Discretion

None explicitly delegated.

### Declined / Undiscussed Gray Areas → Assumptions

Proposed as assumptions in the spec's "Assumptions & Open Questions" and confirmed on spec review: `notebook_members.id` primary key, schema v2 with step-by-step migrations, ISO-8601 text dates, `uuid` package behind `IdGenerator`, own `Clock`, base-62 text fractional keys, keys computed over deleted rows too, initial `blocks.version` = 0, free-text block `type` and opaque `content_json`, titles stored as given, notebook list order, parent rows untouched by child writes, foreign keys on, repeat delete keeps the first `deleted_at`, ADR list from 0026.

---

## Specific References

- PRD §7 (data model and conventions), ADRs 0004, 0005, 0011, 0012, 0013, 0023, 0025.
- `app/.claude/docs/testes.md`: migrations with `make-migrations`, clock and id generator behind providers, fixed invariant tests.
- PowerSync docs: every synced table needs a text `id` primary key; composite keys are not supported; managed tables are views without constraints.
- Drift docs: `store_date_time_values_as_text` recommended for new projects; the default stores unix seconds.

---

## Deferred Ideas

- Foreign keys and `CHECK` constraints under PowerSync-managed views (phase 2, #08): decide between raw tables and repository-level checks.
- Whether a search result marks an archived notebook (ADR 0025 open question): #26.
