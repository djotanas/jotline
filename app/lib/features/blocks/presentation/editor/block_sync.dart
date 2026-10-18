import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/features/blocks/data/block_content.dart';
import 'package:jotline/features/blocks/data/block_repository.dart';
import 'package:jotline/features/blocks/presentation/editor/block_mapper.dart';
import 'package:super_editor/super_editor.dart';

/// Writes the blocks touched in the editor to their `blocks` rows.
///
/// Every edit restarts one page timer; a flush writes every touched block in
/// one [BlockRepository.applyChanges] batch (SAVE-02). Flushes run one after
/// the other, so a batch always knows the ids inserted by the previous one.
class BlockSync {
  new({
    required this.editor,
    required this.pageId,
    required this.repository,
    required Iterable<String> loadedIds,
    this.delay = const Duration(milliseconds: 500),
  }) {
    for (final id in loadedIds) {
      _blockIds[id] = id;
      _persisted.add(id);
    }
    editor.addListener(_listener);
  }

  final Editor editor;
  final String pageId;
  final BlockRepository repository;
  final Duration delay;

  late final EditListener _listener = FunctionalEditListener(_onEdit);
  final Map<String, String> _blockIds = {};
  final List<String> _persisted = [];
  final Set<String> _touched = {};
  bool _moved = false;
  Timer? _timer;
  Future<void> _chain = Future.value();

  /// Node ids changed since the last successful write.
  @visibleForTesting
  Set<String> get pendingNodeIds => Set.unmodifiable(_touched);

  void _onEdit(List<EditEvent> changes) {
    var changed = false;
    for (final change in changes) {
      if (change is! DocumentEdit) continue;
      final event = change.change;
      if (event is NodeMovedEvent) _moved = true;
      if (event is NodeDocumentChange) {
        _touched.add(event.nodeId);
        changed = true;
      }
    }
    if (!changed) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(flush()));
  }

  /// Cancels the timer and writes the pending changes after any flush still
  /// in flight. Never awaited on a frame path (SAVE-12).
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    return _chain = _chain.then((_) => _write());
  }

  void dispose() {
    _timer?.cancel();
    editor.removeListener(_listener);
  }

  Future<void> _write() async {
    if (_touched.isEmpty && !_moved) return;
    final touched = Set.of(_touched);
    final moved = _moved;
    _touched.clear();
    _moved = false;

    final document = editor.document;
    final changes = <BlockChange>[];
    final order = <String>[];
    final deferred = <String>{};
    final trashed = <String, String>{};

    if (moved) changes.addAll(_moves(document));
    for (final node in document) {
      final blockId = _blockIds[node.id];
      if (!touched.contains(node.id)) {
        if (blockId != null) order.add(blockId);
        continue;
      }
      final (type, content) = BlockMapper.fromNode(node);
      if (blockId != null) {
        changes.add(Update(blockId, type, content));
        order.add(blockId);
      } else if (content is BlockContent && content.text.isEmpty) {
        deferred.add(node.id);
      } else {
        final previous = order.isEmpty ? null : order.last;
        changes.add(
          Insert(
            node.id,
            type,
            content,
            previous == null ? const AtStart() : After(previous),
          ),
        );
        order.add(node.id);
      }
    }
    for (final nodeId in touched) {
      if (document.getNodeById(nodeId) != null) continue;
      final blockId = _blockIds.remove(nodeId);
      if (blockId == null) continue;
      trashed[nodeId] = blockId;
      changes.add(Trash(blockId));
    }
    _touched.addAll(deferred);
    if (changes.isEmpty) return;

    try {
      final inserted = await repository.applyChanges(pageId, changes);
      _blockIds.addAll(inserted);
      _persisted
        ..clear()
        ..addAll([for (final id in order) inserted[id] ?? id]);
    } on Object catch (error, stackTrace) {
      developer.log(
        'block flush failed',
        name: 'jotline.editor',
        error: error,
        stackTrace: stackTrace,
      );
      _blockIds.addAll(trashed);
      _touched.addAll(touched);
      _moved = _moved || moved;
    }
  }

  /// The fewest moves that make the persisted order follow the document:
  /// blocks on a longest increasing subsequence stay put (BMOVE-02).
  List<Move> _moves(Document document) {
    final rank = {for (final (i, id) in _persisted.indexed) id: i};
    final order = [
      for (final node in document)
        if (_blockIds[node.id] case final id? when rank.containsKey(id)) id,
    ];
    final keep = _longestIncreasing(order, rank);
    return [
      for (final (i, id) in order.indexed)
        if (!keep.contains(id))
          Move(id, i == 0 ? const AtStart() : After(order[i - 1])),
    ];
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
}
