import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// An icon, a title and one support sentence, with no call to action.
class EmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  static const double iconSize = 40;
  static const double iconStrokeWidth = 1.4;

  final JotIconGlyph icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JotSpace.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: JotSpace.space3,
        children: [
          IconTheme(
            data: IconThemeData(color: colors.ink2),
            child: JotIcon(icon, size: iconSize, strokeWidth: iconStrokeWidth),
          ),
          Text(
            title,
            style: styles.itemTitulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(message, style: styles.apoio, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
