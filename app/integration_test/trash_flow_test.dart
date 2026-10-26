import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';

import 'helpers/flows.dart';
import 'helpers/no_network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(forbidNetwork);

  testWidgets('RF-12: delete a page (undo once, then let it expire) and the '
      'notebook, then restore both from the trash, with no network', (
    tester,
  ) async {
    final app = await pumpJotlineWithoutNetwork(tester);
    await createNotebook(tester, 'Viagem');
    await createPage(tester, 'P1', 'Viagem');
    await createPage(tester, 'P2', 'Viagem');

    await tapAndSettle(tester, find.text('P1'));
    await pageOption(tester, 'Excluir página');
    expect(find.text('Página movida para a lixeira'), findsOneWidget);
    await tapAndSettle(tester, find.text('Desfazer'));
    expect(find.text('P1'), findsOneWidget);
    var pages = await app.db.select(app.db.pages).get();
    expect(pages.every((p) => p.deletedAt == null), isTrue);

    await tapAndSettle(tester, find.text('P2'));
    await pageOption(tester, 'Excluir página');
    await tester.pump(JotUndoToast.duration);
    await settle(tester);
    expect(find.text('Página movida para a lixeira'), findsNothing);
    expect(find.text('P2'), findsNothing);
    pages = await app.db.select(app.db.pages).get();
    expect(pages.singleWhere((p) => p.title == 'P2').deletedAt, isNotNull);

    await notebookOption(tester, 'Excluir caderno');
    await tapAndSettle(tester, find.text('Mover para a lixeira'));
    expect(find.text('Caderno movido para a lixeira'), findsOneWidget);
    await tester.pump(JotUndoToast.duration);
    await settle(tester);
    expect(
      (await app.db.select(app.db.notebooks).get()).single.deletedAt,
      isNotNull,
    );

    await tapAndSettle(tester, iconButton('Lixeira'));
    expect(find.text('Viagem'), findsOneWidget);
    expect(find.text('P2'), findsNothing);
    await tapAndSettle(tester, find.text('Restaurar'));
    expect(find.text('Caderno restaurado'), findsOneWidget);
    expect(
      (await app.db.select(app.db.notebooks).get()).single.deletedAt,
      isNull,
    );

    expect(find.text('P2'), findsOneWidget);
    await tapAndSettle(tester, find.text('Restaurar'));
    expect(find.text('Restaurado em Viagem'), findsOneWidget);
    pages = await app.db.select(app.db.pages).get();
    expect(pages.every((p) => p.deletedAt == null), isTrue);
  });
}
