import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/notebook_cover.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/core/theme/jot_shadows.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

import '../../helpers/pump_jot.dart';

const JotColors _colors = JotColors.light;
const double _width = 164;
const double _height = 196;

Future<void> _pump(
  WidgetTester tester, {
  NotebookColor color = NotebookColor.azulTinta,
  CoverPattern pattern = CoverPattern.lisa,
  String? label = 'Viagem a Lisboa',
  double textScale = 1,
}) {
  return tester.pumpJot(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(
        child: SizedBox(
          width: _width,
          height: _height,
          child: NotebookCover(color: color, pattern: pattern, label: label),
        ),
      ),
    ),
  );
}

RenderObject _coverPaint(WidgetTester tester) {
  return tester.renderObject(
    find.descendant(
      of: find.byType(NotebookCover),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is NotebookCoverPainter,
      ),
    ),
  );
}

PaintPattern _paintsNone(List<Color> colors) {
  final excluded = colors.map((c) => c.toARGB32()).toSet();
  return paints..everything(
    (method, args) => args.whereType<Paint>().every(
      (p) => !excluded.contains(p.color.toARGB32()),
    ),
  );
}

void main() {
  testWidgets('COMP-07: paints every color and pattern', (tester) async {
    for (final color in NotebookColor.values) {
      for (final pattern in CoverPattern.values) {
        await _pump(tester, color: color, pattern: pattern);

        expect(tester.takeException(), isNull);
        expect(
          _coverPaint(tester),
          paints..rect(
            rect: const Rect.fromLTWH(0, 0, _width, _height),
            color: color.color,
          ),
        );
      }
    }
  });

  testWidgets('COMP-07: paints the spine and the elastic', (tester) async {
    await _pump(tester);

    expect(
      _coverPaint(tester),
      paints
        ..rect(color: NotebookColor.azulTinta.color)
        ..rect(
          rect: const Rect.fromLTWH(
            0,
            0,
            NotebookCoverPaint.spineWidth,
            _height,
          ),
          color: NotebookCoverPaint.spineColor,
        )
        ..rect(
          rect: const Rect.fromLTWH(
            _width -
                NotebookCoverPaint.elasticInset -
                NotebookCoverPaint.elasticWidth,
            0,
            NotebookCoverPaint.elasticWidth,
            _height,
          ),
          color: NotebookCoverPaint.elasticColor,
        ),
    );
  });

  testWidgets('COMP-07: pautada paints 1 px white lines every 14 px', (
    tester,
  ) async {
    await _pump(tester, pattern: CoverPattern.pautada);

    expect(
      _coverPaint(tester),
      paints
        ..rect(color: NotebookColor.azulTinta.color)
        ..rect(
          rect: const Rect.fromLTWH(0, 13, _width, 1),
          color: NotebookCoverPaint.ruledColor,
        )
        ..rect(
          rect: const Rect.fromLTWH(0, 27, _width, 1),
          color: NotebookCoverPaint.ruledColor,
        ),
    );
  });

  testWidgets('COMP-07: pontilhada paints white dots of radius 1.2 on a '
      '12 px grid', (tester) async {
    await _pump(tester, pattern: CoverPattern.pontilhada);

    expect(
      _coverPaint(tester),
      paints
        ..rect(color: NotebookColor.azulTinta.color)
        ..circle(
          x: 6,
          y: 6,
          radius: NotebookCoverPaint.dotRadius,
          color: NotebookCoverPaint.dotColor,
        )
        ..circle(
          x: 6,
          y: 18,
          radius: NotebookCoverPaint.dotRadius,
          color: NotebookCoverPaint.dotColor,
        ),
    );
  });

  testWidgets('COMP-07: quadriculada paints 1 px white grid lines every '
      '14 px', (tester) async {
    await _pump(tester, pattern: CoverPattern.quadriculada);

    expect(
      _coverPaint(tester),
      paints
        ..rect(color: NotebookColor.azulTinta.color)
        ..rect(
          rect: const Rect.fromLTWH(0, 0, _width, 1),
          color: NotebookCoverPaint.gridColor,
        )
        ..rect(
          rect: const Rect.fromLTWH(0, 14, _width, 1),
          color: NotebookCoverPaint.gridColor,
        )
        ..something(
          (method, args) =>
              method == #drawRect &&
              args[0] == const Rect.fromLTWH(0, 0, 1, _height) &&
              (args[1] as Paint).color.toARGB32() ==
                  NotebookCoverPaint.gridColor.toARGB32(),
        )
        ..rect(
          rect: const Rect.fromLTWH(14, 0, 1, _height),
          color: NotebookCoverPaint.gridColor,
        ),
    );
  });

  testWidgets('COMP-07: lisa paints no pattern', (tester) async {
    await _pump(tester);

    expect(
      _coverPaint(tester),
      _paintsNone([
        NotebookCoverPaint.ruledColor,
        NotebookCoverPaint.dotColor,
        NotebookCoverPaint.gridColor,
      ]),
    );
  });

  testWidgets('COMP-07: label is shown on bgPapel with rEtiqueta', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Viagem a Lisboa'), findsOneWidget);
    final label = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('Viagem a Lisboa'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = label.decoration as BoxDecoration;
    expect(decoration.color, _colors.bgPapel);
    expect(decoration.borderRadius, BorderRadius.circular(JotRadius.rEtiqueta));
    final style = tester
        .renderObject<RenderParagraph>(find.text('Viagem a Lisboa'))
        .text
        .style!;
    expect(style.fontSize, 14);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, _colors.ink1);
  });

  testWidgets('COMP-07: without a label no text is shown', (tester) async {
    await _pump(tester, label: null);

    expect(
      find.descendant(
        of: find.byType(NotebookCover),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
  });

  testWidgets('COMP-07: cover uses shadowCapa and rCapa', (tester) async {
    await _pump(tester);

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(NotebookCover),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.boxShadow, JotShadows.light.capa);
    expect(decoration.borderRadius, JotRadius.rCapa);
    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(NotebookCover),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, JotRadius.rCapa);
  });

  testWidgets('COMP-07: mini cover paints color and pattern without spine, '
      'elastic, label or shadow, with rCapa halved', (tester) async {
    await tester.pumpJot(
      const Center(
        child: SizedBox(
          width: 36,
          height: 46,
          child: NotebookCover.mini(
            color: NotebookColor.musgo,
            pattern: CoverPattern.pautada,
          ),
        ),
      ),
    );

    final paint = _coverPaint(tester);
    expect(
      paint,
      paints
        ..rect(
          rect: const Rect.fromLTWH(0, 0, 36, 46),
          color: NotebookColor.musgo.color,
        )
        ..rect(
          rect: const Rect.fromLTWH(0, 13, 36, 1),
          color: NotebookCoverPaint.ruledColor,
        ),
    );
    expect(
      paint,
      _paintsNone([
        NotebookCoverPaint.spineColor,
        NotebookCoverPaint.elasticColor,
      ]),
    );
    expect(
      find.descendant(
        of: find.byType(NotebookCover),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(NotebookCover),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, JotRadius.rCapa * 0.5);
  });

  testWidgets('edge case: long label ellipsizes', (tester) async {
    const long =
        'Um caderno com um nome muito comprido que não cabe na etiqueta';
    await _pump(tester, label: long);

    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(long));
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
  });

  testWidgets('text scale 2.0 renders without overflow', (tester) async {
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
