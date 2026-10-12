import 'package:drift/drift.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/database/tables/member_role.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/core/text/title_rules.dart';
import 'package:jotline/core/theme/notebook_palette.dart';

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
  Future<void> archive(String id) => _setArchivedAt(id, _clock.now());

  Future<void> unarchive(String id) => _setArchivedAt(id, null);

  Future<void> _setArchivedAt(String id, DateTime? archivedAt) async {
    final userId = await _localUser.id();
    await (_database.update(_database.notebookMembers)
          ..where((t) => t.notebookId.equals(id) & t.userId.equals(userId)))
        .write(NotebookMembersCompanion(archivedAt: Value(archivedAt)));
  }

  /// Sets `deleted_at` once; a later call keeps the original value.
  Future<void> moveToTrash(String id) async {
    await (_database.update(_database.notebooks)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .write(NotebooksCompanion(deletedAt: Value(_clock.now())));
  }

  Stream<List<Notebook>> watchActive() {
    return _watch(
      archived: false,
      order: (notebooks, members) => [
        OrderingTerm.desc(notebooks.createdAt),
        OrderingTerm.desc(notebooks.id),
      ],
    );
  }

  Stream<List<Notebook>> watchArchived() {
    return _watch(
      archived: true,
      order: (notebooks, members) => [
        OrderingTerm.desc(members.archivedAt),
        OrderingTerm.desc(notebooks.id),
      ],
    );
  }

  Stream<List<Notebook>> _watch({
    required bool archived,
    required List<OrderingTerm> Function(
      $NotebooksTable notebooks,
      $NotebookMembersTable members,
    )
    order,
  }) {
    final notebooks = _database.notebooks;
    final members = _database.notebookMembers;
    return Stream.fromFuture(_localUser.id()).asyncExpand((userId) {
      final query =
          _database.select(notebooks).join([
              innerJoin(
                members,
                members.notebookId.equalsExp(notebooks.id) &
                    members.userId.equals(userId),
              ),
            ])
            ..where(
              notebooks.deletedAt.isNull() &
                  (archived
                      ? members.archivedAt.isNotNull()
                      : members.archivedAt.isNull()),
            )
            ..orderBy(order(notebooks, members));
      return query.watch().map(
        (rows) => [for (final row in rows) row.readTable(notebooks)],
      );
    });
  }
}
