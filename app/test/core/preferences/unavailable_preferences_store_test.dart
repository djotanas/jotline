import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';

void main() {
  test('EDGE-06: the unavailable store reads null and ignores sort '
      'writes', () async {
    final store = UnavailablePreferencesStore();

    await store.setNotebookSort('name');

    expect(store.notebookSort, isNull);
  });
}
