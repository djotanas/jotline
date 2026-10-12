import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_sort_provider.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;

  setUp(() {
    db = createTestDatabase();
    clock = FakeClock(DateTime.utc(2026, 10, 11));
  });
  tearDown(() => db.close());

  ProviderContainer containerFor(AppDatabase database) {
    return ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        preferencesStoreProvider.overrideWithValue(
          UnavailablePreferencesStore(),
        ),
      ],
    );
  }

  Future<String> create(ProviderContainer container, String title) {
    return container
        .read(notebookRepositoryProvider)
        .create(
          title: title,
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
  }

  List<String> titles(ProviderContainer container, {bool archived = false}) => [
    for (final s in container.read(notebookSummariesProvider(archived)).value!)
      s.notebook.title,
  ];

  test('REPO-19: overriding only the database, clock, id generator and '
      'preferences builds the repository and both tabs', () async {
    final container = containerFor(db)
      ..listen(notebookSummariesProvider(false), (_, _) {})
      ..listen(notebookSummariesProvider(true), (_, _) {});

    await container.read(notebookSummariesProvider(false).future);
    await container.read(notebookSummariesProvider(true).future);

    expect(
      container.read(notebookRepositoryProvider),
      isA<NotebookRepository>(),
    );
    expect(container.read(notebookSummariesProvider(false)).value, isEmpty);
    expect(container.read(notebookSummariesProvider(true)).value, isEmpty);
  });

  test('NBLIST-07: a notebook created through the repository shows in the '
      'active tab and moves to the archived tab', () async {
    final container = containerFor(db)
      ..listen(notebookSummariesProvider(false), (_, _) {})
      ..listen(notebookSummariesProvider(true), (_, _) {});
    await container.read(notebookSummariesProvider(false).future);

    final id = await create(container, 'Work');
    await pumpEventQueue();
    expect(titles(container), ['Work']);

    await container.read(notebookRepositoryProvider).archive(id);
    await pumpEventQueue();

    expect(titles(container), isEmpty);
    expect(titles(container, archived: true), ['Work']);
  });

  test('SORT-02: the order follows the notifier and changes when it '
      'changes', () async {
    final container = containerFor(db)
      ..listen(notebookSummariesProvider(false), (_, _) {});
    await create(container, 'Zebra');
    clock.current = DateTime.utc(2026, 10, 12);
    await create(container, 'árvore');
    clock.current = DateTime.utc(2026, 10, 13);
    await create(container, 'Bloco');
    await container.read(notebookSummariesProvider(false).future);
    await pumpEventQueue();
    expect(titles(container), ['Bloco', 'árvore', 'Zebra']);

    await container
        .read(notebookSortProvider.notifier)
        .select(NotebookSort.name);
    await pumpEventQueue();
    expect(titles(container), ['árvore', 'Bloco', 'Zebra']);

    await container
        .read(notebookSortProvider.notifier)
        .select(NotebookSort.createdAt);
    await pumpEventQueue();
    expect(titles(container), ['Bloco', 'árvore', 'Zebra']);
  });

  test('SORT-03: lastEdited puts the notebook with the latest page edit '
      'first', () async {
    final container = containerFor(db)
      ..listen(notebookSummariesProvider(false), (_, _) {});
    await create(container, 'Old');
    clock.current = DateTime.utc(2026, 10, 12);
    await create(container, 'New');
    await container.read(notebookSummariesProvider(false).future);
    await pumpEventQueue();

    expect(titles(container), ['New', 'Old']);
  });

  test('NBLIST-07: notebookProvider emits the summary and then null after '
      'trashing', () async {
    final container = containerFor(db);
    final id = await create(container, 'Work');
    container.listen(notebookProvider(id), (_, _) {});
    await container.read(notebookProvider(id).future);
    expect(container.read(notebookProvider(id)).value?.notebook.title, 'Work');

    await container.read(notebookRepositoryProvider).moveToTrash(id);
    await pumpEventQueue();

    expect(container.read(notebookProvider(id)).value, isNull);
    expect(container.read(notebookProvider(id)), isA<AsyncData<Object?>>());
  });

  test('TRASH-02: trashedNotebooksProvider lists trashed notebooks', () async {
    final container = containerFor(db)
      ..listen(trashedNotebooksProvider, (_, _) {});
    final id = await create(container, 'Work');
    await container.read(trashedNotebooksProvider.future);
    expect(container.read(trashedNotebooksProvider).value, isEmpty);

    await container.read(notebookRepositoryProvider).moveToTrash(id);
    await pumpEventQueue();

    expect(
      container.read(trashedNotebooksProvider).value!.map((t) => t.notebook.id),
      [id],
    );
  });

  test('REPO-19: a failing query surfaces as AsyncError with no retry '
      'timer', () async {
    await db.customStatement('DROP TABLE notebook_members');
    final container = containerFor(db)
      ..listen(notebookSummariesProvider(false), (_, _) {})
      ..listen(notebookProvider('x'), (_, _) {})
      ..listen(trashedNotebooksProvider, (_, _) {});

    await expectLater(
      container.read(notebookSummariesProvider(false).future),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      container.read(notebookProvider('x').future),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      container.read(trashedNotebooksProvider.future),
      throwsA(isA<Exception>()),
    );

    expect(
      container.read(notebookSummariesProvider(false)),
      isA<AsyncError<Object?>>(),
    );
    expect(container.read(notebookProvider('x')), isA<AsyncError<Object?>>());
    expect(
      container.read(trashedNotebooksProvider),
      isA<AsyncError<Object?>>(),
    );
  });
}
