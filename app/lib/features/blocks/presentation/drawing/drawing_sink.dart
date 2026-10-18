import 'package:jotline/features/blocks/data/drawing_content.dart';

/// Where the drawing mode writes its result (DRAW-10, DRAW-14, DRAW-15).
abstract interface class DrawingSink {
  /// Writes [content] now: a new drawing when [nodeId] is null, or the
  /// existing one otherwise. Returns the drawing's node id.
  String save(String? nodeId, DrawingContent content);

  /// Soft-deletes the drawing.
  void remove(String nodeId);
}
