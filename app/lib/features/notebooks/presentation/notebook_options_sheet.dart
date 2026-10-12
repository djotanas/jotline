import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_options_sheet.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/l10n/app_localizations.dart';

enum NotebookAction { rename, cover, archive, unarchive, delete }

/// Opens the "Opções do caderno" sheet. Resolves to the chosen
/// [NotebookAction], or `null` when the sheet is dismissed.
Future<NotebookAction?> showNotebookOptionsSheet(
  BuildContext context,
  NotebookSummary summary,
) {
  final l10n = AppLocalizations.of(context);
  final dates = RelativeDates(
    l10n,
    now: ProviderScope.containerOf(context).read(clockProvider).now(),
  );
  final archivedAt = summary.archivedAt;
  final count = l10n.pageCount(summary.pageCount);
  final date = archivedAt == null
      ? dates.withVerb(l10n.createdVerb, summary.notebook.createdAt)
      : dates.withVerb(l10n.archivedVerb, archivedAt);
  final meta = '$count · $date';
  return showJotOptionsSheet<NotebookAction>(
    context,
    header: NotebookOptionsHeader(summary: summary, meta: meta),
    groups: [
      [
        JotOptionRow(
          icon: JotIconGlyph.edit,
          label: l10n.rename,
          value: NotebookAction.rename,
        ),
        JotOptionRow(
          icon: JotIconGlyph.cover,
          label: l10n.notebookOptionsCover,
          value: NotebookAction.cover,
        ),
        if (archivedAt == null)
          JotOptionRow(
            icon: JotIconGlyph.archive,
            label: l10n.notebookOptionsArchive,
            subtitle: l10n.notebookOptionsArchiveHint,
            value: NotebookAction.archive,
          )
        else
          JotOptionRow(
            icon: JotIconGlyph.unarchive,
            label: l10n.notebookOptionsUnarchive,
            subtitle: l10n.notebookOptionsUnarchiveHint,
            value: NotebookAction.unarchive,
          ),
      ],
      [
        JotOptionRow(
          icon: JotIconGlyph.trash,
          label: l10n.notebookOptionsDelete,
          value: NotebookAction.delete,
          destructive: true,
        ),
      ],
    ],
  );
}

/// Mini cover, title and the page count and date meta line.
class NotebookOptionsHeader extends StatelessWidget {
  const new({required this.summary, required this.meta, super.key});

  static const Size coverSize = Size(34, 46);

  final NotebookSummary summary;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Row(
      spacing: JotSpace.space4,
      children: [
        SizedBox.fromSize(
          size: coverSize,
          child: NotebookCover.mini(
            color: summary.notebook.color,
            pattern: summary.notebook.cover,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: JotSpace.space1,
            children: [
              Text(
                summary.notebook.title,
                style: styles.tituloSheet.copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(meta, style: styles.meta),
            ],
          ),
        ),
      ],
    );
  }
}
