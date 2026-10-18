import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/design_system/block_bar.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_text_input_dialog.dart';
import 'package:jotline/core/design_system/jot_top_bar.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/core/text/title_rules.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_providers.dart';
import 'package:jotline/features/blocks/presentation/editor/page_editor.dart';
import 'package:jotline/features/notebooks/data/notebook_providers.dart';
import 'package:jotline/features/pages/data/page_providers.dart';
import 'package:jotline/features/pages/data/page_summary.dart';
import 'package:jotline/features/pages/presentation/page_options_sheet.dart';
import 'package:jotline/features/pages/presentation/page_outcome.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// A page: back to the notebook, options, an inline title, the "Editada"
/// line and the block editor, saved while the user types.
class PageScreen extends ConsumerStatefulWidget {
  const new({required this.pageId, super.key, this.autofocusTitle = false});

  /// Length from which the title shows its "N/50" counter.
  static const int counterFrom = 40;

  static const Duration saveDelay = Duration(milliseconds: 500);

  final String pageId;
  final bool autofocusTitle;

  @override
  ConsumerState<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends ConsumerState<PageScreen> {
  final TextEditingController _controller = TextEditingController();
  late final AppLifecycleListener _lifecycle;
  Timer? _debounce;
  String? _lastSaved;
  bool _closing = false;
  PageEditor? _blocks;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: _flushAllSoon,
      onHide: _flushAllSoon,
      onPause: _flushAllSoon,
    );
    unawaited(_loadBlocks());
  }

  Future<void> _loadBlocks() async {
    final repository = ref.read(blockRepositoryProvider);
    final rows = await repository.loadPage(widget.pageId);
    if (!mounted) return;
    setState(() {
      _blocks = PageEditor(
        rows: rows,
        pageId: widget.pageId,
        repository: repository,
      );
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _debounce?.cancel();
    _blocks?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _adopt(NotebookPage page) {
    if (_lastSaved != null) return;
    _lastSaved = page.title;
    _controller.text = page.title;
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(PageScreen.saveDelay, _flush);
    setState(() {});
  }

  Future<void> _flush() async {
    _debounce?.cancel();
    final saved = _lastSaved;
    if (saved == null) return;
    final title = _controller.text.trim();
    if (title == saved) return;
    _lastSaved = title;
    await ref.read(pageRepositoryProvider).rename(widget.pageId, title);
  }

  Future<void> _flushAll() async {
    await Future.wait([_flush(), ?_blocks?.flush()]);
  }

  void _flushAllSoon() => unawaited(_flushAll());

  void _pop([PageOutcome? outcome]) => Navigator.of(context).pop(outcome);

  Future<void> _openOptions(PageSummary summary, Notebook notebook) async {
    await _flushAll();
    if (!mounted) return;
    final action = await showPageOptionsSheet(context, summary, notebook);
    if (!mounted) return;
    switch (action) {
      case PageAction.rename:
        await _rename();
      case PageAction.delete:
        await _delete();
      case null:
        break;
    }
  }

  Future<void> _rename() async {
    final l10n = AppLocalizations.of(context);
    final title = await showTextInputDialog(
      context,
      title: l10n.renamePageTitle,
      label: l10n.titleLabel,
      hintText: l10n.untitled,
      helperText: l10n.renamePageHelp,
      allowEmpty: true,
      initialValue: _controller.text,
    );
    if (title == null || !mounted) return;
    _controller.text = title.trim();
    setState(() {});
    await _flush();
  }

  Future<void> _delete() async {
    await _flushAll();
    _closing = true;
    await ref.read(pageRepositoryProvider).moveToTrash(widget.pageId);
    if (mounted) _pop(PageTrashed(widget.pageId));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pageProvider(widget.pageId), (_, next) {
      if (next case AsyncData(value: null) when !_closing) {
        _closing = true;
        _flushAllSoon();
        _pop();
      }
    });
    final summary = ref.watch(pageProvider(widget.pageId)).value;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final Widget body;
    if (summary == null) {
      body = const SizedBox.shrink();
    } else {
      final page = summary.page;
      _adopt(page);
      final notebook = ref.watch(notebookProvider(page.notebookId)).value;
      final dates = RelativeDates(l10n, now: ref.watch(clockProvider).now());
      final blocks = _blocks;
      final scroll = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: JotSpace.space3),
              child: JotTopBar.back(
                previousLabel: notebook?.notebook.title ?? '',
                onBack: _pop,
                actions: [
                  if (notebook != null)
                    JotIconButton(
                      icon: JotIconGlyph.more,
                      semanticLabel: l10n.pageOptionsLabel,
                      onPressed: () => _openOptions(summary, notebook.notebook),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                JotSpace.space4,
                JotSpace.space2,
                JotSpace.space4,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: JotSpace.space2,
                children: [
                  _PageTitleField(
                    controller: _controller,
                    autofocus: widget.autofocusTitle,
                    onChanged: _onChanged,
                    onSubmitted: (_) => blocks?.focusStart(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: JotSpace.space2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dates.withTime(
                              l10n.pageEdited,
                              summary.lastEditedAt,
                            ),
                            style: context.textStyles.meta,
                          ),
                        ),
                        _TitleCounter(controller: _controller),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (blocks != null)
            SliverPadding(
              padding: const EdgeInsets.only(top: JotSpace.space4),
              sliver: PageEditorView(pageEditor: blocks),
            ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: blocks?.focusEnd,
              child: const SizedBox(height: 2 * JotSpace.space11),
            ),
          ),
        ],
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: scroll),
          if (blocks != null) _PageBlockBar(blocks: blocks),
        ],
      );
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _flushAllSoon();
      },
      child: Scaffold(
        backgroundColor: colors.bgPapel,
        body: SafeArea(child: body),
      ),
    );
  }
}

