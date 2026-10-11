import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// An archived or trashed notebook with one action, such as restoring it.
class ArchivedNotebookRow extends StatelessWidget {
  const new({
    required this.color,
    required this.pattern,
    required this.title,
    required this.meta,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  static const Size coverSize = Size(34, 46);
  static const double coverOpacity = 0.85;

  final NotebookColor color;
  final CoverPattern pattern;
  final String title;
  final String meta;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgFolha,
        border: Border.all(color: colors.lineBase),
        borderRadius: BorderRadius.circular(JotRadius.rCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(JotSpace.space3),
        child: Row(
          spacing: JotSpace.space4,
          children: [
            Opacity(
              opacity: coverOpacity,
              child: SizedBox.fromSize(
                size: coverSize,
                child: NotebookCover.mini(color: color, pattern: pattern),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: JotSpace.space1,
                children: [
                  Text(
                    title,
                    style: styles.cardTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    meta,
                    style: styles.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Flexible(
              child: JotButton.pill(label: actionLabel, onPressed: onAction),
            ),
          ],
        ),
      ),
    );
  }
}
