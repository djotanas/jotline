import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jotline/features/notebooks/presentation/notebook_screen.dart';

import 'helpers/flows.dart';
import 'helpers/no_network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(forbidNetwork);

  testWidgets('RF-01: create, rename, archive and delete a notebook with no '
      'network', (tester) async {
    final app = await pumpJotlineWithoutNetwork(tester);
    expect(find.text('Nenhum caderno ainda'), findsOneWidget);

    await createNotebook(tester, 'Receitas');
    expect(find.byType(NotebookScreen), findsOneWidget);
    expect(find.text('Receitas'), findsWidgets);
    var rows = await app.db.select(app.db.notebooks).get();
    expect(rows.map((n) => n.title), ['Receitas']);

    await notebookOption(tester, 'Renomear');
    await tester.enterText(find.byType(TextField), 'Receitas de família');
    await tester.pump();
    await tapAndSettle(tester, find.text('Salvar'));
    rows = await app.db.select(app.db.notebooks).get();
    expect(rows.single.title, 'Receitas de família');

    await notebookOption(tester, 'Arquivar');
    expect(find.byType(NotebookScreen), findsNothing);
    expect(find.text('Caderno arquivado'), findsOneWidget);
    var members = await app.db.select(app.db.notebookMembers).get();
    expect(members.single.archivedAt, isNotNull);
    expect(
      (await app.db.select(app.db.notebooks).get()).single.deletedAt,
      isNull,
    );

    await tapAndSettle(tester, find.textContaining('Arquivados'));
    await tapAndSettle(tester, find.text('Desarquivar').last);
    members = await app.db.select(app.db.notebookMembers).get();
    expect(members.single.archivedAt, isNull);

    await tapAndSettle(tester, find.text('Receitas de família').first);
    await notebookOption(tester, 'Excluir caderno');
    await tapAndSettle(tester, find.text('Mover para a lixeira'));
    expect(find.text('Caderno movido para a lixeira'), findsOneWidget);
    final deleted = (await app.db.select(app.db.notebooks).get()).single;
    expect(deleted.deletedAt, isNotNull);
    expect(find.text('Nenhum caderno ainda'), findsOneWidget);
  });
}
