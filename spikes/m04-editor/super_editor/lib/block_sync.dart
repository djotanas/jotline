import 'package:spike_super_editor/block_mapper.dart';
import 'package:spike_super_editor/block_row.dart';
import 'package:super_editor/super_editor.dart';

/// Writes only the blocks touched by each editor transaction to the store.
///
/// Touched node ids come from the editor's change log; the final document
/// decides whether each one is an upsert or a soft delete.
class BlockSync {
  BlockSync(this.editor, this.store, {required Iterable<String> loadedIds}) {
    for (final id in loadedIds) {
      _blockIdByNodeId[id] = id;
    }
    editor.addListener(FunctionalEditListener(_onEdit));
  }

  final Editor editor;
  final InMemoryBlockStore store;
  final Map<String, String> _blockIdByNodeId = {};
  final Set<String> _touched = {};

  /// Node ids seen in change events since the last [flush].
  Set<String> get pendingNodeIds => Set.unmodifiable(_touched);

  String? blockIdOf(String nodeId) => _blockIdByNodeId[nodeId];

  void _onEdit(List<EditEvent> changes) {
    for (final change in changes) {
      if (change is! DocumentEdit) continue;
      final event = change.change;
      if (event is NodeDocumentChange) _touched.add(event.nodeId);
    }
  }

  void flush() {
    final document = editor.document;
    final ids = _touched.toList();
    _touched.clear();
    for (final nodeId in ids) {
      final node = document.getNodeById(nodeId);
      final blockId = _blockIdByNodeId[nodeId];
      if (node == null) {
        if (blockId != null) store.moveToTrash(blockId);
        continue;
      }
      final (type, contentJson) = BlockMapper.fromNode(node);
      if (blockId == null) {
        if (node is TextNode && node.text.length == 0) {
          _touched.add(nodeId);
          continue;
        }
        final newId = newBlockId();
        _blockIdByNodeId[nodeId] = newId;
        store.insert(
          id: newId,
          type: type,
          contentJson: contentJson,
          afterId: _previousPersisted(document, nodeId),
        );
      } else {
        store.update(blockId, type: type, contentJson: contentJson);
        final row = store.byId(blockId)!;
        final expectedAfter = _previousPersisted(document, nodeId);
        final ordered = store.visible;
        final index = ordered.indexWhere((r) => r.id == row.id);
        final actualAfter = index > 0 ? ordered[index - 1].id : null;
        if (actualAfter != expectedAfter) {
          store.move(blockId, afterId: expectedAfter);
        }
      }
    }
  }

  String? _previousPersisted(Document document, String nodeId) {
    var index = document.getNodeIndexById(nodeId) - 1;
    while (index >= 0) {
      final blockId = _blockIdByNodeId[document.getNodeAt(index)!.id];
      if (blockId != null && !(store.byId(blockId)?.deleted ?? true)) {
        return blockId;
      }
      index--;
    }
    return null;
  }
}
