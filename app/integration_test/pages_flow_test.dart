import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';

import 'helpers/flows.dart';
import 'helpers/no_network.dart';

Finder get _handles => find.byWidgetPredicate(
  (w) => w is JotIcon && w.glyph == JotIconGlyph.dragHandle,
);

List<String> _visibleOrder(WidgetTester tester, List<String> titles) {
  final ordered = [...titles]
    ..sort(
      (a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );
  return ordered;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(forbidNetwork);

  testWidgets('RF-02: create, rename inline and reorder pages, then reopen '
      'the notebook with the order kept, with no network', (tester) async {
    final app = await pumpJotlineWithoutNetwork(tester);
    await createNotebook(tester, 'Diário');

    for (final title in ['A', 'B', 'C']) {
      await createPage(tester, title, 'Diário');
    }
    expect(find.text('3 páginas'), findsOneWidget);
    expect(_visibleOrder(tester, ['A', 'B', 'C']), ['A', 'B', 'C']);

    await tapAndSettle(tester, find.text('B'));
    await tester.enterText(
      find.descendant(
        of: find.byType(PageScreen),
        matching: find.byType(TextField),
      ),
      'B renomeada',
    );
    await tester.pump(const Duration(milliseconds: 600));
    await backFromPage(tester, 'Diário');
    expect(find.text('B renomeada'), findsOneWidget);
    final titles = (await app.db.select(app.db.pages).get()).map(
      (p) => p.title,
    );
    expect(titles, containsAll(['A', 'B renomeada', 'C']));

    await tapAndSettle(tester, find.text('Reordenar'));
    final gesture = await tester.startGesture(tester.getCenter(_handles.last));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await settle(tester);
    await tapAndSettle(tester, find.text('Concluir'));
    expect(_visibleOrder(tester, ['A', 'B renomeada', 'C']), [
      'C',
      'A',
      'B renomeada',
    ]);

    await backFromNotebook(tester);
    await tapAndSettle(tester, find.text('Diário').first);
    expect(_visibleOrder(tester, ['A', 'B renomeada', 'C']), [
      'C',
      'A',
      'B renomeada',
    ]);
  });
}
