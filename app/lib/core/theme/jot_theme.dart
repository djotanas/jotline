import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';

/// The single light theme of the app, built from the canvas tokens.
ThemeData buildJotTheme() {
  const colors = JotColors.light;
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: colors.bgMesa,
    colorScheme: ColorScheme.light(
      primary: colors.accent,
      onPrimary: colors.bgFolha,
      surface: colors.bgFolha,
      onSurface: colors.ink1,
      error: colors.danger,
      onError: colors.bgFolha,
      outline: colors.lineBase,
    ),
    fontFamily: JotTextStyles.fontUi,
    extensions: [colors, JotTextStyles.from(colors), JotShadows.light],
  );
}
