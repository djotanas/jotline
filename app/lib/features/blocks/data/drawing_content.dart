import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:jotline/features/blocks/data/block_content.dart';

/// The persisted drawing tool ids (ADR 0039).
enum DrawingTool {
  pen('pen'),
  highlighter('highlighter');

  new(this.id);

  final String id;

  /// An unknown identifier reads as [pen].
  static DrawingTool fromId(String id) {
    for (final tool in values) {
      if (tool.id == id) return tool;
    }
    return pen;
  }
}

/// The persisted drawing color ids (ADR 0039).
enum DrawingColor {
  ink('ink'),
  accent('accent'),
  danger('danger');

  new(this.id);

  final String id;

  /// An unknown identifier reads as [ink].
  static DrawingColor fromId(String id) {
    for (final color in values) {
      if (color.id == id) return color;
    }
    return ink;
  }
}

/// The stroke widths the drawing mode offers, in logical units.
enum StrokeWidth {
  thin(3),
  medium(6),
  thick(12);

  new(this.value);

  final double value;
}

double _round(double value, int factor) => (value * factor).round() / factor;

/// One point of a stroke in logical coordinates.
@immutable
final class StrokePoint {
  const new(this.x, this.y, this.pressure);

  factory fromJson(List<Object?> values) => StrokePoint(
    (values[0]! as num).toDouble(),
    (values[1]! as num).toDouble(),
    (values[2]! as num).toDouble(),
  );

  final double x;
  final double y;
  final double pressure;

  List<double> toJson() => [
    _round(x, 10),
    _round(y, 10),
    _round(pressure, 100),
  ];

  @override
  bool operator ==(Object other) =>
      other is StrokePoint &&
      other.x == x &&
      other.y == y &&
      other.pressure == pressure;

  @override
  int get hashCode => Object.hash(x, y, pressure);

  @override
  String toString() => 'StrokePoint($x, $y, $pressure)';
}

/// One stroke: the tool, color and width chosen and the points drawn.
@immutable
final class Stroke {
  const new({
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
  });

  final DrawingTool tool;
  final DrawingColor color;
  final double width;
  final List<StrokePoint> points;

  Map<String, Object> toJson() => {
    'tool': tool.id,
    'color': color.id,
    'width': width == width.roundToDouble() ? width.toInt() : width,
    'points': [for (final point in points) point.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is Stroke &&
      other.tool == tool &&
      other.color == color &&
      other.width == width &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(tool, color, width, Object.hashAll(points));
}

/// The content of a drawing block as stored in `content_json` (DRAW-19).
///
/// Holds no field of the drawing library.
@immutable
final class DrawingContent implements StoredContent {
  const new(this.strokes);

  /// Parses `content_json`; a value that does not parse reads as no strokes.
  factory fromJson(String source) {
    try {
      final json = jsonDecode(source) as Map<String, Object?>;
      final strokes = <Stroke>[];
      for (final raw in json['strokes']! as List<Object?>) {
        final stroke = raw! as Map<String, Object?>;
        strokes.add(
          Stroke(
            tool: DrawingTool.fromId(stroke['tool']! as String),
            color: DrawingColor.fromId(stroke['color']! as String),
            width: (stroke['width']! as num).toDouble(),
            points: [
              for (final point in stroke['points']! as List<Object?>)
                StrokePoint.fromJson(point! as List<Object?>),
            ],
          ),
        );
      }
      return DrawingContent(strokes);
    } on Object catch (error) {
      developer.log(
        'content_json does not parse',
        name: 'jotline.editor',
        error: error,
      );
      return const DrawingContent([]);
    }
  }

  /// The logical drawing area every point is stored in (DRAW-03).
  static const Size logicalSize = Size(390, 560);

  final List<Stroke> strokes;

  bool get isEmpty => strokes.isEmpty;

  @override
  String toJson() => jsonEncode({
    'strokes': [for (final stroke in strokes) stroke.toJson()],
  });

  @override
  bool operator ==(Object other) =>
      other is DrawingContent && listEquals(other.strokes, strokes);

  @override
  int get hashCode => Object.hashAll(strokes);
}
