import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Provisional block type identifiers; the final ones belong to the block
/// model ADR.
abstract final class BlockType {
  static const text = 'text';
  static const heading = 'heading';
  static const bulletedListItem = 'bulleted_list_item';
  static const checklistItem = 'checklist_item';
}

/// Provisional mark identifiers inside `content_json`.
abstract final class MarkType {
  static const bold = 'bold';
  static const italic = 'italic';
}

/// A formatted range of a block's text; `end` is exclusive, in UTF-16 units.
@immutable
class Mark {
  const Mark(this.start, this.end, this.type);

  factory Mark.fromJson(Map<String, Object?> json) =>
      Mark(json['start']! as int, json['end']! as int, json['type']! as String);

  final int start;
  final int end;
  final String type;

  Map<String, Object?> toJson() => {'start': start, 'end': end, 'type': type};

  @override
  bool operator ==(Object other) =>
      other is Mark &&
      other.start == start &&
      other.end == end &&
      other.type == type;

  @override
  int get hashCode => Object.hash(start, end, type);

  @override
  String toString() => 'Mark($start, $end, $type)';
}

/// Our own per-block content, stored as `content_json`.
@immutable
class BlockContent {
  const BlockContent(this.text, {this.marks = const [], this.checked});

  factory BlockContent.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    final marks = (json['marks'] as List<Object?>? ?? const [])
        .map((m) => Mark.fromJson(m! as Map<String, Object?>))
        .toList();
    return BlockContent(
      json['text']! as String,
      marks: normalizeMarks(marks),
      checked: json['checked'] as bool?,
    );
  }

  final String text;
  final List<Mark> marks;
  final bool? checked;

  String toJson() => jsonEncode({
    'text': text,
    'marks': [for (final m in normalizeMarks(marks)) m.toJson()],
    'checked': ?checked,
  });

  @override
  bool operator ==(Object other) =>
      other is BlockContent &&
      other.text == text &&
      other.checked == checked &&
      listEquals(normalizeMarks(other.marks), normalizeMarks(marks));

  @override
  int get hashCode => Object.hash(text, checked, Object.hashAll(marks));

  @override
  String toString() => 'BlockContent($text, $marks, checked: $checked)';
}

/// Sorts marks and joins adjacent or overlapping ranges of the same type.
List<Mark> normalizeMarks(List<Mark> marks) {
  final byType = <String, List<Mark>>{};
  for (final m in marks) {
    if (m.end > m.start) (byType[m.type] ??= []).add(m);
  }
  final result = <Mark>[];
  for (final entry in byType.entries) {
    final sorted = entry.value..sort((a, b) => a.start.compareTo(b.start));
    var current = sorted.first;
    for (final m in sorted.skip(1)) {
      if (m.start <= current.end) {
        current = Mark(
          current.start,
          m.end > current.end ? m.end : current.end,
          current.type,
        );
      } else {
        result.add(current);
        current = m;
      }
    }
    result.add(current);
  }
  result.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    return byStart != 0 ? byStart : a.type.compareTo(b.type);
  });
  return result;
}

/// A row shaped like the app's `blocks` table, reduced to what the spike needs.
@immutable
class BlockRow {
  const BlockRow({
    required this.id,
    required this.type,
    required this.contentJson,
    required this.position,
    this.deleted = false,
  });

  final String id;
  final String type;
  final String contentJson;
  final String position;
  final bool deleted;

  BlockContent get content => BlockContent.fromJson(contentJson);

  BlockRow copyWith({
    String? type,
    String? contentJson,
    String? position,
    bool? deleted,
  }) => BlockRow(
    id: id,
    type: type ?? this.type,
    contentJson: contentJson ?? this.contentJson,
    position: position ?? this.position,
    deleted: deleted ?? this.deleted,
  );

  @override
  bool operator ==(Object other) =>
      other is BlockRow &&
      other.id == id &&
      other.type == type &&
      other.contentJson == contentJson &&
      other.position == position &&
      other.deleted == deleted;

  @override
  int get hashCode => Object.hash(id, type, contentJson, position, deleted);

  @override
  String toString() => 'BlockRow($id, $type, $contentJson, $position)';
}

/// A write issued against [InMemoryBlockStore], recorded for assertions.
@immutable
class BlockWrite {
  const BlockWrite(this.kind, this.id);

  final String kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is BlockWrite && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => '$kind($id)';
}

/// In-memory stand-in for the `blocks` table of one page.
///
/// Soft delete only; positions are decimal fractional keys.
class InMemoryBlockStore {
  InMemoryBlockStore([Iterable<BlockRow> rows = const []]) {
    for (final r in rows) {
      _rows[r.id] = r;
    }
  }

  final Map<String, BlockRow> _rows = {};
  final List<BlockWrite> writes = [];

  List<BlockRow> get visible =>
      _rows.values.where((r) => !r.deleted).toList()..sort(_byPosition);

  BlockRow? byId(String id) => _rows[id];

  static int _byPosition(BlockRow a, BlockRow b) {
    final byPosition = a.position.compareTo(b.position);
    return byPosition != 0 ? byPosition : a.id.compareTo(b.id);
  }

  void insert({
    required String id,
    required String type,
    required String contentJson,
    String? afterId,
  }) {
    final ordered = visible;
    final index = afterId == null
        ? -1
        : ordered.indexWhere((r) => r.id == afterId);
    final before = index < 0 ? null : ordered[index].position;
    final after = index + 1 < ordered.length
        ? ordered[index + 1].position
        : null;
    _rows[id] = BlockRow(
      id: id,
      type: type,
      contentJson: contentJson,
      position: keyBetween(before, after),
    );
    writes.add(BlockWrite('insert', id));
  }

  void update(String id, {required String type, required String contentJson}) {
    final row = _rows[id]!;
    if (row.type == type && row.contentJson == contentJson) return;
    _rows[id] = row.copyWith(type: type, contentJson: contentJson);
    writes.add(BlockWrite('update', id));
  }

  void moveToTrash(String id) {
    final row = _rows[id]!;
    if (row.deleted) return;
    _rows[id] = row.copyWith(deleted: true);
    writes.add(BlockWrite('trash', id));
  }

  void move(String id, {String? afterId}) {
    final ordered = visible.where((r) => r.id != id).toList();
    final index = afterId == null
        ? -1
        : ordered.indexWhere((r) => r.id == afterId);
    final before = index < 0 ? null : ordered[index].position;
    final after = index + 1 < ordered.length
        ? ordered[index + 1].position
        : null;
    _rows[id] = _rows[id]!.copyWith(position: keyBetween(before, after));
    writes.add(BlockWrite('move', id));
  }
}

/// A decimal fractional key strictly between [a] and [b] (`null` = open end).
String keyBetween(String? a, String? b) {
  final low = a ?? '';
  String? high = b;
  final buffer = StringBuffer();
  for (var i = 0; ; i++) {
    final digitLow = i < low.length ? low.codeUnitAt(i) - 48 : 0;
    final digitHigh = high == null
        ? 10
        : (i < high.length ? high.codeUnitAt(i) - 48 : 0);
    if (digitHigh - digitLow > 1) {
      buffer.writeCharCode(48 + (digitLow + digitHigh) ~/ 2);
      return buffer.toString();
    }
    buffer.writeCharCode(48 + digitLow);
    if (digitHigh - digitLow == 1) high = null;
  }
}

var _idCounter = 0;

/// Stand-in for the app's UUID v7 generator: unique and time ordered.
String newBlockId() {
  _idCounter++;
  return 'blk-${_idCounter.toString().padLeft(6, '0')}';
}
