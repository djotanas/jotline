import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/empty_state.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/trash/presentation/trash_screen.dart';

import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

late TestApp _app;
late String _n1;
late List<String> _pages;
bool _popped = false;

final DateTime _day1 = DateTime.utc(2026, 10, 10, 15);
final DateTime _day2 = DateTime.utc(2026, 10, 11, 15);
final DateTime _now = DateTime.utc(2026, 10, 12, 15);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Seeds "Viagem a Lisboa" with pages A, B, C; B is trashed on day 1; the
/// notebook is trashed on day 2 when [trashNotebook] is true.
Future<void> _open(
  WidgetTester tester, {
  bool trashNotebook = true,
  bool archived = false,
  Future<void> Function()? seed,
}) async {
  _app = TestApp(now: _day1);
  _popped = false;
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    _n1 = await _app.notebooks.create(
      title: 'Viagem a Lisboa',
      cover: CoverPattern.pautada,
      color: NotebookColor.azulTinta,
    );
    _pages = [
      for (final t in ['A', 'B', 'C']) await _app.pages.create(_n1, title: t),
    ];
    await _app.pages.moveToTrash(_pages[1]);
    if (archived) await _app.notebooks.archive(_n1);
    _app.clock.current = _day2;
    if (trashNotebook) await _app.notebooks.moveToTrash(_n1);
    await seed?.call();
    _app.clock.current = _now;
  });
  await tester.pumpJot(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
              _popped = true;
            },
            child: const SizedBox.square(dimension: 44, child: Text('go')),
          ),
        ),
      ),
    ),
    overrides: _app.overrides,
  );
  await tester.tap(find.text('go'));
  await _settle(tester);
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.runAsync(_app.db.close);
}

Future<DateTime?> _notebookDeletedAt(WidgetTester tester, String id) async =>
    (await tester.runAsync(() => _app.notebook(id)))!.deletedAt;

Future<DateTime?> _pageDeletedAt(WidgetTester tester, String id) async =>
    (await tester.runAsync(() => _app.page(id)))!.deletedAt;

