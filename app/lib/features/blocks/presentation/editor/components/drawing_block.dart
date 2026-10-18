import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:super_editor/super_editor.dart';

/// A drawing as an editor block; keys never delete it (DRAW-13, DRAW-15).
class DrawingNode extends BlockNode {
  new({required this.id, required this.content, super.metadata}) {
    initAddToMetadata({NodeMetadata.isDeletable: false});
  }

  @override
  final String id;

  final DrawingContent content;

  @override
  String? copyContent(dynamic selection) => null;

  @override
  bool hasEquivalentContent(DocumentNode other) =>
      other is DrawingNode && other.content == content;

  @override
  DocumentNode copyWithAddedMetadata(Map<String, dynamic> newProperties) =>
      DrawingNode(
        id: id,
        content: content,
        metadata: {...metadata, ...newProperties},
      );

  @override
  DocumentNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) =>
      DrawingNode(id: id, content: content, metadata: newMetadata);

  DrawingNode copy() => DrawingNode(id: id, content: content);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingNode && other.id == id && other.content == content;

  @override
  int get hashCode => Object.hash(id, content);
}
