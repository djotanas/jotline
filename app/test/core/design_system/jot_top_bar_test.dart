import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/design_system/jot_top_bar.dart';
import 'package:jotline/core/theme/jot_colors.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;

const _longTitle =
    'Um caderno com um nome muito longo que não cabe na largura da barra';

Future<void> _pump(WidgetTester tester, Widget bar, {double textScale = 1}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 320, child: bar),
      ),
    ),
  );
}

Widget _optionsAction() => JotIconButton(
  icon: JotIconGlyph.more,
  semanticLabel: 'Opções do caderno',
  onPressed: () {},
);

void main() {
  group('COMP-12', () {
    testWidgets('COMP-12: back mode shows the back glyph and the previous '
        'label in accent', (tester) async {
      await _pump(
        tester,
        JotTopBar.back(previousLabel: 'Cadernos', onBack: () {}),
      );

      final glyphs = tester
          .widgetList<JotIcon>(find.byType(JotIcon))
          .map((i) => i.glyph);
      expect(glyphs, contains(JotIconGlyph.back));
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byWidgetPredicate(
                        (w) => w is JotIcon && w.glyph == JotIconGlyph.back,
                      ),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as JotIconPainter;
      expect(painter.color, _colors.accent);
      final style = tester
          .renderObject<RenderParagraph>(find.text('Cadernos'))
          .text
          .style!;
      expect(style.color, _colors.accent);
    });

    testWidgets('COMP-12: tapping back calls onBack', (tester) async {
      var backs = 0;
      await _pump(
        tester,
        JotTopBar.back(previousLabel: 'Cadernos', onBack: () => backs++),
      );

      await tester.tap(find.text('Cadernos'));

      expect(backs, 1);
    });

    testWidgets('COMP-12: back mode exposes a button with at least 44 px', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        JotTopBar.back(previousLabel: 'Cadernos', onBack: () {}),
      );

      final node = tester.getSemantics(find.text('Cadernos'));
      expect(
        node,
        isSemantics(label: 'Cadernos', isButton: true, hasTapAction: true),
      );
      expect(node.rect.height, greaterThanOrEqualTo(44));
      handle.dispose();
    });

    testWidgets('COMP-12: back mode renders the actions on the right', (
      tester,
    ) async {
      await _pump(
        tester,
        JotTopBar.back(
          previousLabel: 'Cadernos',
          onBack: () {},
          actions: [_optionsAction()],
        ),
      );

      expect(find.byType(JotIconButton), findsOneWidget);
      expect(
        tester.getTopRight(find.byType(JotIconButton)).dx,
        tester.getTopRight(find.byType(JotTopBar)).dx,
      );
    });

    testWidgets('COMP-12: root mode title uses tituloTela', (tester) async {
      await _pump(tester, const JotTopBar.root(title: 'Cadernos'));

      final style = tester
          .renderObject<RenderParagraph>(find.text('Cadernos'))
          .text
          .style!;
      expect(style.fontSize, 34);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.letterSpacing, -0.02 * 34);
      expect(style.color, _colors.ink1);
    });

    testWidgets('COMP-12: root mode renders the icon actions on the right', (
      tester,
    ) async {
      await _pump(
        tester,
        JotTopBar.root(
          title: 'Cadernos',
          actions: [
            JotIconButton(
              icon: JotIconGlyph.search,
              semanticLabel: 'Buscar',
              onPressed: () {},
            ),
            _optionsAction(),
          ],
        ),
      );

      expect(find.byType(JotIconButton), findsNWidgets(2));
      expect(
        tester.getTopRight(find.byType(JotIconButton).last).dx,
        tester.getTopRight(find.byType(JotTopBar)).dx,
      );
      expect(
        tester.getTopLeft(find.byType(JotIconButton).first).dx,
        greaterThanOrEqualTo(tester.getTopRight(find.text('Cadernos')).dx),
      );
    });

    testWidgets('COMP-12: a long root title ellipsizes instead of '
        'overflowing', (tester) async {
      await _pump(
        tester,
        JotTopBar.root(title: _longTitle, actions: [_optionsAction()]),
      );

      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(_longTitle),
      );
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.didExceedMaxLines, isTrue);
    });

    testWidgets('COMP-12: a long back label ellipsizes instead of '
        'overflowing', (tester) async {
      await _pump(
        tester,
        JotTopBar.back(
          previousLabel: _longTitle,
          onBack: () {},
          actions: [_optionsAction()],
        ),
      );

      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(_longTitle),
      );
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.didExceedMaxLines, isTrue);
    });
  });

  testWidgets('text scale 2.0 renders both modes without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          JotTopBar.back(
            previousLabel: 'Cadernos',
            onBack: () {},
            actions: [_optionsAction()],
          ),
          JotTopBar.root(title: 'Cadernos', actions: [_optionsAction()]),
        ],
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
