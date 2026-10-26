import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_search_field.dart';
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
            child: JotSearchField(
              placeholder: 'Buscar em todas as páginas',
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('COMP-06: shows the search glyph in ink2 on bgTrilho', (
    tester,
  ) async {
    await _pump(tester);

    final icon = tester.widget<JotIcon>(find.byType(JotIcon));
    expect(icon.glyph, JotIconGlyph.search);
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(JotIcon),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as JotIconPainter;
    expect(painter.color, _colors.ink2);
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(JotSearchField),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, _colors.bgTrilho);
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rCampo));
  });

  testWidgets('COMP-06: shows the placeholder passed by parameter', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Buscar em todas as páginas'), findsOneWidget);
  });

  testWidgets('COMP-06: onChanged receives the typed text', (tester) async {
    final values = <String>[];
    await _pump(tester, onChanged: values.add);

    await tester.enterText(find.byType(TextField), 'Lisboa');

    expect(values.last, 'Lisboa');
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
