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
      if (event is NodeMovedEvent) _moved = true;
      if (event is NodeDocumentChange) _touched.add(event.nodeId);
    }
  }

  bool _moved = false;

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
      }
    }
    if (_moved) {
      _moved = false;
      _reorder(document);
    }
  }

  /// Moves the fewest rows needed for the store order to match the document:
  /// rows on a longest increasing subsequence stay where they are.
  void _reorder(Document document) {
    final storeIndex = {for (final (i, r) in store.visible.indexed) r.id: i};
    final order = [
      for (final node in document)
        if (_blockIdByNodeId[node.id] case final id?
            when storeIndex.containsKey(id))
          id,
    ];
    final keep = _longestIncreasing(order, storeIndex);
    for (final (i, id) in order.indexed) {
      if (keep.contains(id)) continue;
      store.move(id, afterId: i == 0 ? null : order[i - 1]);
    }
  }

  static Set<String> _longestIncreasing(
    List<String> order,
    Map<String, int> rank,
  ) {
    final tails = <int>[];
    final previous = List<int>.filled(order.length, -1);
    for (var i = 0; i < order.length; i++) {
      var low = 0;
      var high = tails.length;
      while (low < high) {
        final mid = (low + high) ~/ 2;
        if (rank[order[tails[mid]]]! < rank[order[i]]!) {
          low = mid + 1;
        } else {
          high = mid;
        }
      }
      if (low > 0) previous[i] = tails[low - 1];
      if (low == tails.length) {
        tails.add(i);
      } else {
        tails[low] = i;
      }
    }
    final keep = <String>{};
    for (var i = tails.isEmpty ? -1 : tails.last; i >= 0; i = previous[i]) {
      keep.add(order[i]);
    }
    return keep;
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
