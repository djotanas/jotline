import 'package:drift/drift.dart';
import 'package:jotline/core/database/tables/member_role.dart';
import 'package:jotline/core/database/tables/notebooks.dart';

class NotebookMembers extends Table {
  late final Column<String> id = text()();
  late final Column<String> notebookId = text().references(Notebooks, #id)();
  late final Column<String> userId = text()();
  late final Column<String> role = textEnum<MemberRole>().check(
    const CustomExpression<bool>("role IN ('owner', 'editor', 'viewer')"),
  )();
  late final Column<String> addedBy = text()();
  late final Column<DateTime> createdAt = dateTime()();
  late final Column<DateTime> archivedAt = dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {notebookId, userId},
  ];
}
