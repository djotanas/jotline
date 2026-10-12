import 'package:hive_ce/hive_ce.dart';
import 'package:jotline/core/preferences/preferences_store.dart';

const _lastOpenedNotebookIdKey = 'lastOpenedNotebookId';
const _notebookSortKey = 'notebookSort';

class HivePreferencesStore implements PreferencesStore {
  new(this._box);

  final Box<String> _box;

  @override
  String? get lastOpenedNotebookId => _box.get(_lastOpenedNotebookIdKey);

  @override
  Future<void> setLastOpenedNotebookId(String? id) {
    if (id == null) {
      return _box.delete(_lastOpenedNotebookIdKey);
    }
    return _box.put(_lastOpenedNotebookIdKey, id);
  }

  @override
  String? get notebookSort => _box.get(_notebookSortKey);

  @override
  Future<void> setNotebookSort(String name) => _box.put(_notebookSortKey, name);
}
