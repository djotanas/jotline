import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/presentation/editor/page_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../../helpers/pump_jot.dart';
import '../../../../helpers/test_app.dart';

late TestApp _app;
late String _blockId;
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
    final pageId = await _app.pages.create(notebookId);
    _blockId = await _app.blocks.create(
      pageId,
      type: BlockType.text.id,
      contentJson: const BlockContent('Belém cedo').toJson(),
    );
    rows = await _app.blocks.loadPage(pageId);
  });
  _editor = PageEditor(
    rows: rows,
    pageId: rows.first.pageId,
    repository: _app.blocks,
  );
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
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.runAsync(_app.db.close);
}

void main() {
  testWidgets('EDIT-04: focusEnd moves the caret away from a block the '
      'keyboard is still composing in', (tester) async {
    await _open(tester);
    await tester.placeCaretInParagraph(_blockId, 5);
    final client = imeClientGetter();
    final value = client.currentTextEditingValue!;
    final caret = value.selection.extentOffset;
    client.updateEditingValueWithDeltas([
      TextEditingDeltaNonTextUpdate(
        oldText: value.text,
        selection: value.selection,
        composing: TextRange(start: caret - 5, end: caret),
      ),
    ]);
    await tester.pump();

    _editor.focusEnd();
    await tester.pump();

    expect(tester.takeException(), isNull);
    final selection = SuperEditorInspector.findDocumentSelection()!;
    expect(selection.extent.nodeId, isNot(_blockId));
    await _close(tester);
  });
}
