import 'package:drift/drift.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/ordering/fractional_index.dart';
import 'package:jotline/core/ordering/placement.dart';

/// Tables whose rows are ordered by a fractional `position` under a parent.
enum OrderedTable {
  pages('pages', 'notebook_id'),
  blocks('blocks', 'page_id');

  new(this.tableName, this.parentColumn);

  final String tableName;
  final String parentColumn;
}

/// Turns a [Placement] into a position key.
///
/// Looks at every sibling, deleted ones included, so restoring a row later
/// never collides with a key issued while it was in the trash.
class PositionAllocator {
  const new(this._database);

  final AppDatabase _database;

  /// Returns the key for [at] under [parentId].
  ///
  /// [movingId] is left out of every comparison, so moving a row never
  /// compares it against itself. Throws [ArgumentError] when an [After]
  /// anchor does not exist under [parentId].
  Future<String> keyFor(
    OrderedTable table, {
    required String parentId,
    required Placement at,
    String? movingId,
  }) async {
    switch (at) {
      case AtEnd():
        final last = await _edge(table, 'MAX', parentId, movingId);
        return FractionalIndex.keyBetween(last, null);
      case AtStart():
        final first = await _edge(table, 'MIN', parentId, movingId);
        return FractionalIndex.keyBetween(null, first);
      case After(:final id):
        final anchor = await _positionOf(table, parentId, id);
        if (anchor == null) {
          throw ArgumentError.value(
            id,
            'at',
            'is not a sibling under $parentId',
          );
        }
        final next = await _next(table, parentId, anchor, movingId);
        return FractionalIndex.keyBetween(anchor, next);
    }
  }

  Future<String?> _edge(
    OrderedTable table,
    String aggregate,
    String parentId,
    String? movingId,
  ) async {
    final row = await _database
        .customSelect(
          'SELECT $aggregate(position) AS key FROM ${table.tableName} '
          'WHERE ${table.parentColumn} = ? AND id IS NOT ?',
          variables: [Variable<String>(parentId), Variable<String>(movingId)],
        )
        .getSingle();
    return row.read<String?>('key');
  }

  Future<String?> _positionOf(
    OrderedTable table,
    String parentId,
    String id,
  ) async {
    final rows = await _database
        .customSelect(
          'SELECT position FROM ${table.tableName} '
          'WHERE id = ? AND ${table.parentColumn} = ?',
          variables: [Variable<String>(id), Variable<String>(parentId)],
        )
        .get();
    return rows.isEmpty ? null : rows.single.read<String>('position');
  }

  Future<String?> _next(
    OrderedTable table,
    String parentId,
    String anchor,
    String? movingId,
  ) async {
    final row = await _database
        .customSelect(
          'SELECT MIN(position) AS key FROM ${table.tableName} '
          'WHERE ${table.parentColumn} = ? AND position > ? AND id IS NOT ?',
          variables: [
            Variable<String>(parentId),
            Variable<String>(anchor),
            Variable<String>(movingId),
          ],
        )
        .getSingle();
    return row.read<String?>('key');
  }
}
