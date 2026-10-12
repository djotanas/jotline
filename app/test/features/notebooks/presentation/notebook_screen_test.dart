import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/design_system/empty_state.dart';
import 'package:jotline/core/design_system/jot_badge.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';
import 'package:jotline/core/preferences/preferences_store.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/presentation/notebook_outcome.dart';
import 'package:jotline/features/notebooks/presentation/notebook_screen.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';

import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

class _RecordingPreferences implements PreferencesStore {
  String? lastOpened;

  @override
  String? get lastOpenedNotebookId => lastOpened;

  @override
  Future<void> setLastOpenedNotebookId(String? id) async => lastOpened = id;

  @override
  String? get notebookSort => null;

  @override
  Future<void> setNotebookSort(String name) async {}
}

late TestApp _app;
late _RecordingPreferences _prefs;
late String _notebookId;
late List<String> _pageIds;
Object? _outcome = 'not popped';
bool _popped = false;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _open(
  WidgetTester tester, {
  List<String> titles = const ['A', 'B', 'C'],
  bool archived = false,
}) async {
  _app = TestApp();
  _prefs = _RecordingPreferences();
  _outcome = 'not popped';
  _popped = false;
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    _notebookId = await _app.notebooks.create(
      title: 'Viagem a Lisboa',
      cover: CoverPattern.pautada,
      color: NotebookColor.azulTinta,
    );
    _pageIds = [
      for (final title in titles)
        await _app.pages.create(_notebookId, title: title),
    ];
    if (archived) await _app.notebooks.archive(_notebookId);
  });
  await tester.pumpJot(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: GestureDetector(
            onTap: () async {
              _outcome = await Navigator.of(context).push<Object>(
                MaterialPageRoute(
                  builder: (_) => NotebookScreen(notebookId: _notebookId),
                ),
              );
              _popped = true;
            },
            child: const SizedBox.square(dimension: 44, child: Text('go')),
          ),
        ),
      ),
    ),
    overrides: _app.overrides,
    preferences: _prefs,
  );
  await tester.tap(find.text('go'));
  await _settle(tester);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.runAsync(_app.db.close);
}

Finder get _optionsButton => find.descendant(
  of: find.byType(NotebookScreen),
  matching: find.byType(JotIconButton),
);

Future<void> _tapOption(WidgetTester tester, String label) async {
  await tester.tap(_optionsButton);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await _settle(tester);
}

Future<Notebook> _notebook(WidgetTester tester) async =>
    (await tester.runAsync(() => _app.notebook(_notebookId)))!;

Future<List<NotebookPage>> _pages(WidgetTester tester) async =>
    (await tester.runAsync(() => _app.db.select(_app.db.pages).get()))!;

