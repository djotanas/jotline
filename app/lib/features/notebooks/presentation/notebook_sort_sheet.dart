import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/design_system/jot_options_sheet.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/notebooks/data/notebook_sort_provider.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Opens the "Ordenar por" sheet. Picking an option stores it through
/// [notebookSortProvider] and closes the sheet.
Future<void> showNotebookSortSheet(
  BuildContext context,
  NotebookSort current,
) async {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final picked = await showJotOptionsSheet<NotebookSort>(
    context,
    header: Text(l10n.sortBy, style: context.textStyles.tituloSheet),
    groups: [
      [
        for (final (sort, label) in [
          (NotebookSort.lastEdited, l10n.sortLastEdited),
          (NotebookSort.name, l10n.sortName),
          (NotebookSort.createdAt, l10n.sortCreatedAt),
        ])
          JotOptionRow(label: label, value: sort, checked: sort == current),
      ],
    ],
    footer: Text(
      l10n.sortNote,
      style: context.textStyles.apoio.copyWith(fontSize: 13),
    ),
  );
  if (picked != null) {
    await container.read(notebookSortProvider.notifier).select(picked);
  }
}
