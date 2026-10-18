import 'package:drift/drift.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/database/tables/member_role.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/text/title_rules.dart';
import 'package:jotline/core/theme/notebook_palette.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';

/// A notebook in the trash.
final class TrashedNotebook {
  const new({required this.notebook, required this.pageCount, this.archivedAt});

  /// Its `deletedAt` is non-null.
  final Notebook notebook;

  /// Pages not deleted on their own.
  final int pageCount;

  /// The local user's `archived_at`, kept while the notebook is trashed.
  final DateTime? archivedAt;
}

/// Reads and writes notebooks and the local user's membership in them.
class NotebookRepository {
  new(this._database, this._clock, this._ids, this._localUser);

  final AppDatabase _database;
  final Clock _clock;
  final IdGenerator _ids;
  final LocalUserRepository _localUser;

  /// Creates a notebook and its `owner` member row in one transaction.
  Future<String> create({
    required String title,
    required CoverPattern cover,
    required NotebookColor color,
  }) async {
    final trimmed = notebookTitle(title);
    final userId = await _localUser.id();
    final now = _clock.now();
    final notebookId = _ids.newId();
    final memberId = _ids.newId();
    await _database.transaction(() async {
      await _database
          .into(_database.notebooks)
          .insert(
            NotebooksCompanion.insert(
              id: notebookId,
              title: trimmed,
              cover: cover,
              color: color,
              createdBy: userId,
              createdAt: now,
            ),
          );
      await _database
          .into(_database.notebookMembers)
          .insert(
            NotebookMembersCompanion.insert(
              id: memberId,
              notebookId: notebookId,
              userId: userId,
              role: MemberRole.owner,
              addedBy: userId,
              createdAt: now,
            ),
          );
    });
    return notebookId;
  }

  /// Writes only the given fields of the notebook.
  Future<void> update(
    String id, {
    String? title,
    CoverPattern? cover,
    NotebookColor? color,
  }) async {
    final trimmed = title == null ? null : notebookTitle(title);
    if (trimmed == null && cover == null && color == null) return;
    await (_database.update(
      _database.notebooks,
    )..where((t) => t.id.equals(id))).write(
      NotebooksCompanion(
        title: Value.absentIfNull(trimmed),
        cover: Value.absentIfNull(cover),
        color: Value.absentIfNull(color),
      ),
    );
  }

  /// Archives the notebook for the local user only (ADR 0012).
  Future<void> archive(String id) => setArchivedAt(id, _clock.now());

  Future<void> unarchive(String id) => setArchivedAt(id, null);

  /// Writes `archived_at` on the local user's member row; undo uses it to put
  /// back the previous value.
  Future<void> setArchivedAt(String id, DateTime? value) async {
    final userId = await _localUser.id();
    await (_database.update(_database.notebookMembers)
          ..where((t) => t.notebookId.equals(id) & t.userId.equals(userId)))
        .write(NotebookMembersCompanion(archivedAt: Value(value)));
  }

