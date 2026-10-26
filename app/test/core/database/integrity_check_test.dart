import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/integrity_check.dart';
import 'package:jotline/core/database/integrity_log.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Directory directory;
  late File file;
  late IntegrityCheck check;
  late NotebookRepository notebooks;
  late PageRepository pages;
  late BlockRepository blocks;
  late String notebookId;
  late String pageId;
  late String blockId;

  setUp(() async {
    db = createTestDatabase();
    directory = Directory.systemTemp.createTempSync('integrity_check_test');
    file = File('${directory.path}/integrity.log');
    final clock = FakeClock(DateTime.utc(2026, 10, 17, 12));
    final ids = SequentialIdGenerator();
    final localUser = LocalUserRepository(db, ids);
    notebooks = NotebookRepository(db, clock, ids, localUser);
    pages = PageRepository(db, clock, ids, localUser);
    blocks = BlockRepository(db, clock, ids, localUser);
    check = IntegrityCheck(
      db,
      clock,
      IntegrityLog(() async => file),
      '1.0.0+1',
    );
    notebookId = await notebooks.create(
      title: 'Viagens',
      cover: CoverPattern.lisa,
      color: NotebookColor.azulTinta,
    );
    pageId = await pages.create(notebookId, title: 'Roteiro');
    final inserted = await blocks.applyChanges(pageId, [
      const Insert('k', BlockType.text, BlockContent('cedo'), AtEnd()),
    ]);
    blockId = inserted['k']!;
  });
  tearDown(() async {
    await db.close();
    directory.deleteSync(recursive: true);
  });

  Future<void> raw(String sql) async {
    await db.customStatement('PRAGMA foreign_keys = OFF');
    await db.customStatement(sql);
  }

  String logged() => file.readAsStringSync();

  test('INTEG-06: a clean database gives one pass line', () async {
    final report = await check.run();

    expect(report.passed, isTrue);
    expect(report.failures, isEmpty);
    expect(logged(), '2026-10-17T12:00:00Z 1.0.0+1 pass\n');
  });

  test('INTEG-02: a notebook without an owner row fails with its id', () async {
    await raw('DELETE FROM notebook_members');

    final report = await check.run();

    expect(report.failures.single.invariant, 'notebook_without_owner');
    expect(report.failures.single.ids, [notebookId]);
  });

  test(
    'INTEG-02: a notebook whose only member is not an owner fails',
    () async {
      await raw("UPDATE notebook_members SET role = 'editor'");

      final report = await check.run();

      expect(report.failures.single.invariant, 'notebook_without_owner');
      expect(report.failures.single.ids, [notebookId]);
    },
  );

  test('INTEG-03: a page of a missing notebook fails with its id', () async {
    await raw("UPDATE pages SET notebook_id = 'ghost'");

    final report = await check.run();

    expect(report.failures.single.invariant, 'orphan_page');
    expect(report.failures.single.ids, [pageId]);
  });

  test('INTEG-04: a block of a missing page fails with its id', () async {
    await raw("UPDATE blocks SET page_id = 'ghost'");

    final report = await check.run();

    expect(report.failures.single.invariant, 'orphan_block');
    expect(report.failures.single.ids, [blockId]);
  });

  test(
    'INTEG-05: two pages with the same position fail with both ids',
    () async {
      final other = await pages.create(notebookId, title: 'Mapa');
      await raw(
        'UPDATE pages SET position = '
        "(SELECT position FROM pages WHERE id = '$pageId') WHERE id = '$other'",
      );

      final report = await check.run();

      expect(report.failures.single.invariant, 'duplicate_position');
      expect(report.failures.single.ids, unorderedEquals([pageId, other]));
    },
  );

  test('INTEG-05: two blocks with one position fail with both ids', () async {
    final inserted = await blocks.applyChanges(pageId, [
      const Insert('j', BlockType.text, BlockContent('tarde'), AtEnd()),
    ]);
    final other = inserted['j']!;
    await raw(
      'UPDATE blocks SET position = '
      "(SELECT position FROM blocks WHERE id = '$blockId') WHERE id = '$other'",
    );

    final report = await check.run();

    expect(report.failures.single.invariant, 'duplicate_position');
    expect(report.failures.single.ids, unorderedEquals([blockId, other]));
  });

  test('INTEG-05: a deleted duplicate is not a failure', () async {
    final other = await pages.create(notebookId, title: 'Mapa');
    await raw(
      'UPDATE pages SET position = '
      "(SELECT position FROM pages WHERE id = '$pageId'), "
      "deleted_at = updated_at WHERE id = '$other'",
    );

    final report = await check.run();

    expect(report.passed, isTrue);
  });

  test('INTEG-06: two failures share one line', () async {
    await raw("UPDATE pages SET notebook_id = 'ghost'");
    await raw("UPDATE blocks SET page_id = 'ghost'");

    await check.run();

    expect(
      logged(),
      '2026-10-17T12:00:00Z 1.0.0+1 fail '
      'orphan_page=$pageId orphan_block=$blockId\n',
    );
  });

  test(
    'INTEG-07: a check that throws gives check_error and does not throw',
    () async {
      await db.close();

      final report = await check.run();

      expect(report.passed, isFalse);
      expect(report.failures.single.invariant, 'check_error');
      expect(logged(), contains(' fail check_error='));
    },
  );

  test('INTEG-08: the check changes no table', () async {
    Future<List<Object?>> snapshot() async {
      final rows = await db
          .customSelect(
            'SELECT '
            '(SELECT count(*) FROM notebooks) AS nb, '
            '(SELECT count(*) FROM notebook_members) AS nm, '
            '(SELECT count(*) FROM pages) AS pg, '
            '(SELECT count(*) FROM blocks) AS bl, '
            '(SELECT max(updated_at) FROM pages) AS pu, '
            '(SELECT max(updated_at) FROM blocks) AS bu',
          )
          .getSingle();
      return rows.data.values.toList();
    }

    await raw("UPDATE pages SET notebook_id = 'ghost'");
    final before = await snapshot();

    await check.run();

    expect(await snapshot(), before);
  });
}
