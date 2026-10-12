import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/stream_recorder.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late SequentialIdGenerator ids;
  late LocalUserRepository localUser;
  late NotebookRepository repository;

  setUp(() async {
    db = createTestDatabase();
    clock = FakeClock(DateTime.utc(2026, 10, 11, 8));
    ids = SequentialIdGenerator();
    localUser = LocalUserRepository(db, ids);
    repository = NotebookRepository(db, clock, ids, localUser);
  });
  tearDown(() => db.close());

  Future<String> create(String title) => repository.create(
    title: title,
    cover: CoverPattern.lisa,
    color: NotebookColor.azulTinta,
  );

  Future<List<Notebook>> notebooks() => db.select(db.notebooks).get();
  Future<List<NotebookMember>> members() => db.select(db.notebookMembers).get();

  Future<List<String>> activeTitles() async {
    final recorder = StreamRecorder(repository.watchActive());
    final emissions = await recorder.settle();
    await recorder.cancel();
    return [for (final n in emissions.last) n.title];
  }

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

  test('REPO-06: the active stream orders by created_at descending, then id '
      'descending', () async {
    final oldest = await create('Oldest');
    clock.current = DateTime.utc(2026, 10, 11, 9);
    final tieA = await create('TieA');
    final tieB = await create('TieB');
    clock.current = DateTime.utc(2026, 10, 11, 10);
    final newest = await create('Newest');

    final recorder = StreamRecorder(repository.watchActive());
    final emissions = await recorder.settle();
    await recorder.cancel();

    expect(tieB.compareTo(tieA), greaterThan(0));
    expect(emissions.last.map((n) => n.id), [newest, tieB, tieA, oldest]);
  });

  test('REPO-07: the archived stream holds only archived notebooks, ordered by '
      'archived_at descending, then id descending', () async {
    final a = await create('A');
    final b = await create('B');
    final c = await create('C');
    await create('Active');
    clock.current = DateTime.utc(2026, 10, 12);
    await repository.archive(a);
    clock.current = DateTime.utc(2026, 10, 13);
    await repository.archive(b);
    await repository.archive(c);

    final recorder = StreamRecorder(repository.watchArchived());
    final emissions = await recorder.settle();
    await recorder.cancel();

    expect(c.compareTo(b), greaterThan(0));
    expect(emissions.last.map((n) => n.id), [c, b, a]);
  });

  test('REPO-18: the active stream emits after create, rename, archive and '
      'delete', () async {
    final recorder = StreamRecorder(repository.watchActive());
    List<String> titles() => [for (final n in recorder.emissions.last) n.title];
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
    final archived = StreamRecorder(repository.watchArchived());
    expect((await archived.settle()).last, isEmpty);
    await archived.cancel();
  });

  test('DEL-04: a notebook archived and then trashed is in neither '
      'stream', () async {
    final id = await create('Work');
    await repository.archive(id);
    await repository.moveToTrash(id);

    final archived = StreamRecorder(repository.watchArchived());
    expect((await archived.settle()).last, isEmpty);
    await archived.cancel();
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
    final recorder = StreamRecorder(repository.watchActive());
    await recorder.settle();

    await db.close();
    await recorder.settle();

    expect(recorder.errors, isEmpty);
    expect(recorder.isDone, isTrue);
    db = createTestDatabase();
  });
}