  /// Sets `deleted_at` once; a later call keeps the original value.
  Future<void> moveToTrash(String id) async {
    await (_database.update(_database.notebooks)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(NotebooksCompanion(deletedAt: Value(_clock.now())));
  }

  /// Clears only `notebooks.deleted_at`; no page or block row is written.
  Future<void> restore(String id) async {
    await (_database.update(_database.notebooks)..where((t) => t.id.equals(id)))
        .write(const NotebooksCompanion(deletedAt: Value(null)));
  }

  /// Undo of [restore]: writes the original [deletedAt] back.
  Future<void> putBackInTrash(String id, DateTime deletedAt) async {
    await (_database.update(_database.notebooks)..where((t) => t.id.equals(id)))
        .write(NotebooksCompanion(deletedAt: Value(deletedAt)));
  }

  /// Notebooks not in the trash on the active or archived tab, unordered.
  Stream<List<NotebookSummary>> watchSummaries({required bool archived}) {
    return _watchSummaries(
      (notebooks, members) => archived
          ? members.archivedAt.isNotNull()
          : members.archivedAt.isNull(),
    ).map((rows) => rows.toList());
  }

  /// Emits `null` once the notebook is in the trash.
  Stream<NotebookSummary?> watchOne(String id) {
    return _watchSummaries((notebooks, members) => notebooks.id.equals(id))
        .map((rows) => rows.firstOrNull);
  }

  /// Notebooks in the trash, newest `deleted_at` first, then `id` descending.
  Stream<List<TrashedNotebook>> watchTrashed() {
    final notebooks = _database.notebooks;
    final members = _database.notebookMembers;
    final pages = _database.pages;
    final pageCount = pages.id.count();
    return Stream.fromFuture(_localUser.id()).asyncExpand((userId) {
      final query =
          _database.select(notebooks).join([
              innerJoin(
                members,
                members.notebookId.equalsExp(notebooks.id) &
                    members.userId.equals(userId),
              ),
              leftOuterJoin(
                pages,
                pages.notebookId.equalsExp(notebooks.id) &
                    pages.deletedAt.isNull(),
                useColumns: false,
              ),
            ])
            ..addColumns([pageCount])
            ..where(notebooks.deletedAt.isNotNull())
            ..groupBy([notebooks.id])
            ..orderBy([
              OrderingTerm.desc(notebooks.deletedAt),
              OrderingTerm.desc(notebooks.id),
            ]);
      return query.watch().map(
        (rows) => [
          for (final row in rows)
            TrashedNotebook(
              notebook: row.readTable(notebooks),
              pageCount: row.read(pageCount) ?? 0,
              archivedAt: row.readTable(members).archivedAt,
            ),
        ],
      );
    });
  }

  Stream<Iterable<NotebookSummary>> _watchSummaries(
    Expression<bool> Function(
      $NotebooksTable notebooks,
      $NotebookMembersTable members,
    )
    filter,
  ) {
    final notebooks = _database.notebooks;
    final members = _database.notebookMembers;
    final pages = _database.pages;
    final blocks = _database.blocks;
    final pageCount = pages.id.count(distinct: true);
    final lastPageEdit = pages.updatedAt.max();
    final lastBlockEdit = blocks.updatedAt.max();
    final lastBlockDelete = blocks.deletedAt.max();
    return Stream.fromFuture(_localUser.id()).asyncExpand((userId) {
      final query =
          _database.select(notebooks).join([
              innerJoin(
                members,
                members.notebookId.equalsExp(notebooks.id) &
                    members.userId.equals(userId),
              ),
              leftOuterJoin(
                pages,
                pages.notebookId.equalsExp(notebooks.id) &
                    pages.deletedAt.isNull(),
                useColumns: false,
              ),
              leftOuterJoin(
                blocks,
                blocks.pageId.equalsExp(pages.id),
                useColumns: false,
              ),
            ])
            ..addColumns([
              pageCount,
              lastPageEdit,
              lastBlockEdit,
              lastBlockDelete,
            ])
            ..where(notebooks.deletedAt.isNull() & filter(notebooks, members))
            ..groupBy([notebooks.id]);
      return query.watch().map(
        (rows) => rows.map((row) {
          final notebook = row.readTable(notebooks);
          return NotebookSummary(
            notebook: notebook,
            pageCount: row.read(pageCount) ?? 0,
            lastEditedAt: _latest([
              row.read(lastPageEdit),
              row.read(lastBlockEdit),
              row.read(lastBlockDelete),
            ], fallback: notebook.createdAt),
            archivedAt: row.readTable(members).archivedAt,
          );
        }),
      );
    });
  }

  static DateTime _latest(
    Iterable<DateTime?> dates, {
    required DateTime fallback,
  }) {
    DateTime? latest;
    for (final date in dates) {
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    return latest ?? fallback;
  }
}
