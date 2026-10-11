abstract interface class PreferencesStore {
  String? get lastOpenedNotebookId;

  Future<void> setLastOpenedNotebookId(String? id);
}
