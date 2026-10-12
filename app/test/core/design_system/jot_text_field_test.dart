import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_text_field.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<String>? onChanged,
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: JotTextField(label: 'Nome', onChanged: onChanged),
          ),
        ),
      ),
    ),
  );
}

InputDecorator _decorator(WidgetTester tester) =>
    tester.widget<InputDecorator>(find.byType(InputDecorator));

OutlineInputBorder _activeBorder(WidgetTester tester) {
  final decorator = _decorator(tester);
  final decoration = decorator.decoration;
  return (decorator.isFocused
          ? decoration.focusedBorder
          : decoration.enabledBorder)!
      as OutlineInputBorder;
}

Future<TextEditingController> _pumpLimited(
  WidgetTester tester, {
  int maxLength = 50,
  int counterFrom = 40,
  String? hintText,
  String? helperText,
}) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);
  await tester.pumpJot(
    Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: JotTextField(
            label: 'Nome',
            controller: controller,
            maxLength: maxLength,
            counterFrom: counterFrom,
            hintText: hintText,
            helperText: helperText,
          ),
        ),
      ),
    ),
  );
  return controller;
}

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  testWidgets('NBNEW-04: the counter is hidden at 39 and shown at 40', (
    tester,
  ) async {
    await _pumpLimited(tester);

    await tester.enterText(find.byType(TextField), 'a' * 39);
    await tester.pump();
    expect(find.text('39/50'), findsNothing);
    expect(find.textContaining('/50'), findsNothing);

    await tester.enterText(find.byType(TextField), 'a' * 40);
    await tester.pump();
    expect(find.text('40/50'), findsOneWidget);
  });

  testWidgets('NBNEW-04: the counter sits on the label row, to its right', (
    tester,
  ) async {
    await _pumpLimited(tester);
    await tester.enterText(find.byType(TextField), 'a' * 45);
    await tester.pump();

    final label = tester.getRect(find.text('Nome'));
    final counter = tester.getRect(find.text('45/50'));
    expect(counter.left, greaterThan(label.right));
    expect(counter.center.dy, moreOrLessEquals(label.center.dy, epsilon: 4));
    final style = _styleOf(tester, '45/50');
    expect(style.fontFamily, JotTextStyles.fontMeta);
    expect(style.color, _colors.ink2);
  });

  testWidgets('NBNEW-05: 50 characters are accepted and the 51st is blocked', (
    tester,
  ) async {
    final controller = await _pumpLimited(tester);

    await tester.enterText(find.byType(TextField), 'a' * 50);
    await tester.pump();
    expect(controller.text.length, 50);

    await tester.enterText(find.byType(TextField), 'a' * 51);
    await tester.pump();
    expect(controller.text, 'a' * 50);
  });

  testWidgets('NBNEW-05: the counter is danger at 50 and not before', (
    tester,
  ) async {
    await _pumpLimited(tester);

    await tester.enterText(find.byType(TextField), 'a' * 49);
    await tester.pump();
    expect(_styleOf(tester, '49/50').color, _colors.ink2);

    await tester.enterText(find.byType(TextField), 'a' * 50);
    await tester.pump();
    final style = _styleOf(tester, '50/50');
    expect(style.color, _colors.danger);
    expect(style.fontWeight, FontWeight.w500);
  });

  testWidgets('EDGE-07: 50 skin-tone emoji clusters are accepted', (
    tester,
  ) async {
    final controller = await _pumpLimited(tester);
    const thumb = '\u{1F44D}\u{1F3FD}';

    await tester.enterText(find.byType(TextField), thumb * 50);
    await tester.pump();
    expect(controller.text, thumb * 50);
    expect(find.text('50/50'), findsOneWidget);

    await tester.enterText(find.byType(TextField), thumb * 51);
    await tester.pump();
    expect(controller.text, thumb * 50);
  });

  testWidgets('NBNEW-04: hint and helper text are shown', (tester) async {
    await _pumpLimited(
      tester,
      hintText: 'Nome do caderno',
      helperText: 'Ajuda do campo',
    );

    expect(find.text('Nome do caderno'), findsOneWidget);
    expect(find.text('Ajuda do campo'), findsOneWidget);
    expect(_styleOf(tester, 'Nome do caderno').color, _colors.inkDeco);
  });

  testWidgets('NBOPT-05: autofocus focuses the field and a focusNode is used', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpJot(
      Scaffold(
        body: JotTextField(label: 'Nome', autofocus: true, focusNode: node),
      ),
    );
    await tester.pump();

    expect(node.hasFocus, isTrue);
  });

  testWidgets('NBNEW-04: without maxLength no counter and no limit', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpJot(
      Scaffold(
        body: JotTextField(label: 'Nome', controller: controller),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a' * 80);
    await tester.pump();

    expect(controller.text.length, 80);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('NBNEW-04: the counter works without an external controller', (
    tester,
  ) async {
    await tester.pumpJot(
      const Scaffold(
        body: JotTextField(label: 'Nome', maxLength: 50, counterFrom: 40),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a' * 41);
    await tester.pump();

    expect(find.text('41/50'), findsOneWidget);
  });
  testWidgets('COMP-06: shows the label in the rotulo style', (tester) async {
    await _pump(tester);

    expect(find.text('Nome'), findsOneWidget);
    final style = tester
        .renderObject<RenderParagraph>(find.text('Nome'))
        .text
        .style!;
    expect(style.fontSize, 13);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, _colors.ink2);
  });

  testWidgets('COMP-06: unfocused border is lineForte with rCampo', (
    tester,
  ) async {
    await _pump(tester);

    expect(_decorator(tester).isFocused, isFalse);
    final border = _activeBorder(tester);
    expect(border.borderSide.color, _colors.lineForte);
    expect(border.borderRadius, BorderRadius.circular(JotRadius.rCampo));
  });

  testWidgets('COMP-06: focused border is accent and distinct from '
      'unfocused', (tester) async {
    await _pump(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(_decorator(tester).isFocused, isTrue);
    final border = _activeBorder(tester);
    expect(border.borderSide.color, _colors.accent);
    expect(border.borderRadius, BorderRadius.circular(JotRadius.rCampo));
  });

  testWidgets('COMP-06: onChanged receives the typed text', (tester) async {
    final values = <String>[];
    await _pump(tester, onChanged: values.add);

    await tester.enterText(find.byType(TextField), 'Receitas');

    expect(values.last, 'Receitas');
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
