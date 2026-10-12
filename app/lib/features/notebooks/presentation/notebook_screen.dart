import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/design_system/confirm_dialog.dart';
import 'package:jotline/core/design_system/empty_state.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_badge.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/jot_fab.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_text_input_dialog.dart';
import 'package:jotline/core/design_system/jot_top_bar.dart';
import 'package:jotline/core/design_system/jot_undo_toast.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/preferences/preferences_provider.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';
import 'package:jotline/features/notebooks/presentation/notebook_form_sheet.dart';
import 'package:jotline/features/notebooks/presentation/notebook_options_sheet.dart';
import 'package:jotline/features/notebooks/presentation/notebook_outcome.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:jotline/features/pages/presentation/page_list.dart';
import 'package:jotline/features/pages/presentation/page_outcome.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// A notebook: its header, its pages and the actions on both. Pops with a
/// [NotebookOutcome] when the notebook is archived, unarchived or trashed.
class NotebookScreen extends ConsumerStatefulWidget {
  const new({required this.notebookId, super.key});

  static const Size coverSize = Size(40, 54);

  /// Distance from the bottom edge to the undo toast.
  static const double toastBottom = 108;

  final String notebookId;

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  bool _reordering = false;
  bool _closing = false;
  UndoToastRequest? _toast;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(preferencesStoreProvider)
          .setLastOpenedNotebookId(widget.notebookId),
    );
  }

  void _pop([NotebookOutcome? outcome]) {
    _closing = true;
    Navigator.of(context).pop(outcome);
  }

  void _showToast(String message, VoidCallback onUndo) {
    setState(() => _toast = UndoToastRequest(message: message, onUndo: onUndo));
  }

  Future<void> _openPage(String pageId, {bool autofocusTitle = false}) async {
    final outcome = await Navigator.of(context).push<PageOutcome>(
      MaterialPageRoute(
        builder: (_) =>
            PageScreen(pageId: pageId, autofocusTitle: autofocusTitle),
      ),
    );
    if (!mounted) return;
    if (outcome case PageTrashed(:final id)) {
      final repository = ref.read(pageRepositoryProvider);
      _showToast(
        AppLocalizations.of(context).pageMovedToTrash,
        () => unawaited(repository.restore(id)),
      );
    }
  }

  Future<void> _newPage() async {
    final id = await ref.read(pageRepositoryProvider).create(widget.notebookId);
    if (mounted) await _openPage(id, autofocusTitle: true);
  }

  Future<void> _openOptions(NotebookSummary summary) async {
    final action = await showNotebookOptionsSheet(context, summary);
    if (!mounted) return;
    final repository = ref.read(notebookRepositoryProvider);
    final id = summary.notebook.id;
    switch (action) {
      case NotebookAction.rename:
        await _rename(summary);
      case NotebookAction.cover:
        await showCoverSheet(context, summary);
      case NotebookAction.archive:
        _closing = true;
        await repository.archive(id);
        if (mounted) _pop(NotebookArchived(id, previous: summary.archivedAt));
      case NotebookAction.unarchive:
        _closing = true;
        await repository.unarchive(id);
        if (mounted) {
          _pop(NotebookUnarchived(id, previous: summary.archivedAt));
        }
      case NotebookAction.delete:
        await _delete(summary);
      case null:
        break;
    }
  }

  Future<void> _rename(NotebookSummary summary) async {
    final l10n = AppLocalizations.of(context);
    final title = await showTextInputDialog(
      context,
      title: l10n.renameNotebookTitle,
      label: l10n.nameLabel,
      hintText: l10n.notebookNameHint,
      allowEmpty: false,
      initialValue: summary.notebook.title,
    );
    if (title == null || !mounted) return;
    await ref
        .read(notebookRepositoryProvider)
        .update(summary.notebook.id, title: title);
  }

  Future<void> _delete(NotebookSummary summary) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteNotebookTitle(summary.notebook.title),
      message: l10n.deleteNotebookMessage,
      confirmLabel: l10n.moveToTrash,
    );
    if (!confirmed || !mounted) return;
    _closing = true;
    await ref.read(notebookRepositoryProvider).moveToTrash(summary.notebook.id);
    if (mounted) _pop(NotebookTrashed(summary.notebook.id));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notebookProvider(widget.notebookId), (_, next) {
      if (next case AsyncData(value: null) when !_closing) _pop();
    });
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(notebookProvider(widget.notebookId)).value;
    final pages = ref.watch(pagesProvider(widget.notebookId)).value ?? const [];
    final reordering = _reordering && pages.isNotEmpty;
    final toast = _toast;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (summary != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: JotSpace.space3,
                    ),
                    child: JotTopBar.back(
                      previousLabel: l10n.notebooksTitle,
                      onBack: _pop,
                      actions: [
                        if (pages.isNotEmpty)
                          JotButton.text(
                            label: reordering ? l10n.reorderDone : l10n.reorder,
                            onPressed: () =>
                                setState(() => _reordering = !reordering),
                          ),
                        JotIconButton(
                          icon: JotIconGlyph.more,
                          semanticLabel: l10n.notebookOptionsLabel,
                          onPressed: () => _openOptions(summary),
                        ),
                      ],
                    ),
                  ),
                  _Header(summary: summary),
                  if (reordering)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        JotSpace.space5,
                        0,
                        JotSpace.space5,
                        JotSpace.space3,
                      ),
                      child: Text(
                        l10n.reorderHint,
                        style: context.textStyles.apoio,
                      ),
                    ),
                  Expanded(
                    child: pages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: JotSpace.space8,
                              ),
                              child: EmptyState(
                                icon: JotIconGlyph.page,
                                title: l10n.emptyPagesTitle,
                                message: l10n.emptyPagesMessage,
                              ),
                            ),
                          )
                        : PageList(
                            pages: pages,
                            reordering: reordering,
                            onOpen: (page) => unawaited(_openPage(page.id)),
                          ),
                  ),
                ],
              ),
            if (summary != null && !reordering)
              Positioned(
                right: JotSpace.space5,
                bottom: JotSpace.space6,
                child: JotFab(
                  icon: JotIconGlyph.add,
                  label: l10n.newPage,
                  onPressed: () => unawaited(_newPage()),
                ),
              ),
            if (toast != null)
              Positioned(
                left: JotSpace.space3,
                right: JotSpace.space3,
                bottom: NotebookScreen.toastBottom,
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

class _Header extends StatelessWidget {
  const new({required this.summary});

  final NotebookSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        JotSpace.space5,
        JotSpace.space3,
        JotSpace.space5,
        JotSpace.space5,
      ),
      child: Row(
        spacing: JotSpace.space4,
        children: [
          SizedBox.fromSize(
            size: NotebookScreen.coverSize,
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
                  style: styles.tituloPagina,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(l10n.pageCount(summary.pageCount), style: styles.meta),
                if (summary.archivedAt != null) JotBadge(l10n.archivedBadge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
