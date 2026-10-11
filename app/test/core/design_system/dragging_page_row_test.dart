import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/dragging_page_row.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

Future<void> _pump(
  WidgetTester tester, {
  String title = 'Roteiro — dia 2',
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(width: 320, child: DraggingPageRow(title: title)),
      ),
    ),
  );
}

void main() {
  testWidgets('COMP-09: handle has the semantic label "Mover <title>"', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final label = find.bySemanticsLabel('Mover Roteiro — dia 2');
    expect(label, findsOneWidget);
    expect(tester.getSize(label), const Size(44, 44));
    expect(
      find.descendant(of: label, matching: find.byType(JotIcon)),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('COMP-09: handle is the 18 px drag glyph in ink2', (
    tester,
  ) async {
    await _pump(tester);

    final icon = tester.widget<JotIcon>(find.byType(JotIcon));
    expect(icon.glyph, JotIconGlyph.dragHandle);
    expect(tester.getSize(find.byType(JotIcon)), const Size(18, 18));
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

  testWidgets('COMP-09: title uses itemTitulo', (tester) async {
    await _pump(tester);

    final style = tester
        .renderObject<RenderParagraph>(find.text('Roteiro — dia 2'))
        .text
        .style!;
    expect(style.fontSize, 16);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, _colors.ink1);
  });

  testWidgets('COMP-09: row uses shadowErguido on bgFolha with a lineBase '
      'border, rCard, tilted -0.6 degrees', (tester) async {
    await _pump(tester);

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(DraggingPageRow),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.boxShadow, JotShadows.light.erguido);
    expect(decoration.color, _colors.bgFolha);
    expect(decoration.border, Border.all(color: _colors.lineBase));
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rCard));

    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(DraggingPageRow),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform, Matrix4.rotationZ(-0.6 * math.pi / 180));
  });

  testWidgets('edge case: long title ellipsizes', (tester) async {
    const long = 'Um título de página muito comprido que não cabe na linha';
    await _pump(tester, title: long);

    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(long));
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
