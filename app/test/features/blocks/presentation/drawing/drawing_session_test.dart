import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_session.dart';

const Stroke _line = Stroke(
  tool: DrawingTool.pen,
  color: DrawingColor.ink,
  width: 6,
  points: [StrokePoint(0, 0, 0.5), StrokePoint(100, 0, 0.5)],
);

const Stroke _far = Stroke(
  tool: DrawingTool.pen,
  color: DrawingColor.accent,
  width: 6,
  points: [StrokePoint(0, 300, 0.5), StrokePoint(100, 300, 0.5)],
);

void _draw(DrawingSession session, List<Offset> points) {
  session.startStroke(points.first, 0.5);
  for (final point in points.skip(1).take(points.length - 2)) {
    session.extendStroke(point, 0.5);
  }
  session.endStroke(points.last, 0.5);
}

void _eraseDrag(DrawingSession session, List<Offset> points) {
  session.tool = DrawingModeTool.eraser;
  _draw(session, points);
}

void main() {
  test('DRAW-04: a new session starts with pen, thin and ink', () {
    final session = DrawingSession(const DrawingContent([]));

    expect(session.tool, DrawingModeTool.pen);
    expect(session.width, StrokeWidth.thin);
    expect(session.color, DrawingColor.ink);
  });

  test('DRAW-05: a pen drag stores one stroke with the selected color, '
      'width and every point', () {
    final session = DrawingSession(const DrawingContent([]))
      ..color = DrawingColor.danger
      ..width = StrokeWidth.medium;

    _draw(session, const [Offset(10, 20), Offset(30, 40), Offset(50, 60)]);

    expect(session.content.strokes, const [
      Stroke(
        tool: DrawingTool.pen,
        color: DrawingColor.danger,
        width: 6,
        points: [
          StrokePoint(10, 20, 0.5),
          StrokePoint(30, 40, 0.5),
          StrokePoint(50, 60, 0.5),
        ],
      ),
    ]);
    expect(session.isEmpty, isFalse);
  });

  test(
    'DRAW-06: the highlighter stores the selected width, not 3 times it',
    () {
      final session = DrawingSession(const DrawingContent([]))
        ..tool = DrawingModeTool.highlighter
        ..width = StrokeWidth.thick;

      _draw(session, const [Offset(10, 20), Offset(50, 60)]);

      final stroke = session.content.strokes.single;
      expect(stroke.tool, DrawingTool.highlighter);
      expect(stroke.width, 12);
    },
  );

  test('DRAW-07: the eraser removes a stroke whose segment is exactly '
      'width / 2 + 10 away', () {
    final session = DrawingSession(const DrawingContent([_line, _far]));

    _eraseDrag(session, const [Offset(50, 13), Offset(50, 13)]);

    expect(session.content.strokes, [_far]);
  });

  test('DRAW-07: the eraser keeps a stroke 0.1 beyond width / 2 + 10', () {
    final session = DrawingSession(const DrawingContent([_line, _far]));

    _eraseDrag(session, const [Offset(50, 13.1), Offset(50, 13.1)]);

    expect(session.content.strokes, [_line, _far]);
  });

  test('DRAW-07: the eraser removes a single-point stroke within reach', () {
    const dot = Stroke(
      tool: DrawingTool.pen,
      color: DrawingColor.ink,
      width: 6,
      points: [StrokePoint(200, 200, 0.5)],
    );
    final session = DrawingSession(const DrawingContent([dot]));

    _eraseDrag(session, const [Offset(205, 212), Offset(205, 212)]);

    expect(session.content.strokes, isEmpty);
    expect(session.isEmpty, isTrue);
  });

  test('DRAW-07: an eraser drag stores no stroke of its own', () {
    final session = DrawingSession(const DrawingContent([_far]));

    _eraseDrag(session, const [Offset(50, 100), Offset(60, 100)]);

    expect(session.content.strokes, [_far]);
    expect(session.canUndo, isFalse);
  });

  test('DRAW-08: one eraser drag removes several strokes and one undo '
      'restores them in their order', () {
    const middle = Stroke(
      tool: DrawingTool.pen,
      color: DrawingColor.ink,
      width: 3,
      points: [StrokePoint(0, 150, 0.5), StrokePoint(100, 150, 0.5)],
    );
    final session = DrawingSession(const DrawingContent([_line, middle, _far]));

    _eraseDrag(session, const [
      Offset(50, 0),
      Offset(50, 150),
      Offset(50, 300),
    ]);
    expect(session.content.strokes, isEmpty);

    session.undo();

    expect(session.content.strokes, [_line, middle, _far]);
    expect(session.canUndo, isFalse);
    expect(session.canRedo, isTrue);
  });

  test('DRAW-08: undo removes the last stroke and redo puts it back', () {
    final session = DrawingSession(const DrawingContent([_far]));
    _draw(session, const [Offset(10, 20), Offset(50, 60)]);
    final drawn = session.content.strokes.last;

    session.undo();
    expect(session.content.strokes, [_far]);

    session.redo();
    expect(session.content.strokes, [_far, drawn]);
  });

  test('DRAW-08: redo of an eraser drag removes the strokes again', () {
    final session = DrawingSession(const DrawingContent([_line, _far]));
    _eraseDrag(session, const [Offset(50, 0), Offset(50, 0)]);

    session
      ..undo()
      ..redo();

    expect(session.content.strokes, [_far]);
  });

  test('DRAW-08: a new stroke clears the redo stack', () {
    final session = DrawingSession(const DrawingContent([]));
    _draw(session, const [Offset(10, 20), Offset(50, 60)]);
    session.undo();
    expect(session.canRedo, isTrue);

    _draw(session, const [Offset(80, 20), Offset(90, 60)]);

    expect(session.canRedo, isFalse);
    expect(session.content.strokes, hasLength(1));
  });

  test('DRAW-09: canUndo and canRedo follow the actions', () {
    final session = DrawingSession(const DrawingContent([_line]));
    expect(session.canUndo, isFalse);
    expect(session.canRedo, isFalse);

    _draw(session, const [Offset(10, 20), Offset(50, 60)]);
    expect(session.canUndo, isTrue);
    expect(session.canRedo, isFalse);

    session.undo();
    expect(session.canUndo, isFalse);
    expect(session.canRedo, isTrue);
  });

  test('DRAW-08: undo on a session opened from a drawing never removes its '
      'original strokes', () {
    final session = DrawingSession(const DrawingContent([_line]))..undo();

    expect(session.content.strokes, [_line]);
  });

  test('DRAW-05: listeners hear each point of a stroke being drawn', () {
    final session = DrawingSession(const DrawingContent([]));
    var calls = 0;
    session
      ..addListener(() => calls++)
      ..startStroke(const Offset(10, 20), 0.5)
      ..extendStroke(const Offset(30, 40), 0.5);

    expect(calls, 2);
    expect(session.content.strokes.single.points, hasLength(2));
  });
}
