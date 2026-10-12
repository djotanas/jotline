import 'package:drift/drift.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/database/position_allocator.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/ordering/placement.dart';
import 'package:jotline/core/text/title_rules.dart';

/// Reads and writes the pages of a notebook.
class PageRepository {
  new(this._database, this._clock, this._ids, this._localUser)
    : _allocator = PositionAllocator(_database);

  final AppDatabase _database;
  final Clock _clock;
  final IdGenerator _ids;
  final LocalUserRepository _localUser;
  final PositionAllocator _allocator;

  /// Creates a page at the end of the notebook.
  Future<String> create(String notebookId, {String title = ''}) async {
    final trimmed = pageTitle(title);
    final userId = await _localUser.id();
    final now = _clock.now();
    final id = _ids.newId();
    await _database.transaction(() async {
      final position = await _allocator.keyFor(
        OrderedTable.pages,
        parentId: notebookId,
        at: const AtEnd(),
      );
      await _database
          .into(_database.pages)
          .insert(
            PagesCompanion.insert(
              id: id,
              notebookId: notebookId,
              title: trimmed,
              position: position,
              updatedAt: now,
              updatedBy: userId,
            ),
          );
    });
    return id;
  }

  Future<void> rename(String id, String title) async {
    final trimmed = pageTitle(title);
    final userId = await _localUser.id();
    await (_database.update(
      _database.pages,
    )..where((t) => t.id.equals(id))).write(
      PagesCompanion(
        title: Value(trimmed),
        updatedAt: Value(_clock.now()),
        updatedBy: Value(userId),
      ),
    );
  }

  /// Moves the page among its siblings, changing only that row.
  Future<void> move(String id, Placement to) async {
    final userId = await _localUser.id();
    final now = _clock.now();
    await _database.transaction(() async {
      final page = await (_database.select(
        _database.pages,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (page == null) return;
      final position = await _allocator.keyFor(
        OrderedTable.pages,
        parentId: page.notebookId,
        at: to,
        movingId: id,
      );
      await (_database.update(
        _database.pages,
      )..where((t) => t.id.equals(id))).write(
        PagesCompanion(
          position: Value(position),
          updatedAt: Value(now),
          updatedBy: Value(userId),
        ),
      );
    });
  }

  /// Sets `deleted_at` once; a later call keeps the original value.
  Future<void> moveToTrash(String id) async {
    await (_database.update(_database.pages)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(PagesCompanion(deletedAt: Value(_clock.now())));
  }

  Stream<List<NotebookPage>> watchByNotebook(String notebookId) {
    final pages = _database.pages;
    final notebooks = _database.notebooks;
    final query =
        _database.select(pages).join([
            innerJoin(notebooks, notebooks.id.equalsExp(pages.notebookId)),
          ])
          ..where(
            pages.notebookId.equals(notebookId) &
                pages.deletedAt.isNull() &
                notebooks.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(pages.position),
            OrderingTerm.asc(pages.id),
          ]);
    return query.watch().map(
      (rows) => [for (final row in rows) row.readTable(pages)],
    );
  }
}
