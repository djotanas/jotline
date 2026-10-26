import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_repository.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LocalUserRepository localUser;
  late NotebookRepository notebooks;
  late PageRepository pages;
  late BlockRepository blocks;
  late String notebookId;
  late String pageId;

  setUp(() async {
    db = createTestDatabase();
    final clock = FakeClock(DateTime.utc(2026, 10, 11, 8));
    final ids = SequentialIdGenerator();
    localUser = LocalUserRepository(db, ids);
    notebooks = NotebookRepository(db, clock, ids, localUser);
    pages = PageRepository(db, clock, ids, localUser);
    blocks = BlockRepository(db, clock, ids, localUser);
    notebookId = await notebooks.create(
      title: 'Viagens',
      cover: CoverPattern.lisa,
      color: NotebookColor.azulTinta,
    );
    for (var i = 0; i < 3; i++) {
      pageId = await pages.create(notebookId, title: 'Belém $i');
      await blocks.applyChanges(pageId, [
        const Insert(
          'k',
          BlockType.text,
          BlockContent('belém do pará'),
          AtEnd(),
        ),
      ]);
    }
  });
  tearDown(() => db.close());

  Future<List<String>> plan(String sql, List<Object> values) async {
    final rows = await db
        .customSelect(
          'EXPLAIN QUERY PLAN $sql',
          variables: [for (final value in values) Variable<Object>(value)],
        )
        .get();
    return [for (final row in rows) row.read<String>('detail')];
  }

  void expectNoFullScan(List<String> details) {
    final scans = details.where((detail) {
      final match = RegExp(r'^SCAN (\w+)').firstMatch(detail);
      if (match == null) return false;
      final table = match.group(1);
      return const {'pages', 'blocks', 'p', 'b'}.contains(table) &&
          !detail.contains('USING') &&
          !detail.contains('VIRTUAL TABLE');
    });
    expect(scans, isEmpty, reason: details.join('\n'));
  }

  test('LOAD-07: the notebook summaries do not scan pages or blocks', () async {
    final userId = await localUser.id();
    final context = notebooks.summariesContext(userId);
    expectNoFullScan(
      await plan(context.sql, context.boundVariables.cast<Object>()),
    );
  });

  test('LOAD-07: the page summaries do not scan pages or blocks', () async {
    final details = await plan(
      PageRepository.summariesSql('p.notebook_id = ?'),
      [notebookId],
    );
    expectNoFullScan(details);
  });

  test('LOAD-07: the page block load does not scan pages or blocks', () async {
    final context = BlockRepository.byPageContext(db, pageId);
    expectNoFullScan(
      await plan(context.sql, context.boundVariables.cast<Object>()),
    );
  });

  test('LOAD-07: the search hits do not scan pages or blocks', () async {
    final userId = await localUser.id();
    final expression = MatchQuery.parse('belém').expression(SearchScope.all);
    final details = await plan(SearchRepository.hitsSql, [userId, expression]);
    expectNoFullScan(details);
  });

  test('LOAD-07: the search snippet does not scan pages or blocks', () async {
    final expression = MatchQuery.parse('belém').expression(SearchScope.all);
    final details = await plan(SearchRepository.snippetSql, [
      '[',
      ']',
      '[',
      ']',
      expression,
      pageId,
    ]);
    expectNoFullScan(details);
  });
}
