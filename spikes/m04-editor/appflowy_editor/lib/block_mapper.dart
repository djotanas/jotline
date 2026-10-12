import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:spike_appflowy_editor/block_row.dart';

const drawingType = 'drawing';

/// Converts between `blocks` rows and appflowy_editor nodes.
abstract final class BlockMapper {
  static Document toDocument(List<BlockRow> rows) => Document(
    root: Node(type: 'page', children: [for (final r in rows) toNode(r)]),
  );

  static Node toNode(BlockRow row) {
    if (row.type == drawingType) {
      return Node(
        type: drawingType,
        id: row.id,
        attributes: {'payload': row.contentJson},
      );
    }
    final content = row.content;
    final delta = _toDelta(content).toJson();
    return switch (row.type) {
      BlockType.heading => Node(
        type: HeadingBlockKeys.type,
        id: row.id,
        attributes: {HeadingBlockKeys.delta: delta, HeadingBlockKeys.level: 1},
      ),
      BlockType.bulletedListItem => Node(
        type: BulletedListBlockKeys.type,
        id: row.id,
        attributes: {BulletedListBlockKeys.delta: delta},
      ),
      BlockType.checklistItem => Node(
        type: TodoListBlockKeys.type,
        id: row.id,
        attributes: {
          TodoListBlockKeys.delta: delta,
          TodoListBlockKeys.checked: content.checked ?? false,
        },
      ),
      _ => Node(
        type: ParagraphBlockKeys.type,
        id: row.id,
        attributes: {ParagraphBlockKeys.delta: delta},
      ),
    };
  }

  /// Returns the row `type` and `content_json` for [node].
  static (String, String) fromNode(Node node) {
    if (node.type == drawingType) {
      return (drawingType, node.attributes['payload'] as String);
    }
    final type = switch (node.type) {
      HeadingBlockKeys.type => BlockType.heading,
      BulletedListBlockKeys.type => BlockType.bulletedListItem,
      TodoListBlockKeys.type => BlockType.checklistItem,
      _ => BlockType.text,
    };
    final delta = node.delta ?? Delta();
    final buffer = StringBuffer();
    final marks = <Mark>[];
    for (final op in delta.whereType<TextInsert>()) {
      final start = buffer.length;
      buffer.write(op.text);
      final attributes = op.attributes ?? const {};
      if (attributes[AppFlowyRichTextKeys.bold] == true) {
        marks.add(Mark(start, buffer.length, MarkType.bold));
      }
      if (attributes[AppFlowyRichTextKeys.italic] == true) {
        marks.add(Mark(start, buffer.length, MarkType.italic));
      }
    }
    final content = BlockContent(
      buffer.toString(),
      marks: normalizeMarks(marks),
      checked: type == BlockType.checklistItem
          ? node.attributes[TodoListBlockKeys.checked] == true
          : null,
    );
    return (type, content.toJson());
  }

  static Delta _toDelta(BlockContent content) {
    final cuts = <int>{0, content.text.length};
    for (final m in content.marks) {
      cuts
        ..add(m.start)
        ..add(m.end);
    }
    final sorted = cuts.toList()..sort();
    final delta = Delta();
    for (var i = 0; i + 1 < sorted.length; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (end <= start) continue;
      final attributes = <String, dynamic>{
        for (final m in content.marks)
          if (m.start <= start && m.end >= end)
            (m.type == MarkType.bold
                    ? AppFlowyRichTextKeys.bold
                    : AppFlowyRichTextKeys.italic):
                true,
      };
      delta.insert(
        content.text.substring(start, end),
        attributes: attributes.isEmpty ? null : attributes,
      );
    }
    return delta;
  }
}
