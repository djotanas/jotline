import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_providers.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/pages/data/page_providers.dart';

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

  Future<String> createPage() async {
    final notebookId = await container
        .read(notebookRepositoryProvider)
        .create(
          title: 'Work',
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
    final pageId = await container
        .read(pageRepositoryProvider)
        .create(notebookId);
    return pageId;
  }

  test('REPO-19: overriding only the database, clock and id generator builds '
      'the repository and the stream', () async {
    final pageId = await createPage();
    container.listen(blocksProvider(pageId), (_, _) {});

    await container.read(blocksProvider(pageId).future);

    expect(container.read(blockRepositoryProvider), isA<BlockRepository>());
    expect(container.read(blocksProvider(pageId)).value, isEmpty);
  });

  test('REPO-16: blocksProvider emits the blocks of its page and not '
      'another', () async {
    final first = await createPage();
    final second = await createPage();
    container
      ..listen(blocksProvider(first), (_, _) {})
      ..listen(blocksProvider(second), (_, _) {});
    final repository = container.read(blockRepositoryProvider);
    final blockId = await repository.create(
      first,
      type: 'paragraph',
      contentJson: 'A',
    );
    await repository.create(second, type: 'paragraph', contentJson: 'B');
    await pumpEventQueue();

    expect(
      container.read(blocksProvider(first)).requireValue.map((b) => b.id),
      [blockId],
    );
    expect(
      container
          .read(blocksProvider(second))
          .requireValue
          .map((b) => b.contentJson),
      ['B'],
    );
  });

  test('REPO-19: a failing query surfaces as AsyncError with no retry '
      'timer', () async {
    final pageId = await createPage();
    await db.customStatement('DROP TABLE blocks');
    container.listen(blocksProvider(pageId), (_, _) {});

    await expectLater(
      container.read(blocksProvider(pageId).future),
      throwsA(isA<Exception>()),
    );

    expect(container.read(blocksProvider(pageId)), isA<AsyncError<Object?>>());
  });
}
