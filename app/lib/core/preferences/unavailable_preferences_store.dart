import 'package:jotline/core/preferences/preferences_store.dart';

class UnavailablePreferencesStore implements PreferencesStore {
  @override
  String? get lastOpenedNotebookId => null;

  @override
  Future<void> setLastOpenedNotebookId(String? id) async {}
}
