@Tags(['perf'])
@Timeout(Duration(minutes: 10))
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';

import '../../integration_test/perf/seed_library.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    db = createTestDatabase();
    await seedLibrary(db, random: Random(7));
  });
  tearDownAll(() => db.close());

  Future<int> count(String sql) async {
    final row = await db.customSelect(sql).getSingle();
    return row.read<int>('n');
  }

  test(
    'LOAD-01: seeds 21 notebooks, 12,000 pages and 240,000 blocks',
    () async {
      expect(await count('SELECT count(*) AS n FROM notebooks'), 21);
      expect(await count('SELECT count(*) AS n FROM pages'), 12000);
      expect(await count('SELECT count(*) AS n FROM blocks'), 240000);
    },
  );

  test('LOAD-01: one notebook has 10,000 pages and 20 have 100', () async {
    final rows = await db
        .customSelect(
          'SELECT count(*) AS n FROM pages GROUP BY notebook_id '
          'ORDER BY n DESC',
        )
        .get();
    final sizes = [for (final row in rows) row.read<int>('n')];
    expect(sizes.first, 10000);
    expect(sizes.skip(1), everyElement(100));
    expect(sizes, hasLength(21));
  });

  test('LOAD-01: every notebook has its owner member row', () async {
    expect(
      await count(
        "SELECT count(*) AS n FROM notebook_members WHERE role = 'owner'",
      ),
      21,
    );
    expect(
      await count(
        'SELECT count(*) AS n FROM notebooks nb WHERE NOT EXISTS '
        '(SELECT 1 FROM notebook_members m WHERE m.notebook_id = nb.id)',
      ),
      0,
    );
  });

  test(
    'LOAD-01: every page has 20 text blocks of about 200 characters',
    () async {
      expect(
        await count(
          'SELECT count(*) AS n FROM (SELECT page_id FROM blocks '
          'GROUP BY page_id HAVING count(*) = 20)',
        ),
        12000,
      );
      expect(
        await count("SELECT count(*) AS n FROM blocks WHERE type <> 'text'"),
        0,
      );
      expect(
        await count(
          'SELECT count(*) AS n FROM blocks '
          r"WHERE length(json_extract(content_json, '$.text')) "
          'NOT BETWEEN 180 AND 240',
        ),
        0,
      );
    },
  );

  test(
    'LOAD-01: no two pages of a notebook or blocks of a page share a position',
    () async {
      expect(
        await count(
          'SELECT count(*) AS n FROM (SELECT 1 FROM pages '
          'GROUP BY notebook_id, position HAVING count(*) > 1)',
        ),
        0,
      );
      expect(
        await count(
          'SELECT count(*) AS n FROM (SELECT 1 FROM blocks '
          'GROUP BY page_id, position HAVING count(*) > 1)',
        ),
        0,
      );
    },
  );

  test('LOAD-01: the triggers fill page_search with a row per page', () async {
    expect(await count('SELECT count(*) AS n FROM page_search'), 12000);
  });

  test('LOAD-06: the word belém is in every page', () async {
    expect(
      await count(
        'SELECT count(*) AS n FROM page_search '
        'WHERE page_search MATCH \'"belém"\'',
      ),
      12000,
    );
  });
}
