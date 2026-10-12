# M04 block editor spike: report (#22)

Spike branch `spike/22-block-editor`, not to be merged (SPIKE-11). Run on 2026-10-12, Flutter 3.47.5 / Dart 3.13.4 (`app/.fvmrc`).

| Prototype | Package version used | Tests |
| --- | --- | --- |
| [`super_editor/`](super_editor/) | `super_editor 0.3.0-dev.52` (pub.dev, prerelease) | 26, all passing |
| [`flutter_quill/`](flutter_quill/) | `flutter_quill 11.6.0` (pub.dev) | 11, all passing (2 assert gaps) |
| [`appflowy_editor/`](appflowy_editor/) | `appflowy_editor` git `main` @ `01eccc6` (6.2.0 from pub.dev does not compile) | 13, all passing (1 asserts a gap) |

Each prototype has the same `lib/block_row.dart` (row shaped like `blocks`, our provisional `content_json`, an in-memory store that records every write and only soft-deletes), a `block_mapper.dart` (row ↔ library document), a `block_sync.dart` (detects touched blocks and writes only those) and a page with the six canvas bar buttons plus a custom "Desenho" stub. Run with `fvm flutter test` inside each folder.

Provisional type identifiers used: `text`, `heading`, `bulleted_list_item`, `checklist_item` (the final ones belong to the block model ADR). The provisional `content_json` shape `{"text", "marks":[{start,end,type}], "checked"}` worked for all three. No candidate forced its own format into storage.

## Devices actually used

- **Android emulator** `sdk_gphone64_x86_64`, Android 15 (API 35), AVD `jotline_api35`, Gboard 14.2.09 (preloaded). The emulator has a hardware keyboard enabled, so Gboard ran as its *floating* keyboard, opened with Alt+K. Português (Brasil) was added to Gboard for the test. The pt-BR dictionary was only available partway through the session, so pt-BR autocorrect was verified on super_editor and flutter_quill, not on appflowy_editor. Input was driven by `adb shell input tap` on the Gboard keys, which is real IME input. What was saved was read back from logcat (`ROWS …` lines).
- **No physical Android device. No iOS simulator** (Linux/WSL). Everything iOS is **not verified**. Emulator results are not real-device results.

## Comparison table

Legend: **pass** · **partial** (works with our own workaround, or with a gap) · **fail** · **not verified**.

