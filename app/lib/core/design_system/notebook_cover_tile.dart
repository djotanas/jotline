import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// A notebook in the grid: cover, title and meta line.
class NotebookCoverTile extends StatelessWidget {
  const new({
    required this.color,
    required this.pattern,
    required this.title,
    required this.meta,
    super.key,
    this.onTap,
  });

  static const double coverHeight = 196;

  final NotebookColor color;
  final CoverPattern pattern;
  final String title;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: JotSpace.space3,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                height: coverHeight,
                child: NotebookCover(
                  color: color,
                  pattern: pattern,
                  label: title,
                ),
              ),
            ),
            Column(
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
          ],
        ),
      ),
    );
  }
}
