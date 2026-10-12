import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/app_database.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';

final notebookRepositoryProvider = Provider<NotebookRepository>(
  (ref) => NotebookRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(localUserRepositoryProvider),
  ),
);

final StreamProvider<List<Notebook>> activeNotebooksProvider =
    StreamProvider.autoDispose<List<Notebook>>(
      (ref) => ref
          .watch(notebookRepositoryProvider)
          .watchSummaries(archived: false)
          .map((rows) => [for (final row in rows) row.notebook]),
      retry: (_, _) => null,
    );

final StreamProvider<List<Notebook>> archivedNotebooksProvider =
    StreamProvider.autoDispose<List<Notebook>>(
      (ref) => ref
          .watch(notebookRepositoryProvider)
          .watchSummaries(archived: true)
          .map((rows) => [for (final row in rows) row.notebook]),
      retry: (_, _) => null,
    );