void main() {
  testWidgets('TRASH-01: shows the back button, the title and the intro', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Cadernos'), findsWidgets);
    expect(find.text('Lixeira'), findsOneWidget);
    expect(
      find.text(
        'O que você exclui fica aqui, neste aparelho, e pode ser restaurado.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cadernos').first);
    await tester.pumpAndSettle();
    expect(_popped, isTrue);
    await _close(tester);
  });

  testWidgets('TRASH-02/TRASH-03: a notebook row shows its title and the page '
      'count without pages deleted on their own', (tester) async {
    await _open(tester);

    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    expect(find.text('2 páginas · excluído ontem'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('TRASH-05: pages of a notebook in the trash are not listed', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Páginas'), findsNothing);
    expect(find.text('B'), findsNothing);
    await _close(tester);
  });

  testWidgets('TRASH-10: restoring the notebook lists its pages deleted on '
      'their own', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Restaurar'));
    await _settle(tester);

    expect(find.text('Páginas'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('Cadernos'), findsWidgets);
    await _close(tester);
  });

  testWidgets('TRASH-04: a page row shows title, notebook, date and '
      '"Restaurar"', (tester) async {
    await _open(
      tester,
      trashNotebook: false,
      seed: () => _app.pages.rename(_pages[1], ''),
    );

    expect(find.text('Páginas'), findsOneWidget);
    expect(find.text('Sem título'), findsOneWidget);
    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    expect(find.text('sáb'), findsOneWidget);
    expect(find.text('Restaurar'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('TRASH-06: an empty trash shows the empty state', (tester) async {
    await _open(
      tester,
      trashNotebook: false,
      seed: () => _app.pages.restore(_pages[1]),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('A lixeira está vazia'), findsOneWidget);
    expect(
      find.text(
        'O que você excluir fica aqui, neste aparelho, e pode ser restaurado.',
      ),
      findsOneWidget,
    );
    await _close(tester);
  });

  testWidgets('TRASH-07: restoring a notebook clears only notebooks.deleted_at '
      'and shows "Caderno restaurado"', (tester) async {
    await _open(tester);
    final pagesBefore = await tester.runAsync(
      () => _app.db.select(_app.db.pages).get(),
    );

    await tester.tap(find.text('Restaurar'));
    await _settle(tester);

    expect(await _notebookDeletedAt(tester, _n1), isNull);
    expect(
      await tester.runAsync(() => _app.db.select(_app.db.pages).get()),
      pagesBefore,
    );
    expect(find.text('Caderno restaurado'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('EDGE-04: an archived notebook restored stays archived', (
    tester,
  ) async {
    await _open(tester, archived: true);

    await tester.tap(find.text('Restaurar'));
    await _settle(tester);

    final members = await tester.runAsync(
      () => _app.db.select(_app.db.notebookMembers).get(),
    );
    expect(members!.single.archivedAt, isNotNull);
    expect(await _notebookDeletedAt(tester, _n1), isNull);
    await _close(tester);
  });

  testWidgets('TRASH-08: restoring a page clears its deleted_at and shows '
      '"Restaurado em <caderno>"', (tester) async {
    await _open(tester, trashNotebook: false);

    await tester.tap(find.text('Restaurar'));
    await _settle(tester);

    expect(await _pageDeletedAt(tester, _pages[1]), isNull);
    expect(find.text('Restaurado em Viagem a Lisboa'), findsOneWidget);
    expect(find.text('A lixeira está vazia'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('EDGE-05: a page restored into an archived notebook shows in '
      'its list', (tester) async {
    await _open(tester, trashNotebook: false, archived: true);

    await tester.tap(find.text('Restaurar'));
    await _settle(tester);

    final listed = await tester.runAsync(
      () => _app.pages.watchByNotebook(_n1).first,
    );
    expect(listed!.map((p) => p.title), ['A', 'B', 'C']);
    await _close(tester);
  });

  testWidgets('TRASH-09: "Desfazer" after restoring a notebook puts back the '
      'original deleted_at', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Restaurar'));
    await _settle(tester);
    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    expect(await _notebookDeletedAt(tester, _n1), _day2);
    expect(find.byType(JotUndoToast), findsNothing);
    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('TRASH-09: "Desfazer" after restoring a page puts back the '
      'original deleted_at', (tester) async {
    await _open(tester, trashNotebook: false);

    await tester.tap(find.text('Restaurar'));
    await _settle(tester);
    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    expect(await _pageDeletedAt(tester, _pages[1]), _day1);
    await _close(tester);
  });

  testWidgets('TRASH-11: each section is ordered by deleted_at, then id, '
      'descending', (tester) async {
    late String n2;
    late String n3;
    await _open(
      tester,
      seed: () async {
        n2 = await _app.notebooks.create(
          title: 'Mais recente',
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
        n3 = await _app.notebooks.create(
          title: 'Mesmo instante',
          cover: CoverPattern.lisa,
          color: NotebookColor.musgo,
        );
        _app.clock.current = DateTime.utc(2026, 10, 12, 10);
        await _app.notebooks.moveToTrash(n2);
        await _app.notebooks.moveToTrash(n3);
      },
    );

    final dys = {
      for (final t in ['Viagem a Lisboa', 'Mais recente', 'Mesmo instante'])
        t: tester.getTopLeft(find.text(t)).dy,
    };
    expect(n3.compareTo(n2), greaterThan(0));
    expect(dys['Mesmo instante'], lessThan(dys['Mais recente']!));
    expect(dys['Mais recente'], lessThan(dys['Viagem a Lisboa']!));
    await _close(tester);
  });

  testWidgets('TRASH-12: the trash offers no "empty trash" action', (
    tester,
  ) async {
    await _open(tester);

    expect(find.textContaining('Esvaziar'), findsNothing);
    expect(find.textContaining('Excluir'), findsNothing);
    expect(find.byType(JotButton), findsOneWidget);
    await _close(tester);
  });
}
