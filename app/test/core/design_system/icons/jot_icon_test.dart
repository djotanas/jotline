import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/theme/jot_colors.dart';

import '../../../helpers/pump_jot.dart';

class _Draw {
  new(this.kind, Paint paint, {this.center, this.radius})
    : color = paint.color,
      style = paint.style,
      strokeWidth = paint.strokeWidth,
      strokeCap = paint.strokeCap,
      strokeJoin = paint.strokeJoin;

  final String kind;
  final Color color;
  final PaintingStyle style;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final Offset? center;
  final double? radius;
}

class _RecordingCanvas implements Canvas {
  final draws = <_Draw>[];
  final scales = <Offset>[];

  @override
  void scale(double sx, [double? sy]) => scales.add(Offset(sx, sy ?? sx));

  @override
  void drawPath(Path path, Paint paint) => draws.add(_Draw('path', paint));

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      draws.add(_Draw('circle', paint, center: c, radius: radius));

  @override
  void drawRRect(RRect rrect, Paint paint) => draws.add(_Draw('rrect', paint));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

_RecordingCanvas _paint(
  JotIconGlyph glyph, {
  Color color = const Color.from(alpha: 1, red: 0, green: 0, blue: 0),
  double strokeWidth = 1.8,
  double size = 24,
}) {
  final canvas = _RecordingCanvas();
  JotIconPainter(
    glyph: glyph,
    color: color,
    strokeWidth: strokeWidth,
  ).paint(canvas, Size.square(size));
  return canvas;
}

JotIconPainter _painterOf(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(JotIcon),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as JotIconPainter;
}

void main() {
  group('COMP-14', () {
    test('COMP-14: the ten canvas glyphs exist', () {
      expect(JotIconGlyph.values, [
        JotIconGlyph.search,
        JotIconGlyph.sort,
        JotIconGlyph.trash,
        JotIconGlyph.add,
        JotIconGlyph.back,
        JotIconGlyph.more,
        JotIconGlyph.dragHandle,
        JotIconGlyph.heading,
        JotIconGlyph.checklist,
        JotIconGlyph.drawing,
      ]);
    });

    testWidgets('COMP-14: renders at 22 px with stroke 1.8 by default', (
      tester,
    ) async {
      await tester.pumpJot(const Center(child: JotIcon(JotIconGlyph.search)));

      expect(tester.getSize(find.byType(JotIcon)), const Size(22, 22));
      expect(_painterOf(tester).strokeWidth, 1.8);
    });

    test('COMP-14: the 24 grid is scaled to the rendered size', () {
      final canvas = _paint(JotIconGlyph.search, size: 22);

      expect(canvas.scales, [const Offset(22 / 24, 22 / 24)]);
    });

    testWidgets('COMP-14: color is inherited from IconTheme', (tester) async {
      await tester.pumpJot(
        Center(
          child: IconTheme(
            data: IconThemeData(color: JotColors.light.danger),
            child: const JotIcon(JotIconGlyph.trash),
          ),
        ),
      );

      expect(_painterOf(tester).color, JotColors.light.danger);
    });

    testWidgets('COMP-14: size and strokeWidth parameters are honored', (
      tester,
    ) async {
      await tester.pumpJot(
        const Center(
          child: JotIcon(JotIconGlyph.trash, size: 40, strokeWidth: 1.4),
        ),
      );

      expect(tester.getSize(find.byType(JotIcon)), const Size(40, 40));
      expect(_painterOf(tester).strokeWidth, 1.4);
    });

    test('COMP-14: every glyph paints in the given color with round ends', () {
      final color = JotColors.light.accent;
      for (final glyph in JotIconGlyph.values) {
        final canvas = _paint(glyph, color: color, strokeWidth: 1.4);

        expect(canvas.draws, isNotEmpty, reason: '$glyph draws nothing');
        for (final draw in canvas.draws) {
          expect(draw.color, isSameColorAs(color), reason: '$glyph');
          if (draw.style == PaintingStyle.stroke) {
            expect(
              draw.strokeWidth,
              moreOrLessEquals(1.4, epsilon: 1e-6),
              reason: '$glyph',
            );
            expect(draw.strokeCap, StrokeCap.round, reason: '$glyph');
            expect(draw.strokeJoin, StrokeJoin.round, reason: '$glyph');
          }
        }
      }
    });

    test('COMP-14: each glyph draws the canvas SVG shapes', () {
      final expected = {
        JotIconGlyph.search: ['circle', 'path'],
        JotIconGlyph.sort: ['path'],
        JotIconGlyph.trash: ['path', 'path', 'path'],
        JotIconGlyph.add: ['path'],
        JotIconGlyph.back: ['path'],
        JotIconGlyph.more: ['circle', 'circle', 'circle'],
        JotIconGlyph.dragHandle: List.filled(6, 'circle'),
        JotIconGlyph.heading: ['path'],
        JotIconGlyph.checklist: ['rrect', 'path', 'rrect', 'path'],
        JotIconGlyph.drawing: ['path', 'path'],
      };
      for (final MapEntry(key: glyph, value: kinds) in expected.entries) {
        expect(
          _paint(glyph).draws.map((d) => d.kind).toList(),
          kinds,
          reason: '$glyph',
        );
      }
    });

    test('COMP-14: search lens is a stroked circle at 11,11 radius 7', () {
      final lens = _paint(JotIconGlyph.search).draws.first;

      expect(lens.style, PaintingStyle.stroke);
      expect(lens.center, const Offset(11, 11));
      expect(lens.radius, 7);
    });

    test('COMP-14: options and handle are filled dots from the canvas', () {
      final more = _paint(JotIconGlyph.more).draws;
      expect(more.map((d) => d.center), const [
        Offset(5, 12),
        Offset(12, 12),
        Offset(19, 12),
      ]);
      expect(more.every((d) => d.radius == 1.8), isTrue);
      expect(more.every((d) => d.style == PaintingStyle.fill), isTrue);

      final handle = _paint(JotIconGlyph.dragHandle).draws;
      expect(handle.map((d) => d.center), const [
        Offset(9, 6),
        Offset(15, 6),
        Offset(9, 12),
        Offset(15, 12),
        Offset(9, 18),
        Offset(15, 18),
      ]);
      expect(handle.every((d) => d.radius == 1.6), isTrue);
      expect(handle.every((d) => d.style == PaintingStyle.fill), isTrue);
    });

    testWidgets('COMP-14: every glyph renders in the widget tree', (
      tester,
    ) async {
      await tester.pumpJot(
        Wrap(
          children: [for (final glyph in JotIconGlyph.values) JotIcon(glyph)],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(JotIcon), findsNWidgets(10));
    });

    testWidgets('COMP-14: text scale 2.0 renders without overflow', (
      tester,
    ) async {
      await tester.pumpJot(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Wrap(
            children: [for (final glyph in JotIconGlyph.values) JotIcon(glyph)],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(JotIcon).first), const Size(22, 22));
    });
  });
}
