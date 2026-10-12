import 'package:flutter_riverpod/misc.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/pages/data/page_repository.dart';

import 'fakes.dart';
import 'test_database.dart';

/// An in-memory database with a fake clock and sequential ids, plus
/// repositories built on them for seeding and asserting rows.
class TestApp {
  new({DateTime? now})
    : clock = FakeClock(now ?? DateTime.utc(2026, 10, 12, 15)),
      ids = SequentialIdGenerator(),
      db = createTestDatabase() {
    final localUser = LocalUserRepository(db, ids);
    notebooks = NotebookRepository(db, clock, ids, localUser);
    pages = PageRepository(db, clock, ids, localUser);
  }

  final FakeClock clock;
  final SequentialIdGenerator ids;
  final AppDatabase db;
  late final NotebookRepository notebooks;
  late final PageRepository pages;

  List<Override> get overrides => [
    databaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(clock),
    idGeneratorProvider.overrideWithValue(ids),
  ];

  Future<NotebookPage> page(String id) =>
      (db.select(db.pages)..where((t) => t.id.equals(id))).getSingle();

  Future<Notebook> notebook(String id) =>
      (db.select(db.notebooks)..where((t) => t.id.equals(id))).getSingle();
}
