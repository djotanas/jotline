import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_text_input_dialog.dart';
import 'package:jotline/core/theme/jot_colors.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

class _Outcome {
  bool resolved = false;
  String? value;
}

Future<_Outcome> _open(
  WidgetTester tester, {
  String initialValue = 'Viagem a Lisboa',
  bool allowEmpty = false,
  String? hintText = 'Nome do caderno',
}) async {
  final outcome = _Outcome();
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () async {
              outcome
                ..value = await showTextInputDialog(
                  context,
                  title: 'Renomear caderno',
                  label: 'Nome',
                  initialValue: initialValue,
                  hintText: hintText,
                  allowEmpty: allowEmpty,
                )
                ..resolved = true;
            },
            child: const SizedBox.square(dimension: 44, child: Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return outcome;
}

DecoratedBox _saveBox(WidgetTester tester) => tester.widget<DecoratedBox>(
  find
      .ancestor(of: find.text('Salvar'), matching: find.byType(DecoratedBox))
      .first,
);

void main() {
  testWidgets('NBOPT-03: the title is shown and the field is prefilled', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Renomear caderno'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Viagem a Lisboa',
    );
  });

  testWidgets('NBOPT-04: Salvar is disabled on blank text unless allowEmpty', (
    tester,
  ) async {
    final outcome = await _open(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(
      (_saveBox(tester).decoration as BoxDecoration).color,
      _colors.lineBase,
    );
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('Salvar'))
          .text
          .style!
          .color,
      _colors.inkFeito,
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(outcome.resolved, isFalse);
    expect(find.byType(JotTextInputDialog), findsOneWidget);
  });

  testWidgets('PGOPT-03: Salvar is enabled on blank text when allowEmpty', (
    tester,
  ) async {
    final outcome = await _open(tester, allowEmpty: true);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(
      (_saveBox(tester).decoration as BoxDecoration).color,
      _colors.accent,
    );

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(outcome.resolved, isTrue);
    expect(outcome.value, '');
  });

  testWidgets('NBOPT-03: Salvar returns the typed text', (tester) async {
    final outcome = await _open(tester);

    await tester.enterText(find.byType(TextField), 'Lisboa 2026');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(outcome.value, 'Lisboa 2026');
    expect(find.byType(JotTextInputDialog), findsNothing);
  });

  testWidgets('NBOPT-03: Cancelar returns null', (tester) async {
    final outcome = await _open(tester);

    await tester.enterText(find.byType(TextField), 'Outro');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(outcome.resolved, isTrue);
    expect(outcome.value, isNull);
    expect(find.byType(JotTextInputDialog), findsNothing);
  });

  testWidgets('NBOPT-05: limit 50 with the counter from 40', (tester) async {
    await _open(tester, initialValue: '');

    await tester.enterText(find.byType(TextField), 'a' * 39);
    await tester.pump();
    expect(find.textContaining('/50'), findsNothing);

    await tester.enterText(find.byType(TextField), 'a' * 40);
    await tester.pump();
    expect(find.text('40/50'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a' * 51);
    await tester.pump();
    expect(find.text('50/50'), findsOneWidget);
  });

  testWidgets('PGOPT-02: the field is focused and shows the hint', (
    tester,
  ) async {
    await _open(tester, initialValue: '', hintText: 'Sem título');

    expect(find.text('Sem título'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });
}
