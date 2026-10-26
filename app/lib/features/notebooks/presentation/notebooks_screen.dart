import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/design_system/archived_notebook_row.dart';
import 'package:jotline/core/design_system/empty_state.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_fab.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_segmented_control.dart';
import 'package:jotline/core/design_system/jot_top_bar.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';
import 'package:jotline/core/design_system/notebook_cover_tile.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/notebooks/data/notebook_sort_provider.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/features/notebooks/presentation/notebook_form_sheet.dart';
import 'package:jotline/features/notebooks/presentation/notebook_outcome.dart';
import 'package:jotline/features/notebooks/presentation/notebook_screen.dart';
import 'package:jotline/features/notebooks/presentation/notebook_sort_sheet.dart';
import 'package:jotline/features/search/presentation/search_screen.dart';
import 'package:jotline/features/trash/presentation/trash_screen.dart';
import 'package:jotline/l10n/app_localizations.dart';

enum _Tab { active, archived }

/// The first screen: every notebook, split into active and archived.
class NotebooksScreen extends ConsumerStatefulWidget {
  const new({super.key});

  /// Distance from the bottom edge to the undo toast.
  static const double toastBottom = 108;

  @override
  ConsumerState<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends ConsumerState<NotebooksScreen> {
  _Tab _tab = _Tab.active;
  UndoToastRequest? _toast;

  void _showToast(String message, VoidCallback onUndo) {
    setState(() => _toast = UndoToastRequest(message: message, onUndo: onUndo));
  }

  String _archivedMeta(
    AppLocalizations l10n,
    RelativeDates dates,
    NotebookSummary summary,
  ) {
    final archived = dates.withVerb(l10n.archivedVerb, summary.archivedAt!);
    return '${l10n.pageCount(summary.pageCount)} · $archived';
  }

  Future<void> _openNotebook(String id) async {
    final outcome = await Navigator.of(context).push<NotebookOutcome>(
      MaterialPageRoute(builder: (_) => NotebookScreen(notebookId: id)),
    );
    if (!mounted || outcome == null) return;
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(notebookRepositoryProvider);
    switch (outcome) {
      case NotebookArchived(:final id, :final previous):
        setState(() => _tab = _Tab.active);
        _showToast(
          l10n.notebookArchived,
          () => unawaited(repository.setArchivedAt(id, previous)),
        );
      case NotebookUnarchived(:final id, :final previous):
        setState(() => _tab = _Tab.active);
        _showToast(
          l10n.notebookUnarchived,
          () => unawaited(repository.setArchivedAt(id, previous)),
        );
      case NotebookTrashed(:final id):
        _showToast(
          l10n.notebookTrashed,
          () => unawaited(repository.restore(id)),
        );
    }
  }

  Future<void> _newNotebook() async {
    final id = await showNewNotebookSheet(context);
    if (id != null && mounted) await _openNotebook(id);
  }

  void _unarchive(NotebookSummary summary) {
    final repository = ref.read(notebookRepositoryProvider);
    final id = summary.notebook.id;
    final previous = summary.archivedAt;
    unawaited(repository.unarchive(id));
    setState(() => _tab = _Tab.active);
    _showToast(
      AppLocalizations.of(context).notebookUnarchived,
      () => unawaited(repository.setArchivedAt(id, previous)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(notebookSummariesProvider(false)).value;
    final archived = ref.watch(notebookSummariesProvider(true)).value;
    final dates = RelativeDates(l10n, now: ref.watch(clockProvider).now());
    final loaded = active != null && archived != null;
    final hasNotebooks = loaded && active.length + archived.length > 0;
    final toast = _toast;
    final Widget body;
    if (!loaded) {
      body = const SizedBox.shrink();
    } else if (!hasNotebooks) {
      body = _Centered(
        child: EmptyState(
          icon: JotIconGlyph.notebook,
          title: l10n.emptyNotebooksTitle,
          message: l10n.emptyNotebooksMessage,
        ),
      );
    } else if (_tab == _Tab.active) {
      body = _Grid(
        notebooks: active,
        metaOf: (summary) =>
            '${l10n.pageCount(summary.pageCount)} · '
            '${dates.day(summary.lastEditedAt)}',
        onOpen: (summary) => unawaited(_openNotebook(summary.notebook.id)),
      );
    } else if (archived.isEmpty) {
      body = _Centered(
        child: EmptyState(
          icon: JotIconGlyph.archive,
          title: l10n.emptyArchivedTitle,
          message: l10n.emptyArchivedMessage,
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          JotSpace.space5,
          JotSpace.space2,
          JotSpace.space5,
          NotebooksScreen.toastBottom + JotSpace.space14,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: JotSpace.space4),
            child: Text(
              l10n.archivedExplanation,
              style: context.textStyles.apoio,
            ),
          ),
          for (final summary in archived)
            Padding(
              key: ValueKey(summary.notebook.id),
              padding: const EdgeInsets.only(bottom: JotSpace.space3),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => unawaited(_openNotebook(summary.notebook.id)),
                child: ArchivedNotebookRow(
                  color: summary.notebook.color,
                  pattern: summary.notebook.cover,
                  title: summary.notebook.title,
                  meta: _archivedMeta(l10n, dates, summary),
                  actionLabel: l10n.unarchive,
                  onAction: () => _unarchive(summary),
                ),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    JotSpace.space5,
                    JotSpace.space3,
                    JotSpace.space3,
                    JotSpace.space3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: JotSpace.space5,
                    children: [
                      JotTopBar.root(
                        title: l10n.notebooksTitle,
                        actions: [
                          JotIconButton(
                            icon: JotIconGlyph.search,
                            semanticLabel: l10n.searchLabel,
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => const SearchScreen(),
                              ),
                            ),
                          ),
                          if (hasNotebooks)
                            JotIconButton(
                              icon: JotIconGlyph.sort,
                              semanticLabel: l10n.sortLabel,
                              onPressed: () => unawaited(
                                showNotebookSortSheet(
                                  context,
                                  ref.read(notebookSortProvider),
                                ),
                              ),
                            ),
                          JotIconButton(
                            icon: JotIconGlyph.trash,
                            semanticLabel: l10n.trashTitle,
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => const TrashScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (hasNotebooks)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: JotSpace.space2,
                          ),
                          child: JotSegmentedControl<_Tab>(
                            segments: [
                              JotSegment(
                                value: _Tab.active,
                                label: l10n.tabActive,
                                count: active.length,
                              ),
                              JotSegment(
                                value: _Tab.archived,
                                label: l10n.tabArchived,
                                count: archived.length,
                              ),
                            ],
                            selected: _tab,
                            onChanged: (tab) => setState(() => _tab = tab),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            ),
            Positioned(
              right: JotSpace.space5,
              bottom: JotSpace.space6,
              child: JotFab(
                icon: JotIconGlyph.add,
                label: l10n.newNotebookTitle,
                onPressed: () => unawaited(_newNotebook()),
              ),
            ),
            if (toast != null)
              Positioned(
                left: JotSpace.space3,
                right: JotSpace.space3,
                bottom: NotebooksScreen.toastBottom,
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

class _Centered extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          JotSpace.space8,
          0,
          JotSpace.space8,
          JotSpace.space14 * 2,
        ),
        child: child,
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const new({
    required this.notebooks,
    required this.metaOf,
    required this.onOpen,
  });

  final List<NotebookSummary> notebooks;
  final String Function(NotebookSummary) metaOf;
  final ValueChanged<NotebookSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = (notebooks.length + 1) ~/ 2;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        JotSpace.space5,
        JotSpace.space2,
        JotSpace.space5,
        NotebooksScreen.toastBottom + JotSpace.space14,
      ),
      itemCount: rows,
      itemBuilder: (context, row) {
        Widget cell(int index) {
          if (index >= notebooks.length) return const SizedBox.shrink();
          final summary = notebooks[index];
          return NotebookCoverTile(
            color: summary.notebook.color,
            pattern: summary.notebook.cover,
            title: summary.notebook.title,
            meta: metaOf(summary),
            onTap: () => onOpen(summary),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: JotSpace.space5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: JotSpace.space4,
            children: [
              Expanded(child: cell(row * 2)),
              Expanded(child: cell(row * 2 + 1)),
            ],
          ),
        );
      },
    );
  }
}
