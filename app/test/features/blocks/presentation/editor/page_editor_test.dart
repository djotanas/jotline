import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/editor/components/drawing_block.dart';
import 'package:jotline/features/blocks/presentation/editor/page_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../../../../helpers/test_app.dart';

const _first = DrawingContent([
  Stroke(
    tool: DrawingTool.pen,
    color: DrawingColor.ink,
    width: 3,
    points: [StrokePoint(10, 20, 0.5), StrokePoint(30, 40, 0.5)],
  ),
]);

const _second = DrawingContent([
  Stroke(
    tool: DrawingTool.highlighter,
    color: DrawingColor.accent,
    width: 6,
    points: [StrokePoint(60, 470, 0.5)],
  ),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestApp app;
  late String pageId;
  late PageEditor editor;

  Future<List<String>> seedPage(List<String> texts) async {
    final notebookId = await app.notebooks.create(
      title: 'Viagem',
      cover: CoverPattern.lisa,
      color: NotebookColor.musgo,
    );
    pageId = await app.pages.create(notebookId);
    return [
      for (final text in texts)
        await app.blocks.create(
          pageId,
          type: BlockType.text.id,
          contentJson: BlockContent(text).toJson(),
        ),
    ];
  }

  Future<void> open() async {
    editor = PageEditor(
      rows: await app.blocks.loadPage(pageId),
      pageId: pageId,
      repository: app.blocks,
    );
  }

  void placeCaret(String nodeId) => editor.editor.execute([
    ChangeSelectionRequest(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: nodeId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
      ),
      SelectionChangeType.placeCaret,
      SelectionReason.userInteraction,
    ),
  ]);

  Future<List<Block>> allRows() => (app.db.select(
    app.db.blocks,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<List<Block>> pageRows() async {
    await pumpEventQueue();
    return await app.blocks.loadPage(pageId);
  }

  setUp(() => app = TestApp());
  tearDown(() async {
    editor.dispose();
    await pumpEventQueue();
    await app.db.close();
  });

  test('DRAW-10: an insert after a text block writes one drawing row between '
      'its neighbors, at once', () async {
    final [a, b] = await seedPage(['A', 'B']);
    await open();
    placeCaret(a);

    final nodeId = editor.insertDrawing(_first);
    final rows = await pageRows();

    expect(editor.editor.document.getNodeById(nodeId), isA<DrawingNode>());
    expect(rows, hasLength(3));
    expect(rows[0].id, a);
    expect(rows[1].type, 'drawing');
    expect(rows[1].contentJson, _first.toJson());
    expect(rows[2].id, b);
    expect(await allRows(), hasLength(3));
  });

  test('DRAW-10: an insert in place of an empty block with no row writes only '
      'the drawing row', () async {
    await seedPage([]);
    await open();
    editor.focusEnd();

    final nodeId = editor.insertDrawing(_first);
    final rows = await pageRows();

    expect(rows, hasLength(1));
    expect(rows.single.type, 'drawing');
    expect(await allRows(), hasLength(1));
    expect([for (final node in editor.editor.document) node.id], [nodeId]);
  });

  test('DRAW-10: an empty block that has a row stays, and the drawing goes '
      'after it', () async {
    final [empty] = await seedPage(['']);
    await open();
    placeCaret(empty);

    editor.insertDrawing(_first);
    final rows = await pageRows();

    expect([for (final row in rows) row.type], ['text', 'drawing']);
    expect(rows.first.id, empty);
  });

  test('DRAW-10: save with no node id returns the new node id and writes at '
      'once', () async {
    final [a] = await seedPage(['A']);
    await open();
    placeCaret(a);

    final nodeId = editor.save(null, _first);
    final rows = await pageRows();

    expect(editor.drawingOf(nodeId), _first);
    expect(rows.last.type, 'drawing');
    expect(rows.last.contentJson, _first.toJson());
  });

  test('DRAW-14: save with a node id updates the same row and keeps '
      'version', () async {
    final [a] = await seedPage(['A']);
    await open();
    placeCaret(a);
    final nodeId = editor.save(null, _first);
    final inserted = (await pageRows()).last;
    await app.db.customStatement('UPDATE blocks SET version = 7');
    app.clock.current = DateTime.utc(2026, 10, 13, 9);

    final returned = editor.save(nodeId, _second);
    final rows = await pageRows();

    expect(returned, nodeId);
    expect(rows, hasLength(2));
    expect(rows.last.id, inserted.id);
    expect(rows.last.contentJson, _second.toJson());
    expect(rows.last.updatedAt, DateTime.utc(2026, 10, 13, 9));
    expect(rows.last.version, 7);
    expect(editor.drawingOf(nodeId), _second);
  });

  test('DRAW-15: remove soft-deletes the drawing row at once', () async {
    final [a] = await seedPage(['A']);
    await open();
    placeCaret(a);
    final nodeId = editor.save(null, _first);
    final inserted = (await pageRows()).last;
    app.clock.current = DateTime.utc(2026, 10, 13, 9);

    editor.remove(nodeId);
    final rows = await pageRows();

    expect([for (final row in rows) row.id], [a]);
    final stored = (await allRows()).singleWhere((r) => r.id == inserted.id);
    expect(stored.deletedAt, DateTime.utc(2026, 10, 13, 9));
    expect(editor.editor.document.getNodeById(nodeId), isNull);
  });

  test('DRAW-15: removing the only block of the page leaves one empty '
      'paragraph', () async {
    await seedPage([]);
    await open();
    editor.focusEnd();
    final nodeId = editor.save(null, _first);
    await pageRows();

    editor.remove(nodeId);
    final rows = await pageRows();

    expect(rows, isEmpty);
    expect(editor.editor.document.nodeCount, 1);
    expect(editor.editor.document.first, isA<ParagraphNode>());
  });
}
