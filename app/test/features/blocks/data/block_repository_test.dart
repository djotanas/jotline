import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/stream_recorder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SequentialIdGenerator ids;
  late LocalUserRepository localUser;
  late NotebookRepository notebookRepository;
  late PageRepository pageRepository;
  late BlockRepository repository;
  late String notebookId;
  late String pageId;

  Future<String> createNotebook() => notebookRepository.create(
    title: 'Work',
    cover: CoverPattern.lisa,
    color: NotebookColor.azulTinta,
  );

  setUp(() async {
    db = createTestDatabase();
    clock = FakeClock(DateTime.utc(2026, 10, 11, 8));
    ids = SequentialIdGenerator();
    localUser = LocalUserRepository(db, ids);
    notebookRepository = NotebookRepository(db, clock, ids, localUser);
    pageRepository = PageRepository(db, clock, ids, localUser);
    repository = BlockRepository(db, clock, ids, localUser);
    notebookId = await createNotebook();
    pageId = await pageRepository.create(notebookId, title: 'Page');
  });
  tearDown(() => db.close());

  Future<String> add(String content, {String? onPage, Placement? at}) {
    return repository.create(
      onPage ?? pageId,
      type: 'paragraph',
      contentJson: content,
      at: at ?? const AtEnd(),
    );
  }

  Future<List<Block>> blockRows() =>
      (db.select(db.blocks)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<Block> blockRow(String id) =>
      (db.select(db.blocks)..where((t) => t.id.equals(id))).getSingle();

  Future<List<String>> contents([String? onPage]) async {
    final recorder = StreamRecorder(repository.watchByPage(onPage ?? pageId));
    final emissions = await recorder.settle();
    await recorder.cancel();
    return [for (final b in emissions.last) b.contentJson];
  }

  Future<void> update(String id, String text) => repository.applyChanges(
    pageId,
    [Update(id, BlockType.text, BlockContent(text))],
  );

  String json(String text) => BlockContent(text).toJson();

  Future<List<String>> seed(List<String> contents) async => [
    for (final content in contents) await add(content),
  ];

  test('REPO-13: a block goes at the end by default, with version 0 and '
      'updated_* set', () async {
    final first = await add('A');
    clock.current = DateTime.utc(2026, 10, 12);

    final second = await repository.create(
      pageId,
      type: 'heading',
      contentJson: 'B',
    );

    final row = await blockRow(second);
    expect(row.type, 'heading');
    expect(row.contentJson, 'B');
    expect(row.pageId, pageId);
    expect(row.version, 0);
    expect(row.updatedAt, DateTime.utc(2026, 10, 12));
    expect(row.updatedBy, await localUser.id());
    expect(row.deletedAt, isNull);
    expect(
      row.position.compareTo((await blockRow(first)).position),
      greaterThan(0),
    );
    expect(await contents(), ['A', 'B']);
  });

  test('REPO-13: a block created After a neighbor lands between '
      'neighbors', () async {
    final [a, _] = await seed(['A', 'C']);

    final b = await add('B', at: After(a));

    expect(await contents(), ['A', 'B', 'C']);
    expect((await blockRow(b)).version, 0);
  });

  test('REPO-13: a block created at the start sorts first', () async {
    await seed(['A']);

    await add('Z', at: const AtStart());

    expect(await contents(), ['Z', 'A']);
  });

  test('REPO-14: an Update keeps a manually set version and sets '
      'updated_* ', () async {
    final id = await add('A');
    await db.customStatement("UPDATE blocks SET version = 7 WHERE id = '$id'");
    clock.current = DateTime.utc(2026, 10, 12);

    await update(id, 'A2');

    final row = await blockRow(id);
    expect(row.version, 7);
    expect(row.contentJson, json('A2'));
    expect(row.updatedAt, DateTime.utc(2026, 10, 12));
    expect(row.updatedBy, await localUser.id());
  });

  test('REPO-15: moving keeps a manually set version', () async {
    final [a, b] = await seed(['A', 'B']);
    await db.customStatement("UPDATE blocks SET version = 7 WHERE id = '$a'");

    await repository.move(a, After(b));

    final row = await blockRow(a);
    expect(row.version, 7);
    expect(await contents(), ['B', 'A']);
  });

  test('REPO-16: the stream excludes deleted blocks and orders by position, '
      'then id', () async {
    final [a, b, c] = await seed(['A', 'B', 'C']);
    await db.customStatement(
      "UPDATE blocks SET position = 'a5' WHERE id IN ('$a', '$b')",
    );
    await repository.moveToTrash(c);

    expect(a.compareTo(b), lessThan(0));
    expect(await contents(), ['A', 'B']);
  });

  test('REPO-16: the stream holds only the blocks of its page', () async {
    await seed(['A']);
    final other = await pageRepository.create(notebookId, title: 'Other');
    await add('B', onPage: other);

    expect(await contents(), ['A']);
    expect(await contents(other), ['B']);
  });

  test('REPO-17: the page row stays identical through create, Update, move '
      'and delete', () async {
    final pagesBefore = await db.select(db.pages).get();

    final [a, b] = await seed(['A', 'B']);
    await update(a, 'A2');
    await repository.move(a, After(b));
    await repository.moveToTrash(b);

    expect(await db.select(db.pages).get(), pagesBefore);
  });

  test('POS-09: moving the third of five blocks changes exactly one '
      'row', () async {
    final blockIds = await seed(['A', 'B', 'C', 'D', 'E']);
    final before = await blockRows();

    await repository.move(blockIds[2], const AtStart());

    final after = await blockRows();
    final changed = [
      for (var i = 0; i < before.length; i++)
        if (before[i] != after[i]) after[i].id,
    ];
    expect(changed, [blockIds[2]]);
  });

  test('DEL-01: trashing sets deleted_at and keeps the row', () async {
    final id = await add('A');
    clock.current = DateTime.utc(2026, 10, 12);

    await repository.moveToTrash(id);

    final row = await blockRow(id);
    expect(row.deletedAt, DateTime.utc(2026, 10, 12));
    expect(row.contentJson, 'A');
  });

  test('DEL-02: trashing twice keeps the original deleted_at', () async {
    final id = await add('A');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.moveToTrash(id);
    clock.current = DateTime.utc(2026, 10, 20);

    await repository.moveToTrash(id);

    expect((await blockRow(id)).deletedAt, DateTime.utc(2026, 10, 12));
  });

  test('DEL-08: a trashed block is excluded from the stream', () async {
    final [a, _] = await seed(['A', 'B']);

    await repository.moveToTrash(a);

    expect(await contents(), ['B']);
  });

  test('DEL-05: the blocks of a trashed page are not streamed', () async {
    await seed(['A', 'B']);
    final before = await blockRows();

    await pageRepository.moveToTrash(pageId);

    expect(await contents(), isEmpty);
    expect(await blockRows(), before);
  });

  test('DEL-06: the blocks of a page in a trashed notebook are not '
      'streamed', () async {
    await seed(['A', 'B']);

    await notebookRepository.moveToTrash(notebookId);

    expect(await contents(), isEmpty);
  });

  test('DEL-07: trashing a notebook with 2 pages and 3 blocks changes no page '
      'or block row and hides them from every stream', () async {
    final secondPage = await pageRepository.create(notebookId, title: 'Two');
    await add('A');
    await add('B');
    await add('C', onPage: secondPage);
    final pagesBefore = await db.select(db.pages).get();
    final blocksBefore = await blockRows();

    await notebookRepository.moveToTrash(notebookId);

    expect(await db.select(db.pages).get(), pagesBefore);
    expect(await blockRows(), blocksBefore);
    expect(await contents(), isEmpty);
    expect(await contents(secondPage), isEmpty);
    final pages = StreamRecorder(pageRepository.watchByNotebook(notebookId));
    expect((await pages.settle()).last, isEmpty);
    await pages.cancel();
    final active = StreamRecorder(
      notebookRepository.watchSummaries(archived: false),
    );
    expect((await active.settle()).last, isEmpty);
    await active.cancel();
  });

  test('ID-03: block ids come from the generator', () async {
    final id = await add('A');

    final expected = SequentialIdGenerator();
    for (var i = 0; i < 4; i++) {
      expected.newId();
    }
    expect(id, expected.newId());
  });

  test('USER-05: updated_by holds the local user id on create, update and '
      'move', () async {
    final userId = await localUser.id();
    final [a, b] = await seed(['A', 'B']);
    expect((await blockRow(a)).updatedBy, userId);

    await db.customStatement("UPDATE blocks SET updated_by = 'x'");
    await update(a, 'A2');
    await repository.move(b, const AtStart());

    expect((await blockRow(a)).updatedBy, userId);
    expect((await blockRow(b)).updatedBy, userId);
  });

  test('REPO-18: the stream emits after create, update, move and '
      'delete', () async {
    final recorder = StreamRecorder(repository.watchByPage(pageId));
    List<String> now() => [
      for (final b in recorder.emissions.last) b.contentJson,
    ];
    await recorder.settle();
    expect(now(), isEmpty);

    final a = await add('A');
    await recorder.settle();
    expect(now(), ['A']);

    final b = await add('B');
    await recorder.settle();
    expect(now(), ['A', 'B']);

    await update(a, 'A2');
    await recorder.settle();
    expect(now(), [json('A2'), 'B']);

    await repository.move(b, const AtStart());
    await recorder.settle();
    expect(now(), ['B', json('A2')]);

    await repository.moveToTrash(a);
    await recorder.settle();
    expect(now(), ['B']);
    await recorder.cancel();
  });
  group('loadPage', () {
    test('EDIT-01: returns the blocks not deleted, ordered by position then '
        'id, like the stream', () async {
      final [a, b, c, d] = await seed(['A', 'B', 'C', 'D']);
      await db.customStatement(
        "UPDATE blocks SET position = 'a0' WHERE id IN ('$b', '$a')",
      );
      await db.customStatement(
        "UPDATE blocks SET position = 'Zz' WHERE id = '$d'",
      );
      await repository.moveToTrash(c);

      final loaded = await repository.loadPage(pageId);

      expect([for (final block in loaded) block.id], [d, a, b]);
      expect([for (final block in loaded) block.contentJson], await contents());
    });

    test('EDIT-01: returns nothing for a page in the trash', () async {
      await seed(['A']);
      await pageRepository.moveToTrash(pageId);

      expect(await repository.loadPage(pageId), isEmpty);
    });
  });

  group('applyChanges', () {
    test('SAVE-02: a failing change rolls back the whole batch', () async {
      final [a, b] = await seed(['A', 'B']);
      final before = await blockRows();

      await expectLater(
        repository.applyChanges(pageId, [
          Update(a, BlockType.text, const BlockContent('A2')),
          Insert('n1', BlockType.text, const BlockContent('N'), After(b)),
          Trash(b),
          const Insert('n2', BlockType.text, BlockContent('X'), After('x')),
        ]),
        throwsArgumentError,
      );

      expect(await blockRows(), before);
    });

    test('SAVE-06: an insert After an insert of the same batch lands right '
        'after it, before the next sibling', () async {
      final [a, _] = await seed(['A', 'B']);

      final inserted = await repository.applyChanges(pageId, [
        Insert('n1', BlockType.text, const BlockContent('A1'), After(a)),
        const Insert('n2', BlockType.text, BlockContent('A2'), After('n1')),
      ]);

      expect(inserted.keys, ['n1', 'n2']);
      expect(await contents(), ['A', json('A1'), json('A2'), 'B']);
      final row = await blockRow(inserted['n2']!);
      expect(row.version, 0);
      expect(row.type, 'text');
    });

    test('SAVE-06: an insert AtStart sorts first and returns its id', () async {
      await seed(['A']);

      final inserted = await repository.applyChanges(pageId, [
        const Insert('n1', BlockType.heading, BlockContent('H'), AtStart()),
      ]);

      final [first, _] = await repository.loadPage(pageId);
      expect(first.id, inserted['n1']);
      expect(first.type, 'heading');
      expect(first.contentJson, json('H'));
    });

    test('BAR-05: an Update writes type and content_json', () async {
      final [a] = await seed(['A']);
      await repository.applyChanges(pageId, [
        Update(
          a,
          BlockType.checklistItem,
          const BlockContent('A', marks: [Mark(0, 1, MarkType.bold)]),
        ),
      ]);

      final row = await blockRow(a);
      expect(row.type, 'checklist_item');
      expect(
        row.contentJson,
        '{"text":"A","marks":[{"start":0,"end":1,"type":"bold"}],'
        '"checked":false}',
      );

      await repository.applyChanges(pageId, [
        Update(a, BlockType.text, const BlockContent('A', checked: true)),
      ]);

      expect((await blockRow(a)).type, 'text');
      expect((await blockRow(a)).contentJson, json('A'));
    });

    test('SAVE-05: an Update with the stored type and content writes '
        'nothing', () async {
      final [a] = await seed(['A']);
      await update(a, 'A2');
      clock.current = DateTime.utc(2026, 10, 12);
      await db.customStatement("UPDATE blocks SET updated_by = 'x'");
      final stored = await blockRow(a);

      await update(a, 'A2');

      expect(await blockRow(a), stored);
    });

    test('SAVE-04: every write sets updated_at and updated_by and keeps '
        'version', () async {
      final [a, b, c] = await seed(['A', 'B', 'C']);
      await db.customStatement(
        "UPDATE blocks SET version = 7, updated_by = 'x'",
      );
      clock.current = DateTime.utc(2026, 10, 12, 9);

      final inserted = await repository.applyChanges(pageId, [
        Update(a, BlockType.text, const BlockContent('A2')),
        Move(b, const AtStart()),
        Insert('n1', BlockType.text, const BlockContent('N'), After(c)),
      ]);

      final userId = await localUser.id();
      for (final id in [a, b]) {
        final row = await blockRow(id);
        expect(row.updatedAt, DateTime.utc(2026, 10, 12, 9));
        expect(row.updatedBy, userId);
        expect(row.version, 7);
      }
      final row = await blockRow(inserted['n1']!);
      expect(row.updatedAt, DateTime.utc(2026, 10, 12, 9));
      expect(row.updatedBy, userId);
      expect(row.version, 0);
      expect(await contents(), ['B', json('A2'), 'C', json('N')]);
    });

    test('SAVE-07: a Trash writes only deleted_at', () async {
      final [a] = await seed(['A']);
      await db.customStatement('UPDATE blocks SET version = 7');
      final before = await blockRow(a);
      clock.current = DateTime.utc(2026, 10, 12);

      await repository.applyChanges(pageId, [Trash(a)]);

      expect(
        await blockRow(a),
        before.copyWith(deletedAt: Value(DateTime.utc(2026, 10, 12))),
      );
    });

    test('SAVE-05: the pages row is identical after a batch of every '
        'change', () async {
      final [a, b, c] = await seed(['A', 'B', 'C']);
      final pagesBefore = await db.select(db.pages).get();
      clock.current = DateTime.utc(2026, 10, 12);

      await repository.applyChanges(pageId, [
        Update(a, BlockType.heading, const BlockContent('A2')),
        Insert('n1', BlockType.text, const BlockContent('N'), After(a)),
        Move(c, const AtStart()),
        Trash(b),
      ]);

      expect(await db.select(db.pages).get(), pagesBefore);
    });

    test('SAVE-05: a batch touches only the rows it names', () async {
      final [_, b, _] = await seed(['A', 'B', 'C']);
      final before = await blockRows();
      clock.current = DateTime.utc(2026, 10, 12);

      await repository.applyChanges(pageId, [
        Update(b, BlockType.text, const BlockContent('B2')),
      ]);

      final after = await blockRows();
      final changed = [
        for (var i = 0; i < before.length; i++)
          if (before[i] != after[i]) after[i].id,
      ];
      expect(changed, [b]);
    });

    test('SAVE-09: a batch never issues a physical DELETE', () async {
      final [a, b, c] = await seed(['A', 'B', 'C']);
      await db.customStatement(
        'CREATE TEMP TRIGGER no_block_delete BEFORE DELETE ON blocks '
        "BEGIN SELECT RAISE(ABORT, 'physical delete'); END",
      );

      await repository.applyChanges(pageId, [
        Update(a, BlockType.text, const BlockContent('A2')),
        Insert('n1', BlockType.text, const BlockContent('N'), After(a)),
        Move(c, const AtStart()),
        Trash(b),
        Trash(c),
      ]);

      expect(await blockRows(), hasLength(4));
      expect((await blockRow(b)).deletedAt, isNotNull);
    });

    test('REPO-18: the stream emits once after a batch', () async {
      final [a, b] = await seed(['A', 'B']);
      final recorder = StreamRecorder(repository.watchByPage(pageId));
      await recorder.settle();
      final emitted = recorder.emissions.length;

      await repository.applyChanges(pageId, [
        Update(a, BlockType.text, const BlockContent('A2')),
        Trash(b),
      ]);
      await recorder.settle();

      expect(recorder.emissions.length, emitted + 1);
      expect(
        [for (final block in recorder.emissions.last) block.contentJson],
        [json('A2')],
      );
      await recorder.cancel();
    });
  });
}
