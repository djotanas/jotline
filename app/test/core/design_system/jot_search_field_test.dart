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
  bool autofocus = false,
  String? semanticLabel,
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
              autofocus: autofocus,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    ),
  );
}

double _hintOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text('Buscar em todas as páginas'),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

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

  testWidgets('SRCH-01: the field is focused on the first frame when '
      'autofocus is set', (tester) async {
    await _pump(tester, autofocus: true);

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('SRCH-01: the field is not focused by default', (tester) async {
    await _pump(tester);

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isFalse);
  });

  testWidgets('SRCH-01: the placeholder is shown while empty and hidden once '
      'text is typed', (tester) async {
    await _pump(tester);
    expect(find.text('Buscar em todas as páginas'), findsOneWidget);
    expect(_hintOpacity(tester), 1);

    await tester.enterText(find.byType(TextField), 'Lisboa');
    await tester.pumpAndSettle();

    expect(_hintOpacity(tester), 0);
  });

  testWidgets('SRCH-01: the semantic label names the text field', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, semanticLabel: 'Buscar em títulos e conteúdo');

    expect(
      tester.getSemantics(find.byType(TextField)).label,
      'Buscar em títulos e conteúdo\nBuscar em todas as páginas',
    );
    handle.dispose();
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
