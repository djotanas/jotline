import 'package:jotline/core/preferences/preferences_store.dart';

class UnavailablePreferencesStore implements PreferencesStore {
  @override
  String? get lastOpenedNotebookId => null;

  @override
  Future<void> setLastOpenedNotebookId(String? id) async {}

  @override
  String? get notebookSort => null;

  @override
  Future<void> setNotebookSort(String name) async {}
}
