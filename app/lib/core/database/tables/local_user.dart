import 'package:drift/drift.dart';

class LocalUser extends Table {
  late final Column<int> slot = integer().check(slot.equals(1))();
  late final Column<String> id = text()();

  @override
  Set<Column> get primaryKey => {slot};
}