/// The block bar while a block has the caret, docked above the keyboard
/// (BAR-01, BAR-02).
class _PageBlockBar extends StatelessWidget {
  const new({required this.blocks});

  final PageEditor blocks;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: blocks.changes,
      builder: (context, _) {
        if (!blocks.hasCaret) return const SizedBox.shrink();
        return BlockBar(
          type: switch (blocks.caretType) {
            BlockType.text || BlockType.drawing => BlockBarType.text,
            BlockType.heading => BlockBarType.heading,
            BlockType.bulletedListItem => BlockBarType.bulletedListItem,
            BlockType.checklistItem => BlockBarType.checklistItem,
          },
          bold: blocks.isMarkActive(MarkType.bold),
          italic: blocks.isMarkActive(MarkType.italic),
          onType: (type) => blocks.setType(switch (type) {
            BlockBarType.text => BlockType.text,
            BlockBarType.heading => BlockType.heading,
            BlockBarType.bulletedListItem => BlockType.bulletedListItem,
            BlockBarType.checklistItem => BlockType.checklistItem,
          }),
          onBold: () => blocks.toggleMark(MarkType.bold),
          onItalic: () => blocks.toggleMark(MarkType.italic),
        );
      },
    );
  }
}

class _TitleCounter extends StatelessWidget {
  const new({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final length = controller.text.characters.length;
        if (length < PageScreen.counterFrom) return const SizedBox.shrink();
        final atLimit = length >= maxTitleLength;
        final counter = '$length/$maxTitleLength';
        return Semantics(
          liveRegion: true,
          child: Text(
            counter,
            style: atLimit
                ? styles.meta.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w500,
                  )
                : styles.meta,
          ),
        );
      },
    );
  }
}

class _PageTitleField extends StatefulWidget {
  const new({
    required this.controller,
    required this.autofocus,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_PageTitleField> createState() => _PageTitleFieldState();
}

class _PageTitleFieldState extends State<_PageTitleField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textStyles.tituloPagina;
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(JotRadius.rBloco);
    return Semantics(
      label: l10n.pageTitleLabel,
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: TextField(
          controller: widget.controller,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.next,
          onSubmitted: widget.onSubmitted,
          maxLength: maxTitleLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          style: style,
          cursorColor: colors.accent,
          decoration: InputDecoration(
            filled: true,
            fillColor: _focused ? colors.accentWash : colors.bgPapel,
            hintText: l10n.untitled,
            hintStyle: style.copyWith(color: colors.inkDeco),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: JotSpace.space2,
              vertical: JotSpace.space1,
            ),
            border: UnderlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: UnderlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: colors.accent, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
