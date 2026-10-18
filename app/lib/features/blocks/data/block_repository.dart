import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/database/position_allocator.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/features/blocks/data/block_content.dart';

/// One write of a [BlockRepository.applyChanges] batch.
sealed class BlockChange {
  const new();
}

/// Creates a block; [key] names it in the batch result and in later
/// [After] placements of the same batch.
final class Insert extends BlockChange {
  const new(this.key, this.type, this.content, this.at);

  final String key;
  final BlockType type;
  final BlockContent content;
  final Placement at;
}

/// Writes [type] and [content]; a block that already holds both is left
/// untouched.
final class Update extends BlockChange {
  const new(this.id, this.type, this.content);

  final String id;
  final BlockType type;
  final BlockContent content;
}

/// Sets `deleted_at` on the block.
final class Trash extends BlockChange {
  const new(this.id);

  final String id;
}

/// Moves the block among its siblings.
final class Move extends BlockChange {
  const new(this.id, this.to);

  final String id;
  final Placement to;
}

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

  /// Runs [changes] in order in one transaction and returns the new block id
  /// of each [Insert.key]. Any failure rolls back the whole batch.
  Future<Map<String, String>> applyChanges(
    String pageId,
    List<BlockChange> changes,
  ) async {
    final userId = await _localUser.id();
    final now = _clock.now();
    final inserted = <String, String>{};
    Placement resolve(Placement at) => switch (at) {
      After(:final id) when inserted.containsKey(id) => After(inserted[id]!),
      _ => at,
    };
    await _database.transaction(() async {
      for (final change in changes) {
        switch (change) {
          case Insert(:final key, :final type, :final content, :final at):
            final id = _ids.newId();
            final position = await _allocator.keyFor(
              OrderedTable.blocks,
              parentId: pageId,
              at: resolve(at),
            );
            await _database
                .into(_database.blocks)
                .insert(
                  BlocksCompanion.insert(
                    id: id,
                    pageId: pageId,
                    type: type.id,
                    contentJson: content.forType(type).toJson(),
                    position: position,
                    updatedAt: now,
                    updatedBy: userId,
                  ),
                );
            inserted[key] = id;
          case Update(:final id, :final type, :final content):
            final contentJson = content.forType(type).toJson();
            await (_database.update(_database.blocks)..where(
                  (t) =>
                      t.id.equals(id) &
                      (t.type.equals(type.id).not() |
                          t.contentJson.equals(contentJson).not()),
                ))
                .write(
                  BlocksCompanion(
                    type: Value(type.id),
                    contentJson: Value(contentJson),
                    updatedAt: Value(now),
                    updatedBy: Value(userId),
                  ),
                );
          case Trash(:final id):
            await (_database.update(_database.blocks)
                  ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
                .write(BlocksCompanion(deletedAt: Value(now)));
          case Move(:final id, :final to):
            final position = await _allocator.keyFor(
              OrderedTable.blocks,
              parentId: pageId,
              at: resolve(to),
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
        }
      }
    });
    return inserted;
  }

  /// The page's blocks once, with the same filter and order as
  /// [watchByPage].
  Future<List<Block>> loadPage(String pageId) => _byPage(pageId).get();

  Stream<List<Block>> watchByPage(String pageId) => _byPage(pageId).watch();

  Selectable<Block> _byPage(String pageId) => _byPageQuery(
    _database,
    pageId,
  ).map((row) => row.readTable(_database.blocks));

  @visibleForTesting
  static GenerationContext byPageContext(AppDatabase database, String pageId) =>
      _byPageQuery(database, pageId).constructQuery();

  static JoinedSelectStatement<HasResultSet, dynamic> _byPageQuery(
    AppDatabase database,
    String pageId,
  ) {
    final blocks = database.blocks;
    final pages = database.pages;
    final notebooks = database.notebooks;
    final query =
        database.select(blocks).join([
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
    return query;
  }
}
