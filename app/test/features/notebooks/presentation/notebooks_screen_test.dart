import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';
import 'package:jotline/core/preferences/preferences_store.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/presentation/notebook_screen.dart';
import 'package:jotline/features/notebooks/presentation/notebooks_screen.dart';
import 'package:jotline/features/trash/presentation/trash_screen.dart';

import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

class _Preferences implements PreferencesStore {
  new({this.sort});

  String? sort;

  @override
  String? get lastOpenedNotebookId => null;

  @override
  Future<void> setLastOpenedNotebookId(String? id) async {}

  @override
  String? get notebookSort => sort;

  @override
  Future<void> setNotebookSort(String name) async => sort = name;
}

late TestApp _app;
late _Preferences _prefs;
late Map<String, String> _ids;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Seeds "Bloco" (3 pages), "árvore" (1 page) and "Caderno" (no pages); the
/// ones in [archived] are archived. Creation order: Bloco, árvore, Caderno.
Future<void> _open(
  WidgetTester tester, {
  Set<String> archived = const {},
  Set<String> only = const {'Bloco', 'árvore', 'Caderno'},
  String? sort,
}) async {
  _app = TestApp(now: DateTime.utc(2026, 10, 12, 15));
  _prefs = _Preferences(sort: sort);
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _ids = {};
  await tester.runAsync(() async {
    for (final (title, pages) in [
      ('Bloco', 3),
      ('árvore', 1),
      ('Caderno', 0),
    ]) {
      if (!only.contains(title)) continue;
      final id = await _app.notebooks.create(
        title: title,
        cover: CoverPattern.lisa,
        color: NotebookColor.musgo,
      );
      _ids[title] = id;
      for (var i = 0; i < pages; i++) {
        await _app.pages.create(id, title: 'P$i');
      }
      _app.clock.current = _app.clock.current.add(const Duration(minutes: 1));
      if (archived.contains(title)) await _app.notebooks.archive(id);
    }
  });
  await tester.pumpJot(
    const NotebooksScreen(),
    overrides: _app.overrides,
    preferences: _prefs,
  );
  await _settle(tester);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.runAsync(_app.db.close);
}

Future<DateTime?> _archivedAt(WidgetTester tester, String title) async {
  final rows = await tester.runAsync(
    () => _app.db.select(_app.db.notebookMembers).get(),
  );
  return rows!.firstWhere((m) => m.notebookId == _ids[title]).archivedAt;
}

Future<Notebook> _notebook(WidgetTester tester, String title) async =>
    (await tester.runAsync(() => _app.notebook(_ids[title]!)))!;

Finder get _toast => find.byType(JotUndoToast);

