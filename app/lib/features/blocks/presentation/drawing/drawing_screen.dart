import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jotline/core/design_system/block_bar.dart';
import 'package:jotline/core/design_system/icons/jot_icon.dart';
import 'package:jotline/core/design_system/jot_button.dart';
import 'package:jotline/core/design_system/jot_icon_button.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_painter.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_session.dart';
import 'package:jotline/features/blocks/presentation/drawing/drawing_sink.dart';
import 'package:jotline/l10n/app_localizations.dart';

/// The drawing the mode opens: a new one when [nodeId] is null.
@immutable
final class DrawingTarget {
  const new({required this.original, required this.sink, this.nodeId});

  final String? nodeId;
  final DrawingContent original;
  final DrawingSink sink;
}

/// Opens the full-screen drawing mode for [target] (DRAW-02, DRAW-13).
Future<void> openDrawing(
  BuildContext context, {
  required DrawingTarget target,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DrawingScreen(target: target),
    ),
  );
}

/// The "Modo desenho: tela cheia" artboard.
class DrawingScreen extends StatefulWidget {
  const new({required this.target, super.key});

  /// The drawing area, for tests to drag on.
  static const Key areaKey = ValueKey('drawing-area');

  final DrawingTarget target;

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final DrawingSession _session = DrawingSession(widget.target.original);
  late final AppLifecycleListener _lifecycle;
  late String? _nodeId = widget.target.nodeId;
  bool _savedInBackground = false;
  bool _closing = false;
  int? _pointer;
  double _pressure = 0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: _saveInBackground,
      onHide: _saveInBackground,
      onPause: _saveInBackground,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _session.dispose();
    super.dispose();
  }

  void _saveInBackground() {
    if (_closing || _session.isEmpty) return;
    _nodeId = widget.target.sink.save(_nodeId, _session.content);
    _savedInBackground = true;
  }

  void _done() {
    if (_closing) return;
    final sink = widget.target.sink;
    final nodeId = _nodeId;
    if (!_session.isEmpty) {
      sink.save(nodeId, _session.content);
    } else if (nodeId != null) {
      sink.remove(nodeId);
    }
    _close();
  }

  void _cancel() {
    if (_closing) return;
    final nodeId = _nodeId;
    if (_savedInBackground && nodeId != null) {
      final target = widget.target;
      if (target.nodeId == null) {
        target.sink.remove(nodeId);
      } else {
        target.sink.save(nodeId, target.original);
      }
    }
    _close();
  }

  void _close() {
    _closing = true;
    Navigator.of(context).pop();
  }

  void _down(PointerDownEvent event, double scale) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _pressure = event.pressure;
    _session.startStroke(event.localPosition / scale, _pressure);
  }

  void _move(PointerMoveEvent event, double scale) {
    if (event.pointer != _pointer) return;
    _pressure = event.pressure;
    _session.extendStroke(event.localPosition / scale, _pressure);
  }

  void _up(PointerEvent event, double scale) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _session.endStroke(event.localPosition / scale, _pressure);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: colors.bgPapel,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _session,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  onCancel: _cancel,
                  onUndo: _session.canUndo ? _session.undo : null,
                  onRedo: _session.canRedo ? _session.redo : null,
                  onDone: _done,
                ),
                Expanded(child: _canvas(context)),
                _Tools(session: _session),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _canvas(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgFolha,
        border: Border.symmetric(
          horizontal: BorderSide(color: colors.bgTrilho),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const logical = DrawingContent.logicalSize;
          final scale = math.min(
            constraints.maxWidth / logical.width,
            constraints.maxHeight / logical.height,
          );
          return Center(
            child: Semantics(
              label: l10n.drawingAreaLabel,
              image: true,
              child: Listener(
                key: DrawingScreen.areaKey,
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _down(event, scale),
                onPointerMove: (event) => _move(event, scale),
                onPointerUp: (event) => _up(event, scale),
                onPointerCancel: (event) => _up(event, scale),
                child: CustomPaint(
                  size: logical * scale,
                  painter: DrawingPainter(
                    content: _session.content,
                    scale: scale,
                    colors: colors,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({
    required this.onCancel,
    required this.onUndo,
    required this.onRedo,
    required this.onDone,
  });

  final VoidCallback onCancel;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: JotSpace.space3,
        vertical: JotSpace.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          JotButton.text(label: l10n.drawingCancel, onPressed: onCancel),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: JotSpace.space1,
            children: [
              JotIconButton(
                icon: JotIconGlyph.undo,
                semanticLabel: l10n.drawingUndo,
                onPressed: onUndo,
              ),
              JotIconButton(
                icon: JotIconGlyph.redo,
                semanticLabel: l10n.drawingRedo,
                onPressed: onRedo,
              ),
            ],
          ),
          _DoneButton(label: l10n.drawingDone, onPressed: onDone),
        ],
      ),
    );
  }
}

/// The compact "Concluir" of the artboard header.
class _DoneButton extends StatefulWidget {
  const new({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: JotSpace.space11),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _pressed ? colors.accentPress : colors.accent,
              borderRadius: BorderRadius.circular(JotRadius.rCard),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: JotSpace.space5),
              child: Center(
                widthFactor: 1,
                child: Text(
                  widget.label,
                  style: context.textStyles.acao.copyWith(
                    color: colors.bgFolha,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tools extends StatelessWidget {
  const new({required this.session});

  static const Map<StrokeWidth, double> _dotSizes = {
    StrokeWidth.thin: 4,
    StrokeWidth.medium: 8,
    StrokeWidth.thick: 14,
  };

  final DrawingSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    JotBlockBarButton tool(
      DrawingModeTool value,
      String label,
      JotIconGlyph glyph,
    ) => JotBlockBarButton(
      label: label,
      active: session.tool == value,
      onPressed: () => session.tool = value,
      glyph: (color) => IconTheme(
        data: IconThemeData(color: color),
        child: JotIcon(glyph),
      ),
    );

    JotBlockBarButton width(StrokeWidth value, String label) =>
        JotBlockBarButton(
          label: label,
          active: session.width == value,
          onPressed: () => session.width = value,
          glyph: (color) => SizedBox.square(
            dimension: _dotSizes[value],
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.drawingTools,
      child: ColoredBox(
        color: colors.bgMesa,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: JotSpace.space3,
            vertical: JotSpace.space2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: JotSpace.space1,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: JotSpace.space1,
                    children: [
                      tool(
                        DrawingModeTool.pen,
                        l10n.drawingPen,
                        JotIconGlyph.pen,
                      ),
                      tool(
                        DrawingModeTool.highlighter,
                        l10n.drawingHighlighter,
                        JotIconGlyph.highlighter,
                      ),
                      tool(
                        DrawingModeTool.eraser,
                        l10n.drawingEraser,
                        JotIconGlyph.eraser,
                      ),
                    ],
                  ),
                  Row(
                    spacing: JotSpace.space1,
                    children: [
                      width(StrokeWidth.thin, l10n.drawingThin),
                      width(StrokeWidth.medium, l10n.drawingMedium),
                      width(StrokeWidth.thick, l10n.drawingThick),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: JotSpace.space1,
                children: [
                  _ColorSwatch(
                    label: l10n.drawingInk,
                    color: colors.ink1,
                    selected: session.color == DrawingColor.ink,
                    onPressed: () => session.color = DrawingColor.ink,
                  ),
                  _ColorSwatch(
                    label: l10n.drawingBlue,
                    color: colors.accent,
                    selected: session.color == DrawingColor.accent,
                    onPressed: () => session.color = DrawingColor.accent,
                  ),
                  _ColorSwatch(
                    label: l10n.drawingTerracotta,
                    color: colors.danger,
                    selected: session.color == DrawingColor.danger,
                    onPressed: () => session.color = DrawingColor.danger,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A color of the drawing mode: a 28 px dot, ringed when selected.
class _ColorSwatch extends StatelessWidget {
  const new({
    required this.label,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  static const double optionSize = 48;
  static const double swatchSize = 28;
  static const double ringGap = 3;
  static const double ringWidth = 2;

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: optionSize,
          child: Center(
            child: Container(
              width: swatchSize + (ringGap + ringWidth) * 2,
              height: swatchSize + (ringGap + ringWidth) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: color, width: ringWidth)
                    : null,
              ),
              alignment: Alignment.center,
              child: SizedBox.square(
                dimension: swatchSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
