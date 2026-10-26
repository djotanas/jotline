import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/theme/jot_colors.dart';

import '../../helpers/pump_jot.dart';

Future<void> _pump(WidgetTester tester, VoidCallback? onPressed) {
  return tester.pumpJot(
    Center(
      child: JotIconButton(
        icon: JotIconGlyph.search,
        semanticLabel: 'Buscar',
        onPressed: onPressed,
      ),
    ),
  );
}

void main() {
  testWidgets('COMP-01: icon button is 44 x 44 with a 22 px ink1 icon', (
    tester,
  ) async {
    await _pump(tester, () {});

    expect(tester.getSize(find.byType(JotIconButton)), const Size(44, 44));
    expect(tester.getSize(find.byType(JotIcon)), const Size(22, 22));
    expect(
      tester.widget<JotIcon>(find.byType(JotIcon)).glyph,
      JotIconGlyph.search,
    );
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
    expect(painter.color, JotColors.light.ink1);
  });

  testWidgets('COMP-03, DRAW-09: icon button with a callback is enabled and '
      'tapping calls back', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await _pump(tester, () => taps++);

    expect(
      tester.getSemantics(find.byType(JotIconButton)),
      matchesSemantics(
        label: 'Buscar',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(JotIconButton));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('DRAW-09: icon button with no callback is disabled and drawn '
      'in inkDeco', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, null);

    expect(
      tester.getSemantics(find.byType(JotIconButton)),
      matchesSemantics(label: 'Buscar', isButton: true, hasEnabledState: true),
    );
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
    expect(painter.color, JotColors.light.inkDeco);
    handle.dispose();
  });

  testWidgets('COMP-04: semantic label is exposed to accessibility', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await _pump(tester, () => taps++);

    expect(find.bySemanticsLabel('Buscar'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Buscar'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await tester.pumpJot(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Center(
          child: JotIconButton(
            icon: JotIconGlyph.more,
            semanticLabel: 'Opções',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(JotIconButton)), const Size(44, 44));
  });
}
