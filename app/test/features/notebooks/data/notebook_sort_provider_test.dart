import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/preferences/preferences_store.dart';
import 'package:jotline/core/preferences/unavailable_preferences_store.dart';
import 'package:jotline/features/notebooks/data/notebook_sort_provider.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';

class _RecordingStore implements PreferencesStore {
  new([this.notebookSort]);

  @override
  String? notebookSort;

  @override
  String? lastOpenedNotebookId;

  @override
  Future<void> setLastOpenedNotebookId(String? id) async {
    lastOpenedNotebookId = id;
  }

  @override
  Future<void> setNotebookSort(String name) async {
    notebookSort = name;
  }
}

void main() {
  ProviderContainer containerFor(PreferencesStore store) =>
      ProviderContainer.test(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );

  test('SORT-07: nothing stored starts on lastEdited', () {
    final container = containerFor(_RecordingStore());

    expect(container.read(notebookSortProvider), NotebookSort.lastEdited);
  });

  test('SORT-07: an unknown stored value falls back to lastEdited', () {
    final container = containerFor(_RecordingStore('alphabetical'));

    expect(container.read(notebookSortProvider), NotebookSort.lastEdited);
  });

  test('SORT-06: the stored value is read on build', () {
    final container = containerFor(_RecordingStore('createdAt'));

    expect(container.read(notebookSortProvider), NotebookSort.createdAt);
  });

  test('SORT-02: select updates the state and writes the name', () async {
    final store = _RecordingStore();
    final container = containerFor(store);
    expect(container.read(notebookSortProvider), NotebookSort.lastEdited);

    await container
        .read(notebookSortProvider.notifier)
        .select(NotebookSort.name);

    expect(container.read(notebookSortProvider), NotebookSort.name);
    expect(store.notebookSort, 'name');
  });

  test('SORT-02: select notifies listeners with the new sort', () async {
    final container = containerFor(_RecordingStore());
    final seen = <NotebookSort>[];
    container.listen(notebookSortProvider, (_, next) => seen.add(next));

    await container
        .read(notebookSortProvider.notifier)
        .select(NotebookSort.createdAt);

    expect(seen, [NotebookSort.createdAt]);
  });

  test('EDGE-06: with an unavailable store the state still changes', () async {
    final container = containerFor(UnavailablePreferencesStore());
    expect(container.read(notebookSortProvider), NotebookSort.lastEdited);

    await container
        .read(notebookSortProvider.notifier)
        .select(NotebookSort.name);

    expect(container.read(notebookSortProvider), NotebookSort.name);
  });
}
