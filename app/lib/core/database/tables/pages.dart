import 'package:drift/drift.dart';
import 'package:jotline/core/database/tables/notebooks.dart';

@DataClassName('NotebookPage')
@TableIndex(name: 'pages_notebook_position', columns: {#notebookId, #position})
class Pages extends Table {
  late final Column<String> id = text()();
  late final Column<String> notebookId = text().references(Notebooks, #id)();
  late final Column<String> title = text()();
  late final Column<String> position = text()();
  late final Column<DateTime> updatedAt = dateTime()();
  late final Column<String> updatedBy = text()();
  late final Column<DateTime> deletedAt = dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
