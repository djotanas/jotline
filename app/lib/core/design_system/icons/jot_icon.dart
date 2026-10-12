import 'package:flutter/widgets.dart';

/// The icons of the canvas, drawn on a 24 grid.
enum JotIconGlyph {
  search,
  sort,
  trash,
  add,
  back,
  more,
  dragHandle,
  heading,
  checklist,
  drawing,
  edit,
  cover,
  archive,
  unarchive,
  check,
  page,
  notebook,
}

/// A canvas icon painted with the color of the surrounding [IconTheme].
class JotIcon extends StatelessWidget {
  const new(this.glyph, {super.key, this.size = 22, this.strokeWidth = 1.8});

  final JotIconGlyph glyph;
  final double size;

  /// Stroke width in units of the 24 grid.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: JotIconPainter(
          glyph: glyph,
          color: IconTheme.of(context).color!,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

/// Paints a [JotIconGlyph] from the canvas SVG geometry.
class JotIconPainter extends CustomPainter {
  const new({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  static const double grid = 24;

  final JotIconGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / grid, size.height / grid);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (glyph) {
      case JotIconGlyph.search:
        canvas
          ..drawCircle(const Offset(11, 11), 7, stroke)
          ..drawPath(_lines([(20, 20, 16.5, 16.5)]), stroke);
      case JotIconGlyph.sort:
        canvas.drawPath(
          _lines([(4, 7, 20, 7), (7, 12, 17, 12), (10, 17, 14, 17)]),
          stroke,
        );
      case JotIconGlyph.trash:
        canvas
          ..drawPath(_lines([(4, 7, 20, 7)]), stroke)
          ..drawPath(_polyline([(9, 7), (9, 4), (15, 4), (15, 7)]), stroke)
          ..drawPath(_polyline([(6, 7), (7, 20), (17, 20), (18, 7)]), stroke);
      case JotIconGlyph.add:
        canvas.drawPath(_lines([(12, 5, 12, 19), (5, 12, 19, 12)]), stroke);
      case JotIconGlyph.back:
        canvas.drawPath(_polyline([(15, 5), (8, 12), (15, 19)]), stroke);
      case JotIconGlyph.more:
        for (final x in const [5.0, 12.0, 19.0]) {
          canvas.drawCircle(Offset(x, 12), 1.8, fill);
        }
      case JotIconGlyph.dragHandle:
        for (final y in const [6.0, 12.0, 18.0]) {
          canvas
            ..drawCircle(Offset(9, y), 1.6, fill)
            ..drawCircle(Offset(15, y), 1.6, fill);
        }
      case JotIconGlyph.heading:
        canvas.drawPath(
          _lines([(5, 5, 5, 19), (14, 5, 14, 19), (5, 12, 14, 12)])
            ..addPath(_polyline([(18, 10), (20, 8.5), (20, 19)]), Offset.zero),
          stroke,
        );
      case JotIconGlyph.checklist:
        canvas
          ..drawRRect(_box(3, 4), stroke)
          ..drawPath(_polyline([(4.8, 7.5), (6.4, 9.1), (9, 6.1)]), stroke)
          ..drawRRect(_box(3, 14), stroke)
          ..drawPath(
            _lines([(14, 7.5, 21, 7.5), (14, 17.5, 21, 17.5)]),
            stroke,
          );
      case JotIconGlyph.drawing:
        canvas
          ..drawPath(
            Path()
              ..moveTo(3, 17)
              ..cubicTo(6, 12, 8, 19, 11, 14)
              ..cubicTo(14, 9, 15, 7, 18, 10),
            stroke,
          )
          ..drawPath(
            _polyline([(16, 4), (20, 8), (11, 17), (7, 17), (7, 13)])..close(),
            stroke,
          );
      case JotIconGlyph.edit:
        canvas
          ..drawPath(
            _polyline([(4, 20), (8, 20), (19, 9), (15, 5), (4, 16)])..close(),
            stroke,
          )
          ..drawPath(_lines([(13.5, 6.5, 17.5, 10.5)]), stroke);
      case JotIconGlyph.cover:
        canvas
          ..drawRRect(_cover, stroke)
          ..drawPath(_lines([(9, 3, 9, 21)]), stroke);
      case JotIconGlyph.archive:
        _paintArchiveBox(canvas, stroke);
        canvas.drawPath(_lines([(10, 13, 14, 13)]), stroke);
      case JotIconGlyph.unarchive:
        _paintArchiveBox(canvas, stroke);
        canvas
          ..drawPath(_lines([(12, 18, 12, 12)]), stroke)
          ..drawPath(_polyline([(9.5, 14.5), (12, 12), (14.5, 14.5)]), stroke);
      case JotIconGlyph.check:
        canvas.drawPath(_polyline([(5, 12.5), (9.5, 17), (19, 7.5)]), stroke);
      case JotIconGlyph.page:
        canvas
          ..drawPath(
            _polyline([(6, 3), (15, 3), (19, 7), (19, 21), (6, 21)])..close(),
            stroke,
          )
          ..drawPath(_polyline([(14, 3), (14, 8), (19, 8)]), stroke)
          ..drawPath(_lines([(9, 13, 16, 13), (9, 17, 14, 17)]), stroke);
      case JotIconGlyph.notebook:
        canvas
          ..drawRRect(_cover, stroke)
          ..drawPath(_lines([(9, 3, 9, 21), (12, 8, 16, 8)]), stroke);
    }
    canvas.restore();
  }

  static final RRect _cover = RRect.fromRectAndRadius(
    const Rect.fromLTWH(5, 3, 14, 18),
    const Radius.circular(2),
  );

  static void _paintArchiveBox(Canvas canvas, Paint stroke) {
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(3, 4, 18, 5),
          const Radius.circular(1),
        ),
        stroke,
      )
      ..drawPath(
        Path()
          ..moveTo(5, 9)
          ..lineTo(5, 19)
          ..arcToPoint(const Offset(6, 20), radius: const Radius.circular(1))
          ..lineTo(18, 20)
          ..arcToPoint(const Offset(19, 19), radius: const Radius.circular(1))
          ..lineTo(19, 9),
        stroke,
      );
  }

  static Path _lines(List<(double, double, double, double)> segments) {
    final path = Path();
    for (final (x1, y1, x2, y2) in segments) {
      path
        ..moveTo(x1, y1)
        ..lineTo(x2, y2);
    }
    return path;
  }

  static Path _polyline(List<(double, double)> points) {
    final (x0, y0) = points.first;
    final path = Path()..moveTo(x0, y0);
    for (final (x, y) in points.skip(1)) {
      path.lineTo(x, y);
    }
    return path;
  }

  static RRect _box(double x, double y) => RRect.fromRectAndRadius(
    Rect.fromLTWH(x, y, 7, 7),
    const Radius.circular(1.5),
  );

  @override
  bool shouldRepaint(JotIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
