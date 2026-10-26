import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_bottom_sheet.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';

/// Opens a [JotOptionsSheet] over `bgVeu`. Resolves to the tapped row's
/// value, or `null` when the barrier is tapped.
Future<T?> showJotOptionsSheet<T>(
  BuildContext context, {
  required Widget header,
  required List<List<JotOptionRow<T>>> groups,
  Widget? footer,
}) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    barrierColor: colors.bgVeu,
    backgroundColor: colors.bgMesa,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(JotRadius.rSheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        JotOptionsSheet<T>(header: header, groups: groups, footer: footer),
  );
}

/// One tappable row of a [JotOptionsSheet].
class JotOptionRow<T> {
  const new({
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
    this.destructive = false,
    this.checked = false,
  });

  final JotIconGlyph? icon;
  final String label;
  final String? subtitle;
  final T value;
  final bool destructive;
  final bool checked;
}

/// The content of the canvas options sheet: handle, a header slot and
/// groups of rows, each group drawn as a white card with dividers.
class JotOptionsSheet<T> extends StatelessWidget {
  const new({
    required this.header,
    required this.groups,
    super.key,
    this.footer,
  });

  final Widget header;
  final List<List<JotOptionRow<T>>> groups;

  /// A note drawn under the last group.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        JotSpace.space3,
        JotSpace.space3,
        JotSpace.space3,
        JotSpace.space6 +
            JotSpace.space3 +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: JotSpace.space2,
        children: [
          Center(
            child: SizedBox.fromSize(
              size: JotBottomSheet.handleSize,
              child: DecoratedBox(
                key: JotBottomSheet.handleKey,
                decoration: BoxDecoration(
                  color: colors.lineForte,
                  borderRadius: BorderRadius.circular(JotRadius.rEtiqueta),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: JotSpace.space2,
              vertical: JotSpace.space3,
            ),
            child: header,
          ),
          for (final group in groups) _OptionGroup<T>(rows: group),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                JotSpace.space2,
                JotSpace.space1,
                JotSpace.space2,
                0,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }
}

class _OptionGroup<T> extends StatelessWidget {
  const new({required this.rows});

  final List<JotOptionRow<T>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exclusive = rows.any((row) => row.checked);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgFolha,
        border: Border.all(color: colors.bgTrilho),
        borderRadius: BorderRadius.circular(JotRadius.rCard),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(JotRadius.rCard),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: colors.bgTrilho),
              _OptionTile<T>(row: rows[i], exclusive: exclusive),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const new({required this.row, required this.exclusive});

  final JotOptionRow<T> row;
  final bool exclusive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final icon = row.icon;
    final subtitle = row.subtitle;
    final color = row.destructive ? colors.danger : colors.ink1;
    final weight = row.destructive
        ? FontWeight.w500
        : row.checked
        ? FontWeight.w600
        : FontWeight.w400;
    final minHeight = subtitle == null
        ? JotSpace.space14
        : JotSpace.space14 + JotSpace.space2;
    return Semantics(
      button: true,
      selected: row.checked,
      inMutuallyExclusiveGroup: exclusive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(row.value),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: JotSpace.space4,
              vertical: JotSpace.space3,
            ),
            child: IconTheme(
              data: IconThemeData(color: color),
              child: Row(
                spacing: JotSpace.space4,
                children: [
                  if (icon != null) JotIcon(icon),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: JotSpace.space1,
                      children: [
                        Text(
                          row.label,
                          style: styles.acao.copyWith(
                            color: color,
                            fontWeight: weight,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: styles.apoio.copyWith(fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  if (row.checked)
                    IconTheme(
                      data: IconThemeData(color: colors.accent),
                      child: const JotIcon(
                        JotIconGlyph.check,
                        strokeWidth: 2.2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
