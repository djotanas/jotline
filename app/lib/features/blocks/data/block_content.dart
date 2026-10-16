import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// The persisted `blocks.type` identifiers (ADR 0036).
enum BlockType {
  text('text'),
  heading('heading'),
  bulletedListItem('bulleted_list_item'),
  checklistItem('checklist_item');

  new(this.id);

  final String id;

  /// An unknown identifier reads as [text].
  static BlockType fromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return text;
  }
}

/// The inline formats stored in `content_json`.
enum MarkType {
  bold('bold'),
  italic('italic');

  new(this.id);

  final String id;

  static MarkType? fromId(String id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

/// A formatted range of a block's text, in UTF-16 code units, `end`
/// exclusive.
@immutable
final class Mark {
  const new(this.start, this.end, this.type);

  final int start;
  final int end;
  final MarkType type;

  Map<String, Object> toJson() => {'start': start, 'end': end, 'type': type.id};

  @override
  bool operator ==(Object other) =>
      other is Mark &&
      other.start == start &&
      other.end == end &&
      other.type == type;

  @override
  int get hashCode => Object.hash(start, end, type);

  @override
  String toString() => 'Mark($start, $end, ${type.id})';
}

/// The content of one block as stored in `content_json` (SAVE-10).
///
/// Holds no field of the editor library's model.
@immutable
final class BlockContent {
  const new(this.text, {this.marks = const [], this.checked});

  /// Parses `content_json`; a value that does not parse reads as empty text.
  factory fromJson(String source) {
    try {
      final json = jsonDecode(source) as Map<String, Object?>;
      final marks = <Mark>[];
      for (final raw in json['marks'] as List<Object?>? ?? const []) {
        final mark = raw! as Map<String, Object?>;
        final type = MarkType.fromId(mark['type']! as String);
        if (type == null) continue;
        marks.add(Mark(mark['start']! as int, mark['end']! as int, type));
      }
      return BlockContent(
        json['text']! as String,
        marks: normalizeMarks(marks),
        checked: json['checked'] as bool?,
      );
    } on Object catch (error) {
      developer.log(
        'content_json does not parse',
        name: 'jotline.editor',
        error: error,
      );
      return const BlockContent('');
    }
  }

  final String text;
  final List<Mark> marks;
  final bool? checked;

  String toJson() => jsonEncode({
    'text': text,
    'marks': [for (final mark in normalizeMarks(marks)) mark.toJson()],
    'checked': ?checked,
  });

  /// The content a block of [type] stores: `checked` only on checklist
  /// items, `false` when missing (BAR-06).
  BlockContent forType(BlockType type) => BlockContent(
    text,
    marks: marks,
    checked: type == BlockType.checklistItem ? (checked ?? false) : null,
  );

  @override
  bool operator ==(Object other) =>
      other is BlockContent &&
      other.text == text &&
      other.checked == checked &&
      listEquals(normalizeMarks(other.marks), normalizeMarks(marks));

  @override
  int get hashCode =>
      Object.hash(text, checked, Object.hashAll(normalizeMarks(marks)));

  @override
  String toString() => 'BlockContent($text, $marks, checked: $checked)';
}

/// Sorts marks by start and type, merges overlapping or adjacent ranges of
/// the same type and drops empty ranges.
List<Mark> normalizeMarks(Iterable<Mark> marks) {
  final byType = <MarkType, List<Mark>>{};
  for (final mark in marks) {
    if (mark.end > mark.start) (byType[mark.type] ??= []).add(mark);
  }
  final result = <Mark>[];
  for (final ranges in byType.values) {
    ranges.sort((a, b) => a.start.compareTo(b.start));
    var current = ranges.first;
    for (final mark in ranges.skip(1)) {
      if (mark.start <= current.end) {
        if (mark.end > current.end) {
          current = Mark(current.start, mark.end, current.type);
        }
      } else {
        result.add(current);
        current = mark;
      }
    }
    result.add(current);
  }
  return result..sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    return byStart != 0 ? byStart : a.type.index.compareTo(b.type.index);
  });
}
