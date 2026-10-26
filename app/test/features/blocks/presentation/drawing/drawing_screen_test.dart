import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_screen.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_sink.dart';

import '../../../../helpers/pump_jot.dart';

class _FakeSink implements DrawingSink {
  final List<(String?, DrawingContent)> saves = [];
  final List<String> removes = [];

  @override
  String save(String? nodeId, DrawingContent content) {
    saves.add((nodeId, content));
    return nodeId ?? 'new-node';
  }

  @override
  void remove(String nodeId) => removes.add(nodeId);
}

const Stroke _stroke = Stroke(
  tool: DrawingTool.pen,
  color: DrawingColor.accent,
  width: 6,
  points: [StrokePoint(100, 100, 0.5), StrokePoint(200, 100, 0.5)],
);

const DrawingContent _existing = DrawingContent([_stroke]);

Future<void> _open(
  WidgetTester tester,
  _FakeSink sink, {
  String? nodeId,
  DrawingContent original = const DrawingContent([]),
}) async {
  await tester.pumpJot(
    Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => openDrawing(
            context,
            target: DrawingTarget(
              nodeId: nodeId,
              original: original,
              sink: sink,
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Finder get _area => find.byKey(DrawingScreen.areaKey);

double _scale(WidgetTester tester) =>
    tester.getSize(_area).width / DrawingContent.logicalSize.width;

Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final origin = tester.getTopLeft(_area);
  final scale = _scale(tester);
  final gesture = await tester.startGesture(origin + from * scale);
  await gesture.moveTo(origin + (from + to) / 2 * scale);
  await gesture.moveTo(origin + to * scale);
  await gesture.up();
  await tester.pump();
}

Future<void> _tapLabel(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pumpAndSettle();
}

Future<void> _background(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  await tester.pump();
}

void main() {
  testWidgets('DRAW-02, DRAW-04: the header, the tools, the widths and the '
      'colors match the artboard, with pen, thin and ink selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _FakeSink());

    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
    expect(find.bySemanticsLabel('Área de desenho'), findsOneWidget);
    expect(find.bySemanticsLabel('Ferramentas de desenho'), findsOneWidget);
    expect(
      tester.getTopLeft(find.bySemanticsLabel('Desfazer traço')).dx,
      lessThan(tester.getTopLeft(find.bySemanticsLabel('Refazer traço')).dx),
    );

    for (final (label, selected) in [
      ('Caneta', true),
      ('Marca-texto', false),
      ('Borracha', false),
      ('Traço fino', true),
      ('Traço médio', false),
      ('Traço grosso', false),
      ('Tinta preta', true),
      ('Azul', false),
      ('Terracota', false),
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasToggledState: true,
          isToggled: selected,
          hasTapAction: true,
        ),
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('DRAW-04: tapping a tool, a width and a color selects them', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _FakeSink());

    await _tapLabel(tester, 'Marca-texto');
    await _tapLabel(tester, 'Traço grosso');
    await _tapLabel(tester, 'Terracota');

    for (final (label, selected) in [
      ('Caneta', false),
      ('Marca-texto', true),
      ('Traço fino', false),
      ('Traço grosso', true),
      ('Tinta preta', false),
      ('Terracota', true),
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasToggledState: true,
          isToggled: selected,
          hasTapAction: true,
        ),
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('DRAW-09: undo and redo are disabled when the mode opens, and '
      'undo is enabled after a stroke', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, _FakeSink(), nodeId: 'n1', original: _existing);

    Matcher button(String label, {required bool enabled}) => matchesSemantics(
      label: label,
      isButton: true,
      hasEnabledState: true,
      isEnabled: enabled,
      hasTapAction: enabled,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Desfazer traço')),
      button('Desfazer traço', enabled: false),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Refazer traço')),
      button('Refazer traço', enabled: false),
    );

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Desfazer traço')),
      button('Desfazer traço', enabled: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Refazer traço')),
      button('Refazer traço', enabled: false),
    );
    handle.dispose();
  });

  testWidgets('DRAW-03: on a screen where the area is drawn at 2x, a drag '
      'stores logical points', (tester) async {
    tester.view
      ..physicalSize = const Size(780, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sink = _FakeSink();
    await _open(tester, sink);
    expect(tester.getSize(_area), const Size(780, 1120));

    await _drag(tester, const Offset(50, 60), const Offset(150, 160));
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    final points = sink.saves.single.$2.strokes.single.points;
    expect(points.first, const StrokePoint(50, 60, 1));
    expect(points.last, const StrokePoint(150, 160, 1));
  });

  testWidgets('DRAW-10: "Concluir" on a new drawing with a stroke saves it as '
      'a new drawing and closes the mode', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink);

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(sink.saves, hasLength(1));
    expect(sink.saves.single.$1, isNull);
    expect(sink.saves.single.$2.strokes.single.tool, DrawingTool.pen);
    expect(sink.removes, isEmpty);
    expect(_area, findsNothing);
  });

  testWidgets('DRAW-11: "Concluir" on a new drawing with no stroke writes '
      'nothing', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(sink.saves, isEmpty);
    expect(sink.removes, isEmpty);
    expect(_area, findsNothing);
  });

  testWidgets('DRAW-14: "Concluir" on an existing drawing saves its strokes '
      'under its node', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink, nodeId: 'n1', original: _existing);

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(sink.saves.single.$1, 'n1');
    expect(sink.saves.single.$2.strokes, hasLength(2));
    expect(sink.saves.single.$2.strokes.first, _stroke);
  });

  testWidgets('DRAW-15: with every stroke erased, "Concluir" on an existing '
      'drawing removes it', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink, nodeId: 'n1', original: _existing);

    await _tapLabel(tester, 'Borracha');
    await _drag(tester, const Offset(150, 100), const Offset(160, 100));
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(sink.removes, ['n1']);
    expect(sink.saves, isEmpty);
  });

  testWidgets('DRAW-16: "Cancelar" writes nothing and closes the mode', (
    tester,
  ) async {
    final sink = _FakeSink();
    await _open(tester, sink, nodeId: 'n1', original: _existing);

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(sink.saves, isEmpty);
    expect(sink.removes, isEmpty);
    expect(_area, findsNothing);
  });

  testWidgets('DRAW-17: going to background saves the current strokes', (
    tester,
  ) async {
    final sink = _FakeSink();
    await _open(tester, sink);

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));
    await _background(tester);

    expect(sink.saves, isNotEmpty);
    expect(sink.saves.first.$1, isNull);
    expect(sink.saves.first.$2.strokes, hasLength(1));
    expect(_area, findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('DRAW-17: going to background with a new drawing and no stroke '
      'saves nothing', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink);

    await _background(tester);

    expect(sink.saves, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('DRAW-18: "Cancelar" after a background save writes back the '
      'original content of an existing drawing', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink, nodeId: 'n1', original: _existing);

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));
    await _background(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(sink.saves.last, ('n1', _existing));
    expect(sink.removes, isEmpty);
  });

  testWidgets('DRAW-18: "Cancelar" after a background save removes a new '
      'drawing', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink);

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));
    await _background(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final saves = sink.saves.length;
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(sink.removes, ['new-node']);
    expect(sink.saves, hasLength(saves));
  });

  testWidgets('DRAW-18: the system back after a background save acts as '
      '"Cancelar"', (tester) async {
    final sink = _FakeSink();
    await _open(tester, sink);

    await _drag(tester, const Offset(50, 300), const Offset(150, 300));
    await _background(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(sink.removes, ['new-node']);
    expect(_area, findsNothing);
  });
}
