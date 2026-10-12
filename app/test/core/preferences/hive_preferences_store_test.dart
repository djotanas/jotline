import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:jotline/core/preferences/hive_preferences_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jotline_prefs_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test(
    'PREF-03: a written key survives closing and reopening the box',
    () async {
      var box = await Hive.openBox<String>('preferences');
      final store = HivePreferencesStore(box);

      await store.setLastOpenedNotebookId('notebook-1');
      await box.close();

      box = await Hive.openBox<String>('preferences');
      final reopened = HivePreferencesStore(box);

      expect(reopened.lastOpenedNotebookId, 'notebook-1');
    },
  );

  test('PREF-04: reading a key that was never written returns null', () async {
    final box = await Hive.openBox<String>('preferences');
    final store = HivePreferencesStore(box);

    expect(store.lastOpenedNotebookId, isNull);
  });

  test('PREF-04: reading a key that was cleared returns null', () async {
    final box = await Hive.openBox<String>('preferences');
    final store = HivePreferencesStore(box);

    await store.setLastOpenedNotebookId('notebook-1');
    await store.setLastOpenedNotebookId(null);

    expect(store.lastOpenedNotebookId, isNull);
  });

  test('PREF-05: the box holds only the lastOpenedNotebookId key', () async {
    final box = await Hive.openBox<String>('preferences');
    final store = HivePreferencesStore(box);

    await store.setLastOpenedNotebookId('notebook-1');

    expect(box.keys, ['lastOpenedNotebookId']);
  });

  test('USER-06: after every write the box keys are within '
      '{lastOpenedNotebookId}', () async {
    final box = await Hive.openBox<String>('preferences');
    final store = HivePreferencesStore(box);
    const allowed = {'lastOpenedNotebookId'};

    await store.setLastOpenedNotebookId('notebook-1');
    expect(box.keys.toSet().difference(allowed), isEmpty);

    await store.setLastOpenedNotebookId('notebook-2');
    expect(box.keys.toSet().difference(allowed), isEmpty);

    await store.setLastOpenedNotebookId(null);
    expect(box.keys.toSet().difference(allowed), isEmpty);
  });
}
