import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:jotline/core/clock/clock.dart';
import 'package:jotline/core/database/database_provider.dart';
import 'package:jotline/core/database/local_user_repository.dart';
import 'package:jotline/core/ids/id_generator.dart';
import 'package:jotline/features/notebooks/data/notebook_repository.dart';
import 'package:jotline/features/notebooks/data/notebook_sort_provider.dart';
import 'package:jotline/features/notebooks/data/notebook_summary.dart';

final notebookRepositoryProvider = Provider<NotebookRepository>(
  (ref) => NotebookRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(localUserRepositoryProvider),
  ),
);

/// Notebooks of the active (`false`) or archived (`true`) tab, sorted by
/// [notebookSortProvider].
final StreamProviderFamily<List<NotebookSummary>, bool>
notebookSummariesProvider = StreamProvider.autoDispose
    .family<List<NotebookSummary>, bool>((ref, archived) {
      final sort = ref.watch(notebookSortProvider);
      return ref
          .watch(notebookRepositoryProvider)
          .watchSummaries(archived: archived)
          .map((rows) => sortNotebooks(rows, sort));
    }, retry: (_, _) => null);

final StreamProviderFamily<NotebookSummary?, String> notebookProvider =
    StreamProvider.autoDispose.family<NotebookSummary?, String>(
      (ref, id) => ref.watch(notebookRepositoryProvider).watchOne(id),
      retry: (_, _) => null,
    );

final StreamProvider<List<TrashedNotebook>> trashedNotebooksProvider =
    StreamProvider.autoDispose<List<TrashedNotebook>>(
      (ref) => ref.watch(notebookRepositoryProvider).watchTrashed(),
      retry: (_, _) => null,
    );
