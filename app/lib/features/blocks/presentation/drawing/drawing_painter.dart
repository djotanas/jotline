import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_colors.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// Paints a drawing's strokes with `perfect_freehand`, scaled from the
/// logical area to the screen (DRAW-05, DRAW-06, DRAW-12).
class DrawingPainter extends CustomPainter {
  const new({required this.content, required this.scale, required this.colors});

  static const double _highlighterFactor = 3;
  static const double _highlighterOpacity = 0.35;

  final DrawingContent content;
  final double scale;
  final JotColors colors;

  /// The filled outline of [stroke] at [scale]; a single point is a dot
  /// (EDGE-06).
  static Path strokePath(Stroke stroke, double scale) {
    final size = stroke.tool == DrawingTool.highlighter
        ? stroke.width * _highlighterFactor
        : stroke.width;
    final center = [
      for (final point in stroke.points)
        PointVector(point.x * scale, point.y * scale, point.pressure),
    ];
    if (center.length == 1) {
      return Path()..addOval(
        Rect.fromCircle(center: center.single, radius: size * scale / 2),
      );
    }
    final outline = getStroke(
      center,
      options: StrokeOptions(
        size: size * scale,
        simulatePressure: false,
        isComplete: true,
      ),
    );
    return Path()..addPolygon(outline, true);
  }

  Color _color(Stroke stroke) {
    final base = switch (stroke.color) {
      DrawingColor.ink => colors.ink1,
      DrawingColor.accent => colors.accent,
      DrawingColor.danger => colors.danger,
    };
    return stroke.tool == DrawingTool.highlighter
        ? base.withValues(alpha: _highlighterOpacity)
        : base;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in content.strokes) {
      canvas.drawPath(
        strokePath(stroke, scale),
        Paint()
          ..color = _color(stroke)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) =>
      oldDelegate.content != content ||
      oldDelegate.scale != scale ||
      oldDelegate.colors != colors;
}
