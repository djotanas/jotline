import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:jotline/features/pages/data/page_repository.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026, 10, 11))),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
      ],
    );
  });
  tearDown(() => db.close());

  Future<String> createNotebook() => container
      .read(notebookRepositoryProvider)
      .create(
        title: 'Work',
        cover: CoverPattern.lisa,
        color: NotebookColor.musgo,
      );

  test('REPO-19: overriding only the database, clock and id generator builds '
      'the repository and the stream', () async {
    final notebookId = await createNotebook();
    container.listen(pagesProvider(notebookId), (_, _) {});

    await container.read(pagesProvider(notebookId).future);

    expect(container.read(pageRepositoryProvider), isA<PageRepository>());
    expect(container.read(pagesProvider(notebookId)).value, isEmpty);
  });

  test('REPO-11: pagesProvider emits the pages of its notebook and not '
      'another', () async {
    final first = await createNotebook();
    final second = await createNotebook();
    container
      ..listen(pagesProvider(first), (_, _) {})
      ..listen(pagesProvider(second), (_, _) {});
    final repository = container.read(pageRepositoryProvider);
    final pageId = await repository.create(first, title: 'A');
    await repository.create(second, title: 'B');
    await pumpEventQueue();

    expect(container.read(pagesProvider(first)).requireValue.map((p) => p.id), [
      pageId,
    ]);
    expect(
      container.read(pagesProvider(second)).requireValue.map((p) => p.title),
      ['B'],
    );
  });

  test('REPO-19: a failing query surfaces as AsyncError with no retry '
      'timer', () async {
    final notebookId = await createNotebook();
    await db.customStatement('DROP TABLE pages');
    container.listen(pagesProvider(notebookId), (_, _) {});

    await expectLater(
      container.read(pagesProvider(notebookId).future),
      throwsA(isA<Exception>()),
    );

    expect(
      container.read(pagesProvider(notebookId)),
      isA<AsyncError<Object?>>(),
    );
  });
}
