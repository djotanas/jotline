import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:spike_flutter_quill/block_row.dart';

const drawingType = 'drawing';

/// Lines of a Quill document in order, flattening list blocks.
List<Line> linesOf(Document document) => [
  for (final child in document.root.children)
    if (child is Line)
      child
    else if (child is Block)
      ...child.children.whereType<Line>(),
];

/// Converts between `blocks` rows and Quill lines.
///
/// Quill has no line ids; identity is carried by the [Line] object.
abstract final class BlockMapper {
  static Delta toDelta(List<BlockRow> rows) {
    final delta = Delta();
    for (final row in rows) {
      if (row.type == drawingType) {
        delta
          ..insert(
            BlockEmbed.custom(
              CustomBlockEmbed(drawingType, row.contentJson),
            ).toJson(),
          )
          ..insert('\n');
        continue;
      }
      final content = row.content;
      final cuts = <int>{0, content.text.length};
      for (final m in content.marks) {
        cuts
          ..add(m.start)
          ..add(m.end);
      }
      final sorted = cuts.toList()..sort();
      for (var i = 0; i + 1 < sorted.length; i++) {
        final start = sorted[i];
        final end = sorted[i + 1];
        if (end <= start) continue;
        final attributes = <String, dynamic>{
          for (final m in content.marks)
            if (m.start <= start && m.end >= end)
              (m.type == MarkType.bold
                      ? Attribute.bold.key
                      : Attribute.italic.key):
                  true,
        };
        delta.insert(
          content.text.substring(start, end),
          attributes.isEmpty ? null : attributes,
        );
      }
      delta.insert('\n', switch (row.type) {
        BlockType.heading => {Attribute.header.key: 1},
        BlockType.bulletedListItem => {Attribute.list.key: 'bullet'},
        BlockType.checklistItem => {
          Attribute.list.key: (content.checked ?? false)
              ? 'checked'
              : 'unchecked',
        },
        _ => null,
      });
    }
    return delta;
  }

  /// Returns the row `type` and `content_json` for [line].
  static (String, String) fromLine(Line line) {
    final first = line.children.isEmpty ? null : line.children.first;
    if (first is Embed && first.value.type == drawingType) {
      return (drawingType, first.value.data as String);
    }
    final list = line.style.attributes[Attribute.list.key]?.value;
    final header = line.style.attributes[Attribute.header.key]?.value;
    final type = switch ((list, header)) {
      ('bullet', _) => BlockType.bulletedListItem,
      ('checked' || 'unchecked', _) => BlockType.checklistItem,
      (_, 1) => BlockType.heading,
      _ => BlockType.text,
    };
    final buffer = StringBuffer();
    final marks = <Mark>[];
    for (final op in line.toDelta().toList()) {
      final data = op.data;
      if (data is! String) continue;
      final text = data.endsWith('\n')
          ? data.substring(0, data.length - 1)
          : data;
      final start = buffer.length;
      buffer.write(text);
      final attributes = op.attributes ?? const {};
      if (attributes[Attribute.bold.key] == true) {
        marks.add(Mark(start, buffer.length, MarkType.bold));
      }
      if (attributes[Attribute.italic.key] == true) {
        marks.add(Mark(start, buffer.length, MarkType.italic));
      }
    }
    final content = BlockContent(
      buffer.toString(),
      marks: normalizeMarks(marks),
      checked: type == BlockType.checklistItem ? list == 'checked' : null,
    );
    return (type, content.toJson());
  }
}
