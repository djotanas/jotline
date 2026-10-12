abstract interface class PreferencesStore {
  String? get lastOpenedNotebookId;

  Future<void> setLastOpenedNotebookId(String? id);

  String? get notebookSort;

  Future<void> setNotebookSort(String name);
}
