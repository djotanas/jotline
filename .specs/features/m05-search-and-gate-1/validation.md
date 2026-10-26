# M05 Search and Gate 1 Validation

**Date**: 2026-10-23
**Spec**: `.specs/features/m05-search-and-gate-1/spec.md`
**Diff range**: `main..HEAD` = 47 commits (`f079eec` … `10c6e3e`); merge base `5f2fcd8`. `main` has since moved (`07c163f`, icon/splash and SPIKE-06 docs commits), so file diffs use `main...HEAD`.
**Scope**: T1–T38. Excluded as agreed: T39, T40, GATE-01…GATE-06. T36 verified on `spike/28-local-encryption` (worktree `/home/jon/dev/projects/jotline-spike28`) and ADR 0040.
**Verifier**: independent sub-agent (author ≠ verifier)

## Validation: M05 Search and Gate 1 - PASS

**Result**: PASS (after Re-verificação 1)

One real surviving mutant (INTEG-02 owner role), plus two weak-test findings. Everything else in scope has `file:line` evidence, the gates are green (979 passed, 0 failed), and 21 of 24 mutants were killed (the other two survivors are an unreachable-branch mutant and a near-equivalent one). The fix is one test; see "Fix Plans".

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T1–T35 | ✅ Done | All Done-when boxes ticked in `tasks.md`; every commit exists in `main..HEAD`. |
| T36 | ✅ Done | ADR 0040 on the milestone branch; spike on `spike/28-local-encryption` (commits `89beda0`, `8e7ca6e`, unpushed by design); `git diff main...HEAD -- app/pubspec.yaml` adds only `package_info_plus` and `perfect_freehand`. |
| T37 | ✅ Done | `app/CLAUDE.md` lists seed, perf drive, kill test, `kill_test_test.sh`; Drawing line names `perfect_freehand 2.5.2+1` and ADR 0039; ADRs 0038 and 0039 are "Aceita". |
| T38 | ✅ Done | `docs/gates/uso-interno.md` exists; `data-loss` label exists (`gh label list`). Procedure run on the device is a user/agent record I did not re-run. |
| T39, T40 | Out of scope | Depend on the user and the 2-week period. |

Housekeeping, not counted as gaps: `tasks.md` header still says `Status: Draft`, and `spec.md` Requirement Traceability still shows `Pending` / `Design` for all rows (update table below). T2's `search_index_test.dart` lives in `test/drift/app_database/`, not `test/core/database/` as the task text says.

---

## Spec-Anchored Acceptance Criteria

Evidence format: `test file:line` (declaration line of the test) and the assertion expression. "e2e" rows are not executable here (no device); the test was verified by reading.

