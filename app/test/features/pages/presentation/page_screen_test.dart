import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_text_field.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_providers.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/pages/presentation/page_outcome.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../helpers/editor_ime.dart';
import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

class _Launch {
  bool popped = false;
  Object? outcome;
}

class _GatedBlockRepository extends BlockRepository {
  new(TestApp app)
    : super(app.db, app.clock, app.ids, LocalUserRepository(app.db, app.ids));

  final Completer<void> gate = Completer<void>();
  int calls = 0;

  @override
  Future<Map<String, String>> applyChanges(
    String pageId,
    List<BlockChange> changes,
  ) async {
    calls++;
    await gate.future;
    return await super.applyChanges(pageId, changes);
  }
}

late TestApp _app;
late String _notebookId;
late String _pageId;
late List<String> _blockIds;
late _Launch _launch;

Future<void> _open(
  WidgetTester tester, {
  String title = 'Roteiro',
  bool autofocus = false,
  List<(BlockType, BlockContent)> blocks = const [],
  bool archived = false,
  BlockRepository Function(TestApp app)? blockRepository,
  Future<void> Function()? seed,
}) async {
  _app = TestApp();
  _launch = _Launch();
  await tester.runAsync(() async {
    _notebookId = await _app.notebooks.create(
      title: 'Viagem a Lisboa',
      cover: CoverPattern.lisa,
      color: NotebookColor.musgo,
    );
    if (archived) await _app.notebooks.archive(_notebookId);
    _pageId = await _app.pages.create(_notebookId, title: title);
    _blockIds = [
      for (final (type, content) in blocks)
        await _app.blocks.create(
          _pageId,
          type: type.id,
          contentJson: content.forType(type).toJson(),
        ),
    ];
    await seed?.call();
  });
  final repository = blockRepository?.call(_app);
  await tester.pumpJot(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: GestureDetector(
            onTap: () async {
              _launch.outcome = await Navigator.of(context).push<PageOutcome>(
                MaterialPageRoute(
                  builder: (_) =>
                      PageScreen(pageId: _pageId, autofocusTitle: autofocus),
                ),
              );
              _launch.popped = true;
            },
            child: const SizedBox.square(dimension: 44, child: Text('go')),
          ),
        ),
      ),
    ),
    overrides: [
      ..._app.overrides,
      if (repository != null)
        blockRepositoryProvider.overrideWithValue(repository),
    ],
  );
  await _launchPage(tester);
}

Future<void> _launchPage(WidgetTester tester) async {
  _launch.popped = false;
  _launch.outcome = null;
  await tester.tap(find.text('go'));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<String> _storedTitle(WidgetTester tester) async =>
    (await tester.runAsync(() => _app.page(_pageId)))!.title;

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.runAsync(_app.db.close);
}

Finder get _field => find.byType(TextField);

Future<Block> _block(WidgetTester tester, String id) async =>
    (await tester.runAsync(
      () => (_app.db.select(
        _app.db.blocks,
      )..where((t) => t.id.equals(id))).getSingle(),
    ))!;

Future<String> _storedText(WidgetTester tester, String id) async =>
    BlockContent.fromJson((await _block(tester, id)).contentJson).text;

Future<void> _typeAt(
  WidgetTester tester,
  String nodeId,
  int offset,
  String text,
) async {
  await tester.placeCaretInParagraph(nodeId, offset);
  await tester.typeImeText(text);
}

String _textOf(String nodeId) =>
    (SuperEditorInspector.findDocument()!.getNodeById(nodeId)! as TextNode).text
        .toPlainText();

Finder get _filler => find.descendant(
  of: find.byType(SliverFillRemaining),
  matching: find.byType(GestureDetector),
);

Future<List<Block>> _rows(WidgetTester tester) async =>
    (await tester.runAsync(() => _app.blocks.loadPage(_pageId)))!;

List<DocumentNode> get _nodes => SuperEditorInspector.findDocument()!.toList();

DocumentSelection? get _selection =>
    SuperEditorInspector.findDocumentSelection();

DocumentSelection _caretAt(String nodeId, int offset) =>
    DocumentSelection.collapsed(
      position: DocumentPosition(
        nodeId: nodeId,
        nodePosition: TextNodePosition(offset: offset),
      ),
    );

