import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/tables/member_role.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

import '../../helpers/lib_scan.dart';
import '../../helpers/test_database.dart';

const _at = '2026-10-11T12:00:00.123Z';

Matcher _failsWith(String fragment) =>
    throwsA(predicate((error) => error.toString().contains(fragment)));

void main() {
  late AppDatabase database;

  setUp(() => database = createTestDatabase());
  tearDown(() => database.close());

  Future<void> insertNotebook(String id, {String createdBy = 'u1'}) {
    return database.customStatement(
      'INSERT INTO notebooks (id, title, cover, color, created_by, created_at) '
      "VALUES (?, 't', 'lisa', 'azulTinta', ?, ?)",
      [id, createdBy, _at],
    );
  }

  Future<void> insertPage(String id, String notebookId) {
    return database.customStatement(
      'INSERT INTO pages (id, notebook_id, title, position, updated_at, '
      "updated_by) VALUES (?, ?, 't', 'a0', ?, 'u1')",
      [id, notebookId, _at],
    );
  }

  Future<void> insertMember(
    String id,
    String notebookId, {
    String userId = 'u1',
    String role = 'owner',
  }) {
    return database.customStatement(
      'INSERT INTO notebook_members (id, notebook_id, user_id, role, '
      'added_by, created_at) VALUES (?, ?, ?, ?, ?, ?)',
      [id, notebookId, userId, role, 'u1', _at],
    );
  }

  Future<Map<String, ({String type, bool notNull, bool primaryKey})>> columns(
    String table,
  ) async {
    final rows = await database
        .customSelect("PRAGMA table_info('$table')")
        .get();
    return {
      for (final row in rows)
        row.read<String>('name'): (
          type: row.read<String>('type'),
          notNull: row.read<int>('notnull') == 1,
          primaryKey: row.read<int>('pk') > 0,
        ),
    };
  }

  test('DB-01: schemaVersion is 4', () {
    expect(database.schemaVersion, 4);
  });

  test('DB-06: foreign keys are enforced when the database opens', () async {
    final result = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();

    expect(result.read<int>('foreign_keys'), 1);
  });

  test('SCHEMA-01: notebooks has the specified columns, types and '
      'nullability', () async {
    final table = await columns('notebooks');

    expect(table.keys, [
      'id',
      'title',
      'cover',
      'color',
      'created_by',
      'created_at',
      'deleted_at',
    ]);
    expect(table['id']!.primaryKey, isTrue);
    for (final name in table.keys) {
      expect(table[name]!.type, 'TEXT', reason: name);
      expect(table[name]!.notNull, name != 'deleted_at', reason: name);
    }
  });

  test('SCHEMA-02: notebook_members has the specified columns and a unique '
      'key', () async {
    final table = await columns('notebook_members');

    expect(table.keys, [
      'id',
      'notebook_id',
      'user_id',
      'role',
      'added_by',
      'created_at',
      'archived_at',
    ]);
    expect(table['id']!.primaryKey, isTrue);
    for (final name in table.keys) {
      expect(table[name]!.type, 'TEXT', reason: name);
      expect(table[name]!.notNull, name != 'archived_at', reason: name);
    }
  });

  test('SCHEMA-03: pages has the specified columns, types and '
      'nullability', () async {
    final table = await columns('pages');

    expect(table.keys, [
      'id',
      'notebook_id',
      'title',
      'position',
      'updated_at',
      'updated_by',
      'deleted_at',
    ]);
    expect(table['id']!.primaryKey, isTrue);
    for (final name in table.keys) {
      expect(table[name]!.type, 'TEXT', reason: name);
      expect(table[name]!.notNull, name != 'deleted_at', reason: name);
    }
  });

  test('SCHEMA-04: blocks has the specified columns and version defaults to '
      '0', () async {
    final table = await columns('blocks');

    expect(table.keys, [
      'id',
      'page_id',
      'type',
      'content_json',
      'position',
      'version',
      'updated_at',
      'updated_by',
      'deleted_at',
    ]);
    expect(table['id']!.primaryKey, isTrue);
    expect(table['version']!.type, 'INTEGER');
    for (final name in table.keys) {
      if (name != 'version') {
        expect(table[name]!.type, 'TEXT', reason: name);
      }
      expect(table[name]!.notNull, name != 'deleted_at', reason: name);
    }

    await insertNotebook('n1');
    await insertPage('p1', 'n1');
    await database.customStatement(
      'INSERT INTO blocks (id, page_id, type, content_json, position, '
      "updated_at, updated_by) VALUES ('b1', 'p1', 'text', '{}', 'a0', ?, "
      "'u1')",
      [_at],
    );
    final version = await database
        .customSelect("SELECT version FROM blocks WHERE id = 'b1'")
        .getSingle();

    expect(version.read<int>('version'), 0);
  });

  test('SCHEMA-05: a member role outside owner, editor and viewer is '
      'rejected', () async {
    await insertNotebook('n1');

    await expectLater(
      insertMember('m1', 'n1', role: 'admin'),
      _failsWith('CHECK constraint failed'),
    );
    for (final role in MemberRole.values) {
      await insertMember(
        'm-${role.name}',
        'n1',
        userId: role.name,
        role: role.name,
      );
    }
  });

  final nullAuthors = <String, (String, List<Object?>)>{
    'notebooks.created_by': (
      'INSERT INTO notebooks (id, title, cover, color, created_by, '
          "created_at) VALUES ('n2', 't', 'lisa', 'azulTinta', NULL, ?)",
      [_at],
    ),
    'notebook_members.user_id': (
      'INSERT INTO notebook_members (id, notebook_id, user_id, role, '
          "added_by, created_at) VALUES ('m1', 'n1', NULL, 'owner', 'u1', ?)",
      [_at],
    ),
    'notebook_members.added_by': (
      'INSERT INTO notebook_members (id, notebook_id, user_id, role, '
          "added_by, created_at) VALUES ('m1', 'n1', 'u1', 'owner', NULL, ?)",
      [_at],
    ),
    'pages.updated_by': (
      'INSERT INTO pages (id, notebook_id, title, position, updated_at, '
          "updated_by) VALUES ('p2', 'n1', 't', 'a0', ?, NULL)",
      [_at],
    ),
    'blocks.updated_by': (
      'INSERT INTO blocks (id, page_id, type, content_json, position, '
          "updated_at, updated_by) VALUES ('b1', 'p1', 'text', '{}', 'a0', ?, "
          'NULL)',
      [_at],
    ),
  };
  for (final MapEntry(key: column, value: (sql, args)) in nullAuthors.entries) {
    test('SCHEMA-06: a null $column is rejected', () async {
      await insertNotebook('n1');
      await insertPage('p1', 'n1');

      await expectLater(
        database.customStatement(sql, args),
        _failsWith('NOT NULL constraint failed: $column'),
      );
    });
  }

  test('SCHEMA-07: a member whose notebook does not exist is rejected', () {
    return expectLater(
      insertMember('m1', 'missing'),
      _failsWith('FOREIGN KEY constraint failed'),
    );
  });

  test('SCHEMA-07: a page whose notebook does not exist is rejected', () {
    return expectLater(
      insertPage('p1', 'missing'),
      _failsWith('FOREIGN KEY constraint failed'),
    );
  });

  test('SCHEMA-07: a block whose page does not exist is rejected', () {
    return expectLater(
      database.customStatement(
        'INSERT INTO blocks (id, page_id, type, content_json, position, '
        "updated_at, updated_by) VALUES ('b1', 'missing', 'text', '{}', "
        "'a0', ?, 'u1')",
        [_at],
      ),
      _failsWith('FOREIGN KEY constraint failed'),
    );
  });

  test('SCHEMA-08: a second member with the same notebook and user is '
      'rejected', () async {
    await insertNotebook('n1');
    await insertMember('m1', 'n1');

    await expectLater(
      insertMember('m2', 'n1'),
      _failsWith('UNIQUE constraint failed'),
    );
    await insertMember('m3', 'n1', userId: 'u2', role: 'editor');
  });

  test('SCHEMA-09: cover and color are stored as the enum names', () async {
    await database
        .into(database.notebooks)
        .insert(
          NotebooksCompanion.insert(
            id: 'n1',
            title: 't',
            cover: CoverPattern.pautada,
            color: NotebookColor.azulTinta,
            createdBy: 'u1',
            createdAt: DateTime.utc(2026, 10, 11),
          ),
        );

    final raw = await database
        .customSelect('SELECT cover, color FROM notebooks')
        .getSingle();

    expect(raw.read<String>('cover'), 'pautada');
    expect(raw.read<String>('color'), 'azulTinta');
  });

  test('SCHEMA-10: pages and blocks have their position indexes', () async {
    Future<List<String>> indexColumns(String table, String index) async {
      final list = await database
          .customSelect("PRAGMA index_list('$table')")
          .get();
      expect(list.map((row) => row.read<String>('name')), contains(index));
      final info = await database
          .customSelect("PRAGMA index_info('$index')")
          .get();
      return info.map((row) => row.read<String>('name')).toList();
    }

    expect(await indexColumns('pages', 'pages_notebook_position'), [
      'notebook_id',
      'position',
    ]);
    expect(await indexColumns('blocks', 'blocks_page_position'), [
      'page_id',
      'position',
    ]);
  });

  test('USER-01: local_user rejects any slot other than 1', () async {
    await database.customStatement(
      "INSERT INTO local_user (slot, id) VALUES (1, 'u1')",
    );

    await expectLater(
      database.customStatement(
        "INSERT INTO local_user (slot, id) VALUES (2, 'u2')",
      ),
      _failsWith('CHECK constraint failed'),
    );
    await expectLater(
      database.customStatement(
        "INSERT INTO local_user (slot, id) VALUES (1, 'u2')",
      ),
      _failsWith('UNIQUE constraint failed'),
    );
  });

  test('TIME-02: a UTC date written to a table reads back as the same UTC '
      'instant', () async {
    final written = DateTime.utc(2026, 10, 11, 12, 0, 0, 123);
    await database
        .into(database.notebooks)
        .insert(
          NotebooksCompanion.insert(
            id: 'n1',
            title: 't',
            cover: CoverPattern.lisa,
            color: NotebookColor.grafite,
            createdBy: 'u1',
            createdAt: written,
          ),
        );

    final row = await database.select(database.notebooks).getSingle();
    final raw = await database
        .customSelect('SELECT created_at FROM notebooks')
        .getSingle();

    expect(row.createdAt.isUtc, isTrue);
    expect(row.createdAt, written);
    expect(raw.read<String>('created_at'), '2026-10-11T12:00:00.123Z');
  });

  test('DEL-03: no lib/ file that uses drift deletes rows', () {
    final deletion = RegExp(
      r'\bdelete(Where|All)?\s*\(|DELETE\s+FROM',
      caseSensitive: false,
    );
    final offenders = [
      for (final (file, source) in libSources())
        if (source.contains('package:drift') && deletion.hasMatch(source))
          file.path,
    ];

    expect(offenders, isEmpty);
  });

  test('TEST-03: the in-memory database runs a raw SELECT 1', () async {
    final result = await database.customSelect('SELECT 1 AS value').get();

    expect(result.single.data['value'], 1);
  });

  test(
    'TEST-04: two helper calls return distinct databases with no shared state',
    () async {
      final other = createTestDatabase();
      addTearDown(other.close);

      await database.customStatement(
        'CREATE TABLE marker (id INTEGER PRIMARY KEY)',
      );

      final tablesInOther = await other
          .customSelect("SELECT name FROM sqlite_master WHERE name = 'marker'")
          .get();

      expect(tablesInOther, isEmpty);
    },
  );
}
