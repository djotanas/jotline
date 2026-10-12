import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:spike_super_editor/block_row.dart';
import 'package:spike_super_editor/editor_page.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

void main() {
  BlockRow row(String id, String type, BlockContent content, String position) =>
      BlockRow(
        id: id,
        type: type,
        contentJson: content.toJson(),
        position: position,
      );

  late InMemoryBlockStore store;

  setUp(() {
    store = InMemoryBlockStore([
      row('a', BlockType.text, const BlockContent('Olá mundo'), '1'),
      row('b', BlockType.text, const BlockContent('Segundo'), '2'),
      row('c', BlockType.bulletedListItem, const BlockContent('Item'), '3'),
      row(
        'd',
        BlockType.checklistItem,
        const BlockContent('Tarefa', checked: false),
        '4',
      ),
      row(
        'e',
        BlockType.checklistItem,
        const BlockContent('Outra', checked: false),
        '5',
      ),
      const BlockRow(
        id: 'f',
        type: 'drawing',
        contentJson: '{"strokes":[]}',
        position: '6',
      ),
    ]);
  });

  Future<EditorPageState> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: EditorPage(store: store)));
    await tester.pumpAndSettle();
    return tester.state<EditorPageState>(find.byType(EditorPage));
  }

  String textOf(String id) => store.byId(id)!.content.text;

  List<BlockRow> textRows() =>
      store.visible.where((r) => r.type != 'drawing').toList();

  testWidgets('SPIKE-02/03: typing keeps the id and touches only that block', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('a', 3);
    await tester.typeImeText(' grande');
    expect(page.sync.pendingNodeIds, {'a'});
    page.sync.flush();
    expect(textOf('a'), 'Olá grande mundo');
    expect(store.writes, [const BlockWrite('update', 'a')]);
  });

  testWidgets('SPIKE-02: Enter in the middle splits; the lower block is new', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('a', 4);
    await tester.typeImeText('\n');
    page.sync.flush();
    final visible = store.visible;
    expect(visible.map((r) => r.content.text).take(3), [
      'Olá ',
      'mundo',
      'Segundo',
    ]);
    expect(visible.first.id, 'a');
    final newId = visible[1].id;
    expect(newId, isNot(anyOf('a', 'b')));
    expect(store.writes, [
      const BlockWrite('update', 'a'),
      BlockWrite('insert', newId),
    ]);
  });

  testWidgets('SPIKE-02: Backspace at the start merges into the upper block', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('b', 0);
    await tester.ime.backspace(getter: imeClientGetter);
    page.sync.flush();
    expect(textOf('a'), 'Olá mundoSegundo');
    expect(store.byId('b')!.deleted, isTrue);
    expect(store.writes.toSet(), {
      const BlockWrite('update', 'a'),
      const BlockWrite('trash', 'b'),
    });
  });

  testWidgets('Enter at the end of a checklist item creates an unchecked one', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.placeCaretInParagraph('d', 6);
    await tester.typeImeText('\n');
    await tester.typeImeText('Nova');
    page.sync.flush();
    final visible = textRows().map((r) => (r.type, r.content)).toList();
    expect(visible[3], (
      BlockType.checklistItem,
      const BlockContent('Tarefa', checked: true),
    ));
    expect(visible[4], (
      BlockType.checklistItem,
      const BlockContent('Nova', checked: false),
    ));
  });

  testWidgets('CHECK-06: Enter on an empty list item turns it into text', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('c', 4);
    await tester.typeImeText('\n');
    await tester.typeImeText('\n');
    page.sync.flush();
    final types = textRows().map((r) => r.type).toList();
    final contents = textRows().map((r) => r.content.text).toList();
    expect(contents, contains('Item'));
    expect(
      page.editor.document.getNodeAt(3),
      isA<ParagraphNode>(),
      reason: 'types: $types',
    );
  });

  testWidgets('CHECK-07: Backspace at the start of a list item makes text', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('c', 0);
    await tester.ime.backspace(getter: imeClientGetter);
    page.sync.flush();
    expect(store.byId('c')!.type, BlockType.text);
    expect(textOf('c'), 'Item');
    expect(store.byId('c')!.deleted, isFalse);
  });

  testWidgets('CHECK-02: tapping a checkbox changes only that row', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    page.sync.flush();
    expect(store.writes, [const BlockWrite('update', 'e')]);
    expect(store.byId('e')!.content.checked, isTrue);
    expect(page.editor.composer.selection, isNull);
  });

  testWidgets('BAR-05: changing type keeps the id and the text', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('a', 2);
    await tester.tap(find.byTooltip('Título'));
    await tester.pumpAndSettle();
    page.sync.flush();
    expect(store.byId('a')!.type, BlockType.heading);
    await tester.tap(find.byTooltip('Checklist'));
    await tester.pumpAndSettle();
    page.sync.flush();
    expect(store.byId('a')!.type, BlockType.checklistItem);
    expect(store.byId('a')!.content.checked, isFalse);
    await tester.tap(find.byTooltip('Lista'));
    await tester.pumpAndSettle();
    page.sync.flush();
    expect(store.byId('a')!.type, BlockType.bulletedListItem);
    expect(store.byId('a')!.content.checked, isNull);
    expect(textOf('a'), 'Olá mundo');
    expect(store.writes.map((w) => w.id).toSet(), {'a'});
  });

  testWidgets('BAR-07: bold on a selection writes a bold mark', (tester) async {
    final page = await pumpPage(tester);
    page.editor.execute([
      const ChangeSelectionRequest(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: 'a',
            nodePosition: TextNodePosition(offset: 0),
          ),
          extent: DocumentPosition(
            nodeId: 'a',
            nodePosition: TextNodePosition(offset: 3),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Negrito'));
    await tester.pumpAndSettle();
    page.sync.flush();
    expect(store.byId('a')!.content.marks, [const Mark(0, 3, MarkType.bold)]);
  });

  testWidgets('BAR-08: italic with no selection applies to the next text', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('b', 7);
    await tester.tap(find.byTooltip('Itálico'));
    await tester.pumpAndSettle();
    await tester.typeImeText('!!');
    page.sync.flush();
    expect(store.byId('b')!.content.marks, [const Mark(7, 9, MarkType.italic)]);
  });

  testWidgets('SPIKE-06 (simulated): composing deltas produce accented text', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('b', 7);
    final client = imeClientGetter();
    final before = client.currentTextEditingValue!;
    final at = before.selection.baseOffset;
    await tester.ime.sendDeltas([
      TextEditingDeltaInsertion(
        oldText: before.text,
        textInserted: ' a',
        insertionOffset: at,
        selection: TextSelection.collapsed(offset: at + 2),
        composing: TextRange(start: at + 1, end: at + 2),
      ),
    ], getter: imeClientGetter);
    final composing = client.currentTextEditingValue!;
    await tester.ime.sendDeltas([
      TextEditingDeltaReplacement(
        oldText: composing.text,
        replacementText: 'ação',
        replacedRange: TextRange(start: at + 1, end: at + 2),
        selection: TextSelection.collapsed(offset: at + 5),
        composing: TextRange.empty,
      ),
    ], getter: imeClientGetter);
    page.sync.flush();
    expect(textOf('b'), 'Segundo ação');
  });

  testWidgets('SPIKE-05: the custom block widget renders', (tester) async {
    await pumpPage(tester);
    expect(find.byKey(const ValueKey('drawing-stub')), findsOneWidget);
  });

  testWidgets('EDIT-02: the block with the caret gets the in-edit style', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.byKey(const ValueKey('active-block')), findsNothing);
    await tester.placeCaretInParagraph('b', 1);
    expect(find.byKey(const ValueKey('active-block')), findsOneWidget);
    expect(find.bySemanticsLabel('Mover bloco'), findsOneWidget);
  });

  testWidgets('EDIT-05: an empty new block gets no row until typed into', (
    tester,
  ) async {
    final page = await pumpPage(tester);
    await tester.placeCaretInParagraph('b', 7);
    await tester.typeImeText('\n');
    page.sync.flush();
    expect(store.writes, isEmpty);
    await tester.typeImeText('x');
    page.sync.flush();
    expect(store.writes.single.kind, 'insert');
    final visible = store.visible.map((r) => r.id).toList();
    expect(visible.indexOf(store.writes.single.id), visible.indexOf('b') + 1);
  });
}