| Criterion | super_editor | flutter_quill | appflowy_editor |
| --- | --- | --- | --- |
| **SPIKE-01** prototype on the pinned Flutter | **pass**. Compiles and runs on 3.47.5. Android build needed a `compileSdk 36` override for `super_keyboard 0.4.1` (`android/build.gradle.kts`) | **pass**. Builds with no changes | **fail** for the latest release. `6.2.0` does not compile: `DeltaTextInputService` lacks `TextInputClient.onFocusReceived` (`lib/src/editor/editor_component/service/ime/delta_input_service.dart:7`). Fixed on `main` @ `01eccc6` (2026-08-06), never released. Also needs the `compileSdk 36` override |
| **SPIKE-02** one row per block, ids kept / split / merge | **pass**. Node ids are free strings, so loaded nodes use the block id (`block_mapper.dart` `toNode`). Typing keeps the id (`test/editor_page_test.dart:58`). Split gives the new id to the lower node (`:70`). Merge keeps the upper id and soft-deletes the lower (`:92`). Type changes keep the id (`:170`). Nodes the editor creates get UUID v4 (`lib/src/core/editor.dart:46`), so the mapping assigns our id on first save | **partial**. Quill has **no line ids**. Identity rides on the `Line` object via an `Expando`. Split keeps the upper object (`test/block_sync_test.dart:134`). **Merge keeps the lower object**, the opposite of SPIKE-02; recovered with a heuristic over a snapshot of line end offsets (`lib/block_sync.dart` `_onChange`, test `:146`). Replacing the document drops every identity (`:212`) | **partial**. Nodes have ids (`nanoid(6)`, `lib/src/core/document/node.dart:43`). Split and merge behave correctly (`test/block_sync_test.dart:84`, `:100`). But `Node.type` is `final` (`node.dart:68`), so **every type change is delete + insert with a new id** (`lib/src/editor/command/text_commands.dart:257-265`, `.../convert_to_paragraph_command.dart:43-57`). Recovered by pairing delete/insert at the same index (`lib/block_sync.dart`, test `:111`) |
| **SPIKE-03** detect one block's change without serializing the page | **pass**. `Editor.addListener(FunctionalEditListener)` delivers `DocumentEdit(NodeChangeEvent/NodeInserted/NodeRemoved/NodeMoved)` per transaction (`core/editor.dart:1037`, `core/document.dart:143-229`). Test: after typing, the pending set is exactly `{a}` (`editor_page_test.dart:58`). Caveats: `ReplaceNodeCommand` logs Removed+Inserted for the same id (`default_editor/multi_node_editing.dart:668`), and `MoveNodeCommand` logs a move for every shifted node (`:600-655`). So reconcile against the final document, and diff order with a longest-increasing-subsequence (test `editing_rules_test.dart:150`: one move = one write) | **partial**. `document.changes` gives the change `Delta`. Touched lines come from walking its offsets with `queryChild`, and merges need an offset snapshot. The stream is async/broadcast. Also the IME receives the **whole document plain text** and Quill diffs old/new strings on every keystroke (`editor/raw_editor/raw_editor_state_text_input_client_mixin.dart:233-248`) | **partial**. `transactionStream` gives operations with **paths, not ids**, for text updates. Implemented by replaying the top-level id list op by op (`lib/block_sync.dart`). Test: pending set `{2}` after typing (`test/block_sync_test.dart:69`) |
| **SPIKE-04** lossless round-trip of `content_json` | **pass** (`test/block_mapper_test.dart:46`, `:58`). Includes overlapping bold+italic, accents, a flag emoji, empty text, `checked` only on items. Note: `attributed_text` spans have an **inclusive** end; the mapper converts | **pass** (`test/block_sync_test.dart:49`) | **pass** (`test/block_mapper_test.dart:46`) |
| **SPIKE-05** 4 types, bold, italic, checklist toggle, custom block | **pass**. `ParagraphNode` (+`header1`), `ListItemNode.unordered`, `TaskNode`, `bold`/`italics` attributions, checkbox tap writes one row (`editor_page_test.dart:158`), bold on a selection (`:193`), italic for the next text (`:218`). Custom `BlockNode` + `ComponentBuilder` renders (`:261`, `lib/drawing_stub.dart`) | **pass**. Header 1, `list: bullet`, `list: checked/unchecked`, bold/italic (`:205`), checked toggle (`:168`). Custom block via `EmbedBuilder` (an embed inside its own line), rendered on the emulator | **pass**. Heading, bulleted_list, todo_list, `toggleAttribute` (`:192`), checked toggle (`:180`). Custom block rendered by reusing the divider builder's `wrapper`; a real custom block must implement `SelectableMixin` like `divider_block_component.dart` |
| **SPIKE-06** accented pt-BR, autocorrect, composing (Android) | **pass on the Android emulator**. Gboard pt-BR: typing, auto-capitalization, long-press `á`, suggestion pick replacing the composing word ("naá" → "na área"), autocorrect "nao voce" → "Não você", English autocorrect "wrod" → "word", Enter splits, Backspace merges, checkbox tap. Simulated composing in tests (`editor_page_test.dart:230`). Open upstream issue [#2269](https://github.com/Flutter-Bounty-Hunters/super_editor/issues/2269) ("IME accent panel can result in an invalid character") | **partial on the Android emulator**. Typing, long-press `á` and autocorrect "nao voce" → "Não você" all worked. **Gboard's on-screen Enter did not split** (twice). A raw `KEYCODE_ENTER` did. Quill only forwards `performAction` to an optional app callback (`raw_editor_state_text_input_client_mixin.dart:253-255`), probably the cause; fixable with `onPerformAction` (not tried) | **fail on the Android emulator** (stopped investing). Typing and long-press `á` worked. A suggestion pick did not apply (one try). **Neither Gboard's Enter nor `KEYCODE_ENTER` split the block** |
| **SPIKE-06** (iOS simulator / device) | **not verified** | **not verified** | **not verified** |
| **SPIKE-07** license | **pass**. MIT | **pass**. MIT | **partial**. `AGPL-3.0 OR MPL-2.0`. MPL-2.0 is file-level copyleft: usable next to MIT code if its files stay MPL and changes to them are published. Needs a decision |
| **SPIKE-07** latest release / maintenance | **partial**. Latest on pub.dev `0.3.0-dev.52` (2026-06-11), a **prerelease**. Last stable `0.2.7` (2024-06-11). Repo `Flutter-Bounty-Hunters/super_editor`: last commit 2026-10-09, 325 open issues, 1.9k stars, commits almost all from one maintainer. pub.dev score 60/160 (`has:error`) | **pass**. `11.6.0` (2026-09-16), several contributors, last commit 2026-09-16, 364 open issues, 2.9k stars, 150/160 pub points | **partial**. `6.2.0` (2025-12-08) cannot be used on our Flutter. Repo last commit 2026-08-06, 161 open issues. pub.dev 60/160 (`has:error`). Heavy dependencies (`file_picker`, `pdf`, `http`, `device_info_plus`, …); 3 plugins flagged for the Kotlin Gradle Plugin |
| **SPIKE-07** in-edit background r10 + 12 px bleed | **pass**. A wrapping `ComponentBuilder` paints it on the block whose view model has a selection (`lib/editor_page.dart` `ActiveBlockBuilder`, test `editor_page_test.dart:266`, seen on the emulator). Any decoration must be inside `IgnorePointer`: the Android tap recognizer sits *below* the content (`default_editor/document_gestures_touch_android.dart:1301-1325`), so an opaque box swallows taps | **fail** without forking. Lines are drawn by internal `EditableTextLine`/`EditableTextBlock`, with no per-line decoration hook tied to the caret | **not verified** |
| **SPIKE-07** drag handle at the left of the block in edit | **partial**. Drawn in the same wrapper with the "Mover bloco" label (test `:266`). Decorative: a widget outside the component bounds is not hit-testable, so a 44 px target needs layout room. `MoveNodeRequest` exists; no built-in drag UI | **fail**. No per-line widget hook | **not verified** (`showActions`/`actionBuilder` exist, desktop-oriented) |
| **SPIKE-07** checked item muted + strikethrough | **pass**. Strikethrough built in (`default_editor/tasks.dart:357-363`); muted color via a `TaskComponentBuilder` subclass (`MutedTaskComponentBuilder`, seen on the emulator). CHECK-01 (22×22 checkbox, ≥44 px row) needs our own task component: the built-in uses a Material `Checkbox` (`tasks.dart:383`) | **not verified**. Not struck by default; `DefaultStyles` is the hook | **pass** (default style struck + muted, seen on the emulator) |
| **SPIKE-07** block bar docked above the keyboard | **not verified** (floating keyboard on the emulator). Library-independent with `Scaffold` insets; super_editor also ships `KeyboardPanelScaffold` (not exercised) | **not verified** | **not verified** |
| Enter/Backspace rules (EDIT-07/08/10, CHECK-04/06/07) | **pass**, all built in (`editing_rules_test.dart:41`, `:51`, `:64`, `:79`, `:92`, `:105`; `editor_page_test.dart:107`, `:128`, `:146`) | **partial**. CHECK-06 passes (`:188`). **Gaps**: Enter after a checked item creates a *checked* item (`:176`); Backspace at the start of a list item *merges* instead of turning it into text (`:195`). Needs custom Quill rules | **partial**. **Gap**: splitting a heading gives a paragraph below (`:174`) |
| Drag-to-reorder | **partial**. `MoveNodeRequest` + `NodeMovedEvent`; one row written per move with the LIS diff (`editing_rules_test.dart:150`). Drag UI is ours | **fail**. Moving a line = delete + insert of text, so a new `Line` object | **partial**. `Transaction.moveNode` keeps the node; UI is ours |
| Library format forced into storage | none | none | none (`Node.fromJson` even ignores ids, `node.dart:52-57`) |

## Recommendation

**super_editor**, conditional on the iOS checklist below passing on a real iPhone or a Mac simulator before the ADR is accepted.

1. It is the only candidate whose own model matches ADR 0005. Nodes carry string ids we control, split/merge/type changes keep the right id with no heuristics, and the editor emits a per-transaction change log naming the touched nodes. That gives SPIKE-02 and SPIKE-03 without workarounds.
2. Every Enter/Backspace rule in the spec is already the library's default behavior. All the canvas styling except the bar was reproduced with public extension points (component builders, stylesheet).
3. On the Android emulator with Gboard pt-BR, it was the only candidate where everything worked, including the on-screen Enter.

flutter_quill is the most mature package. But its flat Delta has no block identity: merge keeps the wrong object, undo and document replacement drop identity, and the canvas in-edit styling would need a fork. appflowy_editor is out for now: its latest release does not compile on our Flutter, its license needs a separate decision, type changes destroy node ids, and Enter did not work on the emulator.

## Risks (super_editor)

- **Prerelease dependency.** Only `0.3.0-dev.N` builds exist since 2024; the stable `0.2.7` is two years old. Pin an exact version and treat upgrades as tasks.
- **Bus factor.** Commits come almost entirely from one maintainer.
- **Android build friction.** `super_keyboard 0.4.1` compiles against android-34, so the app needs a `compileSdk` override. It also applies the Kotlin Gradle Plugin, which Flutter warns future versions will refuse to build.
- **iOS not verified at all**, including IME accent panel issue #2269 and floating cursor.
- **Pointer pitfall.** Any decoration inside a component must be `IgnorePointer`, or taps stop placing the caret. Covered by the `EDIT-02` test.
- **IME open issues.** 41 IME results in the tracker, mostly CJK and Korean.
- **The mapping layer is ours** (~150 lines in the spike) and is where the subtle bugs will live. #23 must keep its tests.

## Manual checklist for what could not be verified

Run on an iPhone (iOS keyboard pt-BR) and on a physical mid-range Android phone (Gboard pt-BR, no hardware keyboard) with `spikes/m04-editor/super_editor` (`fvm flutter run -d <device>`). Watch `ROWS …` in the console after each step.

1. Tap the end of "Belém cedo…", type `nao voce acao ` with autocorrect on → saved text reads `Não você ação ` (or what the keyboard suggests), and no stray characters.
2. Long-press `a` and pick `ã` from the accent panel. Then on iOS hold `e` and slide to `é` → exactly one accented character saved (issue #2269).
3. Type `naçã` and pick a suggestion → the word is replaced, not duplicated.
4. iOS: press-and-hold the space bar (floating cursor) to move inside the paragraph, then type → text lands at the cursor.
5. Enter in the middle of a paragraph → two rows; the upper keeps its id. Backspace at the start of the lower → one row.
6. Enter at the end of "Comprar bilhete" (checked) → new unchecked item. Enter again on the empty item → text block.
7. Tap a checkbox → only that row changes and the keyboard does not open.
8. With the docked keyboard open, the block bar sits right above it (BAR-01), and the in-edit background stays aligned while scrolling.
9. iOS: dictation into a paragraph → text saved.
10. Background the app right after typing, kill it, reopen. The spike store is in memory, so this only checks no crash; SAVE-13 belongs to #24.

## What #23 and #24 will need

- **Mapping layer** (`BlockMapper`): row ↔ node for the four types; `heading` = `ParagraphNode` with `blockType: header1`; marks ↔ `AttributedText` spans (end inclusive ↔ exclusive); `checked` only on `TaskNode`.
- **Change detection** (`BlockSync`): an `EditListener` collects node ids from `DocumentEdit` events. On flush (500 ms debounce plus page exit and app background), each touched id is reconciled against the final document: present means upsert, missing means `moveToTrash`. Keep a node id → block id map. Loaded nodes use the block id; editor-created nodes get the id from `BlockRepository.create`. Defer empty new nodes (EDIT-05). After any `NodeMovedEvent`, reorder with an LIS diff, so one drag writes one row via `move(id, After(prev))`.
- **Repository gaps**: `BlockRepository.updateContent` writes only `content_json`; a type change (BAR-05/06, CHECK-07) also needs `type`, so #23 needs an `update(id, type:, contentJson:)` or similar. `create` generates its own id, so the sync becomes async and must keep insert-before-update order.
- **Own components**: task component (22×22 checkbox, ≥44 px row, Riscado color, CHECK-08 semantics), in-edit wrapper (Realce, radius 10, 12 px bleed, "Mover bloco" handle), stylesheet with Literata/Schibsted and weight 600 bold.
- **Paste (EDIT-11)** was not tested in any candidate.

## Spec points revised after the spike (2026-10-12)

- **SAVE-08**: super_editor merges the remainder of the last block into the first and removes the last (`editing_rules_test.dart:119`). The spec now says: the first block is updated with the joined text and every other block in the selection gets `deleted_at`.
- **EDIT-02 / BMOVE-01**: the drag handle follows the canvas, inside the 12 px bleed, with a touch target below 44 × 44 (user decision: the canvas wins).
- **SPIKE-06** asks for an iOS simulator: impossible in Linux/WSL; needs a Mac or a real iPhone.
- **CHECK-01** cannot be reached with the built-in task component; a custom one is needed (doable).
