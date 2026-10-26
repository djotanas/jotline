import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';

DrawingContent _single(List<StrokePoint> points) => DrawingContent([
  Stroke(
    tool: DrawingTool.pen,
    color: DrawingColor.ink,
    width: 3,
    points: points,
  ),
]);

StrokePoint _roundTripPoint(StrokePoint point) =>
    DrawingContent.fromJson(_single([point]).toJson())
        .strokes
        .single
        .points
        .single;

void main() {
  group('DrawingContent JSON', () {
    test('DRAW-19: round trip keeps tool, color, width and points', () {
      const content = DrawingContent([
        Stroke(
          tool: DrawingTool.highlighter,
          color: DrawingColor.accent,
          width: 6,
          points: [StrokePoint(60, 470, 0.5), StrokePoint(100.4, 440, 0.62)],
        ),
        Stroke(
          tool: DrawingTool.pen,
          color: DrawingColor.danger,
          width: 12,
          points: [StrokePoint(1, 2, 0.1), StrokePoint(3, 4, 1)],
        ),
      ]);

      expect(DrawingContent.fromJson(content.toJson()), content);
    });

    test('DRAW-19: writes the exact shape of the ADR example', () {
      const content = DrawingContent([
        Stroke(
          tool: DrawingTool.highlighter,
          color: DrawingColor.accent,
          width: 6,
          points: [StrokePoint(60, 470, 0.5), StrokePoint(100.4, 440, 0.62)],
        ),
      ]);

      expect(
        content.toJson(),
        '{"strokes":[{"tool":"highlighter","color":"accent","width":6,'
        '"points":[[60.0,470.0,0.5],[100.4,440.0,0.62]]}]}',
      );
    });

    test('DRAW-19: writes no field outside strokes, tool, color, width and '
        'points [x, y, pressure]', () {
      final json = jsonDecode(
        const DrawingContent([
          Stroke(
            tool: DrawingTool.pen,
            color: DrawingColor.ink,
            width: 3,
            points: [StrokePoint(1, 2, 0.5)],
          ),
        ]).toJson(),
      ) as Map<String, Object?>;

      expect(json.keys, ['strokes']);
      final stroke = (json['strokes']! as List<Object?>).single! as Map;
      expect(stroke.keys, ['tool', 'color', 'width', 'points']);
      expect(stroke['points'], [
        [1.0, 2.0, 0.5],
      ]);
    });

    test('DRAW-19: tool, color and width ids are the persisted ones', () {
      expect(DrawingTool.values.map((tool) => tool.id), ['pen', 'highlighter']);
      expect(DrawingColor.values.map((color) => color.id), [
        'ink',
        'accent',
        'danger',
      ]);
      expect(StrokeWidth.values.map((width) => width.value), [3, 6, 12]);
    });

    test('DRAW-03: the logical area is 390 x 560', () {
      expect(DrawingContent.logicalSize, const Size(390, 560));
    });

    test('DRAW-19: a coordinate at x.05 rounds up to 0.1 and at x.04 down', () {
      expect(_roundTripPoint(const StrokePoint(12.05, 0.05, 0.5)).x, 12.1);
      expect(_roundTripPoint(const StrokePoint(12.05, 0.05, 0.5)).y, 0.1);
      expect(_roundTripPoint(const StrokePoint(12.04, 0.04, 0.5)).x, 12.0);
      expect(_roundTripPoint(const StrokePoint(12.04, 0.04, 0.5)).y, 0);
    });

    test('DRAW-19: pressure rounds to 0.01 at 0.505 and 0.504', () {
      expect(_roundTripPoint(const StrokePoint(1, 1, 0.505)).pressure, 0.51);
      expect(_roundTripPoint(const StrokePoint(1, 1, 0.504)).pressure, 0.5);
    });

    test('DRAW-19: an unknown tool id reads as pen', () {
      final content = DrawingContent.fromJson(
        '{"strokes":[{"tool":"brush","color":"accent","width":6,'
        '"points":[[1,2,0.5]]}]}',
      );

      expect(content.strokes.single.tool, DrawingTool.pen);
      expect(content.strokes.single.color, DrawingColor.accent);
    });

    test('DRAW-19: an unknown color id reads as ink', () {
      final content = DrawingContent.fromJson(
        '{"strokes":[{"tool":"highlighter","color":"magenta","width":6,'
        '"points":[[1,2,0.5]]}]}',
      );

      expect(content.strokes.single.color, DrawingColor.ink);
      expect(content.strokes.single.tool, DrawingTool.highlighter);
    });

    test('EDGE-07: JSON that does not parse reads as no strokes', () {
      for (final source in ['', 'not json', '[]', '{"strokes":[{"tool":1}]}']) {
        final content = DrawingContent.fromJson(source);

        expect(content.strokes, isEmpty, reason: source);
        expect(content.isEmpty, isTrue, reason: source);
      }
    });

    test('EDGE-06: a stroke with a single point survives the round trip', () {
      final content = DrawingContent.fromJson(
        _single(const [StrokePoint(44, 300, 0.5)]).toJson(),
      );

      expect(content.strokes, hasLength(1));
      expect(content.strokes.single.points, const [StrokePoint(44, 300, 0.5)]);
    });

    test('DRAW-19: an empty drawing writes an empty list of strokes', () {
      expect(const DrawingContent([]).toJson(), '{"strokes":[]}');
    });
  });
}
