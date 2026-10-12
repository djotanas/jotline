import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_text_field.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/pages/presentation/page_outcome.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';

import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

class _Launch {
  bool popped = false;
  Object? outcome;
}

late TestApp _app;
late String _notebookId;
late String _pageId;
late _Launch _launch;

Future<void> _open(
  WidgetTester tester, {
  String title = 'Roteiro',
  bool autofocus = false,
}) async {
  _app = TestApp();
  _launch = _Launch();
  await tester.runAsync(() async {
    _notebookId = await _app.notebooks.create(
      title: 'Viagem a Lisboa',
      cover: CoverPattern.lisa,
      color: NotebookColor.musgo,
    );
    _pageId = await _app.pages.create(_notebookId, title: title);
  });
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
    overrides: _app.overrides,
  );
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
}
