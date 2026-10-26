import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/search/data/match_query.dart';
import 'package:jotline/features/search/data/search_excerpt.dart';
import 'package:jotline/features/search/data/search_hit.dart';
import 'package:jotline/features/search/data/search_providers.dart';
import 'package:jotline/features/search/presentation/search_result_row.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

SearchHit _hit({String title = 'Onde comer em Belém'}) => SearchHit(
  pageId: 'p1',
  title: title,
  notebookTitle: 'Viagem a Lisboa',
  notebookColor: NotebookColor.terracota,
  lastEditedAt: DateTime.utc(2026, 10, 4, 12),
);

Future<void> _pump(
  WidgetTester tester, {
  required Future<SearchSnippet> Function() snippet,
  SearchHit? hit,
  VoidCallback? onTap,
}) {
  return tester.pumpJot(
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(JotSpace.space5),
        child: SearchResultRow(
          hit: hit ?? _hit(),
          query: MatchQuery.parse('belém'),
          scope: SearchScope.all,
          onTap: onTap,
        ),
      ),
    ),
    overrides: [
      clockProvider.overrideWithValue(
        FakeClock(DateTime.utc(2026, 10, 18, 12)),
      ),
      searchSnippetProvider.overrideWith((ref, key) => snippet()),
    ],
  );
}

Finder _mark(String text) => find.ancestor(
  of: find.text(text),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == _colors.accentBusca,
  ),
);

TextStyle _styleOf(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).style!;

TextStyle _richStyleOf(WidgetTester tester, String text) {
  final root =
      tester.widget<RichText>(find.text(text, findRichText: true)).text
          as TextSpan;
  return root.children!.cast<TextSpan>().first.style!;
}

void main() {
  testWidgets('SRCH-11: shows the notebook color spine, title, dot and '
      'date', (tester) async {
    await _pump(
      tester,
      snippet: () async => const SearchSnippet(title: [], excerpt: null),
    );

    final spine = tester.widget<DecoratedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                NotebookColor.terracota.color,
      ),
    );
    expect(
      (spine.decoration as BoxDecoration).borderRadius,
      JotRadius.rLombada,
    );
    final spineBox = find.descendant(
      of: find.byWidget(spine),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(spineBox), const Size(10, 14));
    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    expect(find.text('·'), findsOneWidget);
    expect(find.text('4 out'), findsOneWidget);
  });

  testWidgets('SRCH-11: the date uses the mono meta style', (tester) async {
    await _pump(
      tester,
      snippet: () async => const SearchSnippet(title: [], excerpt: null),
    );

    expect(
      _styleOf(tester, find.text('4 out')).fontFamily,
      JotTextStyles.fontMeta,
    );
  });

  testWidgets('SRCH-14: a marked title word has the accentBusca background '
      'and the rEtiqueta radius', (tester) async {
    await _pump(
      tester,
      snippet: () async => const SearchSnippet(
        title: [
          HighlightSpan('Onde comer em ', marked: false),
          HighlightSpan('Belém', marked: true),
        ],
        excerpt: null,
      ),
    );
    await tester.pump();

    expect(_mark('Belém'), findsOneWidget);
    final box = tester.widget<DecoratedBox>(_mark('Belém'));
    expect(
      (box.decoration as BoxDecoration).borderRadius,
      BorderRadius.circular(JotRadius.rEtiqueta),
    );
    expect(_mark('Onde comer em '), findsNothing);
    expect(
      find.textContaining('Onde comer em', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('SRCH-14: a marked excerpt word has the accentBusca '
      'background', (tester) async {
    await _pump(
      tester,
      snippet: () async => const SearchSnippet(
        title: [],
        excerpt: SearchExcerpt([
          HighlightSpan('…a pastelaria abre às 8h; ', marked: false),
          HighlightSpan('Belém', marked: true),
          HighlightSpan(' fica cheio.', marked: false),
        ]),
      ),
    );
    await tester.pump();

    expect(_mark('Belém'), findsOneWidget);
    expect(
      find.textContaining('…a pastelaria abre às 8h; ', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('SRCH-13: the excerpt is limited to 2 lines with an '
      'ellipsis', (tester) async {
    await _pump(
      tester,
      snippet: () async => SearchSnippet(
        title: const [],
        excerpt: SearchExcerpt([
          HighlightSpan('palavra ' * 80, marked: false),
          const HighlightSpan('Belém', marked: true),
        ]),
      ),
    );
    await tester.pump();

    final excerptFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.textSpan?.style?.fontFamily == JotTextStyles.fontTexto,
    );
    final excerpt = tester.widget<Text>(excerptFinder);
    expect(excerpt.maxLines, 2);
    expect(excerpt.overflow, TextOverflow.ellipsis);
    final lineHeight = JotTextStyles.from(_colors).buscaTrecho;
    expect(
      tester.getSize(excerptFinder).height,
      lessThanOrEqualTo(2 * lineHeight.fontSize! * lineHeight.height! + 1),
    );
  });

  testWidgets('SRCH-12: an untitled page shows "Sem título" in the muted '
      'style', (tester) async {
    await _pump(
      tester,
      hit: _hit(title: ''),
      snippet: () async => const SearchSnippet(title: [], excerpt: null),
    );
    await tester.pump();

    final style = _richStyleOf(tester, 'Sem título');
    expect(style.fontWeight, FontWeight.w500);
    expect(style.color, _colors.inkFeito);
  });

  testWidgets('SRCH-13: no excerpt line when the snippet has none', (
    tester,
  ) async {
    await _pump(
      tester,
      snippet: () async => const SearchSnippet(
        title: [HighlightSpan('Onde comer em Belém', marked: false)],
        excerpt: null,
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(SearchResultRow),
        matching: find.byType(RichText),
      ),
      findsNWidgets(4),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.style?.fontFamily == JotTextStyles.fontTexto,
      ),
      findsNothing,
    );
  });

  testWidgets('SRCH-11: shows the plain title while the snippet loads', (
    tester,
  ) async {
    final pending = Completer<SearchSnippet>();
    await _pump(tester, snippet: () => pending.future);

    expect(find.text('Onde comer em Belém'), findsOneWidget);
    expect(_mark('Onde comer em Belém'), findsNothing);
  });

  testWidgets('SRCH-11: shows the plain title when the page is not in the '
      'index', (tester) async {
    await _pump(
      tester,
      snippet: () async => const SearchSnippet(title: [], excerpt: null),
    );
    await tester.pump();

    expect(find.text('Onde comer em Belém'), findsOneWidget);
  });

  testWidgets('SRCH-16: tapping the card calls onTap', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      snippet: () async => const SearchSnippet(title: [], excerpt: null),
      onTap: () => taps++,
    );

    await tester.tap(find.byType(SearchResultRow));

    expect(taps, 1);
  });
}
