import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/jot_badge.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

void main() {
  testWidgets('PGLIST-04: shows the text on bgTrilho in inkCorpo', (
    tester,
  ) async {
    await tester.pumpJot(const Center(child: JotBadge('Arquivado')));

    expect(find.text('Arquivado'), findsOneWidget);
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(JotBadge),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, _colors.bgTrilho);
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rSelo));
    final style = tester
        .renderObject<RenderParagraph>(find.text('Arquivado'))
        .text
        .style!;
    expect(style.color, _colors.inkCorpo);
    expect(style.fontSize, 12);
    expect(style.fontWeight, FontWeight.w500);
  });
}
