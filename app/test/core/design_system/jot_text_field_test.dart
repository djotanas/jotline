import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_text_field.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

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

void main() {
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
