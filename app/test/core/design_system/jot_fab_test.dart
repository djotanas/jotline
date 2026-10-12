import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_fab.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

Future<void> _pumpFab(WidgetTester tester, VoidCallback onPressed) {
  return tester.pumpJot(
    Center(
      child: JotFab(
        icon: JotIconGlyph.add,
        label: 'Nova página',
        onPressed: onPressed,
      ),
    ),
  );
}

void main() {
  testWidgets('COMP-01: FAB is at least 44 high and uses accent, rFab and '
      'shadowFab', (tester) async {
    await _pumpFab(tester, () {});

    final size = tester.getSize(find.byType(JotFab));
    expect(size.height, greaterThanOrEqualTo(56));
    expect(size.width, greaterThanOrEqualTo(44));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(JotFab),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, _colors.accent);
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rFab));
    expect(decoration.boxShadow, JotShadows.light.fab);
  });

  testWidgets('COMP-01: FAB shows the icon and label in bgFolha', (
    tester,
  ) async {
    await _pumpFab(tester, () {});

    final icon = tester.widget<JotIcon>(find.byType(JotIcon));
    expect(icon.glyph, JotIconGlyph.add);
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
    expect(painter.color, _colors.bgFolha);
    final label = tester
        .renderObject<RenderParagraph>(find.text('Nova página'))
        .text
        .style!;
    expect(label.color, _colors.bgFolha);
    expect(label.fontSize, 16);
    expect(label.fontWeight, FontWeight.w600);
  });

  testWidgets('COMP-03: FAB is always enabled and tapping calls back', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await _pumpFab(tester, () => taps++);

    expect(
      tester.getSemantics(find.byType(JotFab)),
      matchesSemantics(
        label: 'Nova página',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(JotFab));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await tester.pumpJot(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Center(
          child: SizedBox(
            width: 320,
            child: JotFab(
              icon: JotIconGlyph.add,
              label: 'Nova página no caderno',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
