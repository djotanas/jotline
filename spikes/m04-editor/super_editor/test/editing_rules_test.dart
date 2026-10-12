import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:spike_super_editor/block_row.dart';
import 'package:spike_super_editor/editor_page.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

void main() {
  late InMemoryBlockStore store;

  setUp(() {
    BlockRow row(String id, String type, String text, String position) =>
        BlockRow(
          id: id,
          type: type,
          contentJson: BlockContent(
            text,
            checked: type == BlockType.checklistItem ? false : null,
          ).toJson(),
          position: position,
        );
    store = InMemoryBlockStore([
      row('h', BlockType.heading, 'Manhã cedo', '1'),
      row('t', BlockType.text, 'Belém', '2'),
      row('k', BlockType.checklistItem, 'Bilhete', '3'),
      row('t2', BlockType.text, 'Fim', '4'),
    ]);
  });

  Future<EditorPageState> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: EditorPage(store: store)));
    await tester.pumpAndSettle();
    return tester.state<EditorPageState>(find.byType(EditorPage));
  }

  List<(String, String)> rows() => [
    for (final r in store.visible) (r.type, r.content.text),
  ];

  testWidgets('EDIT-07: Enter at the end of a heading creates a text block', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('h', 10);
    await tester.typeImeText('\nx');
    page.sync.flush();
    expect(rows()[1], (BlockType.text, 'x'));
  });

  testWidgets('EDIT-08: Enter in the middle of a heading splits as heading', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('h', 5);
    await tester.typeImeText('\n');
    page.sync.flush();
    expect(rows().take(2), [
      (BlockType.heading, 'Manhã'),
      (BlockType.heading, ' cedo'),
    ]);
  });

  testWidgets('CHECK-07: Backspace at the start of a heading makes text', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('t', 0);
    await tester.ime.backspace(getter: imeClientGetter);
    page.sync.flush();
    store.writes.clear();
    await tester.placeCaretInParagraph('h', 0);
    await tester.ime.backspace(getter: imeClientGetter);
    page.sync.flush();
    expect(store.byId('h')!.type, BlockType.text);
    expect(store.byId('h')!.deleted, isFalse);
  });

  testWidgets(
    'CHECK-07: Backspace at the start of a checklist item makes text',
    (tester) async {
      final page = await pumpPage(tester);
      await tester.placeCaretInParagraph('k', 0);
      await tester.ime.backspace(getter: imeClientGetter);
      page.sync.flush();
      expect(store.byId('k')!.type, BlockType.text);
      expect(store.byId('k')!.content.text, 'Bilhete');
      expect(store.byId('k')!.content.checked, isNull);
    },
  );

  testWidgets('CHECK-06: Enter on an empty checklist item turns it into text', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('k', 7);
    await tester.typeImeText('\n');
    await tester.typeImeText('\n');
    page.sync.flush();
    final node = page.editor.document.getNodeAt(3)!;
    expect(node, isA<ParagraphNode>());
    expect(page.editor.document.getNodeAt(2), isA<TaskNode>());
  });

  testWidgets(
    'EDIT-10: Backspace at the start of the first block does nothing',
    (tester) async {
      final page = await pumpPage(tester);
      await tester.placeCaretInParagraph('h', 0);
      await tester.ime.backspace(getter: imeClientGetter);
      await tester.ime.backspace(getter: imeClientGetter);
      page.sync.flush();
      expect(store.writes, [const BlockWrite('update', 'h')]);
      expect(rows().first, (BlockType.text, 'Manhã cedo'));
      expect(rows(), hasLength(4));
    },
  );

  testWidgets('SAVE-08: deleting a selection across blocks', (tester) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('t', 2);
    page.editor.execute([
      const ChangeSelectionRequest(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: 't',
            nodePosition: TextNodePosition(offset: 2),
          ),
          extent: DocumentPosition(
            nodeId: 't2',
            nodePosition: TextNodePosition(offset: 1),
          ),
        ),
        SelectionChangeType.expandSelection,
        SelectionReason.userInteraction,
      ),
    ]);
    await tester.pumpAndSettle();
    await tester.ime.backspace(getter: imeClientGetter);
    page.sync.flush();
    expect(store.byId('t')!.content.text, 'Beim');
    expect(store.byId('k')!.deleted, isTrue);
    expect(
      store.byId('t2')!.deleted,
      isTrue,
      reason: 'the remainder of the last block is merged into the first',
    );
  });
}
