import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('DB-04: a version 1 database migrates to the exported version 3 '
      'schema', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 3);
  });

  test('DB-05: a database created from scratch matches the exported version '
      '3 schema', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 3);
    await db.validateDatabaseSchema();
  });

  test(
    'SRCH-19: a version 2 database with 2 pages and 3 blocks opens as '
    'version 3 and both pages are found by title and by block text',
    () async {
      final schema = await verifier.schemaAt(2);
      const at = '2026-10-11T12:00:00.000Z';
      schema.rawDatabase
        ..execute(
          'INSERT INTO notebooks (id, title, cover, color, created_by, '
          'created_at) VALUES (?, ?, ?, ?, ?, ?)',
          ['n1', 'Viagens', 'lisa', 'azulTinta', 'u1', at],
        )
        ..execute(
          'INSERT INTO pages (id, notebook_id, title, position, updated_at, '
          'updated_by) VALUES (?, ?, ?, ?, ?, ?), (?, ?, ?, ?, ?, ?)',
          [
            ...['p1', 'n1', 'Roteiro de Belém', 'a0', at, 'u1'],
            ...['p2', 'n1', 'Compras', 'a1', at, 'u1'],
          ],
        )
        ..execute(
          'INSERT INTO blocks (id, page_id, type, content_json, position, '
          'updated_at, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?), '
          '(?, ?, ?, ?, ?, ?, ?), (?, ?, ?, ?, ?, ?, ?)',
          [
            ...['b1', 'p1', 'text', '{"text":"Tacacá no almoço"}', 'a0', at],
            'u1',
            ...['b2', 'p2', 'text', '{"text":"Pão e leite"}', 'a0', at],
            'u1',
            ...['b3', 'p2', 'text', '{"text":"Manteiga"}', 'a1', at],
            'u1',
          ],
        );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 3);

      Future<List<String>> match(String expression) async {
        final rows = await db
            .customSelect(
              'SELECT p.id AS id FROM page_search '
              'JOIN pages p ON p.rowid = page_search.rowid '
              'WHERE page_search MATCH ? ORDER BY p.id',
              variables: [Variable<String>(expression)],
            )
            .get();
        return [for (final row in rows) row.read<String>('id')];
      }

      expect(await match('{title} : "bele"*'), ['p1']);
      expect(await match('{title} : "compras"*'), ['p2']);
      expect(await match('{body} : "tacaca"*'), ['p1']);
      expect(await match('{body} : "manteiga"*'), ['p2']);
    },
  );
}
