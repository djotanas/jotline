import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/features/pages/data/page_repository.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/stream_recorder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SequentialIdGenerator ids;
  late LocalUserRepository localUser;
  late NotebookRepository repository;
  late PageRepository pageRepository;

  setUp(() async {
    db = createTestDatabase();
    clock = FakeClock(DateTime.utc(2026, 10, 11, 8));
    ids = SequentialIdGenerator();
    localUser = LocalUserRepository(db, ids);
    repository = NotebookRepository(db, clock, ids, localUser);
    pageRepository = PageRepository(db, clock, ids, localUser);
  });
  tearDown(() => db.close());

  Future<String> create(String title) => repository.create(
    title: title,
    cover: CoverPattern.lisa,
    color: NotebookColor.azulTinta,
  );

  Future<List<Notebook>> notebooks() => db.select(db.notebooks).get();
  Future<List<NotebookMember>> members() => db.select(db.notebookMembers).get();

  Future<List<NotebookSummary>> summaries({required bool archived}) async {
    final recorder = StreamRecorder(
      repository.watchSummaries(archived: archived),
    );
    final emissions = await recorder.settle();
    await recorder.cancel();
    return emissions.last;
  }

  Future<List<String>> activeTitles() async => [
    for (final s in await summaries(archived: false)) s.notebook.title,
  ];

  test('REPO-01: creating writes the notebook and an owner member row for the '
      'local user', () async {
    final userId = await localUser.id();

    final id = await repository.create(
      title: 'Work',
      cover: CoverPattern.pautada,
      color: NotebookColor.musgo,
    );

    final notebook = (await notebooks()).single;
    expect(notebook.id, id);
    expect(notebook.title, 'Work');
    expect(notebook.cover, CoverPattern.pautada);
    expect(notebook.color, NotebookColor.musgo);
    expect(notebook.createdAt, clock.current);
    expect(notebook.deletedAt, isNull);
    final member = (await members()).single;
    expect(member.notebookId, id);
    expect(member.role.name, 'owner');
    expect(member.userId, userId);
    expect(member.addedBy, userId);
    expect(member.archivedAt, isNull);
    expect(member.createdAt, clock.current);
  });

  test('REPO-02: a failing member insert leaves no notebook row', () async {
    await localUser.id();
    await db.customStatement(
      "INSERT INTO notebooks VALUES ('seed', 'Seed', 'lisa', 'azulTinta', "
      "'u', '2026-10-11T08:00:00.000Z', NULL)",
    );
    final collidingMemberId = SequentialIdGenerator()
      ..newId()
      ..newId();
    final memberId = collidingMemberId.newId();
    await db.customStatement(
      "INSERT INTO notebook_members VALUES ('$memberId', 'seed', 'u', "
      "'owner', 'u', '2026-10-11T08:00:00.000Z', NULL)",
    );
    final before = await members();

    await expectLater(create('Work'), throwsA(isA<Exception>()));

    expect((await notebooks()).map((n) => n.id), ['seed']);
    expect(await members(), before);
  });

  test('REPO-03: renaming or restyling changes only that notebook', () async {
    final first = await create('First');
    final second = await create('Second');
    final secondBefore = (await notebooks()).firstWhere((n) => n.id == second);
    final membersBefore = await members();

    await repository.update(
      first,
      title: 'Renamed',
      cover: CoverPattern.quadriculada,
      color: NotebookColor.grafite,
    );

    final rows = await notebooks();
    final changed = rows.firstWhere((n) => n.id == first);
    expect(changed.title, 'Renamed');
    expect(changed.cover, CoverPattern.quadriculada);
    expect(changed.color, NotebookColor.grafite);
    expect(rows.firstWhere((n) => n.id == second), secondBefore);
    expect(await members(), membersBefore);
  });

  test('REPO-03: updating only the title keeps cover and color', () async {
    final id = await create('First');

    await repository.update(id, title: 'Renamed');

    final row = (await notebooks()).single;
    expect(row.title, 'Renamed');
    expect(row.cover, CoverPattern.lisa);
    expect(row.color, NotebookColor.azulTinta);
  });

  test('REPO-04: archiving sets archived_at on the local user member row '
      'only and keeps deleted_at null', () async {
    final id = await create('Work');
    final notebookBefore = (await notebooks()).single;
    clock.current = DateTime.utc(2026, 10, 12);

    await repository.archive(id);

    expect((await members()).single.archivedAt, DateTime.utc(2026, 10, 12));
    final notebook = (await notebooks()).single;
    expect(notebook.deletedAt, isNull);
    expect(notebook, notebookBefore);
  });

  test('REPO-04: archiving does not touch another user member row', () async {
    final id = await create('Work');
    await db.customStatement(
      "INSERT INTO notebook_members VALUES ('other-member', '$id', "
      "'other-user', 'viewer', 'u', '2026-10-11T08:00:00.000Z', NULL)",
    );

    await repository.archive(id);

    final other = (await members()).firstWhere((m) => m.id == 'other-member');
    expect(other.archivedAt, isNull);
  });

  test(
    'REPO-05: unarchiving clears archived_at on the local user member row',
    () async {
      final id = await create('Work');
      await repository.archive(id);

      await repository.unarchive(id);

      expect((await members()).single.archivedAt, isNull);
      expect((await notebooks()).single.deletedAt, isNull);
    },
  );

  test('REPO-06: the active summaries hold only notebooks that are neither '
      'archived nor trashed', () async {
    final active = await create('Active');
    final archived = await create('Archived');
    final trashed = await create('Trashed');
    await repository.archive(archived);
    await repository.moveToTrash(trashed);

    final rows = await summaries(archived: false);

    expect(rows.map((s) => s.notebook.id), [active]);
    expect(rows.single.archivedAt, isNull);
  });

  test('REPO-07: the archived summaries hold only archived notebooks and '
      'carry the member archived_at', () async {
    final a = await create('A');
    await create('Active');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.archive(a);

    final rows = await summaries(archived: true);

    expect(rows.map((s) => s.notebook.id), [a]);
    expect(rows.single.archivedAt, DateTime.utc(2026, 10, 12));
  });

  test('REPO-18: the active stream emits after create, rename, archive and '
      'delete', () async {
    final recorder = StreamRecorder(repository.watchSummaries(archived: false));
    List<String> titles() => [
      for (final s in recorder.emissions.last) s.notebook.title,
    ];
    await recorder.settle();
    expect(titles(), isEmpty);

    final id = await create('Work');
    await recorder.settle();
    expect(titles(), ['Work']);

    await repository.update(id, title: 'Renamed');
    await recorder.settle();
    expect(titles(), ['Renamed']);

    await repository.archive(id);
    await recorder.settle();
    expect(titles(), isEmpty);

    await repository.unarchive(id);
    await recorder.settle();
    expect(titles(), ['Renamed']);

    await repository.moveToTrash(id);
    await recorder.settle();
    expect(titles(), isEmpty);
    await recorder.cancel();
  });

  test('NBLIST-03: the page count excludes pages in the trash', () async {
    final id = await create('Work');
    await pageRepository.create(id, title: 'A');
    final trashed = await pageRepository.create(id, title: 'B');
    await pageRepository.moveToTrash(trashed);

    final summary = (await summaries(archived: false)).single;

    expect(summary.pageCount, 1);
  });

  test('NBLIST-03: a notebook without pages has a count of 0', () async {
    await create('Work');

    expect((await summaries(archived: false)).single.pageCount, 0);
  });

  test('EDGE-01: lastEditedAt is the latest page updated_at among pages not in '
      'the trash', () async {
    final id = await create('Work');
    clock.current = DateTime.utc(2026, 10, 11, 9);
    await pageRepository.create(id, title: 'A');
    clock.current = DateTime.utc(2026, 10, 11, 12);
    final latest = await pageRepository.create(id, title: 'B');
    clock.current = DateTime.utc(2026, 10, 11, 10);
    await pageRepository.create(id, title: 'C');
    expect(
      (await summaries(archived: false)).single.lastEditedAt,
      DateTime.utc(2026, 10, 11, 12),
    );

    await pageRepository.moveToTrash(latest);

    expect(
      (await summaries(archived: false)).single.lastEditedAt,
      DateTime.utc(2026, 10, 11, 10),
    );
  });

  test('EDGE-01: lastEditedAt is created_at when the notebook has no '
      'pages', () async {
    await create('Work');

    expect(
      (await summaries(archived: false)).single.lastEditedAt,
      DateTime.utc(2026, 10, 11, 8),
    );
  });

  test('EDGE-01: when every page is in the trash the count is 0 and '
      'lastEditedAt is created_at', () async {
    final id = await create('Work');
    clock.current = DateTime.utc(2026, 10, 12);
    final page = await pageRepository.create(id, title: 'A');
    await pageRepository.moveToTrash(page);

    final summary = (await summaries(archived: false)).single;

    expect(summary.pageCount, 0);
    expect(summary.lastEditedAt, DateTime.utc(2026, 10, 11, 8));
  });

  test('NBLIST-04: archived summaries carry the count and the member '
      'archived_at', () async {
    final id = await create('Work');
    await pageRepository.create(id, title: 'A');
    await pageRepository.create(id, title: 'B');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.archive(id);

    final summary = (await summaries(archived: true)).single;

    expect(summary.pageCount, 2);
    expect(summary.archivedAt, DateTime.utc(2026, 10, 12));
  });

  test('NBLIST-07: the summaries re-emit when a page is added, renamed or '
      'trashed', () async {
    final id = await create('Work');
    final recorder = StreamRecorder(repository.watchSummaries(archived: false));
    await recorder.settle();
    expect(recorder.emissions.last.single.pageCount, 0);

    clock.current = DateTime.utc(2026, 10, 12);
    final page = await pageRepository.create(id, title: 'A');
    await recorder.settle();
    expect(recorder.emissions.last.single.pageCount, 1);
    expect(
      recorder.emissions.last.single.lastEditedAt,
      DateTime.utc(2026, 10, 12),
    );

    clock.current = DateTime.utc(2026, 10, 13);
    await pageRepository.rename(page, 'Renamed');
    await recorder.settle();
    expect(
      recorder.emissions.last.single.lastEditedAt,
      DateTime.utc(2026, 10, 13),
    );

    await pageRepository.moveToTrash(page);
    await recorder.settle();
    expect(recorder.emissions.last.single.pageCount, 0);
    await recorder.cancel();
  });

  test(
    'NBLIST-07: the summaries re-emit when the member row changes',
    () async {
      final id = await create('Work');
      final active = StreamRecorder(repository.watchSummaries(archived: false));
      final archived = StreamRecorder(
        repository.watchSummaries(archived: true),
      );
      await active.settle();
      await archived.settle();

      await repository.archive(id);
      await active.settle();
      await archived.settle();
      expect(active.emissions.last, isEmpty);
      expect(archived.emissions.last.single.archivedAt, clock.current);

      await repository.unarchive(id);
      await active.settle();
      await archived.settle();
      expect(active.emissions.last.single.archivedAt, isNull);
      expect(archived.emissions.last, isEmpty);
      await active.cancel();
      await archived.cancel();
    },
  );

  test('NBLIST-07: watchOne emits the summary and then null after '
      'moveToTrash', () async {
    final id = await create('Work');
    await pageRepository.create(id, title: 'A');
    final recorder = StreamRecorder(repository.watchOne(id));
    await recorder.settle();
    expect(recorder.emissions.last?.notebook.id, id);
    expect(recorder.emissions.last?.pageCount, 1);

    await repository.moveToTrash(id);
    await recorder.settle();

    expect(recorder.emissions.last, isNull);
    await recorder.cancel();
  });

  test('NBLIST-07: watchOne also emits an archived notebook', () async {
    final id = await create('Work');
    await repository.archive(id);
    final recorder = StreamRecorder(repository.watchOne(id));

    await recorder.settle();

    expect(recorder.emissions.last?.archivedAt, clock.current);
    await recorder.cancel();
  });

  test('NBLIST-07: watchOne emits null for an unknown id', () async {
    final recorder = StreamRecorder(repository.watchOne('missing'));

    await recorder.settle();

    expect(recorder.emissions, [null]);
    await recorder.cancel();
  });

  test('ARCH-03: setArchivedAt puts back the previous value, including '
      'null', () async {
    final id = await create('Work');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.archive(id);
    final previous = (await members()).single.archivedAt;
    clock.current = DateTime.utc(2026, 10, 20);
    await repository.unarchive(id);
    expect((await members()).single.archivedAt, isNull);

    await repository.setArchivedAt(id, previous);
    expect((await members()).single.archivedAt, DateTime.utc(2026, 10, 12));

    await repository.setArchivedAt(id, null);
    expect((await members()).single.archivedAt, isNull);
  });

  test('ARCH-04: archive and unarchive never write deleted_at', () async {
    final id = await create('Work');

    await repository.archive(id);
    expect((await notebooks()).single.deletedAt, isNull);
    await repository.unarchive(id);

    expect((await notebooks()).single.deletedAt, isNull);
  });

  test(
    'NBDEL-04: restore brings a trashed notebook back to its list',
    () async {
      final id = await create('Work');
      await repository.moveToTrash(id);
      expect(await activeTitles(), isEmpty);

      await repository.restore(id);

      expect(await activeTitles(), ['Work']);
      expect((await notebooks()).single.deletedAt, isNull);
    },
  );

  test('NBDEL-05: restore changes only notebooks.deleted_at and no page or '
      'block row', () async {
    final id = await create('Work');
    final page = await pageRepository.create(id, title: 'A');
    await db.customStatement(
      "INSERT INTO blocks VALUES ('b1', '$page', 'text', 'a0', 'x', 1, "
      "'2026-10-11T08:00:00.000Z', 'u', NULL)",
    );
    await repository.moveToTrash(id);
    final pagesBefore = await db.select(db.pages).get();
    final blocksBefore = await db.select(db.blocks).get();
    final membersBefore = await members();
    final notebookBefore = (await notebooks()).single;

    await repository.restore(id);

    expect(await db.select(db.pages).get(), pagesBefore);
    expect(await db.select(db.blocks).get(), blocksBefore);
    expect(await members(), membersBefore);
    expect(
      (await notebooks()).single,
      notebookBefore.copyWith(deletedAt: const Value(null)),
    );
  });

  test('NBDEL-04: restore keeps the archived state of the member', () async {
    final id = await create('Work');
    await repository.archive(id);
    await repository.moveToTrash(id);

    await repository.restore(id);

    expect((await summaries(archived: true)).single.notebook.id, id);
  });

  test('NBDEL-04: putBackInTrash writes the given date', () async {
    final id = await create('Work');
    await repository.moveToTrash(id);
    final original = (await notebooks()).single.deletedAt!;
    await repository.restore(id);
    clock.current = DateTime.utc(2026, 11);

    await repository.putBackInTrash(id, original);

    expect((await notebooks()).single.deletedAt, original);
    expect(await activeTitles(), isEmpty);
  });

  Future<List<TrashedNotebook>> trashed() async {
    final recorder = StreamRecorder(repository.watchTrashed());
    final emissions = await recorder.settle();
    await recorder.cancel();
    return emissions.last;
  }

  test('TRASH-02: watchTrashed holds only notebooks in the trash', () async {
    final gone = await create('Gone');
    await create('Kept');
    await repository.moveToTrash(gone);

    final rows = await trashed();

    expect(rows.map((t) => t.notebook.id), [gone]);
    expect(rows.single.notebook.deletedAt, clock.current);
  });

  test('TRASH-03: the count excludes pages deleted on their own', () async {
    final id = await create('Gone');
    await pageRepository.create(id, title: 'A');
    await pageRepository.create(id, title: 'B');
    final own = await pageRepository.create(id, title: 'C');
    await pageRepository.moveToTrash(own);
    await repository.moveToTrash(id);

    expect((await trashed()).single.pageCount, 2);
  });

  test('TRASH-03: a trashed notebook without pages has a count of 0', () async {
    final id = await create('Gone');
    await repository.moveToTrash(id);

    expect((await trashed()).single.pageCount, 0);
  });

  test('TRASH-02: archivedAt is carried for a notebook archived before '
      'deletion', () async {
    final archived = await create('Archived');
    final active = await create('Active');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.archive(archived);
    await repository.moveToTrash(archived);
    await repository.moveToTrash(active);

    final rows = {for (final t in await trashed()) t.notebook.id: t};

    expect(rows[archived]!.archivedAt, DateTime.utc(2026, 10, 12));
    expect(rows[active]!.archivedAt, isNull);
  });

  test('TRASH-11: order is deleted_at descending, then id '
      'descending', () async {
    final oldest = await create('Oldest');
    final tieA = await create('TieA');
    final tieB = await create('TieB');
    final newest = await create('Newest');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.moveToTrash(oldest);
    clock.current = DateTime.utc(2026, 10, 13);
    await repository.moveToTrash(tieA);
    await repository.moveToTrash(tieB);
    clock.current = DateTime.utc(2026, 10, 14);
    await repository.moveToTrash(newest);

    expect(tieB.compareTo(tieA), greaterThan(0));
    expect((await trashed()).map((t) => t.notebook.id), [
      newest,
      tieB,
      tieA,
      oldest,
    ]);
  });

  test('TRASH-07: watchTrashed re-emits on trash and restore', () async {
    final id = await create('Work');
    final recorder = StreamRecorder(repository.watchTrashed());
    await recorder.settle();
    expect(recorder.emissions.last, isEmpty);

    await repository.moveToTrash(id);
    await recorder.settle();
    expect(recorder.emissions.last.map((t) => t.notebook.id), [id]);

    await repository.restore(id);
    await recorder.settle();
    expect(recorder.emissions.last, isEmpty);
    await recorder.cancel();
  });

  test('DEL-01: trashing sets deleted_at and keeps the row', () async {
    final id = await create('Work');
    clock.current = DateTime.utc(2026, 10, 12);

    await repository.moveToTrash(id);

    final row = (await notebooks()).single;
    expect(row.id, id);
    expect(row.deletedAt, DateTime.utc(2026, 10, 12));
    expect(await members(), hasLength(1));
  });

  test('DEL-02: trashing twice keeps the original deleted_at', () async {
    final id = await create('Work');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.moveToTrash(id);
    clock.current = DateTime.utc(2026, 10, 20);

    await repository.moveToTrash(id);

    expect((await notebooks()).single.deletedAt, DateTime.utc(2026, 10, 12));
  });

  test('DEL-04: a trashed notebook is in neither stream', () async {
    final id = await create('Work');
    await create('Kept');

    await repository.moveToTrash(id);

    expect(await activeTitles(), ['Kept']);
    expect(await summaries(archived: true), isEmpty);
  });

  test('DEL-04: a notebook archived and then trashed is in neither '
      'stream', () async {
    final id = await create('Work');
    await repository.archive(id);
    await repository.moveToTrash(id);

    expect(await summaries(archived: true), isEmpty);
    expect(await activeTitles(), isEmpty);
  });

  test('ID-03: notebook and member ids come from the generator', () async {
    final userId = await localUser.id();
    final notebookId = await create('Work');

    final expected = SequentialIdGenerator();
    final userExpected = expected.newId();
    final notebookExpected = expected.newId();
    final memberExpected = expected.newId();
    expect(userId, userExpected);
    expect(notebookId, notebookExpected);
    expect((await members()).single.id, memberExpected);
  });

  test('USER-05: created_by, user_id and added_by hold the local user '
      'id', () async {
    await create('Work');

    final userId = await localUser.id();
    expect((await notebooks()).single.createdBy, userId);
    final member = (await members()).single;
    expect(member.userId, userId);
    expect(member.addedBy, userId);
  });

  test('TITLE-01: the stored title is trimmed on create and rename', () async {
    final id = await create('  Work  ');
    expect((await notebooks()).single.title, 'Work');

    await repository.update(id, title: '\tRenamed\n');

    expect((await notebooks()).single.title, 'Renamed');
  });

  test('TITLE-02: an empty title is rejected on create and rename, leaving the '
      'row unchanged', () async {
    await expectLater(create('   '), throwsArgumentError);
    expect(await notebooks(), isEmpty);
    expect(await members(), isEmpty);

    final id = await create('Work');
    final before = await notebooks();
    await expectLater(repository.update(id, title: ' '), throwsArgumentError);

    expect(await notebooks(), before);
  });

  test('TITLE-03: 51 clusters are rejected and 50 accepted', () async {
    final fifty = '👍🏽' * 50;
    final id = await create(fifty);
    expect((await notebooks()).single.title, fifty);
    final before = await notebooks();

    await expectLater(
      repository.update(id, title: '${'👍🏽' * 50}a'),
      throwsArgumentError,
    );
    await expectLater(create('a' * 51), throwsArgumentError);

    expect(await notebooks(), before);
    expect(await members(), hasLength(1));
  });

  test('SCHEMA-09: the stored cover and color are the enum names', () async {
    await repository.create(
      title: 'Work',
      cover: CoverPattern.pontilhada,
      color: NotebookColor.ameixa,
    );

    final row = await db
        .customSelect('SELECT cover, color FROM notebooks')
        .getSingle();
    expect(row.read<String>('cover'), 'pontilhada');
    expect(row.read<String>('color'), 'ameixa');
  });

  test('closing the database completes the stream without an error', () async {
    await create('Work');
    final recorder = StreamRecorder(repository.watchSummaries(archived: false));
    await recorder.settle();

    await db.close();
    await recorder.settle();

    expect(recorder.errors, isEmpty);
    expect(recorder.isDone, isTrue);
    db = createTestDatabase();
  });
  group('last edited from blocks', () {
    late BlockRepository blocks;

    setUp(() => blocks = BlockRepository(db, clock, ids, localUser));

    Future<String> block(String pageId, String text) => blocks.create(
      pageId,
      type: BlockType.text.id,
      contentJson: BlockContent(text).toJson(),
    );

    test('EDITED-03: a notebook whose only change today is a block write '
        'sorts first under lastEdited', () async {
      clock.current = DateTime.utc(2026, 10, 9);
      final older = await create('Older');
      final page = await pageRepository.create(older, title: 'A');
      clock.current = DateTime.utc(2026, 10, 10);
      final newer = await create('Newer');
      await pageRepository.create(newer, title: 'B');
      expect(
        [
          for (final s in sortNotebooks(
            await summaries(archived: false),
            NotebookSort.lastEdited,
          ))
            s.notebook.id,
        ],
        [newer, older],
      );
      clock.current = DateTime.utc(2026, 10, 11, 15);

      await block(page, 'Belém');

      final sorted = sortNotebooks(
        await summaries(archived: false),
        NotebookSort.lastEdited,
      );
      expect([for (final s in sorted) s.notebook.id], [older, newer]);
      expect(sorted.first.lastEditedAt, DateTime.utc(2026, 10, 11, 15));
    });

    test("EDITED-01: a block's deleted_at counts", () async {
      final id = await create('Work');
      final page = await pageRepository.create(id, title: 'A');
      clock.current = DateTime.utc(2026, 10, 12);
      final b = await block(page, 'Belém');
      clock.current = DateTime.utc(2026, 10, 13, 6);

      await blocks.moveToTrash(b);

      expect(
        (await summaries(archived: false)).single.lastEditedAt,
        DateTime.utc(2026, 10, 13, 6),
      );
    });

    test('EDITED-03: blocks of a trashed page do not count', () async {
      final id = await create('Work');
      clock.current = DateTime.utc(2026, 10, 12);
      await pageRepository.create(id, title: 'A');
      final trashed = await pageRepository.create(id, title: 'B');
      clock.current = DateTime.utc(2026, 10, 14);
      await block(trashed, 'Belém');

      await pageRepository.moveToTrash(trashed);

      expect(
        (await summaries(archived: false)).single.lastEditedAt,
        DateTime.utc(2026, 10, 12),
      );
    });

    test(
      'EDITED-03: pageCount is unchanged with many blocks per page',
      () async {
        final id = await create('Work');
        final a = await pageRepository.create(id, title: 'A');
        final b = await pageRepository.create(id, title: 'B');
        for (final text in ['1', '2', '3']) {
          await block(a, text);
        }
        await block(b, '4');
        await blocks.moveToTrash(await block(b, '5'));

        expect((await summaries(archived: false)).single.pageCount, 2);
      },
    );

    test('EDITED-04: the summaries re-emit on a block write', () async {
      final id = await create('Work');
      final page = await pageRepository.create(id, title: 'A');
      final recorder = StreamRecorder(
        repository.watchSummaries(archived: false),
      );
      await recorder.settle();
      expect(
        recorder.emissions.last.single.lastEditedAt,
        DateTime.utc(2026, 10, 11, 8),
      );

      clock.current = DateTime.utc(2026, 10, 12, 10);
      final b = await block(page, 'Belém');
      await recorder.settle();
      expect(
        recorder.emissions.last.single.lastEditedAt,
        DateTime.utc(2026, 10, 12, 10),
      );

      clock.current = DateTime.utc(2026, 10, 12, 11);
      await blocks.applyChanges(page, [
        Update(b, BlockType.text, const BlockContent('Belém cedo')),
      ]);
      await recorder.settle();
      expect(
        recorder.emissions.last.single.lastEditedAt,
        DateTime.utc(2026, 10, 12, 11),
      );
      await recorder.cancel();
    });
  });
}