Future<void> _tapBelow(WidgetTester tester) async {
  await tester.tap(_filler);
  await tester.pump(kTapTimeout);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await _settle(tester);
}

const (BlockType, BlockContent) _belem = (
  BlockType.text,
  BlockContent('Belém'),
);

void main() {
  testWidgets('PAGE-01: shows the notebook title as back label, the options '
      'button, the title and the edited line', (tester) async {
    await _open(tester);

    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    expect(find.byType(JotIconButton), findsOneWidget);
    expect(find.text('Roteiro'), findsOneWidget);
    expect(find.textContaining('Editada hoje, '), findsOneWidget);
    await _close(tester);
  });

  testWidgets('PAGE-01: an empty title shows the "Sem título" placeholder', (
    tester,
  ) async {
    await _open(tester, title: '');

    expect(find.text('Sem título'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('PAGE-02: no block bar and no block widgets, only the title '
      'field', (tester) async {
    await _open(tester);

    expect(_field, findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(JotTextField), findsNothing);
    await _close(tester);
  });

  testWidgets('PAGE-03: the title is saved 500 ms after the last keystroke, '
      'not at 499 ms', (tester) async {
    await _open(tester);

    await tester.enterText(_field, 'Roteiro novo');
    await tester.pump(const Duration(milliseconds: 499));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await _storedTitle(tester), 'Roteiro');

    await tester.pump(const Duration(milliseconds: 1));
    await _settle(tester);
    expect(await _storedTitle(tester), 'Roteiro novo');
    await _close(tester);
  });

  testWidgets('PAGE-03: a keystroke restarts the 500 ms wait', (tester) async {
    await _open(tester);

    await tester.enterText(_field, 'A');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(_field, 'AB');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await _storedTitle(tester), 'Roteiro');

    await tester.pump(const Duration(milliseconds: 100));
    await _settle(tester);
    expect(await _storedTitle(tester), 'AB');
    await _close(tester);
  });

  testWidgets('PAGE-04: leaving at once saves the typed title', (tester) async {
    await _open(tester);

    await tester.enterText(_field, 'Antes de sair');
    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(_launch.popped, isTrue);
    expect(await _storedTitle(tester), 'Antes de sair');
    await _close(tester);
  });

  testWidgets('PAGE-04: the app going to the background saves the title', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(_field, 'Em segundo plano');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await _settle(tester);

    expect(await _storedTitle(tester), 'Em segundo plano');
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _close(tester);
  });

  testWidgets('PAGE-07: the back button returns to the previous screen', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('Viagem a Lisboa'));
    await _settle(tester);

    expect(_launch.popped, isTrue);
    expect(_launch.outcome, isNull);
    await _close(tester);
  });

  testWidgets('EDGE-02: spaces around the title are trimmed in the row', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(_field, '   Com espaços   ');
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);

    expect(await _storedTitle(tester), 'Com espaços');
    await _close(tester);
  });

  testWidgets('PAGE-05: the counter shows from 40 characters and the field '
      'stops at 50', (tester) async {
    await _open(tester);

    await tester.enterText(_field, 'a' * 39);
    await tester.pump();
    expect(find.text('39/50'), findsNothing);

    await tester.enterText(_field, 'a' * 40);
    await tester.pump();
    expect(find.text('40/50'), findsOneWidget);

    await tester.enterText(_field, 'a' * 51);
    await tester.pump();
    expect(find.text('50/50'), findsOneWidget);
    expect(tester.widget<TextField>(_field).controller!.text, 'a' * 50);
    await _close(tester);
  });

  testWidgets('PAGE-06: the "Editada" line follows the saved updated_at', (
    tester,
  ) async {
    await _open(tester);
    _app.clock.current = DateTime.utc(2026, 10, 12, 18, 30);
    final local = _app.clock.current.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');

    await tester.enterText(_field, 'Outro');
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);

    expect(find.text('Editada hoje, $hours:$minutes'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('PGOPT-02: options > Renomear opens the dialog with the field '
      'text, the placeholder and the help', (tester) async {
    await _open(tester);

    await tester.tap(find.byType(JotIconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();

    expect(find.text('Renomear página'), findsOneWidget);
    expect(find.text('Título'), findsOneWidget);
    expect(
      find.text('Opcional. Sem título, a página aparece como “Sem título”.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Roteiro'), findsWidgets);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await _close(tester);
  });

  testWidgets('PGOPT-03: the rename dialog saves an empty title', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.byType(JotIconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await _settle(tester);

    expect(await _storedTitle(tester), '');
    expect(find.text('Sem título'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('PGOPT-04: deleting trashes the page and pops '
      'PageTrashed', (tester) async {
    await _open(tester);

    await tester.tap(find.byType(JotIconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir página'));
    await tester.pumpAndSettle();
    await _settle(tester);

    final page = await tester.runAsync(() => _app.page(_pageId));
    expect(page!.deletedAt, isNotNull);
    expect(_launch.popped, isTrue);
    expect(_launch.outcome, isA<PageTrashed>());
    expect((_launch.outcome! as PageTrashed).id, _pageId);
    await _close(tester);
  });

  testWidgets('EDGE-03: the page trashed from outside pops the screen', (
    tester,
  ) async {
    await _open(tester);

    await tester.runAsync(() => _app.pages.moveToTrash(_pageId));
    await _settle(tester);

    expect(_launch.popped, isTrue);
    expect(_launch.outcome, isNull);
    await _close(tester);
  });

  testWidgets('EDIT-01, SAVE-11: shows the stored blocks not deleted, in '
      'position then id order, with types, text, marks and checked', (
    tester,
  ) async {
    late String first;
    late String trashed;
    await _open(
      tester,
      blocks: [
        (
          BlockType.text,
          const BlockContent(
            'Belém cedo',
            marks: [Mark(0, 5, MarkType.bold), Mark(6, 10, MarkType.italic)],
          ),
        ),
        (BlockType.bulletedListItem, const BlockContent('Torre')),
        (BlockType.checklistItem, const BlockContent('Pastéis', checked: true)),
        (BlockType.checklistItem, const BlockContent('MAAT', checked: false)),
      ],
      seed: () async {
        first = await _app.blocks.create(
          _pageId,
          type: BlockType.heading.id,
          contentJson: const BlockContent('Manhã').toJson(),
          at: const AtStart(),
        );
        trashed = await _app.blocks.create(
          _pageId,
          type: BlockType.text.id,
          contentJson: const BlockContent('Apagado').toJson(),
        );
        await _app.blocks.moveToTrash(trashed);
      },
    );

    final nodes = SuperEditorInspector.findDocument()!.toList();
    expect(nodes.map((n) => n.id), [first, ..._blockIds]);
    expect(nodes.map((n) => (n as TextNode).text.toPlainText()), [
      'Manhã',
      'Belém cedo',
      'Torre',
      'Pastéis',
      'MAAT',
    ]);
    expect(
      (nodes[0] as ParagraphNode).getMetadataValue(NodeMetadata.blockType),
      header1Attribution,
    );
    expect(nodes[1], isA<ParagraphNode>());
    expect(
      (nodes[1] as ParagraphNode).getMetadataValue(NodeMetadata.blockType),
      isNot(header1Attribution),
    );
    final text = (nodes[1] as TextNode).text;
    expect(
      text.getAttributionSpans({boldAttribution}).single,
      const AttributionSpan(attribution: boldAttribution, start: 0, end: 4),
    );
    expect(
      text.getAttributionSpans({italicsAttribution}).single,
      const AttributionSpan(attribution: italicsAttribution, start: 6, end: 9),
    );
    expect(nodes[2], isA<ListItemNode>());
    expect((nodes[2] as ListItemNode).type, ListItemType.unordered);
    expect((nodes[3] as TaskNode).isComplete, isTrue);
    expect((nodes[4] as TaskNode).isComplete, isFalse);
    expect(SuperEditorInspector.findDocument()!.getNodeById(trashed), isNull);
    await _close(tester);
  });

  testWidgets('SAVE-02, SAVE-05, EDITED-04: typing saves the block 500 ms '
      'after the last change, leaves the page and other rows alone and '
      'updates "Editada"', (tester) async {
    await _open(
      tester,
      blocks: [_belem, (BlockType.text, const BlockContent('Pastéis'))],
    );
    final page = await tester.runAsync(() => _app.page(_pageId));
    final other = await _block(tester, _blockIds[1]);
    _app.clock.current = DateTime.utc(2026, 10, 12, 18, 30);
    final local = _app.clock.current.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');

    await tester.placeCaretInParagraph(_blockIds[0], 5);
    await tester.imeInsert(' cedo');
    await tester.pump(const Duration(milliseconds: 499));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await _storedText(tester, _blockIds[0]), 'Belém');

    await tester.pump(const Duration(milliseconds: 1));
    await _settle(tester);
    final saved = await _block(tester, _blockIds[0]);
    expect(BlockContent.fromJson(saved.contentJson).text, 'Belém cedo');
    expect(saved.updatedAt, _app.clock.current);
    expect(await tester.runAsync(() => _app.page(_pageId)), page);
    expect(await _block(tester, _blockIds[1]), other);
    expect(find.text('Editada hoje, $hours:$minutes'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('SAVE-03, SAVE-11: typing then leaving at once saves the block '
      'before the screen closes, and reopening shows it', (tester) async {
    await _open(tester, blocks: [_belem]);

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(_launch.popped, isTrue);
    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo');

    await _launchPage(tester);
    expect(_textOf(_blockIds[0]), 'Belém cedo');
    await _close(tester);
  });

  testWidgets('SAVE-03: the screen removed without a pop still saves the '
      'typed block', (tester) async {
    await _open(tester, blocks: [_belem]);

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    await tester.pumpWidget(const SizedBox());
    await _settle(tester);

    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo');
    await tester.runAsync(_app.db.close);
  });

  testWidgets('SAVE-13: the app turning inactive saves the typed block at '
      'once, without waiting 500 ms', (tester) async {
    await _open(tester, blocks: [_belem]);

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _close(tester);
  });

  testWidgets('SAVE-03: opening the options saves the typed block first', (
    tester,
  ) async {
    await _open(tester, blocks: [_belem]);

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    await tester.tap(find.byType(JotIconButton));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));

    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo');
    await _settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('Excluir página'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _close(tester);
  });

  testWidgets('SAVE-03: deleting the page saves the typed block before the '
      'page goes to the trash', (tester) async {
    await _open(tester, blocks: [_belem]);

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    await tester.tap(find.byType(JotIconButton));
    await _settle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir página'));
    await tester.pumpAndSettle();
    await _settle(tester);

    expect(_launch.outcome, isA<PageTrashed>());
    expect(
      (await tester.runAsync(() => _app.page(_pageId)))!.deletedAt,
      isNotNull,
    );
    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo');
    await _close(tester);
  });

  testWidgets('EDGE-01, EDGE-06: the page trashed while open saves the '
      'pending text and pops; restoring it shows the text', (tester) async {
    await _open(tester, blocks: [_belem]);

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    await tester.runAsync(() => _app.pages.moveToTrash(_pageId));
    await _settle(tester);

    expect(_launch.popped, isTrue);
    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo');

    await tester.runAsync(() => _app.pages.restore(_pageId));
    await _launchPage(tester);
    expect(_textOf(_blockIds[0]), 'Belém cedo');
    await _close(tester);
  });

  testWidgets('EDGE-02: a page of an archived notebook is editable and '
      'saved', (tester) async {
    await _open(tester, blocks: [_belem], archived: true);

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);

    expect(_textOf(_blockIds[0]), 'Belém cedo');
    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo');
    await _close(tester);
  });

  testWidgets('SAVE-12: a write still in flight blocks neither typing nor '
      'leaving', (tester) async {
    late _GatedBlockRepository repository;
    await _open(
      tester,
      blocks: [_belem],
      blockRepository: (app) => repository = _GatedBlockRepository(app),
    );

    await _typeAt(tester, _blockIds[0], 5, ' cedo');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(repository.calls, 1);
    expect(repository.gate.isCompleted, isFalse);

    await tester.typeImeText(' demais');
    await tester.pump();
    expect(_textOf(_blockIds[0]), 'Belém cedo demais');

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_launch.popped, isTrue);
    expect(await _storedText(tester, _blockIds[0]), 'Belém');

    repository.gate.complete();
    await _settle(tester);
    expect(await _storedText(tester, _blockIds[0]), 'Belém cedo demais');
    await _close(tester);
  });

  testWidgets('EDIT-04, EDIT-05: a new page has no block rows and no '
      'placeholder; tapping the body and typing "Olá" saves one text row', (
    tester,
  ) async {
    await _open(tester);

    expect(await _rows(tester), isEmpty);
    expect(
      find.descendant(
        of: find.byType(SuperEditor),
        matching: find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().isNotEmpty,
        ),
      ),
      findsNothing,
    );

    await _tapBelow(tester);
    await _save(tester);
    expect(await _rows(tester), isEmpty);

    await tester.typeImeText('Olá');
    await _save(tester);
    final rows = await _rows(tester);
    expect(rows, hasLength(1));
    expect(rows.single.type, BlockType.text.id);
    expect(BlockContent.fromJson(rows.single.contentJson).text, 'Olá');
    await _close(tester);
  });

  testWidgets('EDIT-04, EDIT-05: tapping below the last block puts the caret '
      'in a new empty text block, saved only after a character', (
    tester,
  ) async {
    await _open(tester, blocks: [_belem]);

    await _tapBelow(tester);

    expect(_nodes, hasLength(2));
    final added = _nodes.last;
    expect(added, isA<ParagraphNode>());
    expect(
      (added as ParagraphNode).getMetadataValue(NodeMetadata.blockType),
      isNot(header1Attribution),
    );
    expect(added.text.toPlainText(), isEmpty);
    expect(_selection, _caretAt(added.id, 0));
    await _save(tester);
    expect(await _rows(tester), hasLength(1));

    await tester.typeImeText('Pastéis');
    await _save(tester);
    final rows = await _rows(tester);
    expect(rows.map((r) => BlockContent.fromJson(r.contentJson).text), [
      'Belém',
      'Pastéis',
    ]);
    await _close(tester);
  });

  testWidgets('EDIT-04: tapping below when the last block is an empty text '
      'block reuses it', (tester) async {
    await _open(
      tester,
      blocks: [_belem, (BlockType.text, const BlockContent(''))],
    );

    await _tapBelow(tester);
    await _tapBelow(tester);

    expect(_nodes.map((n) => n.id), _blockIds);
    expect(_selection, _caretAt(_blockIds[1], 0));
    await _close(tester);
  });

  testWidgets('EDIT-06: Enter in the title moves the caret to the start of '
      'the first block', (tester) async {
    await _open(
      tester,
      blocks: [_belem, (BlockType.text, const BlockContent('Pastéis'))],
    );

    await tester.tap(_field);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(_selection, _caretAt(_blockIds[0], 0));
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    await tester.typeImeText('X');
    expect(_textOf(_blockIds[0]), 'XBelém');
    await _close(tester);
  });

  testWidgets('EDIT-06: Enter in the title of an empty page moves the caret '
      'to an empty text block', (tester) async {
    await _open(tester);

    await tester.tap(_field);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    expect(_nodes, hasLength(1));
    expect(_selection, _caretAt(_nodes.single.id, 0));
    await tester.typeImeText('Olá');
    await _save(tester);
    final rows = await _rows(tester);
    expect(rows.map((r) => BlockContent.fromJson(r.contentJson).text), ['Olá']);
    await _close(tester);
  });

  testWidgets('EDGE-05: deleting every block brings back the empty page of '
      'EDIT-04, with no excerpt', (tester) async {
    await _open(
      tester,
      blocks: [
        (BlockType.text, const BlockContent('Olá')),
        (BlockType.text, const BlockContent('Mar')),
      ],
    );

    await tester.placeCaretInParagraph(_blockIds[1], 3);
    for (var i = 0; i < 7; i++) {
      await tester.imeBackspace();
    }
    await _save(tester);

    expect(_nodes, hasLength(1));
    expect((_nodes.single as TextNode).text.toPlainText(), isEmpty);
    final summary = await tester.runAsync(
      () => _app.pages.watchOne(_pageId).first,
    );
    expect(summary!.excerpt, isNull);

    await _tapBelow(tester);
    expect(_nodes, hasLength(1));
    expect(_selection, _caretAt(_nodes.single.id, 0));
    await _close(tester);
  });
}
