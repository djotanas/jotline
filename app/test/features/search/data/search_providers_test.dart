import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_hit.dart';
import 'package:jotline/features/search/data/search_providers.dart';
import 'package:jotline/features/search/data/search_repository.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/test_database.dart';

class _CountingRepository implements SearchRepository {
  int hitsCalls = 0;
  int snippetCalls = 0;

  @override
  Stream<List<SearchHit>> watchHits(MatchQuery query, SearchScope scope) {
    hitsCalls++;
    return Stream.value(const []);
  }

  @override
  Future<SearchSnippet> snippet(
    String pageId,
    MatchQuery query,
    SearchScope scope,
  ) {
    snippetCalls++;
    return Future.value(const SearchSnippet(title: [], excerpt: null));
  }
}

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

  final belem = MatchQuery.parse('belém');

  test('SRCH-03: the same query and scope give the same provider', () {
    expect(
      searchHitsProvider((MatchQuery.parse('Belém'), SearchScope.all)),
      searchHitsProvider((MatchQuery.parse('Belém!'), SearchScope.all)),
    );
    expect(
      searchSnippetProvider(('p', MatchQuery.parse('Belém'), SearchScope.all)),
      searchSnippetProvider(('p', MatchQuery.parse('Belém!'), SearchScope.all)),
    );
  });

  test('SRCH-03: another scope or page gives another provider', () {
    expect(
      searchHitsProvider((belem, SearchScope.all)),
      isNot(searchHitsProvider((belem, SearchScope.titles))),
    );
    expect(
      searchSnippetProvider(('a', belem, SearchScope.all)),
      isNot(searchSnippetProvider(('b', belem, SearchScope.all))),
    );
  });

  test('SRCH-20: searchHitsProvider emits the hits and follows new '
      'writes', () async {
    final notebookId = await container
        .read(notebookRepositoryProvider)
        .create(
          title: 'Viagens',
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
    final provider = searchHitsProvider((belem, SearchScope.all));
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(provider).requireValue, isEmpty);

    await container
        .read(pageRepositoryProvider)
        .create(notebookId, title: 'Belém');
    await pumpEventQueue();

    expect(container.read(provider).requireValue.map((hit) => hit.title), [
      'Belém',
    ]);
  });

  test('EDGE-05: searchHitsProvider disposes after the last listener '
      'goes away', () async {
    final provider = searchHitsProvider((belem, SearchScope.all));
    final subscription = container.listen(provider, (_, _) {});
    await pumpEventQueue();
    expect(container.exists(provider), isTrue);

    subscription.close();
    await pumpEventQueue();

    expect(container.exists(provider), isFalse);
  });

  test('EDGE-05: searchSnippetProvider disposes after the last listener '
      'goes away', () async {
    final provider = searchSnippetProvider(('p', belem, SearchScope.all));
    final subscription = container.listen(provider, (_, _) {});
    await container.read(provider.future);
    expect(container.exists(provider), isTrue);

    subscription.close();
    await pumpEventQueue();

    expect(container.exists(provider), isFalse);
  });

  test('SRCH-03: a repository error surfaces as AsyncError with no retry '
      'timer', () async {
    await db.customStatement('DROP TABLE page_search');
    final provider = searchHitsProvider((belem, SearchScope.all));
    container.listen(provider, (_, _) {});

    await expectLater(
      container.read(provider.future),
      throwsA(isA<Exception>()),
    );

    expect(container.read(provider), isA<AsyncError<Object?>>());
  });

  test('SRCH-03: a snippet error surfaces as AsyncError', () async {
    await db.customStatement('DROP TABLE page_search');
    final provider = searchSnippetProvider(('p', belem, SearchScope.all));
    container.listen(provider, (_, _) {});

    await expectLater(
      container.read(provider.future),
      throwsA(isA<Exception>()),
    );

    expect(container.read(provider), isA<AsyncError<Object?>>());
  });

  test('EDGE-01: an empty query emits an empty list and runs no SQL', () async {
    final repository = _CountingRepository();
    final fakeContainer = ProviderContainer.test(
      overrides: [searchRepositoryProvider.overrideWithValue(repository)],
    );
    final provider = searchHitsProvider((
      MatchQuery.parse('  ?! '),
      SearchScope.all,
    ));
    fakeContainer.listen(provider, (_, _) {});

    final hits = await fakeContainer.read(provider.future);

    expect(hits, isEmpty);
    expect(repository.hitsCalls, 0);
  });

  test('SRCH-03: a non-empty query asks the repository once', () async {
    final repository = _CountingRepository();
    final fakeContainer = ProviderContainer.test(
      overrides: [searchRepositoryProvider.overrideWithValue(repository)],
    );
    final provider = searchHitsProvider((belem, SearchScope.all));
    fakeContainer.listen(provider, (_, _) {});

    await fakeContainer.read(provider.future);

    expect(repository.hitsCalls, 1);
  });
}
