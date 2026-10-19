import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';

/// The tools the drawing mode offers (DRAW-04); only pen and highlighter
/// are persisted.
enum DrawingModeTool { pen, highlighter, eraser }

sealed class _Action;

final class _Added extends _Action {
  new(this.index, this.stroke);

  final int index;
  final Stroke stroke;
}

final class _Erased extends _Action {
  final List<(int, Stroke)> removed = [];
}

/// The pure logic of the drawing mode (DRAW-04 to DRAW-09).
class DrawingSession with ChangeNotifier {
  new(DrawingContent original) : _strokes = [...original.strokes];

  static const double _eraserReach = 10;

  final List<Stroke> _strokes;
  final List<_Action> _undo = [];
  final List<_Action> _redo = [];

  Stroke? _drawing;
  _Erased? _erasing;

  DrawingModeTool _tool = DrawingModeTool.pen;
  StrokeWidth _width = StrokeWidth.thin;
  DrawingColor _color = DrawingColor.ink;

  DrawingModeTool get tool => _tool;

  set tool(DrawingModeTool value) {
    _tool = value;
    notifyListeners();
  }

  StrokeWidth get width => _width;

  set width(StrokeWidth value) {
    _width = value;
    notifyListeners();
  }

  DrawingColor get color => _color;

  set color(DrawingColor value) {
    _color = value;
    notifyListeners();
  }

  /// The strokes, including the one being drawn.
  DrawingContent get content => DrawingContent([..._strokes, ?_drawing]);

  bool get isEmpty => _strokes.isEmpty && _drawing == null;

  bool get canUndo => _undo.isNotEmpty;

  bool get canRedo => _redo.isNotEmpty;

  void startStroke(Offset logical, double pressure) {
    if (tool == DrawingModeTool.eraser) {
      _erasing = _Erased();
      erase(logical);
      return;
    }
    _drawing = Stroke(
      tool: tool == DrawingModeTool.highlighter
          ? DrawingTool.highlighter
          : DrawingTool.pen,
      color: color,
      width: width.value,
      points: [StrokePoint(logical.dx, logical.dy, pressure)],
    );
    notifyListeners();
  }

  void extendStroke(Offset logical, double pressure) {
    if (tool == DrawingModeTool.eraser) {
      erase(logical);
      return;
    }
    final drawing = _drawing;
    if (drawing == null) return;
    _drawing = Stroke(
      tool: drawing.tool,
      color: drawing.color,
      width: drawing.width,
      points: [
        ...drawing.points,
        StrokePoint(logical.dx, logical.dy, pressure),
      ],
    );
    notifyListeners();
  }

  void endStroke(Offset logical, double pressure) {
    if (tool == DrawingModeTool.eraser) {
      erase(logical);
      final erasing = _erasing;
      _erasing = null;
      if (erasing != null && erasing.removed.isNotEmpty) _push(erasing);
      return;
    }
    extendStroke(logical, pressure);
    final drawing = _drawing;
    if (drawing == null) return;
    _drawing = null;
    _strokes.add(drawing);
    _push(_Added(_strokes.length - 1, drawing));
  }

  /// Removes every stroke within `width / 2 + 10` logical units of
  /// [logical] (DRAW-07).
  void erase(Offset logical) {
    final erasing = _erasing ??= _Erased();
    var changed = false;
    for (var index = _strokes.length - 1; index >= 0; index--) {
      final stroke = _strokes[index];
      if (_distance(stroke, logical) <= stroke.width / 2 + _eraserReach) {
        _strokes.removeAt(index);
        erasing.removed.add((index, stroke));
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    final action = _undo.removeLast();
    switch (action) {
      case _Added(:final index):
        _strokes.removeAt(index);
      case _Erased(:final removed):
        for (final (index, stroke) in removed.reversed) {
          _strokes.insert(index, stroke);
        }
    }
    _redo.add(action);
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    final action = _redo.removeLast();
    switch (action) {
      case _Added(:final index, :final stroke):
        _strokes.insert(index, stroke);
      case _Erased(:final removed):
        for (final (index, _) in removed) {
          _strokes.removeAt(index);
        }
    }
    _undo.add(action);
    notifyListeners();
  }

  void _push(_Action action) {
    _undo.add(action);
    _redo.clear();
    notifyListeners();
  }

  static double _distance(Stroke stroke, Offset point) {
    final points = [for (final p in stroke.points) Offset(p.x, p.y)];
    if (points.length == 1) return (points.single - point).distance;
    var nearest = double.infinity;
    for (var i = 1; i < points.length; i++) {
      nearest = math.min(
        nearest,
        _segmentDistance(points[i - 1], points[i], point),
      );
    }
    return nearest;
  }

  static double _segmentDistance(Offset a, Offset b, Offset point) {
    final ab = b - a;
    final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lengthSquared == 0) return (point - a).distance;
    final ap = point - a;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared).clamp(0.0, 1.0);
    return (point - (a + ab * t)).distance;
  }
}
