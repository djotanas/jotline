import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/design_system/notebook_cover_tile.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

Future<void> _pump(
  WidgetTester tester, {
  String title = 'Viagem a Lisboa',
  VoidCallback? onTap,
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(
          width: 164,
          child: NotebookCoverTile(
            color: NotebookColor.mostarda,
            pattern: CoverPattern.pontilhada,
            title: title,
            meta: '12 páginas · hoje',
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

TextStyle _style(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(text).text.style!;

Finder _outside(String text) => find.descendant(
  of: find.byType(NotebookCoverTile),
  matching: find.byWidgetPredicate(
    (w) => w is Text && w.data == text,
    skipOffstage: false,
  ),
);

void main() {
  testWidgets('COMP-07: tile shows the cover with color, pattern and the '
      'title as label, 196 px high', (tester) async {
    await _pump(tester);

    final cover = tester.widget<NotebookCover>(find.byType(NotebookCover));
    expect(cover.color, NotebookColor.mostarda);
    expect(cover.pattern, CoverPattern.pontilhada);
    expect(cover.label, 'Viagem a Lisboa');
    expect(tester.getSize(find.byType(NotebookCover)).height, 196);
  });

  testWidgets('COMP-07: title uses cardTitulo and meta uses meta', (
    tester,
  ) async {
    await _pump(tester);

    final title = find.descendant(
      of: find.byType(NotebookCoverTile),
      matching: find.text('Viagem a Lisboa'),
    );
    expect(title, findsNWidgets(2));
    final titleStyle = _style(tester, title.last);
    expect(titleStyle.fontSize, 15);
    expect(titleStyle.fontWeight, FontWeight.w600);
    expect(titleStyle.color, _colors.ink1);

    final metaStyle = _style(tester, find.text('12 páginas · hoje'));
    expect(metaStyle.fontFamily, JotTextStyles.fontMeta);
    expect(metaStyle.fontSize, 12);
    expect(metaStyle.color, _colors.ink2);
  });

  testWidgets('COMP-07: tapping the tile calls onTap', (tester) async {
    var taps = 0;
    await _pump(tester, onTap: () => taps++);

    await tester.tap(find.byType(NotebookCoverTile));

    expect(taps, 1);
  });

  testWidgets('COMP-07: a tappable tile is a button in semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, onTap: () {});

    expect(
      tester.getSemantics(find.byType(NotebookCoverTile)),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        label: 'Viagem a Lisboa\n12 páginas · hoje',
      ),
    );
    handle.dispose();
  });

  testWidgets('edge case: long title ellipsizes', (tester) async {
    const long = 'Um caderno com um nome muito comprido para a grade';
    await _pump(tester, title: long);

    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(_outside(long).last);
    expect(paragraph.maxLines, 1);
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
