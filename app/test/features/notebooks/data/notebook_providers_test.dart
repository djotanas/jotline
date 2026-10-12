import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  ProviderContainer containerFor(AppDatabase database) {
    return ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026, 10, 11))),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );
  }

  Future<void> settle(ProviderContainer container) async {
    await container.read(activeNotebooksProvider.future);
    await container.read(archivedNotebooksProvider.future);
  }

  test('REPO-19: overriding only the database, clock and id generator builds '
      'the repository and both streams', () async {
    final container = containerFor(db)
      ..listen(activeNotebooksProvider, (_, _) {})
      ..listen(archivedNotebooksProvider, (_, _) {});

    await settle(container);

    expect(
      container.read(notebookRepositoryProvider),
      isA<NotebookRepository>(),
    );
    expect(container.read(activeNotebooksProvider).value, isEmpty);
    expect(container.read(archivedNotebooksProvider).value, isEmpty);
  });

  test('REPO-06: a notebook created through the repository provider shows in '
      'the active provider', () async {
    final container = containerFor(db)
      ..listen(activeNotebooksProvider, (_, _) {});
    await container.read(activeNotebooksProvider.future);

    final id = await container
        .read(notebookRepositoryProvider)
        .create(
          title: 'Work',
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
    await pumpEventQueue();

    final notebooks = container.read(activeNotebooksProvider).requireValue;
    expect(notebooks.map((n) => n.id), [id]);
    expect(notebooks.single.title, 'Work');
  });

  test('REPO-07: an archived notebook moves from the active to the archived '
      'provider', () async {
    final container = containerFor(db)
      ..listen(activeNotebooksProvider, (_, _) {})
      ..listen(archivedNotebooksProvider, (_, _) {});
    final repository = container.read(notebookRepositoryProvider);
    final id = await repository.create(
      title: 'Work',
      cover: CoverPattern.lisa,
      color: NotebookColor.musgo,
    );
    await repository.archive(id);
    await pumpEventQueue();

    expect(container.read(activeNotebooksProvider).requireValue, isEmpty);
    expect(
      container.read(archivedNotebooksProvider).requireValue.map((n) => n.id),
      [id],
    );
  });

  test('REPO-19: a failing query surfaces as AsyncError with no retry '
      'timer', () async {
    await db.customStatement('DROP TABLE notebook_members');
    final container = containerFor(db)
      ..listen(activeNotebooksProvider, (_, _) {});

    await expectLater(
      container.read(activeNotebooksProvider.future),
      throwsA(isA<Exception>()),
    );

    expect(container.read(activeNotebooksProvider), isA<AsyncError<Object?>>());
  });
}
