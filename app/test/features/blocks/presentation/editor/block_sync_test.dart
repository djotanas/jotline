import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:jotline/features/blocks/presentation/editor/block_sync.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';
import 'package:super_editor/super_editor.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_database.dart';

class _RecordingRepository implements BlockRepository {
  new(this._inner);

  final BlockRepository _inner;
  final List<List<BlockChange>> batches = [];
  int failuresLeft = 0;
  Completer<void>? gate;

  @override
  Future<Map<String, String>> applyChanges(
    String pageId,
    List<BlockChange> changes,
  ) async {
    batches.add(changes);
    await gate?.future;
    if (failuresLeft > 0) {
      failuresLeft--;
      throw StateError('disk full');
    }
    return await _inner.applyChanges(pageId, changes);
  }

  @override
  Future<String> create(
    String pageId, {
    required String type,
    required String contentJson,
    Placement at = const AtEnd(),
  }) => _inner.create(pageId, type: type, contentJson: contentJson, at: at);

  @override
  Future<void> move(String id, Placement to) => _inner.move(id, to);

  @override
  Future<void> moveToTrash(String id) => _inner.moveToTrash(id);

  @override
  Future<List<Block>> loadPage(String pageId) => _inner.loadPage(pageId);

  @override
  Stream<List<Block>> watchByPage(String pageId) => _inner.watchByPage(pageId);
}

class _Fixture {
  late AppDatabase db;
  late FakeClock clock;
  late _RecordingRepository repository;
  late PageRepository pages;
  late String pageId;
  late List<String> ids;
  late Editor editor;
  late BlockSync sync;

