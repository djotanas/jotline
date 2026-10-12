import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/design_system/archived_notebook_row.dart';
import 'package:jotline/core/design_system/empty_state.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/jot_top_bar.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:jotline/features/pages/data/page_repository.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// What was deleted on this device, with a "Restaurar" action and no way to
/// empty it.
class TrashScreen extends ConsumerStatefulWidget {
  const new({super.key});

  /// Distance from the bottom edge to the undo toast.
  static const double toastBottom = JotSpace.space8 + JotSpace.space1;

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  UndoToastRequest? _toast;

  void _showToast(String message, VoidCallback onUndo) {
    setState(() => _toast = UndoToastRequest(message: message, onUndo: onUndo));
  }

  String _notebookMeta(
    AppLocalizations l10n,
    RelativeDates dates,
    TrashedNotebook trashed,
  ) {
    final deleted = dates.withVerb(
      l10n.deletedVerb,
      trashed.notebook.deletedAt!,
    );
    return '${l10n.pageCount(trashed.pageCount)} · $deleted';
  }

  void _restoreNotebook(TrashedNotebook trashed) {
    final repository = ref.read(notebookRepositoryProvider);
    final id = trashed.notebook.id;
    final deletedAt = trashed.notebook.deletedAt!;
    unawaited(repository.restore(id));
    _showToast(
      AppLocalizations.of(context).notebookRestored,
      () => unawaited(repository.putBackInTrash(id, deletedAt)),
    );
  }

  void _restorePage(TrashedPage trashed) {
    final repository = ref.read(pageRepositoryProvider);
    final id = trashed.page.id;
    final deletedAt = trashed.page.deletedAt!;
    unawaited(repository.restore(id));
    _showToast(
      AppLocalizations.of(context).restoredIn(trashed.notebookTitle),
      () => unawaited(repository.putBackInTrash(id, deletedAt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.textStyles;
    final dates = RelativeDates(l10n, now: ref.watch(clockProvider).now());
    final notebooks = ref.watch(trashedNotebooksProvider).value;
    final pages = ref.watch(trashedPagesProvider).value;
    final loaded = notebooks != null && pages != null;
    final empty = loaded && notebooks.isEmpty && pages.isEmpty;
    final toast = _toast;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: JotSpace.space14 * 2),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: JotSpace.space3,
                  ),
                  child: JotTopBar.back(
                    previousLabel: l10n.notebooksTitle,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    JotSpace.space5,
                    JotSpace.space2,
                    JotSpace.space5,
                    JotSpace.space4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: JotSpace.space2,
                    children: [
                      Text(l10n.trashTitle, style: styles.tituloTela),
                      Text(l10n.trashIntro, style: styles.apoio),
                    ],
                  ),
                ),
                if (empty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: JotSpace.space8,
                      vertical: JotSpace.space14,
                    ),
                    child: EmptyState(
                      icon: JotIconGlyph.trash,
                      title: l10n.trashEmptyTitle,
                      message: l10n.trashEmptyMessage,
                    ),
                  ),
                if (notebooks != null && notebooks.isNotEmpty)
                  _Section(
                    title: l10n.trashNotebooksSection,
                    children: [
                      for (final trashed in notebooks)
                        ArchivedNotebookRow(
                          color: trashed.notebook.color,
                          pattern: trashed.notebook.cover,
                          title: trashed.notebook.title,
                          meta: _notebookMeta(l10n, dates, trashed),
                          actionLabel: l10n.restore,
                          onAction: () => _restoreNotebook(trashed),
                        ),
                    ],
                  ),
                if (pages != null && pages.isNotEmpty)
                  _Section(
                    title: l10n.trashPagesSection,
                    children: [
                      for (final trashed in pages)
                        _TrashedPageRow(
                          trashed: trashed,
                          date: dates.day(trashed.page.deletedAt!),
                          onRestore: () => _restorePage(trashed),
                        ),
                    ],
                  ),
              ],
            ),
            if (toast != null)
              Positioned(
                left: JotSpace.space3,
                right: JotSpace.space3,
                bottom: TrashScreen.toastBottom,
                child: JotUndoToast(
                  key: ObjectKey(toast),
                  message: toast.message,
                  onUndo: () {
                    toast.onUndo();
                    setState(() => _toast = null);
                  },
                  onTimeout: () => setState(() => _toast = null),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        JotSpace.space5,
        0,
        JotSpace.space5,
        JotSpace.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: JotSpace.space2,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: JotSpace.space1),
            child: Semantics(
              header: true,
              child: Text(title, style: context.textStyles.rotulo),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _TrashedPageRow extends StatelessWidget {
  const new({
    required this.trashed,
    required this.date,
    required this.onRestore,
  });

  static const Size chipSize = Size(8, 12);
  static const String separator = '·';

  final TrashedPage trashed;
  final String date;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final l10n = AppLocalizations.of(context);
    final title = trashed.page.title;
    final support = styles.apoio.copyWith(fontSize: 12);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgFolha,
        border: Border.all(color: colors.lineBase),
        borderRadius: BorderRadius.circular(JotRadius.rCard),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          JotSpace.space4,
          JotSpace.space3,
          JotSpace.space3,
          JotSpace.space3,
        ),
        child: Row(
          spacing: JotSpace.space3,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: JotSpace.space1,
                children: [
                  Text(
                    title.isEmpty ? l10n.untitled : title,
                    style: styles.cardTitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    spacing: JotSpace.space2,
                    children: [
                      SizedBox.fromSize(
                        size: chipSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: trashed.notebookColor.color,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(1),
                              right: Radius.circular(JotRadius.rEtiqueta),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          trashed.notebookTitle,
                          style: support,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(separator, style: support),
                      Text(date, style: styles.meta),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: JotButton.pill(label: l10n.restore, onPressed: onRestore),
            ),
          ],
        ),
      ),
    );
  }
}
