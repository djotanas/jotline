import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/ids/id_generator.dart';

/// Owns the anonymous author id used before login (ADR 0011).
class LocalUserRepository {
  new(this._database, this._ids);

  final AppDatabase _database;
  final IdGenerator _ids;
  Future<String>? _id;

  /// Returns the anonymous user id, creating it on the first call ever made
  /// against the database.
  Future<String> id() => _id ??= _loadOrCreate();

  Future<String> _loadOrCreate() {
    return _database.transaction(() async {
      await _database
          .into(_database.localUser)
          .insert(
            LocalUserCompanion.insert(slot: const Value(1), id: _ids.newId()),
            mode: InsertMode.insertOrIgnore,
          );
      final row = await _database.select(_database.localUser).getSingle();
      return row.id;
    });
  }
}

final localUserRepositoryProvider = Provider<LocalUserRepository>(
  (ref) => LocalUserRepository(
    ref.watch(databaseProvider),
    ref.watch(idGeneratorProvider),
  ),
);