  Future<void> open(List<(BlockType, BlockContent)> seed) async {
    db = createTestDatabase();
    clock = FakeClock(DateTime.utc(2026, 10, 11, 8));
    final idGenerator = SequentialIdGenerator();
    final localUser = LocalUserRepository(db, idGenerator);
    final notebookId =
        await NotebookRepository(db, clock, idGenerator, localUser).create(
          title: 'Viagem',
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
    pages = PageRepository(db, clock, idGenerator, localUser);
    pageId = await pages.create(notebookId, title: 'Roteiro');
    repository = _RecordingRepository(
      BlockRepository(db, clock, idGenerator, localUser),
    );
    ids = [
      for (final (type, content) in seed)
        await repository.create(
          pageId,
          type: type.id,
          contentJson: content.forType(type).toJson(),
        ),
    ];
    final loaded = await repository.loadPage(pageId);
    editor = createDefaultDocumentEditor(
      document: BlockMapper.toDocument(loaded),
      composer: MutableDocumentComposer(),
    );
    sync = BlockSync(
      editor: editor,
      pageId: pageId,
      repository: repository,
      loadedIds: loaded.map((b) => b.id),
    );
    clock.current = DateTime.utc(2026, 10, 12, 9);
  }

  Future<void> close() async {
    sync.dispose();
    await db.close();
  }

  Future<List<Block>> allRows() =>
      (db.select(db.blocks)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<List<(BlockType, String)>> visible() async => [
    for (final b in await repository.loadPage(pageId))
      (BlockType.fromId(b.type), BlockContent.fromJson(b.contentJson).text),
  ];

  Future<Block> row(String id) =>
      (db.select(db.blocks)..where((t) => t.id.equals(id))).getSingle();

  Future<NotebookPage> pageRow() =>
      (db.select(db.pages)..where((t) => t.id.equals(pageId))).getSingle();

  DocumentPosition at(String nodeId, int offset) => DocumentPosition(
    nodeId: nodeId,
    nodePosition: TextNodePosition(offset: offset),
  );

  void type(String nodeId, int offset, String text) => editor.execute([
    InsertTextRequest(
      documentPosition: at(nodeId, offset),
      textToInsert: text,
      attributions: const {},
    ),
  ]);

  void delete(DocumentPosition start, DocumentPosition end) => editor.execute([
    DeleteContentRequest(
      documentRange: DocumentRange(start: start, end: end),
    ),
  ]);

  void insertAfter(String existingNodeId, DocumentNode node) => editor.execute([
    InsertNodeAfterNodeRequest(existingNodeId: existingNodeId, newNode: node),
  ]);
}

const List<(BlockType, BlockContent)> _abc = [
  (BlockType.text, BlockContent('Abc')),
  (BlockType.text, BlockContent('Def')),
  (BlockType.text, BlockContent('Ghi')),
];

void main() {
  late _Fixture f;

  group('BlockSync timer', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
    }

    testWidgets('SAVE-02: a write happens 500 ms after the last edit, '
        'never before', (tester) async {
      f = _Fixture();
      await tester.runAsync(() => f.open(_abc));
      final before = await tester.runAsync(f.allRows);
      final pageBefore = await tester.runAsync(f.pageRow);

      f.type(f.ids[0], 3, 'x');
      await tester.pump(const Duration(milliseconds: 499));
      await settle(tester);

      expect(f.repository.batches, isEmpty);
      expect(await tester.runAsync(f.allRows), before);

      await tester.pump(const Duration(milliseconds: 1));
      await settle(tester);

      final after = (await tester.runAsync(f.allRows))!;
      expect(BlockContent.fromJson(after[0].contentJson).text, 'Abcx');
      expect(after[0].updatedAt, DateTime.utc(2026, 10, 12, 9));
      expect(after.skip(1), before!.skip(1));
      expect(await tester.runAsync(f.pageRow), pageBefore);
      await tester.runAsync(f.close);
    });

    testWidgets('SAVE-02: every edit restarts the page timer and two '
        'touched blocks are written in one batch', (tester) async {
      f = _Fixture();
      await tester.runAsync(() => f.open(_abc));

      f.type(f.ids[0], 3, 'x');
      await tester.pump(const Duration(milliseconds: 300));
      f.type(f.ids[1], 3, 'y');
      await tester.pump(const Duration(milliseconds: 499));
      await settle(tester);

      expect(f.repository.batches, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await settle(tester);

      expect(f.repository.batches, hasLength(1));
      expect(await tester.runAsync(f.visible), [
        (BlockType.text, 'Abcx'),
        (BlockType.text, 'Defy'),
        (BlockType.text, 'Ghi'),
      ]);
      await tester.runAsync(f.close);
    });
  });

  group('BlockSync flush', () {
    tearDown(() => f.close());

    test('SAVE-05: typing in one block updates only that row, version '
        'unchanged', () async {
      f = _Fixture();
      await f.open(_abc);
      final before = await f.allRows();
      final pageBefore = await f.pageRow();

      f.type(f.ids[1], 0, '>');
      await f.sync.flush();

      final after = await f.allRows();
      expect(BlockContent.fromJson(after[1].contentJson).text, '>Def');
      expect(after[1].version, before[1].version);
      expect(after[1].updatedAt, DateTime.utc(2026, 10, 12, 9));
      expect([after[0], after[2]], [before[0], before[2]]);
      expect(await f.pageRow(), pageBefore);
    });

    test('SAVE-06: a split keeps the original id and inserts the new row '
        'right after it, before the next sibling', () async {
      f = _Fixture();
      await f.open(_abc);

      f.editor.execute([
        SplitParagraphRequest(
          nodeId: f.ids[0],
          splitPosition: const TextNodePosition(offset: 1),
          newNodeId: 'n1',
          replicateExistingMetadata: true,
        ),
      ]);
      await f.sync.flush();

      final rows = await f.repository.loadPage(f.pageId);
      expect(rows.map((b) => b.id).toList(), [
        f.ids[0],
        rows[1].id,
        f.ids[1],
        f.ids[2],
      ]);
      expect(f.ids, isNot(contains(rows[1].id)));
      expect(await f.visible(), [
        (BlockType.text, 'A'),
        (BlockType.text, 'bc'),
        (BlockType.text, 'Def'),
        (BlockType.text, 'Ghi'),
      ]);
    });

    test('SAVE-07: a merge updates the upper row and trashes the lower '
        'one', () async {
      f = _Fixture();
      await f.open(_abc);

      f.editor.execute([
        CombineParagraphsRequest(firstNodeId: f.ids[0], secondNodeId: f.ids[1]),
      ]);
      await f.sync.flush();

      expect(await f.visible(), [
        (BlockType.text, 'AbcDef'),
        (BlockType.text, 'Ghi'),
      ]);
      final lower = await f.row(f.ids[1]);
      expect(lower.deletedAt, DateTime.utc(2026, 10, 12, 9));
      expect(BlockContent.fromJson(lower.contentJson).text, 'Def');
      expect((await f.row(f.ids[0])).deletedAt, isNull);
    });

    test('SAVE-08: deleting across blocks updates the first and trashes '
        'the others', () async {
      f = _Fixture();
      await f.open(_abc);

      f.delete(f.at(f.ids[0], 2), f.at(f.ids[2], 1));
      await f.sync.flush();

      expect(await f.visible(), [(BlockType.text, 'Abhi')]);
      expect((await f.row(f.ids[1])).deletedAt, isNotNull);
      expect((await f.row(f.ids[2])).deletedAt, isNotNull);
      expect(await f.allRows(), hasLength(3));
    });

    test('EDIT-05: an empty new block of any type writes no row until its '
        'first character', () async {
      f = _Fixture();
      await f.open(_abc);
      final nodes = <DocumentNode>[
        ParagraphNode(id: 'p', text: AttributedText()),
        ParagraphNode(
          id: 'h',
          text: AttributedText(),
          metadata: const {NodeMetadata.blockType: header1Attribution},
        ),
        ListItemNode.unordered(id: 'l', text: AttributedText()),
        TaskNode(id: 'k', text: AttributedText(), isComplete: false),
      ];
      for (final node in nodes.reversed) {
        f.insertAfter(f.ids[2], node);
      }
      await f.sync.flush();

      expect(await f.allRows(), hasLength(3));
      expect(f.sync.pendingNodeIds, containsAll(['p', 'h', 'l', 'k']));

      for (final id in ['p', 'h', 'l', 'k']) {
        f.type(id, 0, id);
      }
      await f.sync.flush();

      expect(await f.visible(), [
        (BlockType.text, 'Abc'),
        (BlockType.text, 'Def'),
        (BlockType.text, 'Ghi'),
        (BlockType.text, 'p'),
        (BlockType.heading, 'h'),
        (BlockType.bulletedListItem, 'l'),
        (BlockType.checklistItem, 'k'),
      ]);
      expect(f.sync.pendingNodeIds, isEmpty);
    });

    test('EDGE-04: deleting all the text of a block keeps its row, '
        'empty', () async {
      f = _Fixture();
      await f.open(_abc);

      f.delete(f.at(f.ids[1], 0), f.at(f.ids[1], 3));
      await f.sync.flush();

      final row = await f.row(f.ids[1]);
      expect(row.deletedAt, isNull);
      expect(BlockContent.fromJson(row.contentJson).text, '');
      expect(await f.visible(), hasLength(3));
    });

    test('BMOVE-02: a move changes the position of one row only', () async {
      f = _Fixture();
      await f.open(_abc);
      final before = await f.allRows();

      f.editor.execute([MoveNodeRequest(nodeId: f.ids[2], newIndex: 0)]);
      await f.sync.flush();

      final after = await f.allRows();
      expect(await f.visible(), [
        (BlockType.text, 'Ghi'),
        (BlockType.text, 'Abc'),
        (BlockType.text, 'Def'),
      ]);
      expect([after[0], after[1]], [before[0], before[1]]);
      expect(after[2].position, isNot(before[2].position));
      expect(after[2].contentJson, before[2].contentJson);
    });

    test('BMOVE-03: a move to the same place writes nothing', () async {
      f = _Fixture();
      await f.open(_abc);
      final before = await f.allRows();

      f.editor.execute([MoveNodeRequest(nodeId: f.ids[1], newIndex: 1)]);
      await f.sync.flush();

      expect(await f.allRows(), before);
    });

    test('SAVE-02: a flush during an in-flight flush runs after it and '
        'knows its new ids', () async {
      f = _Fixture();
      await f.open(_abc);
      f.insertAfter(f.ids[2], ParagraphNode(id: 'n', text: AttributedText()));

      f.repository.gate = Completer<void>();

      f.type('n', 0, 'Jk');
      final first = f.sync.flush();
      await pumpEventQueue();
      expect(f.repository.batches, hasLength(1));
      f.type('n', 2, 'l');
      final second = f.sync.flush();
      await pumpEventQueue();
      expect(f.repository.batches, hasLength(1));
      f.repository.gate!.complete();
      await Future.wait([first, second]);

      expect(f.repository.batches, hasLength(2));
      final insert = f.repository.batches[0].single as Insert;
      final update = f.repository.batches[1].single as Update;
      final rows = await f.repository.loadPage(f.pageId);
      expect((insert.content as BlockContent).text, 'Jk');
      expect(update.id, rows.last.id);
      expect((update.content as BlockContent).text, 'Jkl');
      expect(await f.allRows(), hasLength(4));
      expect(await f.visible(), [
        (BlockType.text, 'Abc'),
        (BlockType.text, 'Def'),
        (BlockType.text, 'Ghi'),
        (BlockType.text, 'Jkl'),
      ]);
    });

    test('SAVE-02: a failed write keeps the pending ids and the next flush '
        'writes them', () async {
      f = _Fixture();
      await f.open(_abc);
      f.repository.failuresLeft = 1;

      f.type(f.ids[0], 3, 'x');
      f.delete(f.at(f.ids[1], 3), f.at(f.ids[2], 0));
      await f.sync.flush();

      expect(f.sync.pendingNodeIds, containsAll([f.ids[0], f.ids[2]]));
      expect(await f.visible(), [
        (BlockType.text, 'Abc'),
        (BlockType.text, 'Def'),
        (BlockType.text, 'Ghi'),
      ]);

      await f.sync.flush();

      expect(await f.visible(), [
        (BlockType.text, 'Abcx'),
        (BlockType.text, 'DefGhi'),
      ]);
      expect((await f.row(f.ids[2])).deletedAt, isNotNull);
      expect(f.sync.pendingNodeIds, isEmpty);
    });

    test('SAVE-02: a flush with nothing pending writes nothing', () async {
      f = _Fixture();
      await f.open(_abc);

      await f.sync.flush();

      expect(f.repository.batches, isEmpty);
    });

    test('SAVE-09: no change path deletes a row physically', () async {
      f = _Fixture();
      await f.open(_abc);

      f.delete(f.at(f.ids[0], 0), f.at(f.ids[2], 3));
      await f.sync.flush();

      expect(await f.allRows(), hasLength(3));
      expect(await f.visible(), [(BlockType.text, '')]);
    });
  });
}
