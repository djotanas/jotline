import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';
import 'package:jotline/features/pages/data/page_summary.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/stream_recorder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SequentialIdGenerator ids;
  late LocalUserRepository localUser;
  late NotebookRepository notebookRepository;
  late PageRepository repository;
  late String notebookId;

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
    repository = PageRepository(db, clock, ids, localUser);
    notebookId = await createNotebook();
  });
  tearDown(() => db.close());

  Future<List<NotebookPage>> pageRows() =>
      (db.select(db.pages)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<NotebookPage> pageRow(String id) =>
      (db.select(db.pages)..where((t) => t.id.equals(id))).getSingle();

  Future<List<String>> titles([String? inNotebook]) async {
    final recorder = StreamRecorder(
      repository.watchByNotebook(inNotebook ?? notebookId),
    );
    final emissions = await recorder.settle();
    await recorder.cancel();
    return [for (final p in emissions.last) p.page.title];
  }

  Future<List<String>> seed(List<String> names) async {
    return [
      for (final name in names)
        await repository.create(notebookId, title: name),
    ];
  }

  test('REPO-08: a new page goes after every page, deleted ones included, with '
      'updated_at and updated_by set', () async {
    final first = await repository.create(notebookId, title: 'A');
    final second = await repository.create(notebookId, title: 'B');
    await repository.moveToTrash(second);
    clock.current = DateTime.utc(2026, 10, 12);

    final third = await repository.create(notebookId, title: 'C');

    final row = await pageRow(third);
    expect(
      row.position.compareTo((await pageRow(second)).position),
      greaterThan(0),
    );
    expect(
      row.position.compareTo((await pageRow(first)).position),
      greaterThan(0),
    );
    expect(row.updatedAt, DateTime.utc(2026, 10, 12));
    expect(row.updatedBy, await localUser.id());
    expect(row.notebookId, notebookId);
    expect(row.deletedAt, isNull);
  });

  test('POS-01: the first page of a notebook gets position a0', () async {
    final id = await repository.create(notebookId, title: 'A');

    expect((await pageRow(id)).position, 'a0');
  });

  test('REPO-08: a page created after the highest page was deleted sorts '
      'above it', () async {
    final [_, high] = await seed(['A', 'B']);
    await repository.moveToTrash(high);

    final next = await repository.create(notebookId, title: 'C');

    expect(
      (await pageRow(next)).position.compareTo((await pageRow(high)).position),
      greaterThan(0),
    );
    expect(await titles(), ['A', 'C']);
  });

  test('REPO-08: creating a page in an unknown notebook throws and inserts no '
      'row', () async {
    await expectLater(
      repository.create('missing', title: 'A'),
      throwsA(isA<Exception>()),
    );

    expect(await pageRows(), isEmpty);
  });

  test('REPO-09: renaming sets title, updated_at and updated_by', () async {
    final id = await repository.create(notebookId, title: 'A');
    clock.current = DateTime.utc(2026, 10, 12);

    await repository.rename(id, 'Renamed');

    final row = await pageRow(id);
    expect(row.title, 'Renamed');
    expect(row.updatedAt, DateTime.utc(2026, 10, 12));
    expect(row.updatedBy, await localUser.id());
    expect(row.position, 'a0');
  });

  test('REPO-10: moving to the start, the end and between two pages shows in '
      'the stream order', () async {
    final [a, _, c] = await seed(['A', 'B', 'C']);

    await repository.move(c, const AtStart());
    expect(await titles(), ['C', 'A', 'B']);

    await repository.move(c, const AtEnd());
    expect(await titles(), ['A', 'B', 'C']);

    await repository.move(c, After(a));
    expect(await titles(), ['A', 'C', 'B']);
  });

  test('REPO-10: moving changes position, updated_at and updated_by', () async {
    final [a, b] = await seed(['A', 'B']);
    final before = await pageRow(a);
    clock.current = DateTime.utc(2026, 10, 12);

    await repository.move(a, After(b));

    final after = await pageRow(a);
    expect(after.position, isNot(before.position));
    expect(after.updatedAt, DateTime.utc(2026, 10, 12));
    expect(after.updatedBy, await localUser.id());
    expect(after.title, 'A');
  });

  test('POS-09: moving the third of five pages changes exactly one '
      'row', () async {
    final pageIds = await seed(['A', 'B', 'C', 'D', 'E']);
    final before = await pageRows();

    await repository.move(pageIds[2], const AtStart());

    final after = await pageRows();
    final changed = [
      for (var i = 0; i < before.length; i++)
        if (before[i] != after[i]) after[i].id,
    ];
    expect(changed, [pageIds[2]]);
  });

  test('REPO-11: the stream excludes deleted pages and orders by position, '
      'then id', () async {
    final [a, b, c] = await seed(['A', 'B', 'C']);
    await db.customStatement(
      "UPDATE pages SET position = 'a5' WHERE id IN ('$a', '$b')",
    );
    await repository.moveToTrash(c);
    await repository.create(notebookId, title: 'D');

    expect(a.compareTo(b), lessThan(0));
    expect(await titles(), ['A', 'B', 'D']);
  });

  test('REPO-11: the stream holds only the pages of its notebook', () async {
    await seed(['A']);
    final other = await createNotebook();
    await repository.create(other, title: 'Other');

    expect(await titles(), ['A']);
    expect(await titles(other), ['Other']);
  });

  test('REPO-12: the notebook row and its member rows stay identical through '
      'create, rename, move and delete', () async {
    final notebooksBefore = await db.select(db.notebooks).get();
    final membersBefore = await db.select(db.notebookMembers).get();

    final [a, b] = await seed(['A', 'B']);
    await repository.rename(a, 'Renamed');
    await repository.move(a, After(b));
    await repository.moveToTrash(b);

    expect(await db.select(db.notebooks).get(), notebooksBefore);
    expect(await db.select(db.notebookMembers).get(), membersBefore);
  });

  test('DEL-01: trashing sets deleted_at and keeps the row', () async {
    final id = await repository.create(notebookId, title: 'A');
    clock.current = DateTime.utc(2026, 10, 12);

    await repository.moveToTrash(id);

    final row = await pageRow(id);
    expect(row.deletedAt, DateTime.utc(2026, 10, 12));
    expect(row.title, 'A');
  });

  test('DEL-02: trashing twice keeps the original deleted_at', () async {
    final id = await repository.create(notebookId, title: 'A');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.moveToTrash(id);
    clock.current = DateTime.utc(2026, 10, 20);

    await repository.moveToTrash(id);

    expect((await pageRow(id)).deletedAt, DateTime.utc(2026, 10, 12));
  });

  test('DEL-05: a trashed page is gone from the stream', () async {
    final [a, _] = await seed(['A', 'B']);

    await repository.moveToTrash(a);

    expect(await titles(), ['B']);
  });

  test('DEL-06: the pages of a trashed notebook are not streamed and their '
      'rows do not change', () async {
    await seed(['A', 'B']);
    final before = await pageRows();

    await notebookRepository.moveToTrash(notebookId);

    expect(await titles(), isEmpty);
    expect(await pageRows(), before);
  });

  test('ID-03: page ids come from the generator', () async {
    final id = await repository.create(notebookId, title: 'A');

    final expected = SequentialIdGenerator();
    for (var i = 0; i < 3; i++) {
      expected.newId();
    }
    expect(id, expected.newId());
  });

  test('USER-05: updated_by holds the local user id on create, rename and '
      'move', () async {
    final userId = await localUser.id();
    final [a, b] = await seed(['A', 'B']);
    expect((await pageRow(a)).updatedBy, userId);

    await db.customStatement("UPDATE pages SET updated_by = 'x'");
    await repository.rename(a, 'Renamed');
    await repository.move(b, const AtStart());

    expect((await pageRow(a)).updatedBy, userId);
    expect((await pageRow(b)).updatedBy, userId);
  });

  test('TITLE-01: titles are stored trimmed on create and rename', () async {
    final id = await repository.create(notebookId, title: '  A  ');
    expect((await pageRow(id)).title, 'A');

    await repository.rename(id, ' B\n');

    expect((await pageRow(id)).title, 'B');
  });

  test('TITLE-04: an empty or blank title is stored as empty', () async {
    final created = await repository.create(notebookId, title: '   ');
    final defaulted = await repository.create(notebookId);
    final renamed = await repository.create(notebookId, title: 'A');
    await repository.rename(renamed, '  ');

    expect((await pageRow(created)).title, '');
    expect((await pageRow(defaulted)).title, '');
    expect((await pageRow(renamed)).title, '');
  });

  test('TITLE-03: 51 clusters are rejected on create and rename, leaving the '
      'rows unchanged, and 50 are accepted', () async {
    final fifty = '👍🏽' * 50;
    final id = await repository.create(notebookId, title: fifty);
    expect((await pageRow(id)).title, fifty);
    final before = await pageRows();

    await expectLater(
      repository.create(notebookId, title: '${fifty}a'),
      throwsArgumentError,
    );
    await expectLater(repository.rename(id, '${fifty}a'), throwsArgumentError);

    expect(await pageRows(), before);
  });

  Future<List<TrashedPage>> trashed() async {
    final recorder = StreamRecorder(repository.watchTrashed());
    final emissions = await recorder.settle();
    await recorder.cancel();
    return emissions.last;
  }

  test('EDGE-03: watchOne emits the page and then null once it is '
      'trashed', () async {
    final id = await repository.create(notebookId, title: 'A');
    final recorder = StreamRecorder(repository.watchOne(id));
    await recorder.settle();
    expect(recorder.emissions.last?.page.title, 'A');

    await repository.rename(id, 'B');
    await recorder.settle();
    expect(recorder.emissions.last?.page.title, 'B');

    await repository.moveToTrash(id);
    await recorder.settle();

    expect(recorder.emissions.last, isNull);
    await recorder.cancel();
  });

  test('EDGE-03: watchOne emits null when the notebook is trashed', () async {
    final id = await repository.create(notebookId, title: 'A');
    final recorder = StreamRecorder(repository.watchOne(id));
    await recorder.settle();

    await notebookRepository.moveToTrash(notebookId);
    await recorder.settle();

    expect(recorder.emissions.last, isNull);
    await recorder.cancel();
  });

  test('EDGE-03: watchOne emits null for an unknown id', () async {
    final recorder = StreamRecorder(repository.watchOne('missing'));

    await recorder.settle();

    expect(recorder.emissions, [null]);
    await recorder.cancel();
  });

  test('PGOPT-05: restore clears only deleted_at and keeps position, so the '
      'page returns to its slot', () async {
    final [a, b, c] = await seed(['A', 'B', 'C']);
    final before = await pageRow(b);
    await repository.moveToTrash(b);
    expect(await titles(), ['A', 'C']);

    await repository.restore(b);

    expect(await titles(), ['A', 'B', 'C']);
    expect(await pageRow(b), before);
    expect((await pageRow(a)).deletedAt, isNull);
    expect((await pageRow(c)).deletedAt, isNull);
  });

  test('TRASH-09: putBackInTrash writes the original deleted_at', () async {
    final id = await repository.create(notebookId, title: 'A');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.moveToTrash(id);
    final original = (await pageRow(id)).deletedAt!;
    await repository.restore(id);
    clock.current = DateTime.utc(2026, 11);

    await repository.putBackInTrash(id, original);

    expect((await pageRow(id)).deletedAt, DateTime.utc(2026, 10, 12));
    expect(await titles(), isEmpty);
  });

  test('TRASH-04: watchTrashed lists pages deleted on their own with the '
      'notebook title and color', () async {
    final other = await notebookRepository.create(
      title: 'Ideas',
      cover: CoverPattern.pautada,
      color: NotebookColor.musgo,
    );
    final kept = await repository.create(notebookId, title: 'Kept');
    final gone = await repository.create(other, title: 'Gone');
    await repository.moveToTrash(gone);

    final rows = await trashed();

    expect(kept, isNot(gone));
    expect(rows.map((t) => t.page.id), [gone]);
    expect(rows.single.notebookTitle, 'Ideas');
    expect(rows.single.notebookColor, NotebookColor.musgo);
    expect(rows.single.page.deletedAt, clock.current);
  });

  test('TRASH-05: watchTrashed excludes pages of a notebook in the trash, '
      'TRASH-10: and includes them again after it is restored', () async {
    final id = await repository.create(notebookId, title: 'A');
    await repository.moveToTrash(id);
    expect((await trashed()).map((t) => t.page.id), [id]);

    await notebookRepository.moveToTrash(notebookId);
    expect(await trashed(), isEmpty);

    await notebookRepository.restore(notebookId);
    expect((await trashed()).map((t) => t.page.id), [id]);
  });

  test('TRASH-11: watchTrashed orders by deleted_at descending, then id '
      'descending', () async {
    final [oldest, tieA, tieB, newest] = await seed(['O', 'A', 'B', 'N']);
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.moveToTrash(oldest);
    clock.current = DateTime.utc(2026, 10, 13);
    await repository.moveToTrash(tieA);
    await repository.moveToTrash(tieB);
    clock.current = DateTime.utc(2026, 10, 14);
    await repository.moveToTrash(newest);

    expect(tieB.compareTo(tieA), greaterThan(0));
    expect((await trashed()).map((t) => t.page.id), [
      newest,
      tieB,
      tieA,
      oldest,
    ]);
  });

  test('TRASH-08: watchTrashed re-emits when a page is trashed and '
      'restored', () async {
    final id = await repository.create(notebookId, title: 'A');
    final recorder = StreamRecorder(repository.watchTrashed());
    await recorder.settle();
    expect(recorder.emissions.last, isEmpty);

    await repository.moveToTrash(id);
    await recorder.settle();
    expect(recorder.emissions.last, hasLength(1));

    await repository.restore(id);
    await recorder.settle();
    expect(recorder.emissions.last, isEmpty);
    await recorder.cancel();
  });

  test('EDGE-05: a page restored into an archived notebook shows in '
      'watchByNotebook', () async {
    final id = await repository.create(notebookId, title: 'A');
    await notebookRepository.archive(notebookId);
    await repository.moveToTrash(id);
    expect(await titles(), isEmpty);

    await repository.restore(id);

    expect(await titles(), ['A']);
  });

  test('REPO-18: the stream emits after create, rename, move and '
      'delete', () async {
    final recorder = StreamRecorder(repository.watchByNotebook(notebookId));
    List<String> titlesNow() => [
      for (final p in recorder.emissions.last) p.page.title,
    ];
    await recorder.settle();
    expect(titlesNow(), isEmpty);

    final a = await repository.create(notebookId, title: 'A');
    await recorder.settle();
    expect(titlesNow(), ['A']);

    final b = await repository.create(notebookId, title: 'B');
    await recorder.settle();
    expect(titlesNow(), ['A', 'B']);

    await repository.rename(a, 'A2');
    await recorder.settle();
    expect(titlesNow(), ['A2', 'B']);

    await repository.move(b, const AtStart());
    await recorder.settle();
    expect(titlesNow(), ['B', 'A2']);

    await repository.moveToTrash(a);
    await recorder.settle();
    expect(titlesNow(), ['B']);
    await recorder.cancel();
  });
  group('PageSummary', () {
    late BlockRepository blocks;

    setUp(() => blocks = BlockRepository(db, clock, ids, localUser));

    Future<String> block(
      String pageId,
      String text, {
      BlockType type = BlockType.text,
    }) => blocks.create(
      pageId,
      type: type.id,
      contentJson: BlockContent(text).toJson(),
    );

    Future<List<PageSummary>> summaries() async {
      final recorder = StreamRecorder(repository.watchByNotebook(notebookId));
      final emissions = await recorder.settle();
      await recorder.cancel();
      return emissions.last;
    }

    Future<PageSummary> summary(String id) async =>
        (await summaries()).singleWhere((s) => s.page.id == id);

    test('EDITED-01: a block saved today on a page edited yesterday makes the '
        'page edited today, with the pages row unchanged', () async {
      clock.current = DateTime.utc(2026, 10, 10, 9);
      final id = await repository.create(notebookId, title: 'A');
      final before = await pageRow(id);
      clock.current = DateTime.utc(2026, 10, 11, 14);

      await block(id, 'Belém');

      expect((await summary(id)).lastEditedAt, DateTime.utc(2026, 10, 11, 14));
      expect(await pageRow(id), before);
    });

    test("EDITED-01: a deleted block's deleted_at counts", () async {
      final id = await repository.create(notebookId, title: 'A');
      clock.current = DateTime.utc(2026, 10, 12);
      final b = await block(id, 'Belém');
      clock.current = DateTime.utc(2026, 10, 13, 7);

      await blocks.moveToTrash(b);

      expect((await summary(id)).lastEditedAt, DateTime.utc(2026, 10, 13, 7));
    });

    test('EDITED-01: a page with no blocks uses pages.updated_at', () async {
      clock.current = DateTime.utc(2026, 10, 9, 18);
      final id = await repository.create(notebookId, title: 'A');

      expect((await summary(id)).lastEditedAt, DateTime.utc(2026, 10, 9, 18));
    });

    test('EDITED-01: a page renamed after its last block write uses '
        'pages.updated_at', () async {
      final id = await repository.create(notebookId, title: 'A');
      await block(id, 'Belém');
      clock.current = DateTime.utc(2026, 10, 14);

      await repository.rename(id, 'B');

      expect((await summary(id)).lastEditedAt, DateTime.utc(2026, 10, 14));
    });

    test('EXCERPT-01: the excerpt skips a heading, an empty block, a '
        'whitespace-only block and a deleted block, and is trimmed', () async {
      final id = await repository.create(notebookId, title: 'A');
      await block(id, 'Manhã', type: BlockType.heading);
      await block(id, '');
      await block(id, ' \t\n\r ');
      await blocks.moveToTrash(await block(id, 'Apagado'));
      await block(id, '  Belém cedo  ', type: BlockType.bulletedListItem);
      await block(id, 'Depois');

      expect((await summary(id)).excerpt, 'Belém cedo');
    });

    test('EXCERPT-01: a checklist item can be the excerpt', () async {
      final id = await repository.create(notebookId, title: 'A');
      await block(id, 'Comprar pão', type: BlockType.checklistItem);

      expect((await summary(id)).excerpt, 'Comprar pão');
    });

    test('EXCERPT-04: a page with only a heading has no excerpt', () async {
      final id = await repository.create(notebookId, title: 'A');
      await block(id, 'Manhã', type: BlockType.heading);

      expect((await summary(id)).excerpt, isNull);
    });

    test('EXCERPT-03: a page with no blocks has no excerpt', () async {
      final id = await repository.create(notebookId, title: 'A');

      expect((await summary(id)).excerpt, isNull);
    });

    test(
      'EDGE-05: a page whose blocks are all deleted has no excerpt',
      () async {
        final id = await repository.create(notebookId, title: 'A');
        await blocks.moveToTrash(await block(id, 'Belém'));
        await blocks.moveToTrash(await block(id, 'cedo'));

        expect((await summary(id)).excerpt, isNull);
      },
    );

    test(
      'EDITED-05: the order stays by position after a block write',
      () async {
        final [a, b] = await seed(['A', 'B']);
        clock.current = DateTime.utc(2026, 10, 20);

        await block(b, 'Belém');

        expect([for (final s in await summaries()) s.page.id], [a, b]);
      },
    );

    test('EDITED-04: watchByNotebook re-emits on a block insert, update, move '
        'and trash', () async {
      final id = await repository.create(notebookId, title: 'A');
      final recorder = StreamRecorder(repository.watchByNotebook(notebookId));
      PageSummary now() => recorder.emissions.last.single;
      await recorder.settle();
      expect(now().excerpt, isNull);

      clock.current = DateTime.utc(2026, 10, 12);
      final first = await block(id, 'Belém');
      await recorder.settle();
      expect(now().excerpt, 'Belém');
      expect(now().lastEditedAt, DateTime.utc(2026, 10, 12));

      clock.current = DateTime.utc(2026, 10, 13);
      final second = await block(id, 'cedo');
      await recorder.settle();
      expect(now().lastEditedAt, DateTime.utc(2026, 10, 13));

      clock.current = DateTime.utc(2026, 10, 14);
      await blocks.applyChanges(id, [
        Update(first, BlockType.text, const BlockContent('Belém!')),
      ]);
      await recorder.settle();
      expect(now().excerpt, 'Belém!');
      expect(now().lastEditedAt, DateTime.utc(2026, 10, 14));

      clock.current = DateTime.utc(2026, 10, 15);
      await blocks.move(second, const AtStart());
      await recorder.settle();
      expect(now().excerpt, 'cedo');
      expect(now().lastEditedAt, DateTime.utc(2026, 10, 15));

      clock.current = DateTime.utc(2026, 10, 16);
      await blocks.moveToTrash(second);
      await recorder.settle();
      expect(now().excerpt, 'Belém!');
      expect(now().lastEditedAt, DateTime.utc(2026, 10, 16));
      await recorder.cancel();
    });

    test('EDITED-04: watchOne re-emits on a block write', () async {
      final id = await repository.create(notebookId, title: 'A');
      final recorder = StreamRecorder(repository.watchOne(id));
      await recorder.settle();
      expect(recorder.emissions.last?.excerpt, isNull);

      clock.current = DateTime.utc(2026, 10, 12);
      await block(id, 'Belém');
      await recorder.settle();

      expect(recorder.emissions.last?.excerpt, 'Belém');
      expect(recorder.emissions.last?.lastEditedAt, DateTime.utc(2026, 10, 12));
      await recorder.cancel();
    });
  });
}