Future<void> _trashPageFromItsScreen(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await _settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(PageScreen),
      matching: find.byType(JotIconButton),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Excluir página'));
  await tester.pumpAndSettle();
  await _settle(tester);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PGLIST-07: opening the notebook writes lastOpenedNotebookId', (
    tester,
  ) async {
    await _open(tester);

    expect(_prefs.lastOpened, _notebookId);
    await _close(tester);
  });

  testWidgets('PGLIST-01: shows the back button, the cover, the title, the '
      'count and the pages in order', (tester) async {
    await _open(tester);

    expect(find.text('Cadernos'), findsOneWidget);
    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    expect(find.text('3 páginas'), findsOneWidget);
    expect(find.text('Reordenar'), findsOneWidget);
    expect(find.text('Nova página'), findsOneWidget);
    final titles = ['A', 'B', 'C'];
    final dys = [for (final t in titles) tester.getTopLeft(find.text(t)).dy];
    expect(dys, [...dys]..sort());
    await _close(tester);
  });

  testWidgets('PGLIST-08: "Cadernos" returns to the previous screen', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('Cadernos'));
    await _settle(tester);

    expect(_popped, isTrue);
    expect(_outcome, isNull);
    await _close(tester);
  });

  testWidgets('PGLIST-03: an empty notebook shows the empty state, '
      '"nenhuma página" and no "Reordenar"', (tester) async {
    await _open(tester, titles: const []);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Nenhuma página ainda'), findsOneWidget);
    expect(find.text('Toque em Nova página para começar.'), findsOneWidget);
    expect(find.text('nenhuma página'), findsOneWidget);
    expect(find.text('Reordenar'), findsNothing);
    await _close(tester);
  });

  testWidgets('PGLIST-04: an archived notebook shows the "Arquivado" badge', (
    tester,
  ) async {
    await _open(tester, archived: true);

    expect(find.widgetWithText(JotBadge, 'Arquivado'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('PGLIST-04: an active notebook shows no badge', (tester) async {
    await _open(tester);

    expect(find.byType(JotBadge), findsNothing);
    await _close(tester);
  });

  testWidgets('REORDER-01: "Reordenar" shows "Concluir", the hint and hides '
      '"Nova página"; "Concluir" leaves the mode', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Reordenar'));
    await tester.pump();
    expect(find.text('Concluir'), findsOneWidget);
    expect(find.text('Arraste pela alça para mudar a ordem.'), findsOneWidget);
    expect(find.text('Nova página'), findsNothing);

    await tester.tap(find.text('Concluir'));
    await tester.pump();
    expect(find.text('Reordenar'), findsOneWidget);
    expect(find.text('Nova página'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('PGLIST-05: "Nova página" creates a page at the end and opens '
      'it with the title focused', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Nova página'));
    await _settle(tester);

    final pages = await _pages(tester);
    expect(pages, hasLength(4));
    final created = pages.firstWhere((p) => !_pageIds.contains(p.id));
    expect(created.title, '');
    expect(
      ([...pages]..sort((a, b) => a.position.compareTo(b.position))).last.id,
      created.id,
    );
    expect(find.byType(PageScreen), findsOneWidget);
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byType(PageScreen),
        matching: find.byType(TextField),
      ),
    );
    expect(field.focusNode?.hasFocus ?? field.autofocus, isTrue);
    await _close(tester);
  });

  testWidgets('ARCH-05: pages can be created in an archived notebook', (
    tester,
  ) async {
    await _open(tester, archived: true);

    await tester.tap(find.text('Nova página'));
    await _settle(tester);

    expect(await _pages(tester), hasLength(4));
    await _close(tester);
  });

  testWidgets('NBOPT-06: renaming saves the trimmed title and the header '
      'shows it', (tester) async {
    await _open(tester);

    await tester.tap(_optionsButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '  Porto  ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await _settle(tester);

    expect((await _notebook(tester)).title, 'Porto');
    expect(find.text('Porto'), findsOneWidget);
    expect(find.text('Viagem a Lisboa'), findsNothing);
    await _close(tester);
  });

  testWidgets('NBOPT-08: "Capa e cor" saves the chosen color and cover', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    await _tapOption(tester, 'Mudar capa e cor');
    await tester.tap(find.bySemanticsLabel('Musgo'));
    await tester.tap(find.text('Grade'));
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await _settle(tester);

    final notebook = await _notebook(tester);
    expect(notebook.color, NotebookColor.musgo);
    expect(notebook.cover, CoverPattern.quadriculada);
    await _close(tester);
    semantics.dispose();
  });

  testWidgets('ARCH-01: archiving pops NotebookArchived with the previous '
      'value', (tester) async {
    await _open(tester);

    await _tapOption(tester, 'Arquivar');

    expect(_popped, isTrue);
    expect(_outcome, isA<NotebookArchived>());
    final outcome = _outcome! as NotebookArchived;
    expect(outcome.id, _notebookId);
    expect(outcome.previous, isNull);
    await _close(tester);
  });

  testWidgets('ARCH-02: unarchiving pops NotebookUnarchived with the '
      'archived_at it had', (tester) async {
    await _open(tester, archived: true);

    await _tapOption(tester, 'Desarquivar');

    expect(_outcome, isA<NotebookUnarchived>());
    expect((_outcome! as NotebookUnarchived).previous, _app.clock.current);
    await _close(tester);
  });

  testWidgets('NBDEL-01: "Excluir caderno" opens the confirmation with the '
      'canvas copy', (tester) async {
    await _open(tester);

    await _tapOption(tester, 'Excluir caderno');

    expect(find.text('Excluir “Viagem a Lisboa”?'), findsOneWidget);
    expect(
      find.text(
        'O caderno vai para a lixeira deste aparelho, com as páginas. '
        'Dá para desfazer logo depois ou restaurá-lo pela lixeira.',
      ),
      findsOneWidget,
    );
    expect(find.text('Mover para a lixeira'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await _close(tester);
  });

  testWidgets('NBDEL-02: "Mover para a lixeira" sets only notebooks.deleted_at '
      'and pops NotebookTrashed (NBDEL-05)', (tester) async {
    await _open(tester);
    final pagesBefore = await _pages(tester);

    await _tapOption(tester, 'Excluir caderno');
    await tester.tap(find.text('Mover para a lixeira'));
    await tester.pumpAndSettle();
    await _settle(tester);

    expect((await _notebook(tester)).deletedAt, isNotNull);
    expect(await _pages(tester), pagesBefore);
    expect(_popped, isTrue);
    expect(_outcome, isA<NotebookTrashed>());
    await _close(tester);
  });

  testWidgets('NBDEL-03: "Cancelar" in the delete dialog writes nothing', (
    tester,
  ) async {
    await _open(tester);

    await _tapOption(tester, 'Excluir caderno');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await _settle(tester);

    expect((await _notebook(tester)).deletedAt, isNull);
    expect(_popped, isFalse);
    await _close(tester);
  });

  testWidgets('EDGE-04: the notebook trashed from outside closes the screen', (
    tester,
  ) async {
    await _open(tester);

    await tester.runAsync(() => _app.notebooks.moveToTrash(_notebookId));
    await _settle(tester);

    expect(_popped, isTrue);
    expect(_outcome, isNull);
    await _close(tester);
  });

  testWidgets('PGOPT-04: deleting a page from its screen shows the toast and '
      'PGOPT-05: "Desfazer" restores it in place', (tester) async {
    await _open(tester);

    await _trashPageFromItsScreen(tester, 'B');

    expect(find.byType(PageScreen), findsNothing);
    expect(find.text('Página movida para a lixeira'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(find.text('2 páginas'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    expect(find.text('Página movida para a lixeira'), findsNothing);
    expect(find.text('3 páginas'), findsOneWidget);
    final dys = [
      for (final t in ['A', 'B', 'C']) tester.getTopLeft(find.text(t)).dy,
    ];
    expect(dys, [...dys]..sort());
    await _close(tester);
  });

  testWidgets('TOAST-02: after 3 s the toast disappears and the page stays in '
      'the trash', (tester) async {
    await _open(tester);

    await _trashPageFromItsScreen(tester, 'B');
    await tester.pump(JotUndoToast.duration);
    await tester.pump();

    expect(find.byType(JotUndoToast), findsNothing);
    final page = (await _pages(tester)).firstWhere((p) => p.id == _pageIds[1]);
    expect(page.deletedAt, isNotNull);
    await _close(tester);
  });

  testWidgets('TOAST-05: a second toast replaces the first without undoing '
      'it', (tester) async {
    await _open(tester);

    await _trashPageFromItsScreen(tester, 'B');
    await tester.pump(const Duration(seconds: 1));
    await _trashPageFromItsScreen(tester, 'C');

    expect(find.byType(JotUndoToast), findsOneWidget);
    final pages = await _pages(tester);
    expect(pages.where((p) => p.deletedAt != null), hasLength(2));

    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    final after = await _pages(tester);
    expect(after.firstWhere((p) => p.id == _pageIds[2]).deletedAt, isNull);
    expect(after.firstWhere((p) => p.id == _pageIds[1]).deletedAt, isNotNull);
    await _close(tester);
  });

  testWidgets('TOAST-06: leaving the screen dismisses the toast without '
      'undoing', (tester) async {
    await _open(tester);

    await _trashPageFromItsScreen(tester, 'B');
    await tester.tap(find.text('Cadernos'));
    await _settle(tester);
    await tester.pumpAndSettle();

    expect(find.byType(JotUndoToast), findsNothing);
    final page = (await _pages(tester)).firstWhere((p) => p.id == _pageIds[1]);
    expect(page.deletedAt, isNotNull);
    await _close(tester);
  });
}
