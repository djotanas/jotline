# M04 — Validation

## PERF-01 — Launch to new page with the editor

Metric: the M03 metric, extended. An integration test in profile mode drives the app and measures only app time, with no human pauses. The clock starts when the app is built and stops at the first frame where `BlockEditor` is laid out and the page title has focus. The notebook is seeded through the repository, so the keyboard is not involved. Four marks are reported: `toListMs` (notebooks list shown), `toNotebookMs` (notebook open), `toPageMs` (new page in the tree, the M03 stop point) and `toEditorMs` (editor laid out, title focused). **PERF-02 compares `toEditorMs` with 1000 ms.**

Test: `app/integration_test/perf/launch_to_new_page_test.dart`, driver `app/test_driver/perf_driver.dart`.

Limit: the clock starts at the first `pumpWidget`, so engine and process start are not included. For that, also record the cold start from `adb shell am start -W -n com.jon.jotline/.MainActivity` (`TotalTime`) after `adb shell am force-stop com.jon.jotline`, with the profile APK installed.

### Procedure

Same as M03 (`.specs/features/m03-notebooks-and-pages/validation.md`), on the same device:

1. Mid-range Android device, USB debugging on, battery saver off, normal brightness. Same animation scales in all runs (`adb shell settings get global window_animation_scale`, `transition_animation_scale`, `animator_duration_scale`). `animator_duration_scale` may return `null` (default, equals 1.0): record it as `1.0 (default)`. Note battery saver and brightness. `adb` is in `$ANDROID_HOME/platform-tools`.
2. From `app/`, five times (one process each, so each run is a fresh start of the app process):

   ```
   fvm flutter drive --driver=test_driver/perf_driver.dart \
     --target=integration_test/perf/launch_to_new_page_test.dart \
     --profile -d DEVICE_ID
   ```

   Before each run, `rm -f app/build/launch_to_new_page.json`. Each run writes that file; if it is missing the run failed, so repeat it. Copy it as `run-N.json` before the next run. Discard nothing silently: if the first run is much faster than the rest, say so in the result.
3. Cold-start cross-check, after the first drive (it builds `app-profile.apk`): `adb install -r app/build/app/outputs/flutter-apk/app-profile.apk`. Then 5 times: `adb shell am force-stop com.jon.jotline; sleep 2; adb shell am start -W -n com.jon.jotline/.MainActivity`, and write down `TotalTime` (ms).
4. Sanity: `fvm flutter test integration_test/perf -d DEVICE_ID` (debug) must pass; it writes no json and its time is not a measurement.
5. Record the runs and medians in the table.

Steps checked on the `jotline_api35` emulator (software rendering, no KVM): the profile drive passes and writes the four marks. Emulator numbers are not the measurement.

### Result

| Field | Value |
| --- | --- |
| Device model | Samsung Galaxy A35 5G (SM-A356E), via wireless adb |
| Android version | 16 |
| Build | profile |
| Animation scale (window/transition/animator) | 1.0 / 1.0 / 1.0 |
| Battery saver / brightness | off / 96; battery 14–15 %, charging (AC) |
| `toListMs` runs / median | 68, 87, 86, 75, 72 / **75** |
| `toNotebookMs` runs / median | 110, 141, 133, 114, 142 / **133** |
| `toPageMs` runs / median | 189, 218, 200, 205, 217 / **205** |
| `toEditorMs` runs / median | 190, 219, 201, 206, 218 / **206** |
| `am start -W` TotalTime runs / median | 761, 752, 727, 766, 913 / **761** |

PERF-02: if the `toEditorMs` median is 1000 ms or more, a follow-up issue is drafted with this measurement.

Measured 2026-10-17. PERF-02: `toEditorMs` median 206 ms, below 1000 ms; no follow-up issue. The first run is not faster than the rest. The cold start (761 ms, process start to first frame) and `toEditorMs` (first `pumpWidget` to editor) are measured separately; their sum, about 967 ms, is only a rough upper estimate of icon to editor, since the two windows overlap at the first frame.

---

## Verifier report

**Date**: 2026-10-17
**Spec**: `.specs/features/m04-block-editor/spec.md`
**Diff range**: `main..milestone/m04-block-editor` (`7b3b2bb`…`cc046f6`, 25 commits)
**Result**: PASS

### Task completion

| Task | Status | Notes |
| --- | --- | --- |
| T1–T23 | ✅ Done | Marked in `tasks.md`, one commit each |
| T24 | ✅ Done | `2b396f7` |
| T25 | ✅ Done | `cc046f6` |
| T26 | ✅ Done | Result table above, SM-A356E, 2026-10-17 |

### Spec coverage

- Every EDIT, BAR, CHECK, SAVE, EDITED, EXCERPT, BMOVE and EDGE ID is cited by at least one test name, except EDIT-12 (kept by the unchanged M03 page tests) and SAVE-01 (asserted through row counts in `block_sync_test.dart` and `integration_test/editor_flow_test.dart:138`).
- E2E-01: `integration_test/editor_flow_test.dart:58` (test named by RF-03, RF-04), asserts types, text, bold/italic range `Mark(10, 15, …)` at `:150` and `checked` at `:153–154`. Re-run on the SM-A356E on 2026-10-17: all 5 `integration_test` files passed (3 min 17 s).
- SPIKE-01…11, ADR-01, DOC-03: ADRs 0035–0037 exist; `app/CLAUDE.md:15` names `super_editor` and ADR 0035; PRD §11 marks the question resolved; `spike/22-block-editor` is not merged into `main` or this branch. SPIKE-06 deferred to #67 by decision.
- DOC-01: `app/.claude/docs/design.md:62–63`. DOC-02: `app/.claude/docs/testes.md` RF-03 row kept, ADR sentence dropped in `2b396f7`.
- PERF-01, PERF-02: ✅ `toEditorMs` median 206 ms (Result table above); no follow-up issue.
- Spec traceability table: every ID ✅ Verified.

### Discrimination sensor

Scratch worktree at `HEAD`, real tree porcelain unchanged after cleanup.

| # | File:line | Mutation | Killed? |
| --- | --- | --- | --- |
| 1 | `app/lib/features/blocks/presentation/editor/block_sync.dart:109` | New row always `AtStart()` instead of `After(previous)` | ✅ 4 tests (SAVE-06, SAVE-02, EDIT-05) |
| 2 | `app/lib/features/blocks/presentation/editor/block_sync.dart:120` | Removed `Trash(blockId)` for nodes gone from the document | ✅ 5 tests (SAVE-07, SAVE-08, SAVE-09, EDGE-05) |
| 3 | `app/lib/features/blocks/presentation/editor/block_drag_controller.dart:86` | Drop index `gap` instead of `gap - 1` when moving down | ✅ 2 tests (BMOVE-02, BMOVE-03) |

**Killed**: 3/3.

### Gate

`fvm flutter analyze`: no issues. `fvm dart format --set-exit-if-changed`: 0 changed. `fvm flutter test`: 738 passed, 0 failed. `fvm flutter test integration_test -d 192.168.1.2:42913` (SM-A356E): 5 passed, 0 failed. `build apk --debug` not run separately; the e2e run built the debug APK.

### Gaps

None. Open outside M04: SPIKE-06 manual check in #67; the "every artboard matches" success criterion is a visual review for the PR.
