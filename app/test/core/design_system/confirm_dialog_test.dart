import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/confirm_dialog.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;
const _title = 'Excluir “Viagem a Lisboa”?';
const _message =
    'O caderno vai para a lixeira deste aparelho, com as páginas. '
    'Dá para restaurá-lo de lá.';

Future<void> _open(
  WidgetTester tester, {
  String title = _title,
  List<bool>? results,
}) async {
  await tester.pumpJot(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () async {
              final result = await showConfirmDialog(
                context,
                title: title,
                message: _message,
                confirmLabel: 'Mover para a lixeira',
              );
              results?.add(result);
            },
            child: const SizedBox.square(dimension: 44, child: Text('open')),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder get _dialog => find.byType(ConfirmDialog);

void main() {
  testWidgets('COMP-13: confirming returns true', (tester) async {
    final results = <bool>[];
    await _open(tester, results: results);

    await tester.tap(find.text('Mover para a lixeira'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(_dialog, findsNothing);
  });

  testWidgets('COMP-13: "Cancelar" from l10n returns false', (tester) async {
    final results = <bool>[];
    await _open(tester, results: results);

    final cancel = find.descendant(
      of: find.byType(JotButton),
      matching: find.text('Cancelar'),
    );
    expect(cancel, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(cancel).text.style!.color,
      _colors.accent,
    );
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(_dialog, findsNothing);
  });

  testWidgets('COMP-13: dismissing by the barrier returns false', (
    tester,
  ) async {
    final results = <bool>[];
    await _open(tester, results: results);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(results, [false]);
  });

  testWidgets('COMP-13: confirm is the destructive action, above Cancelar', (
    tester,
  ) async {
    await _open(tester);

    final confirm = find.ancestor(
      of: find.text('Mover para a lixeira'),
      matching: find.byType(JotButton),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: confirm, matching: find.byType(DecoratedBox)),
    );
    expect((box.decoration as BoxDecoration).color, _colors.danger);
    expect(
      tester.getTopLeft(find.text('Cancelar')).dy,
      greaterThan(tester.getBottomLeft(confirm).dy),
    );
  });

  testWidgets('COMP-13: dialog has radius 24, shadowErguido and bgMesa', (
    tester,
  ) async {
    await _open(tester);

    final box = tester.widget<DecoratedBox>(
      find.descendant(of: _dialog, matching: find.byType(DecoratedBox)).first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rSheet));
    expect(decoration.boxShadow, JotShadows.light.erguido);
    expect(decoration.color, _colors.bgMesa);
  });

  testWidgets('COMP-13: shown over bgVeu', (tester) async {
    await _open(tester);

    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(barrier.color, _colors.bgVeu);
  });

  testWidgets('COMP-13: title uses blocoTitulo and message is inkCorpo', (
    tester,
  ) async {
    await _open(tester);

    final title = tester
        .renderObject<RenderParagraph>(find.text(_title))
        .text
        .style!;
    expect(title.fontSize, 19);
    expect(title.fontWeight, FontWeight.w600);
    expect(title.color, _colors.ink1);
    final message = tester
        .renderObject<RenderParagraph>(find.text(_message))
        .text
        .style!;
    expect(message.fontSize, 15);
    expect(message.height, 1.45);
    expect(message.color, _colors.inkCorpo);
  });

  testWidgets('COMP-13: exposed as an alert dialog named by its title', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester);

    final node = tester.getSemantics(
      find.descendant(of: _dialog, matching: find.byType(DecoratedBox)).first,
    );
    final data = node.getSemanticsData();
    expect(data.role, SemanticsRole.alertDialog);
    expect(data.flagsCollection.scopesRoute, isTrue);
    expect(data.flagsCollection.namesRoute, isTrue);
    expect(data.label, _title);
    handle.dispose();
  });

  testWidgets('edge case: long title ellipsizes', (tester) async {
    const long =
        'Excluir “Um caderno com um nome muito, muito comprido que não cabe '
        'no diálogo de confirmação de jeito nenhum”?';
    await _open(tester, title: long);

    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(long));
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester);

    expect(
      MediaQuery.textScalerOf(tester.element(find.text(_title))).scale(10),
      20,
    );
    expect(tester.takeException(), isNull);
  });
}
