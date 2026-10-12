import 'package:drift/drift.dart';
import 'package:jotline/core/database/tables/pages.dart';

@TableIndex(name: 'blocks_page_position', columns: {#pageId, #position})
class Blocks extends Table {
  late final Column<String> id = text()();
  late final Column<String> pageId = text().references(Pages, #id)();
  late final Column<String> type = text()();
  late final Column<String> contentJson = text()();
  late final Column<String> position = text()();
  late final Column<int> version = integer().withDefault(const Constant(0))();
  late final Column<DateTime> updatedAt = dateTime()();
  late final Column<String> updatedBy = text()();
  late final Column<DateTime> deletedAt = dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
