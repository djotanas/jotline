import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_hit.dart';
import 'package:jotline/features/search/data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(
    ref.watch(databaseProvider),
    ref.watch(localUserRepositoryProvider),
  ),
);

final StreamProviderFamily<List<SearchHit>, (MatchQuery, SearchScope)>
searchHitsProvider = StreamProvider.autoDispose
    .family<List<SearchHit>, (MatchQuery, SearchScope)>((ref, key) {
      final (query, scope) = key;
      if (query.isEmpty) return Stream.value(const []);
      return ref.watch(searchRepositoryProvider).watchHits(query, scope);
    }, retry: (_, _) => null);

final FutureProviderFamily<SearchSnippet, (String, MatchQuery, SearchScope)>
searchSnippetProvider = FutureProvider.autoDispose
    .family<SearchSnippet, (String, MatchQuery, SearchScope)>((ref, key) {
      final (pageId, query, scope) = key;
      return ref.watch(searchRepositoryProvider).snippet(pageId, query, scope);
    }, retry: (_, _) => null);
