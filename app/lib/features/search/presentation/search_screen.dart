import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/design_system/empty_state.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/jot_search_field.dart';
import 'package:jotline/core/design_system/jot_segmented_control.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/pages/presentation/page_screen.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_hit.dart';
import 'package:jotline/features/search/data/search_providers.dart';
import 'package:jotline/features/search/presentation/search_result_row.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// Searches the titles and content of every notebook (RF-05).
class SearchScreen extends ConsumerStatefulWidget {
  const new({super.key});

  static const Duration debounce = Duration(milliseconds: 150);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  MatchQuery _query = MatchQuery.parse('');
  String _term = '';
  SearchScope _scope = SearchScope.all;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    final term = text.trim();
    final query = MatchQuery.parse(term);
    if (query.isEmpty) {
      setState(() {
        _query = query;
        _term = '';
      });
      return;
    }
    _timer = Timer(SearchScreen.debounce, () {
      if (!mounted) return;
      setState(() {
        _query = query;
        _term = term;
      });
    });
  }

  void _open(SearchHit hit) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PageScreen(pageId: hit.pageId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hits = _query.isEmpty
        ? null
        : ref.watch(searchHitsProvider((_query, _scope))).value;
    final Widget body;
    if (_query.isEmpty) {
      body = _Centered(
        child: EmptyState(
          icon: JotIconGlyph.search,
          title: l10n.searchEmptyTitle,
          message: l10n.searchEmptyBody,
        ),
      );
    } else if (hits == null) {
      body = const SizedBox.shrink();
    } else if (hits.isEmpty) {
      body = _Centered(
        child: EmptyState(
          icon: JotIconGlyph.searchNone,
          title: l10n.searchNoResultTitle,
          message: l10n.searchNoResultBody(_term),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              JotSpace.space6,
              JotSpace.space1,
              JotSpace.space5,
              JotSpace.space3,
            ),
            child: Text(
              l10n.searchCount(hits.length),
              style: context.textStyles.meta,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                JotSpace.space5,
                0,
                JotSpace.space5,
                JotSpace.space8,
              ),
              itemCount: hits.length,
              itemBuilder: (context, index) {
                final hit = hits[index];
                return Padding(
                  key: ValueKey(hit.pageId),
                  padding: const EdgeInsets.only(bottom: JotSpace.space3),
                  child: SearchResultRow(
                    hit: hit,
                    query: _query,
                    scope: _scope,
                    onTap: () => _open(hit),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                JotSpace.space5,
                JotSpace.space3,
                JotSpace.space3,
                JotSpace.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: JotSpace.space4,
                children: [
                  Row(
                    spacing: JotSpace.space2,
                    children: [
                      Expanded(
                        child: JotSearchField(
                          placeholder: l10n.searchPlaceholder,
                          semanticLabel: l10n.searchFieldLabel,
                          controller: _controller,
                          onChanged: _onChanged,
                          autofocus: true,
                        ),
                      ),
                      JotButton.text(
                        label: l10n.cancel,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: JotSpace.space2),
                    child: Semantics(
                      container: true,
                      label: l10n.searchScopeLabel,
                      child: JotSegmentedControl<SearchScope>(
                        segments: [
                          JotSegment(
                            value: SearchScope.all,
                            label: l10n.searchAll,
                          ),
                          JotSegment(
                            value: SearchScope.titles,
                            label: l10n.searchTitles,
                          ),
                          JotSegment(
                            value: SearchScope.content,
                            label: l10n.searchContent,
                          ),
                        ],
                        selected: _scope,
                        onChanged: (scope) => setState(() => _scope = scope),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
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
