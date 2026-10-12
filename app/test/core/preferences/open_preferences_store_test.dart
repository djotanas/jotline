import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:jotline/core/preferences/hive_preferences_store.dart';
import 'package:jotline/core/preferences/open_preferences_store.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('jotline_open_prefs');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('a successful opener returns a HivePreferencesStore', () async {
    final store = await openPreferencesStore(
      openBox: () => Hive.openBox<String>('preferences'),
    );

    expect(store, isA<HivePreferencesStore>());
  });

  test(
    'PREF-06: a throwing opener returns an UnavailablePreferencesStore',
    () async {
      final store = await openPreferencesStore(
        openBox: () => throw StateError('box is corrupt'),
      );

      expect(store, isA<UnavailablePreferencesStore>());
    },
  );

  test('PREF-06: the unavailable store reads null and accepts writes '
      'without throwing', () async {
    final store = await openPreferencesStore(
      openBox: () => throw StateError('box is corrupt'),
    );

    expect(store.lastOpenedNotebookId, isNull);
    await store.setLastOpenedNotebookId('notebook-1');
    expect(store.lastOpenedNotebookId, isNull);
  });

  test('PREF-06: the box file is not deleted after a failed open', () async {
    final boxFile = File('${tempDir.path}/preferences.hive');
    await boxFile.create();

    await openPreferencesStore(
      openBox: () => throw StateError('box is corrupt'),
    );

    expect(boxFile.existsSync(), isTrue);
  });
}