Future<void> _openFirstNotebookAction(
  WidgetTester tester,
  String tile,
  String action,
) async {
  await tester.tap(find.text(tile).first);
  await _settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(NotebookScreen),
      matching: find.byType(JotIconButton),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('NBLIST-02: the tabs show the number of notebooks in each '
      'list', (tester) async {
    await _open(tester, archived: {'Caderno'});

    expect(find.text('Ativos · 2'), findsOneWidget);
    expect(find.text('Arquivados · 1'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-03: an active tile shows "<pages> · <date>"', (
    tester,
  ) async {
    await _open(tester, only: {'Bloco'});

    expect(find.text('Bloco'), findsWidgets);
    expect(find.text('3 páginas · hoje'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-04: the archived tab shows the explanation and rows '
      'with "arquivado" meta and "Desarquivar"', (tester) async {
    await _open(tester, archived: {'árvore'});

    await tester.tap(find.text('Arquivados · 1'));
    await tester.pump();

    expect(
      find.text(
        'Arquivar tira o caderno da lista principal sem apagar nada. '
        'As páginas continuam na busca.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 página · arquivado hoje'), findsOneWidget);
    expect(find.text('Desarquivar'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-05: with no notebook the empty state shows and the '
      'tabs and "Ordenar" are hidden', (tester) async {
    await _open(tester, only: {});

    expect(find.text('Nenhum caderno ainda'), findsOneWidget);
    expect(
      find.text(
        'Crie o primeiro para começar a escrever. '
        'Tudo fica neste aparelho, mesmo sem internet.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Ativos'), findsNothing);
    expect(find.byType(JotIconButton), findsOneWidget);
    expect(find.text('Novo caderno'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-06: an empty archived tab shows its empty state', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.text('Arquivados · 0'));
    await tester.pump();

    expect(find.text('Nenhum caderno arquivado'), findsOneWidget);
    expect(
      find.text(
        'Arquivar tira um caderno da lista sem apagar nada. '
        'Use as opções do caderno, no ⋯.',
      ),
      findsOneWidget,
    );
    await _close(tester);
  });

  testWidgets('NBLIST-07: a page added elsewhere updates the count and the '
      'meta', (tester) async {
    await _open(tester, only: {'Bloco'});
    expect(find.text('3 páginas · hoje'), findsOneWidget);

    await tester.runAsync(() => _app.pages.create(_ids['Bloco']!, title: 'X'));
    await _settle(tester);

    expect(find.text('4 páginas · hoje'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-08: tapping a tile opens the notebook', (tester) async {
    await _open(tester, only: {'Bloco'});

    await tester.tap(find.text('3 páginas · hoje'));
    await _settle(tester);

    expect(find.byType(NotebookScreen), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-08: tapping an archived row opens the notebook', (
    tester,
  ) async {
    await _open(tester, only: {'Bloco'}, archived: {'Bloco'});

    await tester.tap(find.text('Arquivados · 1'));
    await tester.pump();
    await tester.tap(find.text('Bloco'));
    await _settle(tester);

    expect(find.byType(NotebookScreen), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-09: the trash button opens "Lixeira"', (tester) async {
    await _open(tester);

    await tester.tap(find.byType(JotIconButton).last);
    await _settle(tester);

    expect(find.byType(TrashScreen), findsOneWidget);
    expect(find.text('Lixeira'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBLIST-10: the header has no "Buscar" button', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    expect(find.bySemanticsLabel('Buscar'), findsNothing);
    expect(find.byType(JotIconButton), findsNWidgets(2));
    semantics.dispose();
    await _close(tester);
  });

  testWidgets('NBNEW-06: creating a notebook opens its page list', (
    tester,
  ) async {
    await _open(tester, only: {});

    await tester.tap(find.text('Novo caderno'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Receitas');
    await tester.pump();
    await tester.tap(find.text('Criar caderno'));
    await _settle(tester);

    expect(find.byType(NotebookScreen), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('ARCH-01/ARCH-03: after archiving, the Ativos tab, the toast '
      'and "Desfazer" restores the previous value', (tester) async {
    await _open(tester);

    await _openFirstNotebookAction(tester, 'Bloco', 'Arquivar');
    await _settle(tester);

    expect(find.byType(NotebookScreen), findsNothing);
    expect(find.text('Caderno arquivado'), findsOneWidget);
    expect(find.text('Ativos · 2'), findsOneWidget);
    expect(find.text('Arquivados · 1'), findsOneWidget);
    expect(await _archivedAt(tester, 'Bloco'), isNotNull);

    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    expect(await _archivedAt(tester, 'Bloco'), isNull);
    expect(find.text('Ativos · 3'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('ARCH-02/ARCH-03: "Desarquivar" on a row shows the toast and '
      'the Ativos tab; "Desfazer" re-archives with the original date', (
    tester,
  ) async {
    await _open(tester, archived: {'Bloco'});
    final original = await _archivedAt(tester, 'Bloco');

    await tester.tap(find.text('Arquivados · 1'));
    await tester.pump();
    await tester.tap(find.text('Desarquivar'));
    await _settle(tester);

    expect(find.text('Caderno de volta à lista principal'), findsOneWidget);
    expect(find.text('Ativos · 3'), findsOneWidget);
    expect(await _archivedAt(tester, 'Bloco'), isNull);

    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    expect(await _archivedAt(tester, 'Bloco'), original);
    expect(find.text('Arquivados · 1'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('NBDEL-02/NBDEL-04: after deleting, the toast; "Desfazer" '
      'restores the notebook', (tester) async {
    await _open(tester);

    await _openFirstNotebookAction(tester, 'Bloco', 'Excluir caderno');
    await tester.tap(find.text('Mover para a lixeira'));
    await _settle(tester);

    expect(find.text('Caderno movido para a lixeira'), findsOneWidget);
    expect(find.text('Ativos · 2'), findsOneWidget);
    expect((await _notebook(tester, 'Bloco')).deletedAt, isNotNull);

    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    expect((await _notebook(tester, 'Bloco')).deletedAt, isNull);
    expect(find.text('Ativos · 3'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('TOAST-02: the toast goes away after 3 s and the action '
      'stays', (tester) async {
    await _open(tester, archived: {'Bloco'});

    await tester.tap(find.text('Arquivados · 1'));
    await tester.pump();
    await tester.tap(find.text('Desarquivar'));
    await _settle(tester);
    await tester.pump(JotUndoToast.duration);
    await tester.pump();

    expect(_toast, findsNothing);
    expect(await _archivedAt(tester, 'Bloco'), isNull);
    await _close(tester);
  });

  testWidgets('TOAST-05: a new toast replaces the visible one and the old '
      'action stays applied', (tester) async {
    await _open(tester, archived: {'Bloco', 'árvore'});

    await tester.tap(find.text('Arquivados · 2'));
    await tester.pump();
    await tester.tap(find.text('Desarquivar').first);
    await _settle(tester);
    await tester.tap(find.text('Arquivados · 1'));
    await tester.pump();
    await tester.tap(find.text('Desarquivar'));
    await _settle(tester);

    expect(_toast, findsOneWidget);
    expect(await _archivedAt(tester, 'Bloco'), isNull);
    expect(await _archivedAt(tester, 'árvore'), isNull);

    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    final archived = [
      await _archivedAt(tester, 'Bloco'),
      await _archivedAt(tester, 'árvore'),
    ];
    expect(archived.where((d) => d != null), hasLength(1));
    await _close(tester);
  });

  testWidgets('TOAST-06: leaving the screen dismisses the toast without '
      'undoing', (tester) async {
    await _open(tester, archived: {'Bloco'});

    await tester.tap(find.text('Arquivados · 1'));
    await tester.pump();
    await tester.tap(find.text('Desarquivar'));
    await _settle(tester);
    expect(_toast, findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(JotUndoToast.duration);

    expect(_toast, findsNothing);
    expect(await _archivedAt(tester, 'Bloco'), isNull);
    await tester.runAsync(_app.db.close);
  });

  testWidgets('SORT-06/SORT-03: a stored "name" sort is applied on start', (
    tester,
  ) async {
    await _open(tester, sort: 'name');

    final dys = [
      for (final t in ['árvore', 'Bloco', 'Caderno'])
        tester.getTopLeft(find.text(t).first),
    ];
    expect(dys[0].dy, lessThanOrEqualTo(dys[1].dy));
    expect(dys[1].dy, lessThanOrEqualTo(dys[2].dy));
    expect(dys[0].dx, lessThan(dys[1].dx));
    await _close(tester);
  });

  testWidgets('SORT-02: picking "Nome (A–Z)" in the sheet reorders the grid '
      'and stores the choice', (tester) async {
    await _open(tester);

    await tester.tap(find.byType(JotIconButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nome (A–Z)'));
    await _settle(tester);

    expect(_prefs.sort, 'name');
    final positions = [
      for (final t in ['árvore', 'Bloco', 'Caderno'])
        tester.getTopLeft(find.text(t).first),
    ];
    expect(positions[0].dx, lessThan(positions[1].dx));
    expect(positions[1].dy, positions[0].dy);
    expect(positions[2].dy, greaterThan(positions[0].dy));
    await _close(tester);
  });
}
