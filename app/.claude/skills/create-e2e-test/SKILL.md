---
name: create-e2e-test
description: Writes or changes an end-to-end test for the Jotline Flutter app in app/integration_test/, following the project's helpers, determinism and naming rules. Use whenever the task is to add, change, fix or run an e2e test or a main-flow test ("escreve o e2e", "teste de fluxo", "teste ponta a ponta", "integration_test", "testa esse fluxo no app"), when a new screen flow or milestone needs e2e coverage, or when an RF/RNF must be proven offline from the UI down to SQLite. Do NOT use for unit, widget, database or migration tests (those follow app/.claude/docs/testes.md), for performance measurements in integration_test/perf/, or for server-side tests.
license: CC-BY-4.0
metadata:
  author: jon
  version: 1.0.0
---

# Create an e2e test (Jotline app)

An e2e test drives the real `JotlineApp` through the UI on a device or emulator and then checks both the screen and the local SQLite. It exists to prove a main flow works offline, from tap to stored row. Anything that can be proven below the UI belongs in `test/` instead (see `app/.claude/docs/testes.md`).

## Before writing

1. Read `app/integration_test/notebooks_flow_test.dart` (the model file) and `app/integration_test/helpers/flows.dart` (the actions you must reuse before writing new ones).
2. Name the flow and its requirement codes (RF-xx / RNF-xx). Find them in `docs/prd/PRD.md`, reading only the relevant section. If the flow or its expected behavior is not in the PRD, ask the user before inferring (root `CLAUDE.md`, "Doubts").
3. Check the flow table below. A flow or sub-flow already covered is extended in its existing file, not duplicated in a new one, even when the request sounds like a new test ("test renaming a page" extends `pages_flow_test.dart`). Say so to the user and ask only when extending would make the file unreadable.

## Main flows

Each row is one file in `integration_test/`. A new main flow is added to this table in the same commit as its test.

