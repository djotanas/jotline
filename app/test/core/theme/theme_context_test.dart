import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';
import 'package:jotline/core/theme/theme_context.dart';

import '../../helpers/pump_jot.dart';

void main() {
  testWidgets('THEME-07: context accessors resolve the theme tokens', (
    tester,
  ) async {
    late JotColors colors;
    late JotTextStyles textStyles;
    late JotShadows shadows;

    await tester.pumpJot(
      Builder(
        builder: (context) {
          colors = context.colors;
          textStyles = context.textStyles;
          shadows = context.shadows;
          return const SizedBox();
        },
      ),
    );

    expect(colors, JotColors.light);
    expect(textStyles.tituloTela.fontSize, 34);
    expect(textStyles.tituloTela.color, JotColors.light.ink1);
    expect(shadows.capa, hasLength(2));
  });
}
