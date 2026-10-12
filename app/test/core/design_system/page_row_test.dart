import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/page_row.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;
const _excerpt = 'Adaptador de tomada, capa de chuva, sapato…';

Future<void> _pump(
  WidgetTester tester, {
  String title = 'O que levar',
  String? excerpt = _excerpt,
  VoidCallback? onTap,
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(
          width: 320,
          child: PageRow(
            title: title,
            date: '05 out',
            excerpt: excerpt,
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  testWidgets('COMP-09: title uses itemTitulo', (tester) async {
    await _pump(tester);

    final style = _paragraph(tester, 'O que levar').text.style!;
    expect(style.fontFamily, JotTextStyles.fontUi);
    expect(style.fontSize, 16);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, _colors.ink1);
  });

  testWidgets('COMP-09: date uses meta', (tester) async {
    await _pump(tester);

    final style = _paragraph(tester, '05 out').text.style!;
    expect(style.fontFamily, JotTextStyles.fontMeta);
    expect(style.fontSize, 12);
    expect(style.color, _colors.ink2);
  });

  testWidgets('COMP-09: excerpt uses itemTrecho on one line', (tester) async {
    await _pump(tester);

    final paragraph = _paragraph(tester, _excerpt);
    final style = paragraph.text.style!;
    expect(style.fontFamily, JotTextStyles.fontTexto);
    expect(style.fontSize, 14);
    expect(style.height, 1.4);
    expect(style.color, _colors.ink2);
    expect(paragraph.maxLines, 1);
  });

  testWidgets('COMP-09: no excerpt is rendered when it is null', (
    tester,
  ) async {
    await _pump(tester, excerpt: null);

    expect(
      find.descendant(of: find.byType(PageRow), matching: find.byType(Text)),
      findsNWidgets(2),
    );
    expect(find.text('O que levar'), findsOneWidget);
    expect(find.text('05 out'), findsOneWidget);
  });

  testWidgets('COMP-09: row is bgFolha with a bgTrilho border and rCard', (
    tester,
  ) async {
    await _pump(tester);

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(PageRow),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, _colors.bgFolha);
    expect(decoration.border, Border.all(color: _colors.bgTrilho));
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rCard));
  });

  testWidgets('COMP-09: tapping the row calls onTap', (tester) async {
    var taps = 0;
    await _pump(tester, onTap: () => taps++);

    await tester.tap(find.byType(PageRow));

    expect(taps, 1);
  });

  testWidgets('edge case: long title and excerpt ellipsize', (tester) async {
    const title = 'Um título de página muito comprido que não cabe na linha';
    const excerpt =
        'Um trecho muito longo que continua por várias palavras e não cabe '
        'numa única linha da lista de páginas';
    await _pump(tester, title: title, excerpt: excerpt);

    expect(tester.takeException(), isNull);
    for (final text in [title, excerpt]) {
      final paragraph = _paragraph(tester, text);
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.didExceedMaxLines, isTrue);
    }
    expect(find.text('05 out'), findsOneWidget);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
