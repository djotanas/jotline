import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_spacing.dart';
import 'package:jotline/core/theme/theme_context.dart';
import 'package:super_editor/super_editor.dart';

/// Drags a block by its handle (BMOVE-02…BMOVE-04).
///
/// While dragging, a proxy of the block with `shadow.erguido` follows the
/// finger in the overlay and the scroll view auto-scrolls near its edges.
/// The drop moves the node to the gap nearest to the finger with a
/// [MoveNodeRequest]; a drop on its own place changes nothing.
class BlockDragController {
  new({required this.editor, required this.layoutKey, required this.styler});

  /// Pixels per frame at full auto-scroll speed, as in `ReorderableList`.
  static const double autoScrollVelocity = 50;

  final Editor editor;

  /// The key of the editor's document layout.
  final GlobalKey layoutKey;

  /// Styles the proxy text: the base style of the block, then the marks.
  final TextStyle Function(DocumentNode node, Set<Attribution> attributions)
  styler;

  String? _nodeId;
  OverlayEntry? _proxy;
  EdgeDraggingAutoScroller? _autoScroller;
  Rect _proxyRect = Rect.zero;
  Offset _grab = Offset.zero;
  double _fingerY = 0;

  /// The node being dragged, if any.
  String? get draggingNodeId => _nodeId;

  /// Starts dragging [nodeId] with the finger at [globalPosition].
  void start(BuildContext context, String nodeId, Offset globalPosition) {
    cancel();
    final node = editor.document.getNodeById(nodeId);
    final rect = _globalRect(nodeId);
    if (node is! TextNode || rect == null) return;
    _nodeId = nodeId;
    _grab = globalPosition - rect.topLeft;
    _proxyRect = rect;
    _fingerY = globalPosition.dy;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      _autoScroller = EdgeDraggingAutoScroller(
        scrollable,
        velocityScalar: autoScrollVelocity,
      );
    }
    final overlay = Overlay.of(context);
    _proxy = OverlayEntry(
      builder: (context) => Positioned.fromRect(
        rect: _proxyRect,
        child: IgnorePointer(
          child: BlockDragProxy(
            text: node.text,
            styleBuilder: (attributions) => styler(node, attributions),
          ),
        ),
      ),
    );
    overlay.insert(_proxy!);
  }

  /// Moves the proxy with the finger and auto-scrolls near the edges.
  void update(Offset globalPosition) {
    if (_nodeId == null) return;
    _fingerY = globalPosition.dy;
    _proxyRect = (globalPosition - _grab) & _proxyRect.size;
    _proxy?.markNeedsBuild();
    _autoScroller?.startAutoScrollIfNecessary(_proxyRect);
  }

  /// Drops the block at the gap nearest to the finger.
  void end() {
    final nodeId = _nodeId;
    if (nodeId == null) return;
    final from = editor.document.getNodeIndexById(nodeId);
    final gap = _nearestGap(_fingerY);
    cancel();
    if (gap == null) return;
    final to = gap > from ? gap - 1 : gap;
    if (to == from) return;
    editor.execute([MoveNodeRequest(nodeId: nodeId, newIndex: to)]);
  }

  /// Stops dragging without moving anything.
  void cancel() {
    _autoScroller?.stopAutoScroll();
    _autoScroller = null;
    _proxy?.remove();
    _proxy?.dispose();
    _proxy = null;
    _nodeId = null;
  }

  void dispose() => cancel();

  int? _nearestGap(double y) {
    final rects = [for (final node in editor.document) _globalRect(node.id)];
    if (rects.isEmpty || rects.contains(null)) return null;
    final gaps = [
      rects.first!.top,
      for (var i = 1; i < rects.length; i++)
        (rects[i - 1]!.bottom + rects[i]!.top) / 2,
      rects.last!.bottom,
    ];
    var nearest = 0;
    for (var i = 1; i < gaps.length; i++) {
      if ((gaps[i] - y).abs() < (gaps[nearest] - y).abs()) nearest = i;
    }
    return nearest;
  }

  Rect? _globalRect(String nodeId) {
    final layout = layoutKey.currentState as DocumentLayout?;
    final component = layout?.getComponentByNodeId(nodeId);
    if (component == null) return null;
    final box = component.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// The block being dragged: its text in its style on `bgFolha`, lifted with
/// `shadow.erguido` (BMOVE-04).
class BlockDragProxy extends StatelessWidget {
  const new({required this.text, required this.styleBuilder, super.key});

  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.bgFolha,
        borderRadius: BorderRadius.circular(JotRadius.rBloco),
        boxShadow: context.shadows.erguido,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Text.rich(
          text.computeInlineSpan(context, styleBuilder, const []),
        ),
      ),
    );
  }
}
