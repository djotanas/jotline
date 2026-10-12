import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/archived_notebook_row.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/jot_text_styles.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

Future<void> _pump(
  WidgetTester tester, {
  String title = 'Mudança 2025',
  VoidCallback? onAction,
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(
          width: 340,
          child: ArchivedNotebookRow(
            color: NotebookColor.musgo,
            pattern: CoverPattern.lisa,
            title: title,
            meta: '17 páginas',
            actionLabel: 'Desarquivar',
            onAction: onAction ?? () {},
          ),
        ),
      ),
    ),
  );
}

TextStyle _style(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  testWidgets('COMP-09: shows a 34 x 46 mini cover in the notebook color and '
      'pattern at 85% opacity', (tester) async {
    await _pump(tester);

    final cover = find.byType(NotebookCover);
    expect(tester.getSize(cover), const Size(34, 46));
    final widget = tester.widget<NotebookCover>(cover);
    expect(widget.color, NotebookColor.musgo);
    expect(widget.pattern, CoverPattern.lisa);
    expect(widget.label, isNull);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: cover, matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.85);
  });

  testWidgets('COMP-09: title uses cardTitulo and meta uses meta', (
    tester,
  ) async {
    await _pump(tester);

    final title = _style(tester, 'Mudança 2025');
    expect(title.fontSize, 15);
    expect(title.fontWeight, FontWeight.w600);
    expect(title.color, _colors.ink1);
    final meta = _style(tester, '17 páginas');
    expect(meta.fontFamily, JotTextStyles.fontMeta);
    expect(meta.fontSize, 12);
    expect(meta.color, _colors.ink2);
  });

  testWidgets('COMP-09: action is a pill button with the given label', (
    tester,
  ) async {
    await _pump(tester);

    final button = find.byType(JotButton);
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.text('Desarquivar')),
      findsOneWidget,
    );
    final pill = tester.widget<DecoratedBox>(
      find.descendant(of: button, matching: find.byType(DecoratedBox)),
    );
    final decoration = pill.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rPilula));
    expect(decoration.border, Border.all(color: _colors.lineBase));
  });

  testWidgets('COMP-09: tapping the action calls onAction', (tester) async {
    var taps = 0;
    await _pump(tester, onAction: () => taps++);

    await tester.tap(find.text('Desarquivar'));

    expect(taps, 1);
  });

  testWidgets('COMP-09: row is bgFolha with a lineBase border and rCard', (
    tester,
  ) async {
    await _pump(tester);

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ArchivedNotebookRow),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, _colors.bgFolha);
    expect(decoration.border, Border.all(color: _colors.lineBase));
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rCard));
  });

  testWidgets('edge case: long title ellipsizes', (tester) async {
    const long = 'Um caderno arquivado com um nome muito comprido demais';
    await _pump(tester, title: long);

    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(long));
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(find.text('Desarquivar'), findsOneWidget);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
