import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_excerpt.dart';
import 'package:jotline/features/search/data/search_hit.dart';
import 'package:jotline/features/search/data/search_providers.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// A search result card: notebook, date, highlighted title and excerpt.
class SearchResultRow extends ConsumerWidget {
  const new({
    required this.hit,
    required this.query,
    required this.scope,
    super.key,
    this.onTap,
  });

  static const String separator = '·';

  final SearchHit hit;
  final MatchQuery query;
  final SearchScope scope;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final styles = context.textStyles;
    final l10n = AppLocalizations.of(context);
    final dates = RelativeDates(l10n, now: ref.watch(clockProvider).now());
    final snippet = ref
        .watch(searchSnippetProvider((hit.pageId, query, scope)))
        .value;
    final untitled = hit.title.isEmpty;
    final titleSpans = snippet == null || snippet.title.isEmpty
        ? [HighlightSpan(hit.title, marked: false)]
        : snippet.title;
    final excerpt = snippet?.excerpt;
    final titleStyle = untitled
        ? styles.itemTitulo.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.inkFeito,
          )
        : styles.itemTitulo;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.bgFolha,
            border: Border.all(color: colors.bgTrilho),
            borderRadius: BorderRadius.circular(JotRadius.rCard),
          ),
          child: Padding(
            padding: const EdgeInsets.all(JotSpace.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: JotSpace.space2,
              children: [
                Row(
                  spacing: JotSpace.space2,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: hit.notebookColor.color,
                        borderRadius: JotRadius.rLombada,
                      ),
                      child: const SizedBox(width: 10, height: 14),
                    ),
                    Flexible(
                      child: Text(
                        hit.notebookTitle,
                        style: styles.buscaCaderno,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(separator, style: styles.buscaCaderno),
                    Text(dates.day(hit.lastEditedAt), style: styles.meta),
                  ],
                ),
                Text.rich(
                  _highlighted(
                    untitled
                        ? [HighlightSpan(l10n.untitled, marked: false)]
                        : titleSpans,
                    titleStyle,
                    markedColor: colors.ink1,
                    markBackground: colors.accentBusca,
                  ),
                ),
                if (excerpt != null)
                  Text.rich(
                    _highlighted(
                      excerpt.spans,
                      styles.buscaTrecho,
                      markedColor: colors.ink1,
                      markBackground: colors.accentBusca,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextSpan _highlighted(
  List<HighlightSpan> spans,
  TextStyle style, {
  required Color markedColor,
  required Color markBackground,
}) {
  return TextSpan(
    style: style,
    children: [
      for (final span in spans)
        if (span.marked)
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: markBackground,
                borderRadius: BorderRadius.circular(JotRadius.rEtiqueta),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: JotSpace.space1,
                ),
                child: Text(
                  span.text,
                  style: style.copyWith(color: markedColor),
                ),
              ),
            ),
          )
        else
          TextSpan(text: span.text),
    ],
  );
}
