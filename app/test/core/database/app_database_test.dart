import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = createTestDatabase());
  tearDown(() => database.close());

  test('TEST-01: schemaVersion is 1 and the database has no tables', () {
    expect(database.schemaVersion, 1);
    expect(database.allTables, isEmpty);
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
