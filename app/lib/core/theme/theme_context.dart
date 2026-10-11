import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';

/// Shortcuts to the design system tokens of the nearest [Theme].
extension JotThemeContext on BuildContext {
  JotColors get colors => Theme.of(this).extension<JotColors>()!;
  JotTextStyles get textStyles => Theme.of(this).extension<JotTextStyles>()!;
  JotShadows get shadows => Theme.of(this).extension<JotShadows>()!;
}
