import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// A page in the notebook list: title, date and an optional excerpt.
class PageRow extends StatelessWidget {
  const new({
    required this.title,
    required this.date,
    super.key,
    this.excerpt,
    this.onTap,
    this.muted = false,
    this.leading,
  });

  final String title;
  final String date;
  final String? excerpt;
  final VoidCallback? onTap;

  /// Draws the title as a placeholder ("Sem título"): weight 500, `inkFeito`.
  final bool muted;

  /// A widget before the text inside the card, such as a drag handle.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final excerpt = this.excerpt;
    final leading = this.leading;
    final text = Padding(
      padding: EdgeInsets.fromLTRB(
        leading == null ? JotSpace.space3 : 0,
        JotSpace.space3,
        JotSpace.space3,
        JotSpace.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: JotSpace.space1,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: JotSpace.space3,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: muted
                      ? styles.itemTitulo.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.inkFeito,
                        )
                      : styles.itemTitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(date, style: styles.meta),
            ],
          ),
          if (excerpt != null)
            Text(
              excerpt,
              style: styles.itemTrecho,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.bgFolha,
            border: Border.all(color: colors.bgTrilho),
            borderRadius: BorderRadius.circular(JotRadius.rCard),
          ),
          child: leading == null
              ? text
              : Row(
                  children: [
                    leading,
                    Expanded(child: text),
                  ],
                ),
        ),
      ),
    );
  }
}
