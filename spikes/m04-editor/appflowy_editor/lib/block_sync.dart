import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:spike_appflowy_editor/block_mapper.dart';
import 'package:spike_appflowy_editor/block_row.dart';

/// Writes only the blocks touched by each transaction to the store.
///
/// Operations carry paths, not ids, so the top-level id list is replayed
/// operation by operation. A type change is a delete plus an insert at the
/// same index; the new node inherits the old node's block id.
class BlockSync {
  BlockSync(
    this.editorState,
    this.store, {
    required Iterable<String> loadedIds,
  }) {
    for (final id in loadedIds) {
      _blockIdByNodeId[id] = id;
    }
    _ids = [for (final n in editorState.document.root.children) n.id];
    _subscription = editorState.transactionStream.listen((value) {
      if (value.$1 == TransactionTime.after) _onTransaction(value.$2);
    });
  }

  final EditorState editorState;
  final InMemoryBlockStore store;
  final Map<String, String> _blockIdByNodeId = {};
  final Set<String> _touched = {};
  late List<String> _ids;
  late final StreamSubscription<EditorTransactionValue> _subscription;

  /// Node ids seen in operations since the last [flush].
  Set<String> get pendingNodeIds => Set.unmodifiable(_touched);

  String? blockIdOf(String nodeId) => _blockIdByNodeId[nodeId];

  void _onTransaction(Transaction transaction) {
    final before = List<String>.of(_ids);
    final inserted = <String>{};
    final deleted = <String>{};
    for (final op in transaction.operations) {
      final index = op.path.first;
      if (op.path.length > 1) {
        _touched.add(_ids[index]);
        continue;
      }
      switch (op) {
        case InsertOperation(:final nodes):
          final ids = [for (final n in nodes) n.id];
          _ids.insertAll(index, ids);
          inserted.addAll(ids);
          _touched.addAll(ids);
        case DeleteOperation(:final nodes):
          final ids = _ids.sublist(index, index + nodes.length);
          _ids.removeRange(index, index + nodes.length);
          deleted.addAll(ids);
          _touched.addAll(ids);
        default:
          _touched.add(_ids[index]);
      }
    }
    for (final oldId in deleted.difference(inserted)) {
      final at = before.indexOf(oldId);
      if (at < 0 || at >= _ids.length) continue;
      final newId = _ids[at];
      if (inserted.contains(newId) &&
          _blockIdByNodeId[newId] == null &&
          _blockIdByNodeId[oldId] != null) {
        _blockIdByNodeId[newId] = _blockIdByNodeId.remove(oldId)!;
        _touched.remove(oldId);
      }
    }
  }

  void flush() {
    final ids = _touched.toList();
    _touched.clear();
    final nodes = {for (final n in editorState.document.root.children) n.id: n};
    for (final nodeId in ids) {
      final node = nodes[nodeId];
      final blockId = _blockIdByNodeId[nodeId];
      if (node == null) {
        if (blockId != null) store.moveToTrash(blockId);
        continue;
      }
      final (type, contentJson) = BlockMapper.fromNode(node);
      if (blockId == null) {
        if (node.delta != null && node.delta!.isEmpty) {
          _touched.add(nodeId);
          continue;
        }
        final newId = newBlockId();
        _blockIdByNodeId[nodeId] = newId;
        store.insert(
          id: newId,
          type: type,
          contentJson: contentJson,
          afterId: _previousPersisted(nodeId),
        );
      } else {
        store.update(blockId, type: type, contentJson: contentJson);
      }
    }
  }

  String? _previousPersisted(String nodeId) {
    for (var i = _ids.indexOf(nodeId) - 1; i >= 0; i--) {
      final blockId = _blockIdByNodeId[_ids[i]];
      if (blockId != null && !(store.byId(blockId)?.deleted ?? true)) {
        return blockId;
      }
    }
    return null;
  }

  Future<void> dispose() => _subscription.cancel();
}
