import 'dart:convert';

import 'package:spike_super_editor/block_row.dart';
import 'package:spike_super_editor/drawing_stub.dart';
import 'package:super_editor/super_editor.dart';

const _markToAttribution = {
  MarkType.bold: boldAttribution,
  MarkType.italic: italicsAttribution,
};

/// Converts between `blocks` rows and super_editor nodes.
abstract final class BlockMapper {
  static MutableDocument toDocument(List<BlockRow> rows) =>
      MutableDocument(nodes: [for (final r in rows) toNode(r)]);

  static DocumentNode toNode(BlockRow row) {
    if (row.type == DrawingStubNode.blockType) {
      return DrawingStubNode(id: row.id, payload: row.contentJson);
    }
    final content = row.content;
    final text = _toAttributedText(content);
    return switch (row.type) {
      BlockType.heading => ParagraphNode(
        id: row.id,
        text: text,
        metadata: const {NodeMetadata.blockType: header1Attribution},
      ),
      BlockType.bulletedListItem => ListItemNode.unordered(
        id: row.id,
        text: text,
      ),
      BlockType.checklistItem => TaskNode(
        id: row.id,
        text: text,
        isComplete: content.checked ?? false,
      ),
      _ => ParagraphNode(id: row.id, text: text),
    };
  }

  /// Returns the row `type` and `content_json` for [node].
  static (String, String) fromNode(DocumentNode node) {
    if (node is DrawingStubNode) {
      return (DrawingStubNode.blockType, node.payload);
    }
    final textNode = node as TextNode;
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
      textNode.text.toPlainText(),
      marks: _toMarks(textNode.text),
      checked: node is TaskNode ? node.isComplete : null,
    );
    return (type, content.toJson());
  }

  static AttributedText _toAttributedText(BlockContent content) {
    final text = AttributedText(content.text);
    for (final mark in content.marks) {
      final attribution = _markToAttribution[mark.type];
      if (attribution == null || mark.end <= mark.start) continue;
      text.addAttribution(attribution, SpanRange(mark.start, mark.end - 1));
    }
    return text;
  }

  static List<Mark> _toMarks(AttributedText text) {
    final marks = <Mark>[];
    for (final entry in _markToAttribution.entries) {
      for (final span in text.getAttributionSpans({entry.value})) {
        marks.add(Mark(span.start, span.end + 1, entry.key));
      }
    }
    return normalizeMarks(marks);
  }

  /// Encodes [rows] the way the app would read them back, for assertions.
  static String describe(List<BlockRow> rows) => jsonEncode([
    for (final r in rows)
      {'type': r.type, 'content': jsonDecode(r.contentJson)},
  ]);
}
