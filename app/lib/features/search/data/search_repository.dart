import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/last_edited_sql.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_excerpt.dart';
import 'package:jotline/features/search/data/search_hit.dart';

const _markStart = '';
const _markEnd = '';

/// Reactive full-text search over the local database (RF-05).
class SearchRepository {
  const new(this._database, this._localUser);

  final AppDatabase _database;
  final LocalUserRepository _localUser;

  @visibleForTesting
  static const hitsSql =
      'SELECT p.id AS page_id, p.title AS title, n.title AS notebook_title, '
      'n.color AS notebook_color, $lastEditedSql AS last_edited_at '
      'FROM page_search '
      'INNER JOIN pages p ON p.rowid = page_search.rowid '
      'INNER JOIN notebooks n ON n.id = p.notebook_id '
      'INNER JOIN notebook_members m '
      'ON m.notebook_id = n.id AND m.user_id = ? '
      'WHERE page_search MATCH ? '
      'AND p.deleted_at IS NULL AND n.deleted_at IS NULL '
      'ORDER BY last_edited_at DESC, p.id';

  @visibleForTesting
  static const snippetSql =
      'SELECT highlight(page_search, 0, ?, ?) AS title, '
      'highlight(page_search, 1, ?, ?) AS body '
      'FROM page_search '
      'WHERE page_search MATCH ? '
      'AND page_search.rowid = (SELECT rowid FROM pages WHERE id = ?)';

  /// The pages of the local user's notebooks, archived ones included, that
  /// match [query] within [scope], most recently edited first, then by `id`.
  Stream<List<SearchHit>> watchHits(
    MatchQuery query,
    SearchScope scope,
  ) async* {
    if (query.isEmpty) {
      yield const [];
      return;
    }
    final userId = await _localUser.id();
    yield* _database
        .customSelect(
          hitsSql,
          variables: [
            Variable<String>(userId),
            Variable<String>(query.expression(scope)),
          ],
          readsFrom: {
            _database.pages,
            _database.blocks,
            _database.notebooks,
            _database.notebookMembers,
          },
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              SearchHit(
                pageId: row.read<String>('page_id'),
                title: row.read<String>('title'),
                notebookTitle: row.read<String>('notebook_title'),
                notebookColor: NotebookColor.values.byName(
                  row.read<String>('notebook_color'),
                ),
                lastEditedAt: row.read<DateTime>('last_edited_at'),
              ),
          ],
        );
  }

  /// The highlighted title and excerpt of one page for [query] in [scope].
  Future<SearchSnippet> snippet(
    String pageId,
    MatchQuery query,
    SearchScope scope,
  ) async {
    final row = await _database
        .customSelect(
          snippetSql,
          variables: [
            const Variable<String>(_markStart),
            const Variable<String>(_markEnd),
            const Variable<String>(_markStart),
            const Variable<String>(_markEnd),
            Variable<String>(query.expression(scope)),
            Variable<String>(pageId),
          ],
          readsFrom: {_database.pageSearch},
        )
        .getSingleOrNull();
    if (row == null) return const SearchSnippet(title: [], excerpt: null);
    return SearchSnippet(
      title: HighlightSpan.parse(row.read<String>('title')),
      excerpt: SearchExcerpt.from(row.read<String>('body')),
    );
  }
}
