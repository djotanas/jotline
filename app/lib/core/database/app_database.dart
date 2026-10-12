import 'package:drift/drift.dart';
import 'package:jotline/core/database/app_database.steps.dart';
import 'package:jotline/core/database/tables/blocks.dart';
import 'package:jotline/core/database/tables/local_user.dart';
import 'package:jotline/core/database/tables/member_role.dart';
import 'package:jotline/core/database/tables/notebook_members.dart';
import 'package:jotline/core/database/tables/notebooks.dart';
import 'package:jotline/core/database/tables/pages.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Notebooks, NotebookMembers, Pages, Blocks, LocalUser])
class AppDatabase extends _$AppDatabase {
  new(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        for (final entity in schema.entities) {
          await m.create(entity);
        }
      },
    ),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
