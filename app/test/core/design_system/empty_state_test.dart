import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/empty_state.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_colors.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

Future<void> _pump(WidgetTester tester, {double textScale = 1}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const Center(
        child: SizedBox(
          width: 320,
          child: EmptyState(
            icon: JotIconGlyph.trash,
            title: 'A lixeira está vazia',
            message: 'Tudo foi restaurado.',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('COMP-11: icon is 40 px with stroke 1.4 in ink2', (tester) async {
    await _pump(tester);

    expect(tester.getSize(find.byType(JotIcon)), const Size(40, 40));
    final icon = tester.widget<JotIcon>(find.byType(JotIcon));
    expect(icon.glyph, JotIconGlyph.trash);
    expect(icon.strokeWidth, 1.4);
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
  });

  testWidgets('COMP-11: title is UI 16/600 in ink1', (tester) async {
    await _pump(tester);

    final style = tester
        .renderObject<RenderParagraph>(find.text('A lixeira está vazia'))
        .text
        .style!;
    expect(style.fontSize, 16);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, _colors.ink1);
  });

  testWidgets('COMP-11: shows the support sentence', (tester) async {
    await _pump(tester);

    expect(find.text('Tudo foi restaurado.'), findsOneWidget);
  });

  testWidgets('COMP-11: has no call-to-action button', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(
      find.descendant(
        of: find.byType(EmptyState),
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector || w is InkWell || w is ButtonStyleButton,
        ),
      ),
      findsNothing,
    );
    expect(find.bySemanticsLabel('A lixeira está vazia'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('A lixeira está vazia')),
      isSemantics(isButton: false, hasTapAction: false),
    );
    handle.dispose();
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
