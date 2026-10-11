import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/database_provider.dart';

import '../../helpers/test_database.dart';

void main() {
  test(
    'TEST-02: databaseProvider override returns the overridden instance',
    () {
      final database = createTestDatabase();
      addTearDown(database.close);

      final container = ProviderContainer.test(
        overrides: [databaseProvider.overrideWithValue(database)],
      );

      expect(container.read(databaseProvider), same(database));
    },
  );
}
