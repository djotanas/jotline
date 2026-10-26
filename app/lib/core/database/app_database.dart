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

@DriftDatabase(
  tables: [Notebooks, NotebookMembers, Pages, Blocks, LocalUser],
  include: {'search.drift'},
)
class AppDatabase extends _$AppDatabase {
  new(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        for (final entity in schema.entities) {
          await m.create(entity);
        }
      },
      from2To3: (m, schema) async {
        await m.create(schema.pageSearch);
        await m.create(schema.pagesSearchAi);
        await m.create(schema.pagesSearchAu);
        await m.create(schema.blocksSearchAi);
        await m.create(schema.blocksSearchAu);
        await m.create(schema.blocksSearchAd);
        await m.database.customStatement(_backfillPageSearch);
      },
      from3To4: (m, schema) async {
        await m.create(schema.blocksPageEdits);
      },
    ),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

const _backfillPageSearch = r"""
INSERT INTO page_search (rowid, title, body)
SELECT p.rowid, p.title, COALESCE((
  SELECT group_concat(t.text, char(8233)) FROM (
    SELECT CASE WHEN json_valid(b.content_json)
      THEN CAST(json_extract(b.content_json, '$.text') AS TEXT) END AS text
    FROM blocks AS b
    WHERE b.page_id = p.id AND b.deleted_at IS NULL
      AND b.type IN ('text', 'heading', 'bulleted_list_item', 'checklist_item')
    ORDER BY b.position, b.id
  ) AS t
), '')
FROM pages AS p
""";