### P1: Local search

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| SRCH-01 | Field focused, empty, placeholder "Buscar em todos os cadernos", "Tudo" selected | `app/test/features/search/presentation/search_screen_test.dart:100` - `editable.focusNode.hasFocus isTrue`; `find.text('Buscar em todos os cadernos') findsOneWidget`; `getSemantics(find.text('Tudo')) isSemantics(isSelected: true …)`. Button: `app/test/features/notebooks/presentation/notebooks_screen_test.dart:248` `buttons.map(semanticLabel) == ['Buscar','Ordenar','Lixeira']`, `:267` shown with zero notebooks, `:277` tap opens `SearchScreen` with focus. `app/test/core/design_system/jot_search_field_test.dart:100,115,127` | ✅ PASS |
| SRCH-02 | "Busque em todos os cadernos" state, no count line while trimmed term is empty | `search_screen_test.dart:121` - `find.text('Busque em todos os cadernos') findsOneWidget`, `_countLine findsNothing`, repeated after typing `'   '` | ✅ PASS |
| SRCH-03 | Results and "1 página"/"N páginas" 150 ms after last change | `search_screen_test.dart:133` - `_rows findsNothing` at 149 ms, `_rows findsNWidgets(3)` at 150 ms; `:150` keystroke restarts the window; `:168` `find.text('3 páginas')`, `find.text('1 página')`. Sensor M15 (100 ms debounce) killed | ✅ PASS |
| SRCH-04 | "bele" and "BELEM" find "Belém"; "lém" does not | `app/test/features/search/data/search_repository_test.dart:102` - ids `[blockPage, archivedPage, titlePage]`; `:139` `titles('BELEM') hasLength(3)`; `:147` (assertion at `:151`) `expect(await titles('lém'), isEmpty)`. `app/test/features/search/data/match_query_test.dart:7` `all('bele') == '"bele"*'` | ✅ PASS |
| SRCH-05 | Every word must match within the filter's fields | `search_repository_test.dart:155` - `hits('belem cedo')` ids `[blockPage]`; `match_query_test.dart:21` `'"tacacá"* AND "almoço"*'` | ✅ PASS |
| SRCH-06 | "Títulos": title only, no excerpt | `search_repository_test.dart:115` ids `[titlePage]`; `:359` `snippet.excerpt isNull`; `match_query_test.dart:30` `'{title} : ("bele"*)'`. Sensor M21 killed | ✅ PASS |
| SRCH-07 | "Conteúdo": block text only | `search_repository_test.dart:126` ids `[blockPage, archivedPage]`; `:373` title span `marked: false`; `match_query_test.dart:38` `'{body} : ("bele"*)'` | ✅ PASS |
| SRCH-08 | "Tudo": title and blocks together | `search_repository_test.dart:163` - `hits('roteiro belem')` ids `[blockPage]` while `Títulos` and `Conteúdo` are `isEmpty` | ✅ PASS |
| SRCH-09 | Archived included; deleted pages, pages of deleted notebooks, deleted blocks, drawings excluded | `search_repository_test.dart:174` trashed page `isNot(contains(...))`; `:182` `ids == [archivedPage]`; `:194` deleted block `titles('belem') isEmpty`; `:203` drawing `isEmpty`; `:215` archived `== [archivedPage]`; `app/test/drift/app_database/search_index_test.dart:148`. Sensors M03, M22, M23 killed. e2e `app/integration_test/search_flow_test.dart:105` `find.text('1 página') findsOneWidget` after trashing (not executable here) | ✅ PASS |
| SRCH-10 | Last edited desc, then `id` | `search_repository_test.dart:102` order `[blockPage, archivedPage, titlePage]`; `:224` same-instant ids `[first, second, third]`. Sensors M04, M05 killed | ✅ PASS |
| SRCH-11 | Spine 10×14 in notebook color, notebook title, "·", date, page title | `app/test/features/search/presentation/search_result_row_test.dart:77` - `tester.getSize(spineBox) == Size(10, 14)`, `find.text('·')`, `find.text('4 out')`; `:107` date uses `fontMeta`; `search_repository_test.dart:237` `hit.notebookColor == NotebookColor.musgo`, `hit.lastEditedAt == DateTime.utc(2026,10,11,10)` | ⚠️ Spec-precision gap (date example "04 out" in the spec vs `d MMM` = "4 out" from `RelativeDates.day`; "hoje" is not asserted in the row) |
| SRCH-12 | "Sem título" muted | `search_result_row_test.dart:197` - `style.fontWeight == w500`, `style.color == _colors.inkFeito` | ✅ PASS |
| SRCH-13 | Excerpt ≤ 2 lines, first matching block in `position` order, "…" at each cut end | `search_excerpt_test.dart:128,137` first block wins; `:70` (exactly 40 characters in, no cut) and `:80` (41 characters in) (`expect(excerpt.text, '…${_filler(38)} Belém fim')`); `search_result_row_test.dart:168` `excerpt.maxLines == 2`, `overflow == TextOverflow.ellipsis`; `:211` no excerpt line. Sensors M14, M17 killed | ⚠️ Spec-precision gap (a trailing "…" is only the Text overflow ellipsis; the code never adds one at the end of the cut, and the spec's "each cut end" does not say what to do on the end side) |
| SRCH-14 | Every matched whole word marked with `accent.busca` in title and excerpt | `search_result_row_test.dart:119` - `_mark('Belém') findsOneWidget` (`DecoratedBox.color == _colors.accentBusca`), radius `rEtiqueta`; `:146` excerpt; `search_repository_test.dart:387` marked spans `['Belém','Santarém']` in title and excerpt | ✅ PASS |
| SRCH-15 | "Nenhuma página encontrada" with the term quoted | `search_screen_test.dart:203` - `find.text('Nenhuma página encontrada')`, `find.text('Nada com “passaporte” em títulos ou conteúdo. Confira a grafia ou tente outro termo.')` | ✅ PASS |
| SRCH-16 | Tap opens the page; back keeps term, filter, scroll | `search_screen_test.dart:222` - controller text `'bel'`, scroll `position.pixels == offset`, `find.text('13 páginas')`. e2e `app/integration_test/search_flow_test.dart:79-86` back from the page keeps `find.text('bele')` and `'2 páginas'` (not executable here) | ✅ PASS (segment kept is not asserted separately; the count `13 páginas` under "Títulos" implies it) |
| SRCH-17 | "Cancelar" returns to Cadernos | `search_screen_test.dart:260` - `find.byType(SearchScreen) findsNothing`, `find.text('home') findsOneWidget` | ✅ PASS |
| SRCH-18 | New text found, removed text not | `search_repository_test.dart:250` `titles('santarem') == ['Roteiro']`, `titles('belem') isEmpty`; `search_index_test.dart:69,75,82,112,122,135,157,170,182,199,214` | ✅ PASS |
| SRCH-19 | v2 database: every page searchable after upgrade | `app/test/drift/app_database/migration_test.dart:36` - `match('{title} : "bele"*') == ['p1']`, `match('{body} : "tacaca"*') == ['p1']`, `match('{body} : "manteiga"*') == ['p2']` | ✅ PASS |
| SRCH-20 | List refreshes on data change | `search_repository_test.dart:264` (block save), `:280` (rename), `:296` (trash → `isEmpty`); `search_providers_test.dart:79` | ✅ PASS |
| SRCH-21 | Local database only, no network | `app/test/app_test.dart:242` NET-01 (no network client under `lib/`), `:282` NET-02 (no `http`/`dio`); `grep dart:io|HttpClient|package:http lib/features/search` empty; e2e `app/integration_test/search_flow_test.dart:32` `forbidNetwork()` (not executable here) | ✅ PASS |

### P1: Performance with 10,000 pages

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| LOAD-01 | Seed: 1×10,000 + 20×100 pages, 20 text blocks of ~200 chars | `app/test/perf/seed_library_test.dart:30-33` `count(notebooks) == 21`, `pages == 12000`, `blocks == 240000`; `:36` `sizes.first == 10000`, `sizes.skip(1) everyElement(100)`; `:110` `page_search == 12000`. Ran with `--tags perf --run-skipped`: 7 passed | ✅ PASS |
| LOAD-02 | Notebook list data < 100 ms | `.specs/features/m05-search-and-gate-1/load-results.md:19` 2192/2188/2182 ms (miss). Harness: `app/integration_test/perf/large_library_test.dart:54` | ✅ Recorded; target missed, accepted by the user (`load-results.md:43`, 2026-10-19). Not a gap |
| LOAD-03 | Open 10,000-page notebook < 100 ms | `load-results.md:20` 683/696/702 ms (miss) | ✅ Recorded; target missed, accepted by the user. Not a gap |
| LOAD-04 | Scroll average frame build < 16 ms | `load-results.md:21` 6.73/7.03/6.87 ms (met); `app/test/perf/frame_stats_test.dart:18,25` | ✅ PASS (SPEC_DEVIATION recorded at `load-results.md:11`: `addTimingsCallback` instead of `traceAction`; frame counts may differ, a spec-precision gap already declared) |
| LOAD-05 | Open page < 100 ms | `load-results.md:22` 47/50/48 ms (met) | ✅ PASS |
| LOAD-06 | First results < 100 ms after the debounce | `load-results.md:23` 103/100/89 ms ("oscila na meta") | ✅ Recorded; borderline, accepted by the user. Not a gap |
| LOAD-07 | Plans use an index, no full scan of `pages`/`blocks` | `app/test/core/database/query_plan_test.dart:75,83,91,98,105` - `expectNoFullScan(details)` for the five queries (`scans, isEmpty`). Note: 3-page seed | ✅ PASS |
| LOAD-08 | Measurements with device model and Android version | `load-results.md:7` "Samsung SM-A356E, Android 16" | ⚠️ Pending: record exists, but the branch is not pushed and no PR exists (`gh pr list` empty), so "recorded in the M05 PR" is not yet true |
| LOAD-09 | On a miss: stop, report values, targets, attempts, friction | `load-results.md:27-43` one index attempt (schema v4, `9cab0a7`), friction and user decision; `migration_test.dart:93` `index hasLength(1)` for v3→v4 | ✅ PASS |

### P1: Startup integrity check

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| INTEG-01 | Check runs after the first frame, not delaying it | `app/test/app_test.dart:93` `check.framesAtRun.single greaterThan(before)`; `:104` `framesAtRun hasLength(1)` after a rebuild. Sensor M24 (never runs) killed; M16 (microtask instead of post-frame) survived | ⚠️ Weak: the test cannot tell post-frame from microtask scheduling (see Sensor). `PRAGMA integrity_check` itself is never asserted either |
| INTEG-02 | Fail when a non-deleted notebook has no `owner` row | `app/test/core/database/integrity_check_test.dart:87` - 'a notebook whose only member is not an owner fails'; fails under M07 | ✅ PASS |
| INTEG-03 | Fail on a page of a missing notebook | `integrity_check_test.dart:86` - `'orphan_page'`, `ids == [pageId]` | ✅ PASS |
| INTEG-04 | Fail on a block of a missing page | `integrity_check_test.dart:95` - `'orphan_block'`, `ids == [blockId]` | ✅ PASS |
| INTEG-05 | Fail on duplicate `position` (pages, blocks) among non-deleted | `integrity_check_test.dart:120` (blocks), `:105` pages test, `:136` deleted duplicate `report.passed isTrue`. Sensor M08 killed | ✅ PASS |
| INTEG-06 | One log line: UTC date, version, pass/fail, invariant and ids | `app/test/core/database/integrity_log_test.dart:19` `'2026-10-17T12:00:00Z 1.0.0+1 pass\n'`; `:25` `'… fail orphan_page=p1,p2 duplicate_position=b1\n'`; `integrity_check_test.dart:149` | ⚠️ Spec-precision gap (the line format is not defined in the spec; tests assert the implemented format) |
| INTEG-07 | Throwing check logs a failure and the app keeps running | `integrity_check_test.dart:163` - `invariant == 'check_error'`, `logged() contains(' fail check_error=')` | ✅ PASS |
| INTEG-08 | No write to synced tables | `integrity_check_test.dart:175` - `snapshot() == before` (row counts and `max(updated_at)`) | ✅ PASS |

### P1: Automated kill test

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| KILL-01 | Instrumented build, scripted edits, `adb force-stop`, relaunch, compare | `app/integration_test/kill/kill_app.dart:116-176` (loop with `pending`/`ack`, `verifyKill`); `app/tool/kill_test.sh` (build, install, `am force-stop`, relaunch); `app/test/kill/kill_app_test.dart:43` `actual == expected` per step | ✅ PASS by reading; device run is recorded in `kill-results.md`, not executable here |
| KILL-02 | Every block saved before the kill is present with identical `type`/`content_json` | `app/test/kill/kill_verify_test.dart:27` `verdict.passed isTrue`; `:58` missing block → `passed isFalse`, `reason == 'blocks'`, `expected`/`actual` lists | ⚠️ Spec-precision gap (the spec says "identical" to the saved content; `verifyKill` also accepts any `pending` snapshot after the last ack, justified in `kill_verify.dart:76-78`, not stated in the spec) |
| KILL-03 | Integrity check passes after a kill | `kill_verify_test.dart:78` - `verdict.passed isFalse`, `reason == 'integrity: orphan_block=b1'` | ✅ PASS |
| KILL-04 | 100 iterations; divergences, seeds, expected/actual | `app/tool/kill_test_test.sh:44` `"100/100 iterations, 0 divergences"`; `:52-58` `"10/10 iterations, 1 divergences"`, `"iteration 7 (seed 7007)"`, expected and actual text. `bash tool/kill_test_test.sh` passed | ✅ PASS |
| KILL-05 | Non-zero exit on any divergence | `kill_test_test.sh:52` `assert_report "failing file counts" 1 …` (exit code checked) | ✅ PASS |
| KILL-06 | 100-iteration result recorded in the M05 PR | `.specs/features/m05-search-and-gate-1/kill-results.md:14` `100/100 iterations, 0 divergences`, exit 0, device SM-A356E; fault injection `:23` `5/5 iterations, 5 divergences`, exit 1 | ⚠️ Pending the PR (same as LOAD-08); the record itself is complete |

### P2: Local database encryption evaluation

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| CRYPT-01 | SQLCipher or equivalent with pinned Drift, on an unmerged spike branch | `/home/jon/dev/projects/jotline-spike28`, branch `spike/28-local-encryption`, `app/test/spike/encryption_spike_test.dart` (154 lines, commits `89beda0`, `8e7ca6e`); `docs/adr/0040-criptografia-do-banco-local.md:12` | ✅ PASS (not merged, not pushed) |
| CRYPT-02 | Records PowerSync compatibility with documentation or prototype | `docs/adr/0040-criptografia-do-banco-local.md:20` table row: SDK Dart 2.0 `EncryptionOptions(key: …)`, "Não prototipado", cites PowerSync "At Rest Encryption > Dart/Flutter" | ✅ PASS (documentation route) |
| CRYPT-03 | Migration cost, key storage, size, LOAD-03 and LOAD-06 encrypted vs not | `docs/adr/0040-criptografia-do-banco-local.md:22-25` (`rekey` 1,7 s; APK +0,27 MB / +3,35 MB; LOAD-03 402 vs 230 ms; LOAD-06 162 vs 115 ms) and `:30-39` (device); key storage `:41` "não foi prototipada"; `sqlcipher` encrypted on the device not measured (`:39`) | ⚠️ Partial, declared in the ADR: key storage is a recommendation with no prototype; `sqlcipher` encrypted on the device is unmeasured |
| CRYPT-04 | Portuguese ADR decides phase 2 or later; PRD §11 marked | `docs/adr/0040-criptografia-do-banco-local.md:47` "A criptografia entra na fase 2 … `sqlite3mc`"; `docs/prd/PRD.md:248` `- [x] … Decidido na ADR 0040`; `docs/adr/README.md:46` | ✅ PASS |
| CRYPT-05 | `main` keeps the unencrypted database | `git diff main...HEAD -- app/pubspec.yaml` adds `package_info_plus: ^10.2.2` and `perfect_freehand: 2.5.2+1` only | ✅ PASS |

### P3: Freehand drawing block

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| DRAW-01 | "Desenho" button in the block bar, after "Checklist" | `app/test/core/design_system/block_bar_test.dart:161` `labels.indexOf('Desenho') == labels.indexOf('Checklist') + 1`, `_expectActive(... active: false)`; `:176` `_calls == ['drawing']`; `:112` seven 48×48 buttons; `app/test/features/pages/presentation/page_screen_test.dart:835` | ✅ PASS |
| DRAW-02 | Tap opens full-screen drawing mode with an empty area | `app/test/features/blocks/presentation/drawing/drawing_screen_test.dart:85` (`Cancelar`, `Concluir`, `Área de desenho`, `Ferramentas de desenho`); `page_screen_test.dart:999` `find.byKey(DrawingScreen.areaKey) findsOneWidget` after tapping "Desenho" | ✅ PASS (emptiness of the area is implied by `DrawingContent([])`, not asserted on pixels) |
| DRAW-03 | 390×560 logical area, fitted and centered, points stored in logical coordinates | `app/test/features/blocks/data/drawing_content_test.dart:92` `logicalSize == Size(390, 560)`; `drawing_screen_test.dart:194` `getSize(_area) == Size(780, 1120)`, `points.first == StrokePoint(50, 60, 1)`. Sensor M18 killed | ⚠️ Partial: scale to logical coordinates is asserted; "centered between header and tools" is not |
| DRAW-04 | Tools, widths 3/6/12, colors, defaults Caneta/fino/Tinta preta | `drawing_screen_test.dart:85` semantics toggled for 9 controls (`('Caneta', true)` … `('Terracota', false)`); `:127` selection; `app/test/features/blocks/presentation/drawing/drawing_session_test.dart:33` pen/thin/ink; `drawing_content_test.dart:82` `StrokeWidth.values == [3, 6, 12]`, ids `['pen','highlighter']`, `['ink','accent','danger']` | ✅ PASS |
| DRAW-05 | Stroke with `perfect_freehand` in selected color and width | `drawing_session_test.dart:41` stores `Stroke(tool: pen, color: danger, width: 6, points: …)`; `app/test/features/blocks/presentation/drawing/drawing_painter_test.dart:86` `paints..path(color: colors.ink1)`; `:92` accent/danger tokens | ✅ PASS |
| DRAW-06 | Marca-texto at 3× width, 35 % opacity | `drawing_painter_test.dart:61` `highlighter bounds == wide(width 9)`; `:73` `paints..path(color: colors.accent.withValues(alpha: 0.35))`; `drawing_session_test.dart:65` stores width 12. Sensor M13 killed | ✅ PASS |
| DRAW-07 | Borracha removes the whole stroke it touches | `drawing_session_test.dart:79` `session.content.strokes == [_far]` at exactly `width/2 + 10`; `:88` kept at +0.1. Sensors M10, M12 killed | ⚠️ Spec-precision gap (spec says "touches"; the `width/2 + 10` reach lives in ADR 0039 and the task, not in the spec) |
| DRAW-08 | Undo/redo one step per stroke or erase | `drawing_session_test.dart:120` one drag erases three strokes, one `undo()` restores `[_line, middle, _far]`; `:144` undo/redo; `:167` new stroke clears redo (sensor M11 killed). The header buttons' tap is not widget-tested (only their enabled state) | ✅ PASS (logic) |
| DRAW-09 | Disabled button when nothing to undo/redo | `drawing_screen_test.dart:160` `button('Desfazer traço', enabled: false)` then `enabled: true` after a stroke; `app/test/core/design_system/jot_icon_button_test.dart:67` `painter.color == JotColors.light.inkDeco` | ✅ PASS |
| DRAW-10 | "Concluir" inserts a `drawing` block after the cursor block, or replaces an empty no-row block, in one write | `app/test/features/blocks/presentation/editor/page_editor_test.dart:92` `rows[1].type == 'drawing'`, `rows[1].contentJson == _first.toJson()`; `:132` `rows hasLength(1)`, `allRows() hasLength(1)`; `:160` writes at once; `page_screen_test.dart:999` `rows.map(type) == ['text','drawing','text']`, `rows[1].version == 0`; `drawing_screen_test.dart:213`. Sensor M20 killed | ✅ PASS |
| DRAW-11 | No block on "Concluir" of an empty new drawing | `drawing_screen_test.dart:229` `sink.saves isEmpty`, `sink.removes isEmpty` | ✅ PASS |
| DRAW-12 | Card at page width, 390:560 ratio, styled, labeled "Desenho" | `app/test/features/blocks/presentation/editor/components/drawing_block_test.dart:128` `card.width == page.width - 2 * JotSpace.space6`, `card.height closeTo(card.width * 560 / 390, 0.01)`; `:140` `BoxDecoration(color: bgFolha, border: Border.all(color: bgTrilho), borderRadius: rCard)`; `:162` `node.label == 'Desenho'`; `drawing_painter_test.dart:49` bounds scale with the factor | ✅ PASS |
| DRAW-13 | Tapping a card opens the drawing mode with its strokes | `drawing_block_test.dart:176` `fixture.opened == [fixture.drawing]`; `page_screen_test.dart:1029` `painter.content == content` | ✅ PASS |
| DRAW-14 | "Concluir" on an existing drawing updates `content_json` and `updated_at`, keeps `version` | `page_editor_test.dart:174` `rows.last.contentJson == _second.toJson()`, `updatedAt == DateTime.utc(2026,10,13,9)`, `version == 7`; `app/test/features/blocks/presentation/editor/block_sync_test.dart:522` same; `app/test/features/blocks/data/block_repository_test.dart:575`; `drawing_screen_test.dart:242` | ✅ PASS |
| DRAW-15 | Existing drawing with every stroke erased: soft-delete | `drawing_screen_test.dart:256` `sink.removes == ['n1']`; `page_editor_test.dart:196` `stored.deletedAt == DateTime.utc(2026,10,13,9)`; `block_sync_test.dart:552`; `drawing_block_test.dart:208,238` Backspace/Delete never delete the row. e2e `app/integration_test/editor_flow_test.dart:238` `rows[1].deletedAt isNotNull` (not executable here) | ✅ PASS |
| DRAW-16 | "Cancelar" leaves the drawing as it was, no confirmation | `drawing_screen_test.dart:270` `sink.saves isEmpty`, `sink.removes isEmpty`, `_area findsNothing` | ✅ PASS |
| DRAW-17 | Background saves current strokes, except a new drawing with none | `drawing_screen_test.dart:285` `saves.first.$2.strokes hasLength(1)`; `:301` `sink.saves isEmpty` | ✅ PASS |
| DRAW-18 | "Cancelar" after a background save writes back the original or soft-deletes a new drawing | `drawing_screen_test.dart:312` `sink.saves.last == ('n1', _existing)`; `:327` `sink.removes == ['new-node']`; `:343` system back. Sensor M19 killed | ✅ PASS |
| DRAW-19 | `content_json` has only strokes with tool id, color id, width, `[x, y, pressure]` | `drawing_content_test.dart:44` exact JSON `'{"strokes":[{"tool":"highlighter","color":"accent","width":6,"points":[[60.0,470.0,0.5],[100.4,440.0,0.62]]}]}'`; `:61` `json.keys == ['strokes']`, `stroke.keys == ['tool','color','width','points']`; `:96` x.05→0.1, x.04→0; `:103` 0.505→0.51; `app/test/features/blocks/presentation/editor/block_mapper_test.dart:248`. Sensor M09 killed | ⚠️ Spec-precision gap (rounding to 0.1 and 0.01 is defined by ADR 0039/design, not by the spec) |
| DRAW-20 | Page excerpt and search ignore drawings | `block_repository_test.dart:596` page excerpt ignores a drawing that comes first; `search_repository_test.dart:203`; `search_index_test.dart:148` | ✅ PASS |

### P3: Decision records and docs

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| ADR-01 | Portuguese ADR for local search; linked from the design | `docs/adr/0038-busca-local.md:3` "Aceita"; `docs/adr/README.md:44`; design lists the number at `.specs/features/m05-search-and-gate-1/design.md:449` | ✅ PASS (documentary; no test by design) |
| ADR-02 | Portuguese ADR for the drawing block | `docs/adr/0039-bloco-de-desenho.md:3` "Aceita", JSON example at `:15`; `docs/adr/README.md:45`; import boundary test `app/test/app_test.dart:267` `offenders, isEmpty` | ✅ PASS |
| DOC-01 | Schema change bumps `schemaVersion` with a tested migration from v2 | `app/test/core/database/app_database_test.dart` `schemaVersion == 4`; `migration_test.dart:36` (v2→v4) and `:93` (v3→v4); `app/test/drift/app_database/generated/schema_v3.dart`, `schema_v4.dart` committed | ✅ PASS |
| DOC-02 | New `.claude/docs` listed in `app/CLAUDE.md` References in the same commit | No new doc file; `blocked-tests.md` is listed in the commit that changed it (`6ea5b12`) | ✅ PASS |
| DOC-03 | `app/CLAUDE.md` lists seed, perf driver, kill test | `app/CLAUDE.md` Commands: `--tags perf --run-skipped`, `large_library_test.dart … --profile`, `kill_app.dart` build, `tool/kill_test.sh 100`, `tool/kill_test_test.sh` | ✅ PASS (commands run as written were checked by the author's subagent; I ran `bash tool/kill_test_test.sh` and the perf-tag test) |

### Edge cases

| Edge case | `file:line` + assertion | Result |
| --- | --- | --- |
| EDGE-01 punctuation/spaces only | `match_query_test.dart:61,69,76` `query.isEmpty isTrue`; `search_repository_test.dart:312` `hits('  ?! ') isEmpty`; `search_providers_test.dart:156` no SQL run | ✅ PASS |
| EDGE-02 FTS operators as text | `match_query_test.dart:85,91,96,101,105` e.g. `all('NEAR(a b)') == '"NEAR"* AND "a"* AND "b"*'`; `search_repository_test.dart:318` `recorder.errors, isEmpty` for six terms | ✅ PASS (the `"` doubling branch in `match_query.dart:28` is unreachable, since words are only letters/digits; mutant M01 is equivalent) |
| EDGE-03 bold/italic word shows as plain text with highlight | `search_excerpt_test.dart:146` `excerpt.spans.map(marked) == [false, true, false]` on a synthetic marker string | ⚠️ Weak: no block with bold/italic ranges goes through the index and `snippet()`; the guarantee comes from `json_extract(content_json, '$.text')` in `search.drift:6-14`, untested for marked blocks |
| EDGE-04 no "…" on the uncut side | `search_excerpt_test.dart:50,63,97,107` | ✅ PASS |
| EDGE-05 Cancelar during loading, no error | `search_screen_test.dart:273,288` `tester.takeException() isNull`; `search_providers_test.dart:103,116` auto-dispose | ✅ PASS |
| EDGE-06 single-point stroke is a dot | `drawing_painter_test.dart:110` `bounds.contains(const Offset(100, 100)) isTrue`; `drawing_content_test.dart:137`; `drawing_session_test.dart:96` | ✅ PASS |
| EDGE-07 unparsable `content_json`: empty area, no crash | `drawing_content_test.dart:128` `content.strokes isEmpty` for `''`, `'not json'`, `'[]'`, `'{"strokes":[{"tool":1}]}'` | ⚠️ Partial: parser only; no card or page test with a corrupt drawing row |
| EDGE-08 log file created | `integrity_log_test.dart:42` | ✅ PASS |

**Status**: ❌ Gaps present (1 genuine gap: INTEG-02; 2 partial/weak: EDGE-03, EDGE-07; spec-precision gaps flagged above).

---

## Discrimination Sensor

Depth: P0 / data-integrity path, so ≥ 5 manual fault injections; I ran 24. Scratch: `git worktree add --detach /tmp/claude-1000/verifier-wt` (HEAD `10c6e3e`), `pub get` + `build_runner` there, mutate, run the covering test files, `git checkout -- file`; drift mutants rebuilt generated code both ways. The worktree was removed with `git worktree remove --force`. Real tree `git status --porcelain` was empty before and after (identical); no `git stash` used.

| # | File:line | Mutation | Tests run | Killed? |
| - | --------- | -------- | --------- | ------- |
| M01 | `app/lib/features/search/data/match_query.dart:28` | Stop doubling `"` inside a word | match_query + search_repository | ❌ Survived: equivalent mutant, the branch is unreachable because `_wordPattern` only yields letters and digits |
| M02 | `match_query.dart:28` | Drop the trailing `*` (exact word instead of prefix) | same | ✅ Killed (25 failures) |
| M03 | `app/lib/features/search/data/search_repository.dart:31` | Stop filtering `p.deleted_at` | search_repository | ✅ Killed (5) |
| M04 | `search_repository.dart:32` | `last_edited_at DESC` → `ASC` | search_repository | ✅ Killed (2) |
| M05 | `search_repository.dart:32` | `p.id` tie-break → `p.id DESC` | search_repository | ✅ Killed (1) |
| M06 | `app/lib/core/database/integrity_check.dart:22` | Never report `notebook_without_owner` (`AND 1 = 0`) | integrity_check | ✅ Killed (1) |
| M07 | `integrity_check.dart:25` | Any member row counts as owner (`m.role = 'owner'` → `1 = 1`) | integrity_check | ✅ Killed (re-verificação 1) |
| M08 | `integrity_check.dart:36` | Duplicate position needs 3 rows (`> 1` → `> 2`) | integrity_check | ✅ Killed (1) |
| M09 | `app/lib/features/blocks/data/drawing_content.dart:74` | `_round(x, 10)` → `_round(x, 1)` (drawing rounding) | drawing_content | ✅ Killed (3) |
| M10 | `app/lib/features/blocks/presentation/drawing/drawing_session.dart:130` | Eraser reach `<=` → `<` | drawing_session | ✅ Killed (2) |
| M11 | `drawing_session.dart:171` | New action keeps the redo stack | drawing_session | ✅ Killed (1) |
| M12 | `drawing_session.dart:130` | Eraser removes only the first stroke it touches (`break`) | drawing_session | ✅ Killed (1) |
| M13 | `app/lib/features/blocks/presentation/drawing/drawing_painter.dart:12` | Highlighter opacity 0.35 → 0.5 | drawing_painter | ✅ Killed (1) |
| M14 | `app/lib/features/search/data/search_excerpt.dart:6` | Excerpt context 40 → 41 | search_excerpt | ✅ Killed (1) |
| M15 | `app/lib/features/search/presentation/search_screen.dart:23` | Debounce 150 → 100 ms | search_screen | ✅ Killed (1) |
| M16 | `app/lib/app.dart:21` | `addPostFrameCallback` → `Future.microtask` | app_test | ❌ Survived: near-equivalent, `check.run()` is already behind an async provider future; stronger variant M24 killed |
| M17 | `search_excerpt.dart:90` | Excerpt from the last matching block (`.reversed`) | search_excerpt | ✅ Killed (1) |
| M18 | `app/lib/features/blocks/presentation/drawing/drawing_screen.dart:119` | First stroke point not divided by scale | drawing_screen | ✅ Killed (1) |
| M19 | `drawing_screen.dart:104` | "Cancelar" after a background save does not write back | drawing_screen | ✅ Killed (1) |
| M20 | `app/lib/features/blocks/presentation/editor/page_editor.dart:255` | Drawing inserted at index 0 instead of after the caret block | page_editor | ✅ Killed (6) |
| M21 | `match_query.dart:32` | "Títulos" scope filters `{body}` | match_query + search_repository | ✅ Killed (5) |
| M22 | `app/lib/core/database/search.drift:19,37` | Triggers index deleted blocks | search_index + search_repository | ✅ Killed (2) |
| M23 | `search.drift:20,38` | Triggers index drawing blocks | same | ✅ Killed (2) |
| M24 | `app/lib/app.dart:23` | Integrity check never runs | app_test | ✅ Killed (2) |

**Sensor depth**: P0-full (manual, 24 mutations)
**Outcome**: 22/24 killed after re-verificação 1. Survivors: M01 (equivalent), M16 (near-equivalent); both non-blocking.

---

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code / no scope creep | ✅ No feature beyond the spec found in `lib/`. ADR 0041 (editor verification only on Android) and the `blocks_page_edits` index (schema v4) are outside the original task list but are recorded decisions (`load-results.md:43`, ADR 0041) |
| Surgical changes | ✅ `PageRepository`/`NotebookRepository` refactors keep their tests; no test removed (see below) |
| Matches patterns | ✅ Feature-first layout, reactive Drift streams, Riverpod hand-written providers |
| No explanatory comments in Dart | ✅ `grep` for non-`///` comments over every changed `.dart` file: none. No `// ignore:`, `TODO`, `FIXME` |
| Shell comments | ⚠️ `app/tool/kill_test.sh:2-9` has an explanatory header comment block (usage and behavior); the rule says no explanatory comments in code and offers `///` only for Dart. Minor, arguable |
| Test names start with the requirement code | ✅ All new tests (the 3 non-conforming names in changed files are older "text scale 2.0 …" tests) |
| Only `…/presentation/editor/` imports `super_editor` | ✅ (`app_test.dart` scan passes; no offender) |
| Only `…/presentation/drawing/` imports `perfect_freehand` | ✅ Only `drawing_painter.dart:4`; `app_test.dart:267` enforces it |
| No literal color or font outside `lib/core/theme/` | ✅ `grep Color(0x|Colors.|fontFamily: '|GoogleFonts` over changed `lib/` outside theme: empty; UI strings only via l10n (no `Text('…')` literals in the new screens) |
| Tests map to ACs, no unclaimed tests | ✅ Spot-checked search, drawing, integrity, kill |
| Guidelines followed | `app/.claude/docs/testes.md`, `docs/adr/0015`, `app/CLAUDE.md` rule "a test that cannot run is a stop" |

Test integrity: declared tests went from 705 (`5f2fcd8`) to 948 (`HEAD`), +243. Eight names disappeared, all superseded renames: `DB-01 schemaVersion 2→4`, `DB-04` (v1→2 now →4), `SAVE-10 four→five ids`, `BAR-01 six→seven buttons`, `BAR-03 no Desenho→Desenho`, `COMP-03 → COMP-03, DRAW-09` (supersession declared in DRAW-09), `NBLIST-10 no Buscar→SRCH-01`, `BAR-01` in `page_screen_test.dart`. No assertion was weakened.

---

## Gate Check

- **Gate commands** (from `app/`): `fvm dart run build_runner build --delete-conflicting-outputs`, `fvm flutter analyze`, `fvm dart format --set-exit-if-changed lib test integration_test`, `fvm flutter test`, `fvm flutter test --tags perf --run-skipped`, `bash tool/kill_test_test.sh`
- **build_runner**: exit 0
- **analyze**: `No issues found!` (exit 0)
- **format**: `Formatted 219 files (0 changed)` (exit 0)
- **test**: `+979 ~1: All tests passed!`, 0 failed, 1 skipped (exit 0)
- **perf tag**: `+7: All tests passed!` (exit 0)
- **kill_test_test.sh**: `all kill_test.sh report checks passed` (exit 0)
- **Test count before feature**: 705 declared (`5f2fcd8`)
- **Test count after feature**: 948 declared (`HEAD`); delta +243
- **Skipped**: `test/perf/seed_library_test.dart` (library-level `@Tags(['perf'])`, skipped by `app/dart_test.yaml` by design; run explicitly above)
- **Failures**: none
- **Not run**: `fvm flutter build apk --debug` (part of the tasks.md Build gate; no Android toolchain run here), `integration_test` and `flutter drive` (no device). Not executable here: `app/integration_test/search_flow_test.dart` (SRCH-09/16/21, RF-05), `app/integration_test/editor_flow_test.dart:181` (RF-06), `app/integration_test/perf/large_library_test.dart` (LOAD-02…06), `app/integration_test/kill/kill_app.dart` (KILL-01…03) and the 100-iteration kill run. Evidence for those is the code (read), the unit-level equivalents above, and `kill-results.md` / `load-results.md`.

---

## Fix Plans

### F1 (Major for the sensor, small effort): INTEG-02 owner role is untested

- **Root cause**: `integrity_check_test.dart:77` empties `notebook_members`, so a notebook with only a non-owner member never reaches the `m.role = 'owner'` condition at `integrity_check.dart:25`. Mutant M07 survives.
- **Fix task**: add `test('INTEG-02: a notebook whose only member is not the owner fails with its id')` that sets `UPDATE notebook_members SET role = 'editor'` (`'editor'` or `'viewer'`, the other values `notebook_members.role` allows (`app/lib/core/database/tables/notebook_members.dart:10`)) and expects `notebook_without_owner` with `[notebookId]`.
- **Verify**: re-run mutant M07; it must fail.
- **Priority**: Major (blocks PASS).

### F2 (Minor): EDGE-07 at card or page level

- **Gap**: only `DrawingContent.fromJson` is tested. Add a widget test in `drawing_block_test.dart` (or `page_screen_test.dart`) that seeds a `drawing` row with `content_json = 'not json'` and expects the card to render, no exception.

### F3 (Minor): EDGE-03 with a real bold/italic block

- **Gap**: `search_excerpt_test.dart:146` feeds a synthetic string. Add a `search_repository_test.dart` case that writes a block with a bold range through `BlockContent`, then asserts `snippet().excerpt.text` is plain with the marked word.

### F4 (Optional): INTEG-01 and `PRAGMA integrity_check`

- Neither the post-frame scheduling (M16) nor the `PRAGMA integrity_check` call is pinned by a test. Low risk, mention only.

### Spec-precision follow-ups (edit `spec.md`, no code)

1. SRCH-11: the example "04 out" contradicts `RelativeDates.day` ("4 out", `d MMM`); say which.
2. SRCH-13: define whether the 2-line truncation "…" is the text overflow ellipsis.
3. DRAW-07: state the eraser reach (`width / 2 + 10`) or "touch" semantics.
4. DRAW-19: state the rounding (0.1 and 0.01).
5. INTEG-06: state the log line format.
6. KILL-02: state that a save that committed just before the kill is also accepted.
7. EDGE-03/EDGE-04 and EDGE-01/02/05/06/07/08 reuse codes of earlier milestones' edge cases in several test names (for example `page_repository_test.dart:319`); prefix by story if searches by code need to be unambiguous.

---

## Requirement Traceability Update

`spec.md` was not edited by the Verifier. Proposed statuses once F1 is done:

| Requirement | Previous Status | New Status |
| ----------- | --------------- | ---------- |
| SRCH-01…SRCH-21 | Pending / Implementing | ✅ Verified (SRCH-11 and SRCH-13 with spec-precision notes) |
| LOAD-01, LOAD-04, LOAD-05, LOAD-07, LOAD-09 | Pending | ✅ Verified |
| LOAD-02, LOAD-03, LOAD-06 | Pending | Recorded, target missed, accepted by the user (2026-10-19) |
| LOAD-08, KILL-06 | Pending | Records complete; PR not opened yet |
| INTEG-01, INTEG-03…INTEG-08 | Pending | ✅ Verified |
| INTEG-02 | Fail when a non-deleted notebook has no `owner` row | `app/test/core/database/integrity_check_test.dart:87` - 'a notebook whose only member is not an owner fails'; fails under M07 | ✅ PASS |
| KILL-01…KILL-05 | Pending | ✅ Verified (KILL-01 by reading plus `kill-results.md`) |
| CRYPT-01, 02, 04, 05 | Pending | ✅ Verified; CRYPT-03 verified with declared gaps |
| DRAW-01…DRAW-20 | Pending | ✅ Verified (DRAW-03 partial: centering unasserted) |
| ADR-01, ADR-02, DOC-01…DOC-03 | Pending | ✅ Verified |
| EDGE-01, 02, 04, 05, 06, 08 | Pending | ✅ Verified |
| EDGE-03, EDGE-07 | Pending | ⚠️ Weak (F3, F2) |
| GATE-01…GATE-06 | Pending | Out of scope for this run |

---

## Summary

**Overall**: ❌ Not Ready (one test to add; everything else is in good shape)

**Spec-anchored check**: 88 requirements minus 6 GATE = 82 in scope. 1 gap (INTEG-02), 2 partial/weak (EDGE-03, EDGE-07), 3 pending-but-recorded or partial (LOAD-08/KILL-06 PR, CRYPT-03, DRAW-03), 3 recorded-and-accepted misses (LOAD-02, LOAD-03, LOAD-06), 7 spec-precision gaps flagged (SRCH-11, SRCH-13, INTEG-06, KILL-02, DRAW-07, DRAW-19, LOAD-04 method), plus one note on reused edge-case codes.
**Sensor**: 21/24 mutants killed; survivors M01 (equivalent), M16 (near-equivalent), M07 (real gap).
**Gate**: 979 passed, 0 failed, 1 skipped by design; analyze clean; format clean; perf-tag 7 passed; kill-script test passed.

**What works**: the search stack (FTS5 triggers, MatchQuery, repository ordering and exclusions, excerpt boundaries, screen debounce), the drawing model, session, painter and editor sync, the integrity check and log, the kill-test verify logic and report script, the ADRs and docs, and the CRYPT records.

**Issues found**: F1 (INTEG-02 owner role), F2 (EDGE-07), F3 (EDGE-03), the shell-comment style item, and the `spec.md`/`tasks.md` status housekeeping.

**Next steps**: implement F1 (and F2/F3 if wanted), re-run `fvm flutter test test/core/database/integrity_check_test.dart` and mutant M07, then re-verify. Open the PR with `load-results.md` and `kill-results.md` to close LOAD-08 and KILL-06.

---

## validate_state.py

Command (from `/home/jon/dev/projects/jotline`): `python3 /home/jon/.claude/skills/tlc-spec-driven/scripts/validate_state.py m05-search-and-gate-1`

Output, exit code 1 (expected while the verdict is FAIL):

```
  ERROR m05-search-and-gate-1: validation.md verdict is FAIL - route the ranked gaps to fix tasks, then re-verify (feature is not done)

validate_state: 1 error(s) across [m05-search-and-gate-1]
```

The report is real (verdict filled, `file:line` evidence present); the exit code reflects only the FAIL verdict. After F1 lands and the sensor is re-run, flip the verdict to PASS and re-run the script.


## Re-verificação 1 (2026-10-23)

- M07 reapplied in a temporary worktree (`m.role = 'owner'` -> `1 = 1`): the new test `INTEG-02: a notebook whose only member is not an owner fails` (`integrity_check_test.dart:87`) FAILS (+10 -1). Mutant killed. Worktree removed; real repo status unchanged (only validation.md untracked).
- Gates in `app/`: `fvm flutter analyze` no issues; `fvm dart format --set-exit-if-changed lib test integration_test` 219 files, 0 changed; `fvm flutter test` 980 passed, 1 skipped, 0 failed.
- INTEG-02: PASS. No blocking gap remains. Verdict: **PASS**.

### Ressalvas conhecidas (non-blocking)

EDGE-03 (weak, no real bold/italic block), EDGE-07 (card/page level), INTEG-01 (M16 near-equivalent), DRAW-03 (centering), CRYPT-03 (partial).
