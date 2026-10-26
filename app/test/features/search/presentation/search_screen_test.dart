import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/jot_search_field.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';
import 'package:jotline/features/search/presentation/search_result_row.dart';
import 'package:jotline/features/search/presentation/search_screen.dart';

import '../../../helpers/pump_jot.dart';
import '../../../helpers/test_app.dart';

late TestApp _app;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, {int extraBelemPages = 0}) async {
  _app = TestApp();
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    final notebook = await _app.notebooks.create(
      title: 'Viagem a Lisboa',
      cover: CoverPattern.lisa,
      color: NotebookColor.musgo,
    );
    Future<void> write(String pageId, String text) async {
      await _app.blocks.applyChanges(pageId, [
        Insert('k', BlockType.text, BlockContent(text), const AtEnd()),
      ]);
    }

    await _app.pages.create(notebook, title: 'Onde comer em Belém');
    await write(
      await _app.pages.create(notebook, title: 'Roteiro'),
      'Belém cedo',
    );
    await write(
      await _app.pages.create(notebook, title: 'Diário'),
      'ir a Belém no mesmo dia',
    );
    await _app.pages.create(notebook, title: 'Receitas');
    for (var i = 0; i < extraBelemPages; i++) {
      await _app.pages.create(
        notebook,
        title: 'Belém ${i.toString().padLeft(2, '0')}',
      );
    }
  });
  await tester.pumpJot(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            child: const Text('home'),
          ),
        ),
      ),
    ),
    overrides: _app.overrides,
  );
  await tester.tap(find.text('home'));
  await _settle(tester);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.runAsync(_app.db.close);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(SearchScreen.debounce);
  await _settle(tester);
}

Finder get _rows => find.byType(SearchResultRow);

Finder get _countLine => find.byWidgetPredicate(
  (widget) =>
      widget is Text && RegExp(r'^\d+ páginas?$').hasMatch(widget.data ?? ''),
);

void main() {
  testWidgets('SRCH-01: opens with the field focused, the placeholder and '
      'Tudo selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    expect(find.text('Buscar em todos os cadernos'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Tudo')),
      isSemantics(isSelected: true, hasSelectedState: true),
    );
    expect(
      tester.getSemantics(find.text('Títulos')),
      isSemantics(isSelected: false, hasSelectedState: true),
    );
    expect(find.byType(JotSearchField), findsOneWidget);
    await _close(tester);
    semantics.dispose();
  });

  testWidgets('SRCH-02: shows the empty state and no count while the term is '
      'empty', (tester) async {
    await _open(tester);

    expect(find.text('Busque em todos os cadernos'), findsOneWidget);
    expect(_countLine, findsNothing);
    await _type(tester, '   ');
    expect(find.text('Busque em todos os cadernos'), findsOneWidget);
    expect(_rows, findsNothing);
    await _close(tester);
  });

  testWidgets('SRCH-03: nothing at 149 ms and the results at 150 ms', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'bele');
    await tester.pump(const Duration(milliseconds: 149));
    await _settleWithoutAdvancing(tester);
    expect(_rows, findsNothing);
    expect(find.text('Busque em todos os cadernos'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await _settle(tester);
    expect(_rows, findsNWidgets(3));
    await _close(tester);
  });

  testWidgets('SRCH-03: a keystroke inside the window restarts the 150 ms', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'bel');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'bele');
    await tester.pump(const Duration(milliseconds: 100));
    await _settleWithoutAdvancing(tester);
    expect(_rows, findsNothing);

    await tester.pump(const Duration(milliseconds: 50));
    await _settle(tester);
    expect(_rows, findsNWidgets(3));
    await _close(tester);
  });

  testWidgets('SRCH-03: the count line says "3 páginas" and "1 página"', (
    tester,
  ) async {
    await _open(tester);

    await _type(tester, 'bele');
    expect(find.text('3 páginas'), findsOneWidget);

    await _type(tester, 'roteiro');
    expect(find.text('1 página'), findsOneWidget);
    expect(_rows, findsOneWidget);
    await _close(tester);
  });

  testWidgets('SRCH-06/SRCH-07: switching the segment filters the '
      'results', (tester) async {
    await _open(tester);
    await _type(tester, 'bele');

    await tester.tap(find.text('Títulos'));
    await _settle(tester);
    expect(find.text('1 página'), findsOneWidget);
    expect(_rows, findsOneWidget);

    await tester.tap(find.text('Conteúdo'));
    await _settle(tester);
    expect(find.text('2 páginas'), findsOneWidget);
    expect(_rows, findsNWidgets(2));

    await tester.tap(find.text('Tudo'));
    await _settle(tester);
    expect(find.text('3 páginas'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('SRCH-15: shows "Nenhuma página encontrada" with the term '
      'quoted', (tester) async {
    await _open(tester);

    await _type(tester, 'passaporte');

    expect(find.text('Nenhuma página encontrada'), findsOneWidget);
    expect(
      find.text(
        'Nada com “passaporte” em títulos ou conteúdo. '
        'Confira a grafia ou tente outro termo.',
      ),
      findsOneWidget,
    );
    expect(_rows, findsNothing);
    expect(_countLine, findsNothing);
    await _close(tester);
  });

  testWidgets('SRCH-16: tapping a result opens the page and going back '
      'keeps the term, segment and scroll offset', (tester) async {
    await _open(tester, extraBelemPages: 12);
    await _type(tester, 'bel');
    await tester.tap(find.text('Títulos'));
    await _settle(tester);
    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -300));
    await _settle(tester);
    final offset = tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position
        .pixels;
    expect(offset, greaterThan(0));

    await tester.tap(_rows.first);
    await _settle(tester);
    expect(find.byType(PageScreen), findsOneWidget);

    await tester.tap(find.text('Viagem a Lisboa').last);
    await _settle(tester);

    expect(find.byType(PageScreen), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'bel',
    );
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position
          .pixels,
      offset,
    );
    expect(find.text('13 páginas'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('SRCH-17: Cancelar returns to the previous screen', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(find.widgetWithText(JotButton, 'Cancelar'));
    await _settle(tester);

    expect(find.byType(SearchScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('EDGE-05: Cancelar while the results load shows no error', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'bele');
    await tester.pump(SearchScreen.debounce);
    await tester.tap(find.widgetWithText(JotButton, 'Cancelar'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(SearchScreen), findsNothing);
    await _close(tester);
  });

  testWidgets('EDGE-05: Cancelar inside the debounce window shows no error', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), 'bele');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(JotButton, 'Cancelar'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(SearchScreen), findsNothing);
    await _close(tester);
  });
}

Future<void> _settleWithoutAdvancing(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
}
