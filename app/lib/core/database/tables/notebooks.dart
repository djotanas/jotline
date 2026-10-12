import 'package:drift/drift.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

class Notebooks extends Table {
  late final Column<String> id = text()();
  late final Column<String> title = text()();
  late final Column<String> cover = textEnum<CoverPattern>()();
  late final Column<String> color = textEnum<NotebookColor>()();
  late final Column<String> createdBy = text()();
  late final Column<DateTime> createdAt = dateTime()();
  late final Column<DateTime> deletedAt = dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
