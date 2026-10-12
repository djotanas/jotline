import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';

/// Holds the notebook sort and keeps it on the device.
class NotebookSortNotifier extends Notifier<NotebookSort> {
  @override
  NotebookSort build() {
    final stored = ref.read(preferencesStoreProvider).notebookSort;
    return NotebookSort.values.asNameMap()[stored] ?? NotebookSort.lastEdited;
  }

  /// Sets the state first so lists reorder even when the store is
  /// unavailable.
  Future<void> select(NotebookSort sort) async {
    state = sort;
    await ref.read(preferencesStoreProvider).setNotebookSort(sort.name);
  }
}

final NotifierProvider<NotebookSortNotifier, NotebookSort>
notebookSortProvider = NotifierProvider<NotebookSortNotifier, NotebookSort>(
  NotebookSortNotifier.new,
);
