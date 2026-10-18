import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/design_system/dragging_page_row.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/page_row.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:jotline/features/pages/data/page_summary.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// The pages of a notebook as rows. In reorder mode each row shows a drag
/// handle and a drop saves a single `move`.
class PageList extends ConsumerStatefulWidget {
  const new({
    required this.pages,
    required this.reordering,
    required this.onOpen,
    super.key,
  });

  /// Room left under the list for the floating button.
  static const double fabClearance = JotSpace.space14 * 2;

  final List<PageSummary> pages;
  final bool reordering;
  final ValueChanged<NotebookPage> onOpen;

  @override
  ConsumerState<PageList> createState() => _PageListState();
}

class _PageListState extends ConsumerState<PageList> {
  List<PageSummary>? _optimistic;

  @override
  void didUpdateWidget(PageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages != widget.pages) _optimistic = null;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final current = _optimistic ?? widget.pages;
    final moved = current[oldIndex];
    final rest = [...current]..removeAt(oldIndex);
    final placement = newIndex == 0
        ? const AtStart()
        : After(rest[newIndex - 1].page.id);
    setState(() => _optimistic = [...rest]..insert(newIndex, moved));
    unawaited(ref.read(pageRepositoryProvider).move(moved.page.id, placement));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dates = RelativeDates(l10n, now: ref.watch(clockProvider).now());
    final pages = _optimistic ?? widget.pages;
    String label(NotebookPage page) =>
        page.title.isEmpty ? l10n.untitled : page.title;
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(
        JotSpace.space3,
        0,
        JotSpace.space3,
        PageList.fabClearance,
      ),
      itemCount: pages.length,
      onReorderItem: _onReorder,
      proxyDecorator: (child, index, animation) => Material(
        type: MaterialType.transparency,
        child: DraggingPageRow(title: label(pages[index].page)),
      ),
      itemBuilder: (context, index) {
        final summary = pages[index];
        final page = summary.page;
        final title = label(page);
        return Padding(
          key: ValueKey(page.id),
          padding: const EdgeInsets.only(bottom: JotSpace.space2),
          child: PageRow(
            title: title,
            muted: page.title.isEmpty,
            date: dates.day(summary.lastEditedAt),
            excerpt: summary.excerpt,
            onTap: () => widget.onOpen(page),
            leading: widget.reordering
                ? ReorderableDragStartListener(
                    index: index,
                    child: Semantics(
                      container: true,
                      label: l10n.moveItem(title),
                      child: SizedBox.square(
                        dimension: JotSpace.space11,
                        child: Center(
                          child: IconTheme(
                            data: IconThemeData(color: context.colors.ink2),
                            child: const JotIcon(
                              JotIconGlyph.dragHandle,
                              size: DraggingPageRow.handleIconSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
