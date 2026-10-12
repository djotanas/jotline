import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_options_sheet.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/l10n/app_localizations.dart';

enum PageAction { rename, delete }

/// Opens the "Opções da página" sheet. Resolves to the chosen [PageAction],
/// or `null` when the sheet is dismissed.
Future<PageAction?> showPageOptionsSheet(
  BuildContext context,
  NotebookPage page,
  Notebook notebook,
) {
  final l10n = AppLocalizations.of(context);
  final dates = RelativeDates(
    l10n,
    now: ProviderScope.containerOf(context).read(clockProvider).now(),
  );
  return showJotOptionsSheet<PageAction>(
    context,
    header: PageOptionsHeader(
      title: page.title.isEmpty ? l10n.untitled : page.title,
      notebook: notebook,
      edited: dates.withTime(l10n.pageEditedInline, page.updatedAt),
    ),
    groups: [
      [
        JotOptionRow(
          icon: JotIconGlyph.edit,
          label: l10n.rename,
          value: PageAction.rename,
        ),
      ],
      [
        JotOptionRow(
          icon: JotIconGlyph.trash,
          label: l10n.pageOptionsDelete,
          subtitle: l10n.pageOptionsDeleteHint,
          value: PageAction.delete,
          destructive: true,
        ),
      ],
    ],
  );
}

/// Page title, then the notebook color chip, its title and the edited line.
class PageOptionsHeader extends StatelessWidget {
  const new({
    required this.title,
    required this.notebook,
    required this.edited,
    super.key,
  });

  static const Key chipKey = ValueKey('pageOptionsChip');
  static const Size chipSize = Size(8, 12);
  static const String separator = '·';

  final String title;
  final Notebook notebook;
  final String edited;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: JotSpace.space1,
      children: [
        Text(
          title,
          style: styles.tituloSheet,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          spacing: JotSpace.space2,
          children: [
            SizedBox.fromSize(
              size: chipSize,
              child: DecoratedBox(
                key: chipKey,
                decoration: BoxDecoration(
                  color: notebook.color.color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(1),
                    right: Radius.circular(JotRadius.rEtiqueta),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Text(
                notebook.title,
                style: styles.apoio.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(separator, style: styles.apoio.copyWith(fontSize: 12)),
            Text(edited, style: styles.meta),
          ],
        ),
      ],
    );
  }
}
