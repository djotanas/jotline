# CLAUDE.md — app (Flutter)

Jotline mobile app. General rules and invariants in the [root CLAUDE.md](../CLAUDE.md); requirements in [docs/prd/PRD.md](../docs/prd/PRD.md).

> Skeleton created with `flutter create` (`com.jon.jotline`, Android and iOS) plus the stack dependencies. Still **undecided** — ask before assuming: `lib/` organization, Riverpod with or without code generation, lint set (currently the default `flutter_lints`).

## Stack

- **Flutter via FVM** (version pinned in `.fvmrc`); Android and iOS.
- **State:** Riverpod. The UI consumes reactive streams from the local database.
- **Local database:** SQLite with **Drift** — source of truth on the device (ADR 0001). In phase 2 SQLite becomes managed by PowerSync, with Drift on top.
- **UI text:** PT-BR only in phase 1, via `flutter_localizations` + `gen-l10n` (`app_pt.arb`, keys in English); no strings hardcoded in widgets (ADR 0016). Set up in the scaffold.
- **Preferences:** `hive_ce` — only theme, last opened notebook and the like; nothing that syncs.
- **Block editor:** _open_ — `flutter_quill`, `appflowy_editor` or `super_editor`, decided by a 1-week spike. Do not adopt one without the decision recorded in an ADR.
- **Drawing (RF-06, Could):** `perfect_freehand`, strokes saved as JSON.
- **Ordering:** fractional index in `position` — reordering changes a single row.
- **Tests:** `flutter_test` + `mocktail`; database tested with real in-memory Drift; e2e with `integration_test` (ADR 0015).

## Commands

Always through `fvm`, to use the pinned version.

```bash
fvm flutter pub get
fvm flutter run
fvm flutter analyze
fvm dart format lib test integration_test
fvm flutter test
fvm flutter test path/to/file_test.dart
fvm flutter test integration_test                              # e2e; needs an emulator or device
fvm dart run build_runner build --delete-conflicting-outputs   # after cloning and after changing Drift tables
fvm dart run drift_dev make-migrations                         # after bumping schemaVersion
```

Generated code (`*.g.dart`) is not committed: generate it locally before analyze, test and build. CI to be defined.

## Structure

_To be defined in the scaffold._

## References

Read the doc before touching the topic (ADR 0014).

| When | File |
| --- | --- |
| Writing or changing any test, touching a Drift table or creating a screen flow | [`app/.claude/docs/testes.md`](.claude/docs/testes.md) |
| Touching a screen, theme, color, font or icon | [`app/.claude/docs/design.md`](.claude/docs/design.md) |

## Rules

- **Root invariants, app side:** IDs generated at creation time, offline; queries filter out records with `deleted_at`; screens and business rules never import the PowerSync SDK.
- **The phase 1 data model already includes** `notebook_members` (owner only), `blocks.version` and `updated_by`, even without a server (PRD §7).
- **Authorship before login:** an anonymous local user (UUID v7 generated on first launch) fills `created_by`, `user_id`, `added_by` and `updated_by`; on login, a transaction replaces it with the account id before the first upload (ADR 0011).
- **Archiving is per member:** `notebook_members.archived_at` on the user's row, not `deleted_at` (ADR 0012).
- **The app never increments `blocks.version`:** it stores the version received from the server and sends it as the base on upload (ADR 0013).
- **Phase 2:** the upload queue survives closing the app, restarting and switching networks (RNF-02); the status indicator is discreet — synced, pending, error (RF-09).
- **Performance:** list and page opening with no noticeable loading with 10,000 local pages (RNF-06).
- **Tests (ADR 0015):** all new code comes with a unit or widget test; anything touching Drift, with an in-memory database test; schema changes, with a tested migration; main flows, with e2e.
