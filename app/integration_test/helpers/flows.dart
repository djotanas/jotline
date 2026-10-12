import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_fab.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/features/notebooks/presentation/notebook_screen.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';

import 'no_network.dart';

Finder iconButton(String label) => find.byWidgetPredicate(
  (w) => w is JotIconButton && w.semanticLabel == label,
);

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await settle(tester);
}

Future<void> createNotebook(WidgetTester tester, String name) async {
  await tapAndSettle(tester, find.widgetWithText(JotFab, 'Novo caderno'));
  await tester.enterText(find.byType(TextField), name);
  await tester.pump();
  await tapAndSettle(tester, find.text('Criar caderno'));
}

Future<void> backFromNotebook(WidgetTester tester) => tapAndSettle(
  tester,
  find.descendant(
    of: find.byType(NotebookScreen),
    matching: find.text('Cadernos'),
  ),
);

Future<void> backFromPage(WidgetTester tester, String notebookTitle) =>
    tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(PageScreen),
        matching: find.text(notebookTitle),
      ),
    );

Future<void> createPage(
  WidgetTester tester,
  String title,
  String notebookTitle,
) async {
  await tapAndSettle(tester, find.widgetWithText(JotFab, 'Nova página'));
  await tester.enterText(
    find.descendant(
      of: find.byType(PageScreen),
      matching: find.byType(TextField),
    ),
    title,
  );
  await tester.pump(const Duration(milliseconds: 600));
  await backFromPage(tester, notebookTitle);
}

Future<void> notebookOption(WidgetTester tester, String label) async {
  await tapAndSettle(tester, iconButton('Opções do caderno'));
  await tapAndSettle(tester, find.text(label));
}

Future<void> pageOption(WidgetTester tester, String label) async {
  await tapAndSettle(tester, iconButton('Opções da página'));
  await tapAndSettle(tester, find.text(label));
}
