import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotline/core/design_system/jot_fab.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';
import 'package:jotline/features/search/presentation/search_result_row.dart';
import 'package:jotline/features/search/presentation/search_screen.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import 'helpers/flows.dart';
import 'helpers/no_network.dart';

Finder get _rows => find.byType(SearchResultRow);

Future<void> _search(WidgetTester tester, String term) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(SearchScreen),
      matching: find.byType(TextField),
    ),
    term,
  );
  await tester.pump(SearchScreen.debounce);
  await settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    forbidNetwork();
    BlinkController.indeterminateAnimationsEnabled = false;
    addTearDown(() => BlinkController.indeterminateAnimationsEnabled = true);
  });

  testWidgets('RF-05: search by title and content across notebooks, archived '
      'included, open a result and come back, filter by title, and drop a '
      'trashed page, with no network', (tester) async {
    final db = await pumpJotlineWithoutNetwork(tester);
    await createNotebook(tester, 'Arquivo');
    await createPage(tester, 'Onde comer em Belém', 'Arquivo');
    await notebookOption(tester, 'Arquivar');

    await createNotebook(tester, 'Viagens');
    await tapAndSettle(tester, find.widgetWithText(JotFab, 'Nova página'));
    await tester.enterText(
      find.descendant(
        of: find.byType(PageScreen),
        matching: find.byType(TextField),
      ),
      'Roteiro',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle(tester);
    await tester.typeImeText('Belém cedo');
    await backFromPage(tester, 'Viagens');
    await backFromNotebook(tester);

    await tapAndSettle(tester, iconButton('Buscar'));
    await _search(tester, 'bele');
    expect(find.text('2 páginas'), findsOneWidget);
    expect(_rows, findsNWidgets(2));
    expect(
      find.descendant(of: _rows, matching: find.text('Roteiro')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _rows, matching: find.text('Arquivo')),
      findsOneWidget,
    );

    await tapAndSettle(
      tester,
      find.descendant(of: _rows, matching: find.text('Roteiro')),
    );
    expect(find.byType(PageScreen), findsOneWidget);
    await backFromPage(tester, 'Viagens');
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('bele'), findsOneWidget);
    expect(find.text('2 páginas'), findsOneWidget);
    expect(_rows, findsNWidgets(2));

    await tapAndSettle(tester, find.text('Títulos'));
    expect(find.text('1 página'), findsOneWidget);
    expect(_rows, findsOneWidget);
    expect(
      find.descendant(of: _rows, matching: find.text('Arquivo')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _rows, matching: find.text('Roteiro')),
      findsNothing,
    );

    await tapAndSettle(tester, find.text('Tudo'));
    expect(_rows, findsNWidgets(2));
    await tapAndSettle(
      tester,
      find.descendant(of: _rows, matching: find.text('Roteiro')),
    );
    await pageOption(tester, 'Excluir página');
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('1 página'), findsOneWidget);
    expect(_rows, findsOneWidget);
    final trashed = (await db.select(db.pages).get()).where(
      (p) => p.deletedAt != null,
    );
    expect(trashed.map((p) => p.title), ['Roteiro']);
  });
}
