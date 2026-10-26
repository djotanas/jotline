import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_painter.dart';

const ValueKey<String> _key = ValueKey('canvas');

Stroke _stroke({
  DrawingTool tool = DrawingTool.pen,
  DrawingColor color = DrawingColor.ink,
  double width = 6,
  List<StrokePoint> points = const [
    StrokePoint(40, 100, 0.5),
    StrokePoint(120, 160, 0.5),
    StrokePoint(200, 120, 0.5),
    StrokePoint(300, 240, 0.5),
  ],
}) => Stroke(tool: tool, color: color, width: width, points: points);

Future<RenderObject> _paint(
  WidgetTester tester,
  List<Stroke> strokes, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: CustomPaint(
          key: _key,
          size: DrawingContent.logicalSize * scale,
          painter: DrawingPainter(
            content: DrawingContent(strokes),
            scale: scale,
            colors: JotColors.light,
          ),
        ),
      ),
    ),
  );
  return tester.renderObject(find.byKey(_key));
}

void main() {
  const colors = JotColors.light;

  group('DrawingPainter', () {
    test('DRAW-12: the stroke path bounds scale with the scale factor', () {
      final stroke = _stroke();

      final small = DrawingPainter.strokePath(stroke, 1).getBounds();
      final large = DrawingPainter.strokePath(stroke, 2).getBounds();

      expect(large.width, closeTo(small.width * 2, small.width * 0.02));
      expect(large.height, closeTo(small.height * 2, small.height * 0.02));
      expect(large.left, closeTo(small.left * 2, small.width * 0.02));
      expect(large.top, closeTo(small.top * 2, small.height * 0.02));
    });

    test('DRAW-06: the highlighter is drawn at 3 times the selected width', () {
      final highlighter = DrawingPainter.strokePath(
        _stroke(tool: DrawingTool.highlighter, width: 3),
        1,
      ).getBounds();
      final wide = DrawingPainter.strokePath(_stroke(width: 9), 1).getBounds();
      final same = DrawingPainter.strokePath(_stroke(width: 3), 1).getBounds();

      expect(highlighter, wide);
      expect(highlighter, isNot(same));
    });

    testWidgets('DRAW-06: the highlighter paints at 35 % opacity', (
      tester,
    ) async {
      final canvas = await _paint(tester, [
        _stroke(tool: DrawingTool.highlighter, color: DrawingColor.accent),
      ]);

      expect(
        canvas,
        paints..path(color: colors.accent.withValues(alpha: 0.35)),
      );
    });

    testWidgets('DRAW-05: the pen paints opaque', (tester) async {
      final canvas = await _paint(tester, [_stroke()]);

      expect(canvas, paints..path(color: colors.ink1));
    });

    testWidgets('DRAW-04: each color id paints with its theme token', (
      tester,
    ) async {
      final canvas = await _paint(tester, [
        _stroke(),
        _stroke(color: DrawingColor.accent),
        _stroke(color: DrawingColor.danger),
      ]);

      expect(
        canvas,
        paints
          ..path(color: colors.ink1)
          ..path(color: colors.accent)
          ..path(color: colors.danger),
      );
    });

    test('EDGE-06: a stroke with one point paints a non-empty dot', () {
      final bounds = DrawingPainter.strokePath(
        _stroke(points: const [StrokePoint(100, 100, 0.5)], width: 12),
        1,
      ).getBounds();

      expect(bounds.isEmpty, isFalse);
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
      expect(bounds.contains(const Offset(100, 100)), isTrue);
    });

    test(
      'DRAW-12: shouldRepaint is true only when content or scale changes',
      () {
        final content = DrawingContent([_stroke()]);
        DrawingPainter painter(DrawingContent content, double scale) =>
            DrawingPainter(content: content, scale: scale, colors: colors);

        final base = painter(content, 1);

        expect(
          base.shouldRepaint(painter(DrawingContent([_stroke()]), 1)),
          false,
        );
        expect(base.shouldRepaint(painter(const DrawingContent([]), 1)), true);
        expect(base.shouldRepaint(painter(content, 2)), true);
      },
    );
  });
}
