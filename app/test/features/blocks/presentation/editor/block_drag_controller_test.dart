import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/presentation/editor/block_drag_controller.dart';
import 'package:jotline/features/blocks/presentation/editor/components/active_block_builder.dart';
import 'package:jotline/features/blocks/presentation/editor/page_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../../helpers/pump_jot.dart';
import '../../../../helpers/test_app.dart';

late TestApp _app;
late String _pageId;
late List<String> _ids;
late PageEditor _editor;

Future<void> _open(WidgetTester tester) async {
  _app = TestApp();
  late List<Block> rows;
  await tester.runAsync(() async {
    final notebookId = await _app.notebooks.create(
      title: 'Viagem',
      cover: CoverPattern.lisa,
      color: NotebookColor.musgo,
    );
    _pageId = await _app.pages.create(notebookId);
    _ids = [
      for (final text in ['Belém cedo', 'Pastéis na fábrica', 'Mosteiro'])
        await _app.blocks.create(
          _pageId,
          type: BlockType.text.id,
          contentJson: BlockContent(text).toJson(),
        ),
    ];
    rows = await _app.blocks.loadPage(_pageId);
  });
  _editor = PageEditor(rows: rows, pageId: _pageId, repository: _app.blocks);
  await tester.pumpJot(
    Scaffold(
      body: CustomScrollView(slivers: [PageEditorView(pageEditor: _editor)]),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  _editor.dispose();
  await _settle(tester);
  await tester.runAsync(_app.db.close);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _save(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await _settle(tester);
}

Future<List<Block>> _rows(WidgetTester tester) async =>
    (await tester.runAsync(() => _app.blocks.loadPage(_pageId)))!;

Finder get _handle => find.byType(BlockDragHandle);

Rect _rect(String nodeId) =>
    SuperEditorInspector.findComponentOffset(nodeId, Alignment.topLeft) &
    SuperEditorInspector.findComponentSize(nodeId);

Future<TestGesture> _longPressHandle(WidgetTester tester) async {
  final gesture = await tester.startGesture(tester.getCenter(_handle));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  return gesture;
}

void main() {
  testWidgets('BMOVE-02: dragging the last block to the top changes only its '
      'position, and the page reopens in the new order', (tester) async {
    await _open(tester);
    final before = await _rows(tester);
    await tester.placeCaretInParagraph(_ids[2], 2);

    final gesture = await _longPressHandle(tester);
    await gesture.moveTo(Offset(12, _rect(_ids[0]).top - 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await _save(tester);

    expect(SuperEditorInspector.findDocument()!.map((n) => n.id), [
      _ids[2],
      _ids[0],
      _ids[1],
    ]);
    final after = await _rows(tester);
    expect(after.map((r) => r.id), [_ids[2], _ids[0], _ids[1]]);
    expect(after[1], before[0]);
    expect(after[2], before[1]);
    expect(after[0].position, isNot(before[2].position));
    expect(after[0].contentJson, before[2].contentJson);

    final reopened = PageEditor(
      rows: after,
      pageId: _pageId,
      repository: _app.blocks,
    );
    await tester.pumpJot(
      Scaffold(
        body: CustomScrollView(slivers: [PageEditorView(pageEditor: reopened)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(SuperEditorInspector.findDocument()!.map((n) => n.id), [
      _ids[2],
      _ids[0],
      _ids[1],
    ]);
    await tester.pumpWidget(const SizedBox());
    reopened.dispose();
    await _close(tester);
  });

  testWidgets('BMOVE-03: dropping the block where it started writes '
      'nothing', (tester) async {
    await _open(tester);
    final before = await _rows(tester);
    await tester.placeCaretInParagraph(_ids[1], 2);

    final gesture = await _longPressHandle(tester);
    await gesture.moveBy(const Offset(0, 6));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await _save(tester);

    expect(SuperEditorInspector.findDocument()!.map((n) => n.id), _ids);
    expect(await _rows(tester), before);
    await _close(tester);
  });

  testWidgets('BMOVE-04: the dragged block is drawn with shadow.erguido and '
      'its text while dragging', (tester) async {
    await _open(tester);
    await tester.placeCaretInParagraph(_ids[2], 2);

    final gesture = await _longPressHandle(tester);
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();

    final proxy = find.byType(BlockDragProxy);
    expect(proxy, findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: proxy, matching: find.byType(DecoratedBox)),
    );
    expect(
      (box.decoration as BoxDecoration).boxShadow,
      JotShadows.light.erguido,
    );
    expect(
      find.descendant(of: proxy, matching: find.text('Mosteiro')),
      findsOneWidget,
    );
    final text = tester.widget<RichText>(
      find.descendant(of: proxy, matching: find.byType(RichText)),
    );
    expect(text.text.style?.decoration, isNot(TextDecoration.underline));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(proxy, findsNothing);
    await _close(tester);
  });

  testWidgets('BMOVE-02: a long press on the handle starts a drag and does '
      'not select a word', (tester) async {
    await _open(tester);
    await tester.placeCaretInParagraph(_ids[1], 2);
    final selection = SuperEditorInspector.findDocumentSelection();

    final gesture = await _longPressHandle(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BlockDragProxy), findsOneWidget);
    expect(SuperEditorInspector.findDocumentSelection(), selection);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(SuperEditorInspector.findDocumentSelection(), selection);
    expect(selection!.isCollapsed, isTrue);
    await _close(tester);
  });

  testWidgets('BMOVE-02: dragging the first block below the last moves it '
      'to the end', (tester) async {
    await _open(tester);
    await tester.placeCaretInParagraph(_ids[0], 2);

    final gesture = await _longPressHandle(tester);
    await gesture.moveTo(Offset(12, _rect(_ids[2]).bottom + 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await _save(tester);

    expect((await _rows(tester)).map((r) => r.id), [_ids[1], _ids[2], _ids[0]]);
    await _close(tester);
  });
}
