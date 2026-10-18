import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/drawing_content.dart';
import 'package:jotline/features/blocks/presentation/editor/components/drawing_block.dart';
import 'package:super_editor/super_editor.dart';

const Map<MarkType, Attribution> _attributions = {
  MarkType.bold: boldAttribution,
  MarkType.italic: italicsAttribution,
};

/// Converts between `blocks` rows and editor nodes (ADR 0036).
abstract final class BlockMapper {
  /// One node per row, with the block id as node id. An empty page gets one
  /// empty paragraph whose id is not a block id (EDIT-04, EDIT-05).
  static MutableDocument toDocument(List<Block> rows) {
    if (rows.isEmpty) return MutableDocument.empty();
    return MutableDocument(
      nodes: [
        for (final row in rows)
          toNode(
            BlockType.fromId(row.type),
            BlockType.fromId(row.type) == BlockType.drawing
                ? DrawingContent.fromJson(row.contentJson)
                : BlockContent.fromJson(row.contentJson),
            id: row.id,
          ),
      ],
    );
  }

  static DocumentNode toNode(
    BlockType type,
    StoredContent content, {
    required String id,
  }) {
    if (type == BlockType.drawing) {
      return DrawingNode(id: id, content: content as DrawingContent);
    }
    content as BlockContent;
    final text = _toAttributedText(content);
    return switch (type) {
      BlockType.text || BlockType.drawing => ParagraphNode(id: id, text: text),
      BlockType.heading => ParagraphNode(
        id: id,
        text: text,
        metadata: const {NodeMetadata.blockType: header1Attribution},
      ),
      BlockType.bulletedListItem => ListItemNode.unordered(id: id, text: text),
      BlockType.checklistItem => TaskNode(
        id: id,
        text: text,
        isComplete: content.checked ?? false,
      ),
    };
  }

  /// The block type and content of [node]; any node or block type without a
  /// block type of its own reads as text, and only bold and italic are kept.
  static (BlockType, StoredContent) fromNode(DocumentNode node) {
    if (node is DrawingNode) return (BlockType.drawing, node.content);
    if (node is! TextNode) return (BlockType.text, const BlockContent(''));
    final type = switch (node) {
      TaskNode() => BlockType.checklistItem,
      ListItemNode() => BlockType.bulletedListItem,
      ParagraphNode()
          when node.getMetadataValue(NodeMetadata.blockType) ==
              header1Attribution =>
        BlockType.heading,
      _ => BlockType.text,
    };
    final content = BlockContent(
      node.text.toPlainText(),
      marks: _toMarks(node.text),
      checked: node is TaskNode ? node.isComplete : null,
    );
    return (type, content);
  }

  static AttributedText _toAttributedText(BlockContent content) {
    final text = AttributedText(content.text);
    for (final mark in content.marks) {
      text.addAttribution(
        _attributions[mark.type]!,
        SpanRange(mark.start, mark.end - 1),
      );
    }
    return text;
  }

  static List<Mark> _toMarks(AttributedText text) => normalizeMarks([
    for (final MapEntry(key: type, value: attribution) in _attributions.entries)
      for (final span in text.getAttributionSpans({attribution}))
        Mark(span.start, span.end + 1, type),
  ]);
}
