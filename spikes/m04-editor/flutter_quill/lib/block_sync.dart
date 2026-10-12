import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:spike_flutter_quill/block_mapper.dart';
import 'package:spike_flutter_quill/block_row.dart';

/// Writes only the lines touched by each change delta to the store.
///
/// Block ids are attached to [Line] objects with an [Expando]. Quill keeps
/// the lower line object on a merge, so a deleted line break moves the upper
/// line's id onto the surviving line.
class BlockSync {
  BlockSync(this.document, this.store, {required List<String> loadedIds}) {
    final lines = linesOf(document);
    for (var i = 0; i < lines.length; i++) {
      if (i < loadedIds.length) _blockIds[lines[i]] = loadedIds[i];
    }
    _known = lines.toSet();
    _snapshot = _ends();
    _subscription = document.changes.listen(_onChange);
  }

  final Document document;
  final InMemoryBlockStore store;
  final Expando<String> _blockIds = Expando('blockId');
  final Set<Line> _touched = {};
  final Set<String> _trash = {};
  late Set<Line> _known;
  late List<(Line, int)> _snapshot;
  late final StreamSubscription<DocChange> _subscription;

  Set<String?> get pendingBlockIds => {for (final l in _touched) _blockIds[l]};

  String? blockIdOf(Line line) => _blockIds[line];

  List<(Line, int)> _ends() => [
    for (final l in linesOf(document)) (l, l.documentOffset + l.length),
  ];

  void _onChange(DocChange change) {
    var before = 0;
    var after = 0;
    for (final op in change.change.toList()) {
      final length = op.length!;
      if (op.isRetain) {
        if (op.attributes != null) _touchRange(after, length - 1);
        before += length;
        after += length;
      } else if (op.isInsert) {
        _touchRange(after, length);
        after += length;
      } else if (op.isDelete) {
        final merged = [
          for (final (line, end) in _snapshot)
            if (end - 1 >= before && end - 1 < before + length) line,
        ];
        final survivor = _lineAt(after);
        if (merged.isNotEmpty && survivor != null) {
          final upperId = _blockIds[merged.first];
          final survivorId = _blockIds[survivor];
          if (upperId != null) {
            _blockIds[survivor] = upperId;
            if (survivorId != null) _trash.add(survivorId);
          }
          for (final line in merged) {
            final id = _blockIds[line];
            if (id != null && id != upperId) _trash.add(id);
            _blockIds[line] = null;
          }
        }
        _touchRange(after, 0);
        before += length;
      }
    }
    _snapshot = _ends();
  }

  Line? _lineAt(int offset) {
    if (offset >= document.length) return null;
    final node = document.queryChild(offset).node;
    final line = node is Line ? node : node?.parent;
    return line is Line ? line : null;
  }

  void _touchRange(int start, int extra) {
    var offset = start;
    while (offset <= start + extra) {
      final line = _lineAt(offset);
      if (line == null) break;
      _touched.add(line);
      offset = line.documentOffset + line.length;
    }
  }

  void flush() {
    final lines = linesOf(document);
    final present = lines.toSet();
    for (final gone in _known.difference(present)) {
      final id = _blockIds[gone];
      if (id != null) _trash.add(id);
    }
    _touched.addAll(present.difference(_known));
    _known = present;
    _trash.forEach(store.moveToTrash);
    _trash.clear();
    for (final line in lines.where(_touched.contains)) {
      final (type, contentJson) = BlockMapper.fromLine(line);
      final id = _blockIds[line];
      if (id != null) {
        store.update(id, type: type, contentJson: contentJson);
        continue;
      }
      if (line.toPlainText() == '\n') continue;
      final newId = newBlockId();
      _blockIds[line] = newId;
      final index = lines.indexOf(line);
      String? afterId;
      for (var i = index - 1; i >= 0 && afterId == null; i--) {
        afterId = _blockIds[lines[i]];
      }
      store.insert(
        id: newId,
        type: type,
        contentJson: contentJson,
        afterId: afterId,
      );
    }
    _touched.clear();
  }

  Future<void> dispose() => _subscription.cancel();
}
