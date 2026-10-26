import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/editor/block_editor.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:jotline/features/blocks/presentation/editor/block_sync.dart';
import 'package:jotline/features/blocks/presentation/editor/components/active_block_builder.dart';
import 'package:jotline/features/blocks/presentation/editor/components/drawing_block.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../../../helpers/fakes.dart';
import '../../../../../helpers/pump_jot.dart';
import '../../../../../helpers/test_database.dart';

const _drawing = DrawingContent([
  Stroke(
    tool: DrawingTool.pen,
    color: DrawingColor.ink,
    width: 3,
    points: [StrokePoint(10, 20, 0.5), StrokePoint(300, 400, 0.5)],
  ),
]);

class _Fixture {
  late AppDatabase db;
  late BlockRepository repository;
  late String pageId;
  late String above;
  late String drawing;
  late String below;
  late Editor editor;
  late BlockSync sync;
  final opened = <String>[];
  final focusNode = FocusNode();

  Future<void> open() async {
    db = createTestDatabase();
    final clock = FakeClock(DateTime.utc(2026, 10, 11, 8));
    final ids = SequentialIdGenerator();
    final localUser = LocalUserRepository(db, ids);
    final notebookId = await NotebookRepository(db, clock, ids, localUser)
        .create(
          title: 'Viagem',
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
    pageId = await PageRepository(
      db,
      clock,
      ids,
      localUser,
    ).create(notebookId, title: 'Roteiro');
    repository = BlockRepository(db, clock, ids, localUser);
    above = await repository.create(
      pageId,
      type: 'text',
      contentJson: const BlockContent('Acima').toJson(),
    );
    drawing = await repository.create(
      pageId,
      type: 'drawing',
      contentJson: _drawing.toJson(),
    );
    below = await repository.create(
      pageId,
      type: 'text',
      contentJson: const BlockContent('Abaixo').toJson(),
    );
    final rows = await repository.loadPage(pageId);
    editor = createBlockEditor(BlockMapper.toDocument(rows));
    sync = BlockSync(
      editor: editor,
      pageId: pageId,
      repository: repository,
      loadedIds: rows.map((row) => row.id),
    );
  }

  Future<Block> row(String id) =>
      (db.select(db.blocks)..where((t) => t.id.equals(id))).getSingle();

  Future<void> close() async {
    sync.dispose();
    await db.close();
  }
}

Future<_Fixture> _pump(WidgetTester tester) async {
  final fixture = _Fixture();
  await tester.runAsync(fixture.open);
  addTearDown(fixture.focusNode.dispose);
  await tester.pumpJot(
    Scaffold(
      body: CustomScrollView(
        slivers: [
          BlockEditor(
            editor: fixture.editor,
            focusNode: fixture.focusNode,
            onOpenDrawing: fixture.opened.add,
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(fixture.close);
  });
  return fixture;
}

void main() {
  const colors = JotColors.light;

  testWidgets('DRAW-12: the card is at page width with a 390:560 ratio', (
    tester,
  ) async {
    await _pump(tester);

    final card = tester.getSize(find.byType(DrawingCard));
    final page = tester.getSize(find.byType(CustomScrollView));

    expect(card.width, page.width - 2 * JotSpace.space6);
    expect(card.height, closeTo(card.width * 560 / 390, 0.01));
  });

  testWidgets('DRAW-12: border, radius and fill come from the tokens', (
    tester,
  ) async {
    await _pump(tester);

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(DrawingCard),
        matching: find.byType(DecoratedBox),
      ),
    );

    expect(
      box.decoration,
      BoxDecoration(
        color: colors.bgFolha,
        border: Border.all(color: colors.bgTrilho),
        borderRadius: BorderRadius.circular(JotRadius.rCard),
      ),
    );
  });

  testWidgets('DRAW-12: the card is labeled "Desenho" for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final node = tester.getSemantics(find.bySemanticsLabel('Desenho'));

    expect(node.label, 'Desenho');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('DRAW-13: a tap on the card calls onOpen with the node id', (
    tester,
  ) async {
    final fixture = await _pump(tester);

    await tester.tap(find.byType(DrawingCard));
    await tester.pump();

    expect(fixture.opened, [fixture.drawing]);
  });

  testWidgets('DRAW-13: the drawing block shows no drag handle', (
    tester,
  ) async {
    final fixture = await _pump(tester);
    await tester.placeCaretInParagraph(fixture.above, 5);
    expect(find.byType(BlockDragHandle), findsOneWidget);

    await tester.tap(find.byType(DrawingCard));
    await tester.pump();

    final block = find.ancestor(
      of: find.byType(DrawingCard),
      matching: find.byType(ActiveBlock),
    );
    expect(block, findsOneWidget);
    expect(
      find.descendant(of: block, matching: find.byType(BlockDragHandle)),
      findsNothing,
    );
  });

  testWidgets('DRAW-15: Backspace at the start of the block below leaves the '
      'drawing row untouched', (tester) async {
    final fixture = await _pump(tester);
    final before = await tester.runAsync(() => fixture.row(fixture.drawing));

    fixture.focusNode.requestFocus();
    fixture.editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: fixture.below,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
    ]);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    await tester.runAsync(fixture.sync.flush);

    expect(fixture.editor.document.getNodeById(fixture.drawing), isNotNull);
    expect(await tester.runAsync(() => fixture.row(fixture.drawing)), before);
    expect(before!.deletedAt, isNull);
  });

  testWidgets('DRAW-15: Delete at the end of the block above leaves the '
      'drawing row untouched', (tester) async {
    final fixture = await _pump(tester);
    final before = await tester.runAsync(() => fixture.row(fixture.drawing));

    await tester.placeCaretInParagraph(fixture.above, 5);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    await tester.runAsync(fixture.sync.flush);

    expect(fixture.editor.document.getNodeById(fixture.drawing), isNotNull);
    expect(await tester.runAsync(() => fixture.row(fixture.drawing)), before);
    expect(before!.deletedAt, isNull);
  });
}
