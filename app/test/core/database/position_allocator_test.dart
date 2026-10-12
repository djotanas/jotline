import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/position_allocator.dart';
import 'package:jotline/core/ordering/placement.dart';

import '../../helpers/test_database.dart';

const _at = '2026-10-11T12:00:00.000Z';

void main() {
  late AppDatabase database;
  late PositionAllocator allocator;

  setUp(() {
    database = createTestDatabase();
    allocator = PositionAllocator(database);
  });
  tearDown(() => database.close());

  Future<void> seedParents() async {
    for (final notebook in ['n1', 'n2', 'n3']) {
      await database.customStatement(
        'INSERT INTO notebooks (id, title, cover, color, created_by, '
        "created_at) VALUES (?, 't', 'lisa', 'azulTinta', 'u1', ?)",
        [notebook, _at],
      );
    }
    for (final (page, notebook) in [('p1', 'n3'), ('p2', 'n3')]) {
      await database.customStatement(
        'INSERT INTO pages (id, notebook_id, title, position, updated_at, '
        "updated_by) VALUES (?, ?, 't', 'a0', ?, 'u1')",
        [page, notebook, _at],
      );
    }
  }

  Future<void> insertSibling(
    OrderedTable table, {
    required String id,
    required String parent,
    required String position,
    bool deleted = false,
  }) {
    final deletedAt = deleted ? _at : null;
    return switch (table) {
      OrderedTable.pages => database.customStatement(
        'INSERT INTO pages (id, notebook_id, title, position, updated_at, '
        "updated_by, deleted_at) VALUES (?, ?, 't', ?, ?, 'u1', ?)",
        [id, parent, position, _at, deletedAt],
      ),
      OrderedTable.blocks => database.customStatement(
        'INSERT INTO blocks (id, page_id, type, content_json, position, '
        "updated_at, updated_by, deleted_at) VALUES (?, ?, 'text', '{}', "
        "?, ?, 'u1', ?)",
        [id, parent, position, _at, deletedAt],
      ),
    };
  }

  for (final table in OrderedTable.values) {
    final parent = table == OrderedTable.pages ? 'n1' : 'p1';
    final otherParent = table == OrderedTable.pages ? 'n2' : 'p2';

    group('${table.name}:', () {
      setUp(seedParents);

      Future<void> seed(
        List<(String, String)> siblings, {
        String? deletedId,
      }) async {
        for (final (id, position) in siblings) {
          await insertSibling(
            table,
            id: id,
            parent: parent,
            position: position,
            deleted: id == deletedId,
          );
        }
      }

      Future<String> keyFor(
        Placement at, {
        String? movingId,
        String? parentId,
      }) {
        return allocator.keyFor(
          table,
          parentId: parentId ?? parent,
          at: at,
          movingId: movingId,
        );
      }

      test(
        'POS-02: an empty parent gets a0 at the end and at the start',
        () async {
          expect(await keyFor(const AtEnd()), 'a0');
          expect(await keyFor(const AtStart()), 'a0');
        },
      );

      test('POS-01: AtEnd is greater than every sibling', () async {
        await seed([('x1', 'a0'), ('x2', 'a1')]);

        final key = await keyFor(const AtEnd());

        expect(key.compareTo('a1'), greaterThan(0));
      });

      test('POS-01: AtEnd is greater than a deleted sibling holding the '
          'maximum', () async {
        await seed([('x1', 'a0'), ('x2', 'a5')], deletedId: 'x2');

        final key = await keyFor(const AtEnd());

        expect(key.compareTo('a5'), greaterThan(0));
      });

      test('POS-01: AtStart is less than every sibling', () async {
        await seed([('x1', 'a0'), ('x2', 'a1')]);

        final key = await keyFor(const AtStart());

        expect(key.compareTo('a0'), lessThan(0));
      });

      test('POS-01: AtStart is less than a deleted sibling holding the '
          'minimum', () async {
        await seed([('x1', 'a0'), ('x2', 'a1')], deletedId: 'x1');

        final key = await keyFor(const AtStart());

        expect(key.compareTo('a0'), lessThan(0));
      });

      test('POS-01: After(x) is strictly between x and the next '
          'sibling', () async {
        await seed([('x1', 'a0'), ('x2', 'a1'), ('x3', 'a2')]);

        final key = await keyFor(const After('x1'));

        expect(key.compareTo('a0'), greaterThan(0));
        expect(key.compareTo('a1'), lessThan(0));
      });

      test('POS-01: After(x) counts a deleted next sibling', () async {
        await seed([('x1', 'a0'), ('x2', 'a1')], deletedId: 'x2');

        final key = await keyFor(const After('x1'));

        expect(key.compareTo('a0'), greaterThan(0));
        expect(key.compareTo('a1'), lessThan(0));
      });

      test('POS-01: After the last sibling is greater than it', () async {
        await seed([('x1', 'a0'), ('x2', 'a1')]);

        final key = await keyFor(const After('x2'));

        expect(key.compareTo('a1'), greaterThan(0));
      });

      test('POS-01: movingId is ignored at the end', () async {
        await seed([('x1', 'a0'), ('x2', 'a1'), ('x3', 'a2')]);

        expect(await keyFor(const AtEnd(), movingId: 'x3'), 'a2');
      });

      test('POS-01: movingId is ignored at the start', () async {
        await seed([('x1', 'a0'), ('x2', 'a1')]);

        expect(await keyFor(const AtStart(), movingId: 'x1'), 'a0');
      });

      test(
        'POS-01: movingId is ignored when finding the next sibling',
        () async {
          await seed([('x1', 'a0'), ('x2', 'a1'), ('x3', 'a2')]);

          final key = await keyFor(const After('x1'), movingId: 'x2');

          expect(key.compareTo('a0'), greaterThan(0));
          expect(key.compareTo('a2'), lessThan(0));
          expect(key, 'a1');
        },
      );

      test('POS-01: only siblings of the same parent are compared', () async {
        await seed([('x1', 'a0')]);
        await insertSibling(
          table,
          id: 'y1',
          parent: otherParent,
          position: 'a9',
        );

        expect(await keyFor(const AtEnd()), 'a1');
      });

      test(
        'POS-01: an anchor under another parent throws ArgumentError',
        () async {
          await seed([('x1', 'a0')]);
          await insertSibling(
            table,
            id: 'y1',
            parent: otherParent,
            position: 'a0',
          );

          await expectLater(keyFor(const After('y1')), throwsArgumentError);
        },
      );

      test('POS-01: a missing anchor throws ArgumentError', () async {
        await expectLater(keyFor(const After('missing')), throwsArgumentError);
      });
    });
  }
}
