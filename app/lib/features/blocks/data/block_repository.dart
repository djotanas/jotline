import 'package:drift/drift.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/database/position_allocator.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/ordering/placement.dart';

/// Reads and writes the blocks of a page.
///
/// Never writes `version`: only the server increments it (ADR 0013).
class BlockRepository {
  new(this._database, this._clock, this._ids, this._localUser)
    : _allocator = PositionAllocator(_database);

  final AppDatabase _database;
  final Clock _clock;
  final IdGenerator _ids;
  final LocalUserRepository _localUser;
  final PositionAllocator _allocator;

  Future<String> create(
    String pageId, {
    required String type,
    required String contentJson,
    Placement at = const AtEnd(),
  }) async {
    final userId = await _localUser.id();
    final now = _clock.now();
    final id = _ids.newId();
    await _database.transaction(() async {
      final position = await _allocator.keyFor(
        OrderedTable.blocks,
        parentId: pageId,
        at: at,
      );
      await _database
          .into(_database.blocks)
          .insert(
            BlocksCompanion.insert(
              id: id,
              pageId: pageId,
              type: type,
              contentJson: contentJson,
              position: position,
              updatedAt: now,
              updatedBy: userId,
            ),
          );
    });
    return id;
  }

  Future<void> updateContent(String id, String contentJson) async {
    final userId = await _localUser.id();
    await (_database.update(
      _database.blocks,
    )..where((t) => t.id.equals(id))).write(
      BlocksCompanion(
        contentJson: Value(contentJson),
        updatedAt: Value(_clock.now()),
        updatedBy: Value(userId),
      ),
    );
  }

  /// Moves the block among its siblings, changing only that row.
  Future<void> move(String id, Placement to) async {
    final userId = await _localUser.id();
    final now = _clock.now();
    await _database.transaction(() async {
      final block = await (_database.select(
        _database.blocks,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (block == null) return;
      final position = await _allocator.keyFor(
        OrderedTable.blocks,
        parentId: block.pageId,
        at: to,
        movingId: id,
      );
      await (_database.update(
        _database.blocks,
      )..where((t) => t.id.equals(id))).write(
        BlocksCompanion(
          position: Value(position),
          updatedAt: Value(now),
          updatedBy: Value(userId),
        ),
      );
    });
  }

  /// Sets `deleted_at` once; a later call keeps the original value.
  Future<void> moveToTrash(String id) async {
    await (_database.update(_database.blocks)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(BlocksCompanion(deletedAt: Value(_clock.now())));
  }

  Stream<List<Block>> watchByPage(String pageId) {
    final blocks = _database.blocks;
    final pages = _database.pages;
    final notebooks = _database.notebooks;
    final query =
        _database.select(blocks).join([
            innerJoin(pages, pages.id.equalsExp(blocks.pageId)),
            innerJoin(notebooks, notebooks.id.equalsExp(pages.notebookId)),
          ])
          ..where(
            blocks.pageId.equals(pageId) &
                blocks.deletedAt.isNull() &
                pages.deletedAt.isNull() &
                notebooks.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(blocks.position),
            OrderingTerm.asc(blocks.id),
          ]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(blocks)],
    );
  }
}
