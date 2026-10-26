import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/blocks/presentation/editor/page_editor.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';
import 'package:super_editor/super_editor.dart';

import '../../integration_test/kill/kill_app.dart';
import '../helpers/fakes.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late BlockRepository blocks;
  late String pageId;

  setUp(() async {
    db = createTestDatabase();
    final clock = FakeClock(DateTime.utc(2026, 10, 17, 12));
    final ids = SequentialIdGenerator();
    final localUser = LocalUserRepository(db, ids);
    blocks = BlockRepository(db, clock, ids, localUser);
    final notebookId = await NotebookRepository(db, clock, ids, localUser)
        .create(
          title: 'Kill test',
          cover: CoverPattern.lisa,
          color: NotebookColor.azulTinta,
        );
    pageId = await PageRepository(
      db,
      clock,
      ids,
      localUser,
    ).create(notebookId, title: 'Kill test');
  });
  tearDown(() => db.close());

  testWidgets('KILL-02: the snapshot taken before a flush equals the saved '
      'blocks after it, across relaunches', (tester) async {
    await tester.runAsync(() async {
      for (var iteration = 1; iteration <= 4; iteration++) {
        final editor = PageEditor(
          rows: await blocks.loadPage(pageId),
          pageId: pageId,
          repository: blocks,
        );
        final random = Random(iteration);
        for (var step = 0; step < 60; step++) {
          applyKillOperation(editor.editor, random);
          final expected = snapshotOfDocument(editor.editor.document);
          await editor.flush();
          final actual = snapshotOfRows(await blocks.loadPage(pageId));
          expect(actual, expected, reason: 'iteration $iteration step $step');
        }
        editor.dispose();
      }
      final rows = await blocks.loadPage(pageId);
      expect(rows, isNotEmpty);
      expect(rows.length, lessThanOrEqualTo(maxKillBlocks + 1));
    });
  });
}