| Flow | File | Requirements |
| --- | --- | --- |
| Create, rename, archive and delete a notebook | `notebooks_flow_test.dart` | RF-01 |
| Create, rename inline and reorder pages | `pages_flow_test.dart` | RF-02 |
| Delete and restore pages and notebooks through the trash, with undo | `trash_flow_test.dart` | RF-12 |
| Write in a block, close and reopen the app with the text preserved | `editor_flow_test.dart` | RF-03, RF-04 |
| Search by title and content | `search_flow_test.dart`, written on `milestone/m05-search-and-gate-1` (PR #70 was reverted, so it is not on `main` yet) | RF-05 |

## Skeleton

One file per flow, named `<flow>_flow_test.dart`. Use a subfolder only when two or more flows share helpers that nothing else uses.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/flows.dart';
import 'helpers/no_network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(forbidNetwork);

  testWidgets('RF-xx: <what the user achieves>, with no network', (tester) async {
    final app = await pumpJotlineWithoutNetwork(tester);

    await createNotebook(tester, 'Receitas');

    final rows = await app.db.select(app.db.notebooks).get();
    expect(rows.map((n) => n.title), ['Receitas']);
  });
}
```

- The description starts with the requirement code, in English, as in `testes.md`.
- `forbidNetwork` fails the test if the app opens an `HttpClient` (E2E-02). Keep it in `setUp`.
- `pumpJotlineWithoutNetwork` returns a `TestApp` (`test/helpers/test_app.dart`): in-memory database, `FakeClock`, `SequentialIdGenerator` and the three repositories. It closes the database in `addTearDown`, so never share a database between tests.

## Arrange, act, assert

- **Arrange through the UI when creating is what the test is about** (`createNotebook`, `createPage`). Otherwise seed through the repositories, which is also what "create it straight in the database" means here: raw table inserts skip `notebook_members`, authorship and positions, so the data would not look like the app's.
  - `app.notebooks.create(title: ..., cover: CoverPattern..., color: NotebookColor...)` (enums from `lib/core/theme/notebook_palette.dart`; check the file for the current names)
  - `app.pages.create(notebookId, title: ...)`
  - `app.blocks.create(pageId, type: ..., contentJson: ...)` They fill `notebook_members`, `created_by` and positions the same way the app does, so there is no parallel factory to keep in sync. Seed before the first `settle` that follows the rows you need, or call `settle(tester)` after seeding so the streams deliver.
- **Act through `helpers/flows.dart`.** If an action will be used by a second flow, add it there instead of repeating finders. Prefer finders by widget type or semantic label over raw text when the text can appear twice.
- **Assert twice:** what the user sees (`find.text`, `find.byType`) and what is stored (`app.db`). Check the invariants the flow touches: deletion only sets `deleted_at`, archiving sets `notebook_members.archived_at`, ids are the generator's.
- **Wait with `settle` / `tapAndSettle`**, never a bare `pump()` after a navigation. Drift streams and animations need several frames. A timed UI such as the undo toast is advanced with `tester.pump(JotUndoToast.duration)` followed by `settle`.

## Determinism

The clock and the ids are fixed by `TestApp`. Never call `DateTime.now()` or `Uuid()` in a test. To make time pass for the data, set `app.clock.current = DateTime.utc(...)` (UTC, aligned to the millisecond) and `settle`. Waiting for a UI timer is different: a debounce or toast of the app under test is advanced with `tester.pump(<its duration>)`, as `createPage` does for the title field (600 ms) and the trash flow does with `JotUndoToast.duration`. Never wait with real sleeps.

## Cover the unhappy path

Each feature gets at least one e2e of a failure the user can reach, in the same file as its happy path: an over-long title being trimmed, undo cancelling a deletion, restoring something whose notebook is gone, a conflict copy (RF-10) once it exists. State in the test description what is refused and why.

Take the expected behavior from the "Rules" section of `app/CLAUDE.md` (title limits and trimming, archiving, deletion) and from the PRD. If neither says what should happen, ask the user which failure to cover instead of inventing the behavior.

## Anti-patterns

- Hardcoded ids or `DateTime.now()`; a real clock makes ordering and trash expiry non-reproducible.
- Reusing one `AppDatabase` across tests, or reading it after the teardown.
- Missing `forbidNetwork`: a network call would pass silently and break the offline-first invariant.
- Asserting only on the screen, or only on the database.
- Putting a performance measurement here. Perf lives in `integration_test/perf/` and runs with `flutter drive --profile` (see `app/CLAUDE.md`); never judge it from debug.
- Creating data through the UI in every test just to reach a screen: it is slow and couples unrelated flows.
- Anything that needs a server, an account or a fake sync endpoint: that is phase 2 and an open decision (ADR first). Do not invent a mock server.

## Verify

1. `fvm dart format integration_test` and `fvm flutter analyze` pass.
2. Run the file on an Android emulator or device: `fvm flutter test integration_test/<flow>_flow_test.dart -d <device>`. Check `fvm flutter devices` first. Only Android or iOS counts: the Linux desktop or Chrome entries are not valid targets, since the project has no such platform. If no valid device is connected, stop there and report that the test was written but not run, even when the user asked you to run it and tell them the result; never claim it passed. Running these files as plain host widget tests is not a substitute (the existing flows fail there too).
3. Update the flow table in this file when a flow is added.
4. Commit with Conventional Commits in Portuguese, citing the requirement code (`test(app): fluxo de busca (RF-05)`), no co-authorship.

## Examples

**Example 1: new sub-flow already covered.** User says: "testa renomear página no e2e". Renaming is already part of RF-02, so extend `pages_flow_test.dart` rather than creating a file. Reuse `createNotebook` / `createPage`, edit the title field and `tester.pump(const Duration(milliseconds: 600))` for the debounce, then assert the screen and `app.db.pages`. Add one failure case (a title over 50 graphemes is trimmed), taking the limit from `app/CLAUDE.md`.

**Example 2: flow with seeded data.** User says: "e2e de arquivar caderno com dois cadernos já existentes". Seed with `app.notebooks.create(...)` twice, `settle`, archive one through `notebookOption(tester, 'Arquivar')`, then assert the screen and that `notebook_members.archived_at` is set while `notebooks.deleted_at` stays null.

## Troubleshooting

- **"A Timer is still pending" or the test hangs:** a Drift stream or animation was not drained. End the test after a `settle`; the helper's `addTearDown` closes the database.
- **`StateError: E2E-02: the app attempted a network call`:** a screen or provider opened an `HttpClient`. That breaks the offline-first invariant; fix the app, never remove `forbidNetwork`.
- **A finder finds nothing right after seeding:** the stream has not delivered yet; call `settle(tester)` after the seed.
- **`No supported devices connected`:** no Android or iOS target. Report the test as written but not run.

